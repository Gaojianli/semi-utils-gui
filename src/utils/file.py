"""
文件操作工具
"""

from pathlib import Path


def get_file_list(path):
    """
    获取 jpg 文件列表
    :param path: 路径
    :return: 文件名
    """
    path = Path(path)
    return [file_path for file_path in path.iterdir()
            if file_path.is_file() and file_path.suffix.lower() in ['.jpg', '.jpeg', '.png']]
