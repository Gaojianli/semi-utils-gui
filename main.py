"""
Semi-Utils GUI - 启动入口
"""

import os
import sys


def get_working_dir():
    """获取工作目录（用户数据存放位置）"""
    if getattr(sys, 'frozen', False):
        # 打包后的环境
        if sys.platform == 'darwin':
            # macOS .app 包，工作目录设为 .app 所在目录
            app_path = os.path.dirname(sys.executable)  # Contents/MacOS
            app_path = os.path.dirname(app_path)  # Contents
            app_path = os.path.dirname(app_path)  # .app
            app_path = os.path.dirname(app_path)  # .app 所在目录
            return app_path
        else:
            # Windows/Linux
            return os.path.dirname(sys.executable)
    else:
        # 开发环境
        return os.path.dirname(os.path.abspath(__file__))


if __name__ == "__main__":
    # 切换工作目录
    os.chdir(get_working_dir())

    # 确保 input 和 output 目录存在
    os.makedirs('./input', exist_ok=True)
    os.makedirs('./output', exist_ok=True)

    from src.gui import guimain
    guimain()
