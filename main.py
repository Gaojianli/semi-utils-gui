"""
Semi-Utils GUI 版本 - Qt Quick (QML) + Material Design
基于 PySide6 的现代化图片水印处理工具
"""

import sys
import os
import tempfile
import logging
from pathlib import Path
from multiprocessing import freeze_support

from PySide6.QtCore import QObject, Property, Signal, Slot, QThread, QUrl, QTimer
from PySide6.QtGui import QGuiApplication, QIcon
from PySide6.QtQml import QQmlApplicationEngine

from entity.image_container import ImageContainer
from entity.image_processor import ProcessorChain
from init import (
    LAYOUT_ITEMS,
    layout_items_dict,
    ITEM_LIST,
    config,
    SHADOW_PROCESSOR,
    MARGIN_PROCESSOR,
    PADDING_TO_ORIGINAL_RATIO_PROCESSOR,
    SIMPLE_PROCESSOR,
)
from utils import get_file_list
from translations import TRANSLATIONS

# 布局名称到翻译 key 的映射
LAYOUT_NAME_KEYS = {
    "normal(Logo 居右)": "layout_normal_right",
    "normal": "layout_normal",
    "normal(黑红配色，Logo 居右)": "layout_normal_dark_right",
    "normal(黑红配色)": "layout_normal_dark",
    "normal(自定义配置)": "layout_custom",
    "1:1填充": "layout_square",
    "简洁": "layout_simple",
    "背景模糊": "layout_blur",
    "背景模糊+白框": "layout_blur_white",
    "白色边框": "layout_white_border",
}


class PreviewWorker(QThread):
    """预览生成工作线程"""

    preview_ready = Signal(str)  # 预览图片路径
    error = Signal(str)

    def __init__(self, file_path, config, output_path, parent=None):
        super().__init__(parent)
        self.file_path = file_path
        self.config = config
        self.output_path = output_path
        self._cancelled = False

    def cancel(self):
        self._cancelled = True

    def run(self):
        try:
            if self._cancelled:
                return

            # 创建处理链
            processor_chain = ProcessorChain()

            # 如果需要添加阴影
            if (
                self.config.has_shadow_enabled()
                and "square" != self.config.get_layout_type()
            ):
                processor_chain.add(SHADOW_PROCESSOR)

            # 根据布局添加不同的水印处理器
            if self.config.get_layout_type() in layout_items_dict:
                processor_chain.add(
                    layout_items_dict.get(self.config.get_layout_type()).processor
                )
            else:
                processor_chain.add(SIMPLE_PROCESSOR)

            # 如果需要添加白边
            if (
                self.config.has_white_margin_enabled()
                and "watermark" in self.config.get_layout_type()
            ):
                processor_chain.add(MARGIN_PROCESSOR)

            # 如果需要按原有比例填充
            if (
                self.config.has_padding_with_original_ratio_enabled()
                and "square" != self.config.get_layout_type()
            ):
                processor_chain.add(PADDING_TO_ORIGINAL_RATIO_PROCESSOR)

            if self._cancelled:
                return

            # 处理图片
            container = ImageContainer(Path(self.file_path))
            container.is_use_equivalent_focal_length(
                self.config.use_equivalent_focal_length()
            )
            processor_chain.process(container)

            if self._cancelled:
                container.close()
                return

            # 保存预览图片
            container.save(self.output_path, quality=85)
            container.close()

            self.preview_ready.emit(str(self.output_path))

        except Exception as e:
            logging.exception(f"预览生成错误: {e}")
            self.error.emit(str(e))


