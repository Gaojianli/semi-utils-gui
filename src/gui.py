"""
Semi-Utils GUI 版本 - Qt Quick (QML) + Material Design
基于 PySide6 的现代化图片水印处理工具
"""

import sys
import os
from pathlib import Path
from multiprocessing import freeze_support

from PySide6.QtGui import QGuiApplication, QIcon
from PySide6.QtQml import QQmlApplicationEngine

from src.ui.backend import Backend


def guimain():
    freeze_support()

    # 设置 Qt Quick Controls 样式
    os.environ["QT_QUICK_CONTROLS_STYLE"] = "Material"
    os.environ["QT_QUICK_CONTROLS_MATERIAL_THEME"] = "Light"
    os.environ["QT_QUICK_CONTROLS_MATERIAL_ACCENT"] = "Teal"

    app = QGuiApplication(sys.argv)
    app.setApplicationName("Semi-Utils-GUI")
    app.setOrganizationName("Semi-Utils-GUI")

    # 设置应用图标
    icon_path = Path(__file__).parent.parent / "logo.ico"
    if icon_path.exists():
        app.setWindowIcon(QIcon(str(icon_path)))

    # 创建后端
    backend = Backend()

    # 创建 QML 引擎
    engine = QQmlApplicationEngine()

    # 将后端暴露给 QML
    engine.rootContext().setContextProperty("backend", backend)

    # 加载 QML (支持 PyInstaller 打包)
    if getattr(sys, 'frozen', False):
        # 打包后的路径
        base_path = Path(sys._MEIPASS)
    else:
        # 开发环境路径
        base_path = Path(__file__).parent.parent
    qml_file = base_path / "src/layout" / "main.qml"
    engine.load(qml_file)

    if not engine.rootObjects():
        print("Error: Failed to load QML file")
        sys.exit(-1)

    sys.exit(app.exec())


if __name__ == "__main__":
    guimain()
