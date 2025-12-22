"""
数据提取和处理工具
"""


def calculate_pixel_count(width: int, height: int) -> str:
    """计算像素总数并转换为百万像素"""
    # 计算像素总数
    pixel_count = width * height
    # 计算百万像素数
    megapixel_count = pixel_count / 1000000.0
    # 返回结果字符串
    return f"{megapixel_count:.2f} MP"


def extract_attribute(data_dict: dict, *keys, default_value: str = '', prefix='', suffix='') -> str:
    """
    从字典中提取对应键的属性值

    :param data_dict: 包含属性值的字典
    :param keys: 一个或多个键
    :param default_value: 默认值，默认为空字符串
    :return: 对应的属性值或空字符串
    """
    for key in keys:
        if key in data_dict:
            return data_dict[key] + suffix
    return default_value


def extract_gps_lat_and_long(coords):
    """从元组中提取纬度和经度"""
    if isinstance(coords, tuple) and len(coords) == 2:
        lat, long = coords
        return lat, long
    return '', ''


def extract_gps_info(gps_info: str):
    """从 GPSPosition 字符串中提取纬度和经度"""
    try:
        lat, long = gps_info.split(", ")
        return lat, long
    except Exception:
        return '', ''
