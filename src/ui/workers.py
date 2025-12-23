"""
后台工作线程
"""

import logging
from pathlib import Path

from PySide6.QtCore import QThread, Signal

from src.entity.image_container import ImageContainer
from src.entity.image_processor import ProcessorChain
from src.init import (
    layout_items_dict,
    SHADOW_PROCESSOR,
    MARGIN_PROCESSOR,
    PADDING_TO_ORIGINAL_RATIO_PROCESSOR,
    SIMPLE_PROCESSOR,
)


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
            container = ImageContainer(Path(self.file_path), self.config.use_equivalent_focal_length())
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
                    container = ImageContainer(source_path, self.config.use_equivalent_focal_length())
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