class ProcessWorker(QThread):
    """图片处理工作线程"""

    progress = Signal(int, int)  # current, total
    finished = Signal()
    error = Signal(str)

    def __init__(self, file_list, config, parent=None):
        super().__init__(parent)
        self.file_list = file_list
        self.config = config
        self._is_cancelled = False

    def cancel(self):
        self._is_cancelled = True

    def run(self):
        try:
            processor_chain = ProcessorChain()

            if (
                self.config.has_shadow_enabled()
                and "square" != self.config.get_layout_type()
            ):
                processor_chain.add(SHADOW_PROCESSOR)

            if self.config.get_layout_type() in layout_items_dict:
                processor_chain.add(
                    layout_items_dict.get(self.config.get_layout_type()).processor
                )
            else:
                processor_chain.add(SIMPLE_PROCESSOR)

            if (
                self.config.has_white_margin_enabled()
                and "watermark" in self.config.get_layout_type()
            ):
                processor_chain.add(MARGIN_PROCESSOR)

            if (
                self.config.has_padding_with_original_ratio_enabled()
                and "square" != self.config.get_layout_type()
            ):
                processor_chain.add(PADDING_TO_ORIGINAL_RATIO_PROCESSOR)

            total = len(self.file_list)
            for idx, source_path in enumerate(self.file_list):
                if self._is_cancelled:
                    break

                try:
                    container = ImageContainer(source_path)
                    container.is_use_equivalent_focal_length(
                        self.config.use_equivalent_focal_length()
                    )
                    processor_chain.process(container)

                    target_path = Path(self.config.get_output_dir()).joinpath(
                        source_path.name
                    )
                    container.save(target_path, quality=self.config.get_quality())
                    container.close()
                except Exception as e:
                    self.error.emit(f"处理 {source_path.name} 失败: {str(e)}")

                self.progress.emit(idx + 1, total)

            self.finished.emit()
        except Exception as e:
            self.error.emit(str(e))


