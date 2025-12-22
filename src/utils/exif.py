"""
EXIF 信息读取和格式化工具
"""

import logging

import exifread

logger = logging.getLogger(__name__)


def get_exif(path) -> dict:
    """
    使用 exifread 获取 EXIF 信息
    :param path: 照片路径
    :return: exif 信息字典
    """
    exif_dict = {}
    try:
        with open(path, 'rb') as f:
            tags = exifread.process_file(f, details=False)

        # 映射 exifread 标签到我们需要的格式
        tag_mapping = {
            # 相机信息
            'Image Make': 'Make',
            'Image Model': 'CameraModelName',
            # 镜头信息
            'EXIF LensModel': 'LensModel',
            'EXIF LensInfo': 'Lens',
            'EXIF LensMake': 'LensMake',
            # 拍摄参数
            'EXIF DateTimeOriginal': 'DateTimeOriginal',
            'EXIF FocalLength': 'FocalLength',
            'EXIF FocalLengthIn35mmFilm': 'FocalLengthIn35mmFormat',
            'EXIF FNumber': 'FNumber',
            'EXIF ISOSpeedRatings': 'ISO',
            'EXIF ExposureTime': 'ExposureTime',
            'EXIF ShutterSpeedValue': 'ShutterSpeedValue',
            # 方向
            'Image Orientation': 'Orientation',
            # GPS
            'GPS GPSLatitude': 'GPSLatitude',
            'GPS GPSLongitude': 'GPSLongitude',
            'GPS GPSLatitudeRef': 'GPSLatitudeRef',
            'GPS GPSLongitudeRef': 'GPSLongitudeRef',
        }

        for exif_tag, our_tag in tag_mapping.items():
            if exif_tag in tags:
                value = tags[exif_tag]
                # 转换值为字符串
                str_value = str(value)

                # 特殊处理某些字段
                if our_tag == 'FocalLength':
                    # 处理焦距格式 "50" 或 "50/1"
                    str_value = _format_focal_length(value)
                elif our_tag == 'FocalLengthIn35mmFormat':
                    str_value = str(value)
                elif our_tag == 'FNumber':
                    # 处理光圈值
                    str_value = _format_fnumber(value)
                elif our_tag == 'ExposureTime':
                    # 处理曝光时间
                    str_value = _format_exposure_time(value)
                elif our_tag == 'Orientation':
                    # 处理方向
                    str_value = _format_orientation(value)
                elif our_tag in ['GPSLatitude', 'GPSLongitude']:
                    # 处理 GPS 坐标
                    ref_tag = exif_tag + 'Ref'
                    ref = str(tags.get(ref_tag, '')) if ref_tag.replace('GPS GPS', 'GPS ') in tags else ''
                    str_value = _format_gps_coordinate(value, ref)

                exif_dict[our_tag] = str_value

        # 处理 GPS Position (组合)
        if 'GPSLatitude' in exif_dict and 'GPSLongitude' in exif_dict:
            lat_ref = str(tags.get('GPS GPSLatitudeRef', 'N'))
            lon_ref = str(tags.get('GPS GPSLongitudeRef', 'E'))
            lat = _format_gps_for_position(tags.get('GPS GPSLatitude'), lat_ref)
            lon = _format_gps_for_position(tags.get('GPS GPSLongitude'), lon_ref)
            if lat and lon:
                exif_dict['GPSPosition'] = f"{lat}, {lon}"

    except Exception as e:
        logger.error(f'get_exif error: {path} : {e}')

    return exif_dict


def _format_focal_length(value) -> str:
    """格式化焦距值"""
    try:
        # exifread 返回的值可能是 Ratio 对象
        if hasattr(value, 'values') and len(value.values) > 0:
            ratio = value.values[0]
            if hasattr(ratio, 'num') and hasattr(ratio, 'den'):
                focal = ratio.num / ratio.den if ratio.den != 0 else ratio.num
                return f"{focal:.1f}"
        return str(value).split()[0]
    except Exception:
        return str(value)


def _format_fnumber(value) -> str:
    """格式化光圈值"""
    try:
        if hasattr(value, 'values') and len(value.values) > 0:
            ratio = value.values[0]
            if hasattr(ratio, 'num') and hasattr(ratio, 'den'):
                f_num = ratio.num / ratio.den if ratio.den != 0 else ratio.num
                return f"{f_num:.1f}"
        # 尝试从字符串解析
        str_val = str(value)
        if '/' in str_val:
            parts = str_val.split('/')
            return f"{int(parts[0]) / int(parts[1]):.1f}"
        return str_val
    except Exception:
        return str(value)


def _format_exposure_time(value) -> str:
    """格式化曝光时间"""
    try:
        if hasattr(value, 'values') and len(value.values) > 0:
            ratio = value.values[0]
            if hasattr(ratio, 'num') and hasattr(ratio, 'den'):
                if ratio.den > ratio.num and ratio.num > 0:
                    # 分数形式，如 1/1000
                    return f"1/{int(ratio.den / ratio.num)}"
                else:
                    # 秒形式
                    exp = ratio.num / ratio.den if ratio.den != 0 else ratio.num
                    if exp >= 1:
                        return f"{exp:.0f}"
                    else:
                        return f"1/{int(1/exp)}"
        return str(value)
    except Exception:
        return str(value)


def _format_orientation(value) -> str:
    """格式化方向值"""
    orientation_map = {
        '1': 'Rotate 0',
        'Horizontal (normal)': 'Rotate 0',
        '3': 'Rotate 180',
        'Rotated 180': 'Rotate 180',
        '6': 'Rotate 90 CW',
        'Rotated 90 CW': 'Rotate 90 CW',
        '8': 'Rotate 270 CW',
        'Rotated 90 CCW': 'Rotate 270 CW',
    }
    str_val = str(value)
    return orientation_map.get(str_val, 'Rotate 0')


def _format_gps_coordinate(value, ref) -> str:
    """格式化 GPS 坐标"""
    try:
        if hasattr(value, 'values') and len(value.values) >= 3:
            degrees = _ratio_to_float(value.values[0])
            minutes = _ratio_to_float(value.values[1])
            seconds = _ratio_to_float(value.values[2])
            return f"{int(degrees)} deg {int(minutes)}' {seconds:.2f}\" {ref}"
    except Exception:
        pass
    return str(value)


def _format_gps_for_position(value, ref) -> str:
    """格式化 GPS 坐标用于 GPSPosition"""
    try:
        if hasattr(value, 'values') and len(value.values) >= 3:
            degrees = _ratio_to_float(value.values[0])
            minutes = _ratio_to_float(value.values[1])
            seconds = _ratio_to_float(value.values[2])
            return f"{int(degrees)} deg {int(minutes)}' {seconds:.2f}\" {ref}"
    except Exception:
        pass
    return ""


def _ratio_to_float(ratio) -> float:
    """将 Ratio 对象转换为浮点数"""
    if hasattr(ratio, 'num') and hasattr(ratio, 'den'):
        return ratio.num / ratio.den if ratio.den != 0 else float(ratio.num)
    return float(ratio)