class Backend(QObject):
    """QML 后端接口"""

    # 信号定义
    layoutItemsChanged = Signal()
    layoutIndexChanged = Signal()
    logoEnabledChanged = Signal()
    logoItemsChanged = Signal()
    defaultLogoIndexChanged = Signal()
    qualityChanged = Signal()
    textItemsChanged = Signal()
    shadowEnabledChanged = Signal()
    whiteMarginEnabledChanged = Signal()
    paddingRatioEnabledChanged = Signal()
    equivFocalEnabledChanged = Signal()
    inputDirChanged = Signal()
    outputDirChanged = Signal()
    fileListChanged = Signal()
    fileCountChanged = Signal()
    selectedFileIndexChanged = Signal()
    previewImageChanged = Signal()
    previewLoadingChanged = Signal()
    previewMessageChanged = Signal()
    progressChanged = Signal()
    progressTextChanged = Signal()
    processingChanged = Signal()
    processingFinished = Signal()
    autoOpenOutputChanged = Signal()
    languageChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._config = config
        self._file_list = []
        self._file_paths = []
        self._selected_index = -1
        self._preview_image = ""
        self._preview_loading = False
        self._progress = 0
        self._processing = False
        self._auto_open_output = True
        self._preview_worker = None
        self._process_worker = None

        # 语言设置
        self._language = self._config.get_or_default("gui_language", "zh")
        self._translations = TRANSLATIONS.get(self._language, TRANSLATIONS["zh"])
        self._preview_message = self._translations["select_file_preview"]
        self._progress_text = self._translations["ready"]

        # 预览临时目录
        self._preview_dir = tempfile.mkdtemp()
        self._preview_counter = 0

        # 防抖定时器
        self._debounce_timer = QTimer()
        self._debounce_timer.setSingleShot(True)
        self._debounce_timer.timeout.connect(self._do_refresh_preview)

        # 文字位置索引映射
        self._text_indices = {
            "left_top": 0,
            "left_bottom": 0,
            "right_top": 0,
            "right_bottom": 0,
        }
        self._load_text_indices()

    def _load_text_indices(self):
        """加载文字位置索引"""
        for key in self._text_indices.keys():
            element = self._config._data["layout"]["elements"][key]
            name = element["name"]
            for i, item in enumerate(ITEM_LIST):
                if item.value == name:
                    self._text_indices[key] = i
                    break

    # ===== 布局设置 =====
    @Property(list, notify=layoutItemsChanged)
    def layoutItems(self):
        result = []
        for item in LAYOUT_ITEMS:
            key = LAYOUT_NAME_KEYS.get(item.name)
            if key and key in self._translations:
                result.append(self._translations[key])
            else:
                result.append(item.name)
        return result

    @Property(int, notify=layoutIndexChanged)
    def layoutIndex(self):
        layout_type = self._config.get_layout_type()
        for i, item in enumerate(LAYOUT_ITEMS):
            if item.value == layout_type:
                return i
        return 0

    @layoutIndex.setter
    def layoutIndex(self, index):
        if 0 <= index < len(LAYOUT_ITEMS):
            self._config.set_layout(LAYOUT_ITEMS[index].value)
            self.layoutIndexChanged.emit()
            self._schedule_preview_refresh()

    # ===== Logo 设置 =====
    @Property(bool, notify=logoEnabledChanged)
    def logoEnabled(self):
        return self._config.has_logo_enabled()

    @logoEnabled.setter
    def logoEnabled(self, enabled):
        if enabled:
            self._config.enable_logo()
        else:
            self._config.disable_logo()
        self.logoEnabledChanged.emit()
        self._schedule_preview_refresh()

    @Property(list, notify=logoItemsChanged)
    def logoItems(self):
        return [info["id"] for info in self._config._makes.values()]

    @Property(int, notify=defaultLogoIndexChanged)
    def defaultLogoIndex(self):
        current_path = self._config._data["logo"]["default"]["path"]
        for i, info in enumerate(self._config._makes.values()):
            if info["path"] == current_path:
                return i
        return 0

    @defaultLogoIndex.setter
    def defaultLogoIndex(self, index):
        paths = list(self._config._makes.values())
        if 0 <= index < len(paths):
            self._config.set_default_logo_path(paths[index]["path"])
            self.defaultLogoIndexChanged.emit()
            self._schedule_preview_refresh()

    # ===== 输出质量 =====
    @Property(int, notify=qualityChanged)
    def quality(self):
        return self._config.get_quality()

    @quality.setter
    def quality(self, value):
        self._config._data["base"]["quality"] = int(value)
        self.qualityChanged.emit()

    # ===== 文字设置 =====
    @Property(list, notify=textItemsChanged)
    def textItems(self):
        return [item.name for item in ITEM_LIST]

    @Property(int, constant=True)
    def customTextIndex(self):
        """返回自定义文字选项的索引"""
        for i, item in enumerate(ITEM_LIST):
            if item.value == "Custom":
                return i
        return -1

    @Slot(str, result=int)
    def getTextIndex(self, key):
        return self._text_indices.get(key, 0)

    @Slot(str, int)
    def setTextIndex(self, key, index):
        if 0 <= index < len(ITEM_LIST):
            self._text_indices[key] = index
            self._config._data["layout"]["elements"][key]["name"] = ITEM_LIST[
                index
            ].value
            self._schedule_preview_refresh()

    @Slot(str, result=str)
    def getCustomText(self, key):
        element = self._config._data["layout"]["elements"][key]
        return element.get("value", "")

    @Slot(str, str)
    def setCustomText(self, key, text):
        self._config._data["layout"]["elements"][key]["value"] = text
        self._schedule_preview_refresh()

    # ===== 效果设置 =====
    @Property(bool, notify=shadowEnabledChanged)
    def shadowEnabled(self):
        return self._config.has_shadow_enabled()

    @shadowEnabled.setter
    def shadowEnabled(self, enabled):
        if enabled:
            self._config.enable_shadow()
        else:
            self._config.disable_shadow()
        self.shadowEnabledChanged.emit()
        self._schedule_preview_refresh()

    @Property(bool, notify=whiteMarginEnabledChanged)
    def whiteMarginEnabled(self):
        return self._config.has_white_margin_enabled()

    @whiteMarginEnabled.setter
    def whiteMarginEnabled(self, enabled):
        if enabled:
            self._config.enable_white_margin()
        else:
            self._config.disable_white_margin()
        self.whiteMarginEnabledChanged.emit()
        self._schedule_preview_refresh()

    @Property(bool, notify=paddingRatioEnabledChanged)
    def paddingRatioEnabled(self):
        return self._config.has_padding_with_original_ratio_enabled()

    @paddingRatioEnabled.setter
    def paddingRatioEnabled(self, enabled):
        if enabled:
            self._config.enable_padding_with_original_ratio()
        else:
            self._config.disable_padding_with_original_ratio()
        self.paddingRatioEnabledChanged.emit()
        self._schedule_preview_refresh()

    @Property(bool, notify=equivFocalEnabledChanged)
    def equivFocalEnabled(self):
        return self._config.use_equivalent_focal_length()

    @equivFocalEnabled.setter
    def equivFocalEnabled(self, enabled):
        if enabled:
            self._config.enable_equivalent_focal_length()
        else:
            self._config.disable_equivalent_focal_length()
        self.equivFocalEnabledChanged.emit()
        self._schedule_preview_refresh()

    # ===== 目录设置 =====
    @Property(str, notify=inputDirChanged)
    def inputDir(self):
        return self._config.get_input_dir()

    @inputDir.setter
    def inputDir(self, path):
        self._config._data["base"]["input_dir"] = path
        self.inputDirChanged.emit()

    @Property(str, notify=outputDirChanged)
    def outputDir(self):
        return self._config.get_output_dir()

    @outputDir.setter
    def outputDir(self, path):
        self._config._data["base"]["output_dir"] = path
        self.outputDirChanged.emit()

    # ===== 文件列表 =====
    @Property(list, notify=fileListChanged)
    def fileList(self):
        return self._file_list

    @Property(int, notify=fileCountChanged)
    def fileCount(self):
        return len(self._file_paths)

    @Property(int, notify=selectedFileIndexChanged)
    def selectedFileIndex(self):
        return self._selected_index

    @selectedFileIndex.setter
    def selectedFileIndex(self, index):
        if index != self._selected_index and 0 <= index < len(self._file_paths):
            self._selected_index = index
            self.selectedFileIndexChanged.emit()
            self._schedule_preview_refresh()

    @Slot()
    def refreshFileList(self):
        """刷新文件列表"""
        input_dir = self._config.get_input_dir()
        if os.path.exists(input_dir):
            self._file_paths = get_file_list(input_dir)
            self._file_list = [p.name for p in self._file_paths]
        else:
            self._file_paths = []
            self._file_list = []

        self.fileListChanged.emit()
        self.fileCountChanged.emit()

        # 自动选择第一个文件
        if self._file_paths:
            self._selected_index = 0
            self.selectedFileIndexChanged.emit()
            self._schedule_preview_refresh()
        else:
            self._selected_index = -1
            self.selectedFileIndexChanged.emit()
            self._preview_message = self._translations["select_file_preview"]
            self.previewMessageChanged.emit()

    @Slot(list)
    def addFiles(self, paths):
        """添加文件"""
        for path in paths:
            p = Path(path)
            if p not in self._file_paths:
                self._file_paths.append(p)
                self._file_list.append(p.name)

        self.fileListChanged.emit()
        self.fileCountChanged.emit()

        # 如果是第一次添加，自动选择
        if len(paths) > 0 and self._selected_index < 0:
            self._selected_index = 0
            self.selectedFileIndexChanged.emit()
            self._schedule_preview_refresh()

    @Slot()
    def clearFileList(self):
        """清空文件列表"""
        self._file_paths = []
        self._file_list = []
        self._selected_index = -1
        self._preview_image = ""
        self._preview_message = self._translations["select_file_preview"]

        self.fileListChanged.emit()
        self.fileCountChanged.emit()
        self.selectedFileIndexChanged.emit()
        self.previewImageChanged.emit()
        self.previewMessageChanged.emit()

    # ===== 预览 =====
    @Property(str, notify=previewImageChanged)
    def previewImage(self):
        return self._preview_image

    @Property(bool, notify=previewLoadingChanged)
    def previewLoading(self):
        return self._preview_loading

    @Property(str, notify=previewMessageChanged)
    def previewMessage(self):
        return self._preview_message

    def _schedule_preview_refresh(self):
        """调度预览刷新（防抖）"""
        self._debounce_timer.stop()
        self._debounce_timer.start(300)

    def _do_refresh_preview(self):
        """实际执行预览刷新"""
        if self._selected_index < 0 or self._selected_index >= len(self._file_paths):
            return

        file_path = str(self._file_paths[self._selected_index])
        if not os.path.exists(file_path):
            self._preview_message = self._translations["file_not_exist"]
            self.previewMessageChanged.emit()
            return

        # 取消之前的预览任务
        if self._preview_worker and self._preview_worker.isRunning():
            self._preview_worker.cancel()
            self._preview_worker.wait(1000)

        # 设置加载状态
        self._preview_loading = True
        self._preview_message = self._translations["generating_preview"]
        self.previewLoadingChanged.emit()
        self.previewMessageChanged.emit()

        # 生成新的预览文件名
        self._preview_counter += 1
        preview_path = os.path.join(
            self._preview_dir, f"preview_{self._preview_counter}.jpg"
        )

        # 启动预览工作线程
        self._preview_worker = PreviewWorker(file_path, self._config, preview_path)
        self._preview_worker.preview_ready.connect(self._on_preview_ready)
        self._preview_worker.error.connect(self._on_preview_error)
        self._preview_worker.start()

    @Slot()
    def refreshPreview(self):
        """手动刷新预览"""
        self._schedule_preview_refresh()

    def _on_preview_ready(self, path):
        """预览生成完成"""
        self._preview_loading = False
        self._preview_image = QUrl.fromLocalFile(path).toString()
        self._preview_message = ""
        self.previewLoadingChanged.emit()
        self.previewImageChanged.emit()
        self.previewMessageChanged.emit()

    def _on_preview_error(self, error_msg):
        """预览生成错误"""
        self._preview_loading = False
        self._preview_message = f"{self._translations['preview_failed']}\n{error_msg}"
        self.previewLoadingChanged.emit()
        self.previewMessageChanged.emit()

    # ===== 处理进度 =====
    @Property(int, notify=progressChanged)
    def progress(self):
        return self._progress

    @Property(str, notify=progressTextChanged)
    def progressText(self):
        return self._progress_text

    @Property(bool, notify=processingChanged)
    def processing(self):
        return self._processing

    @Property(bool, notify=autoOpenOutputChanged)
    def autoOpenOutput(self):
        return self._auto_open_output

    @autoOpenOutput.setter
    def autoOpenOutput(self, value):
        if self._auto_open_output != value:
            self._auto_open_output = value
            self.autoOpenOutputChanged.emit()

    # ===== 语言设置 =====
    @Property(list, constant=True)
    def languageOptions(self):
        return ["中文", "English"]

    @Property(int, notify=languageChanged)
    def languageIndex(self):
        return 0 if self._language == "zh" else 1

    @languageIndex.setter
    def languageIndex(self, index):
        lang = "zh" if index == 0 else "en"
        if self._language != lang:
            self._language = lang
            self._translations = TRANSLATIONS[lang]
            self._config.set("gui_language", lang)
            self._config.save()
            self.languageChanged.emit()
            self.layoutItemsChanged.emit()  # 更新布局选项翻译
            self._update_dynamic_texts()

    @Slot(str, result=str)
    def tr(self, key):
        """翻译函数"""
        return self._translations.get(key, key)

    def _update_dynamic_texts(self):
        """更新动态文本"""
        if not self._processing:
            self._progress_text = self._translations["ready"]
            self.progressTextChanged.emit()
        if self._selected_index < 0:
            self._preview_message = self._translations["select_file_preview"]
            self.previewMessageChanged.emit()

    # ===== 操作 =====
    @Slot()
    def saveConfig(self):
        """保存配置"""
        self._config.save()

    @Slot()
    def loadConfig(self):
        """加载配置"""
        self._load_text_indices()
        self.layoutIndexChanged.emit()
        self.logoEnabledChanged.emit()
        self.defaultLogoIndexChanged.emit()
        self.qualityChanged.emit()
        self.shadowEnabledChanged.emit()
        self.whiteMarginEnabledChanged.emit()
        self.paddingRatioEnabledChanged.emit()
        self.equivFocalEnabledChanged.emit()

    @Slot()
    def startProcessing(self):
        """开始处理"""
        if not self._file_paths:
            return

        output_dir = self._config.get_output_dir()
        os.makedirs(output_dir, exist_ok=True)

        self._processing = True
        self._progress = 0
        self._progress_text = self._translations["processing"]
        self.processingChanged.emit()
        self.progressChanged.emit()
        self.progressTextChanged.emit()

        self._process_worker = ProcessWorker(self._file_paths, self._config)
        self._process_worker.progress.connect(self._on_process_progress)
        self._process_worker.finished.connect(self._on_process_finished)
        self._process_worker.error.connect(self._on_process_error)
        self._process_worker.start()

    @Slot()
    def cancelProcessing(self):
        """取消处理"""
        if self._process_worker:
            self._process_worker.cancel()
            self._progress_text = self._translations["cancelling"]
            self.progressTextChanged.emit()

    def _on_process_progress(self, current, total):
        """处理进度更新"""
        self._progress = int(current / total * 100)
        self._progress_text = f"{self._translations['processing']} {current}/{total}"
        self.progressChanged.emit()
        self.progressTextChanged.emit()

    def _on_process_finished(self):
        """处理完成"""
        self._processing = False
        self._progress = 100
        self._progress_text = self._translations["completed"]
        self.processingChanged.emit()
        self.progressChanged.emit()
        self.progressTextChanged.emit()
        self.processingFinished.emit()

        # 如果开启了自动打开输出目录
        if self._auto_open_output:
            self.openOutputDir()

    def _on_process_error(self, error_msg):
        """处理错误"""
        self._progress_text = f"{self._translations['error']}{error_msg}"
        self.progressTextChanged.emit()

    @Slot()
    def openOutputDir(self):
        """打开输出目录"""
        output_dir = self._config.get_output_dir()
        if os.path.exists(output_dir):
            import subprocess
            import platform

            if platform.system() == "Darwin":
                subprocess.run(["open", output_dir])
            elif platform.system() == "Windows":
                subprocess.run(["explorer", output_dir])
            else:
                subprocess.run(["xdg-open", output_dir])


def main():
    freeze_support()

    # 设置 Qt Quick Controls 样式
    os.environ["QT_QUICK_CONTROLS_STYLE"] = "Material"
    os.environ["QT_QUICK_CONTROLS_MATERIAL_THEME"] = "Light"
    os.environ["QT_QUICK_CONTROLS_MATERIAL_ACCENT"] = "Teal"

    app = QGuiApplication(sys.argv)
    app.setApplicationName("Semi-Utils-GUI")
    app.setOrganizationName("Semi-Utils-GUI")

    # 设置应用图标
    icon_path = Path(__file__).parent / "logo.ico"
    if icon_path.exists():
        app.setWindowIcon(QIcon(str(icon_path)))

    # 创建后端
    backend = Backend()

    # 创建 QML 引擎
    engine = QQmlApplicationEngine()

    # 将后端暴露给 QML
    engine.rootContext().setContextProperty("backend", backend)

    # 加载 QML
    qml_file = Path(__file__).parent / "qml" / "main.qml"
    engine.load(qml_file)

    if not engine.rootObjects():
        print("Error: Failed to load QML file")
        sys.exit(-1)

    sys.exit(app.exec())


if __name__ == "__main__":
    main()
