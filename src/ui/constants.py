"""
UI 相关的常量定义
"""

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

# 文字选项 value 到翻译 key 的映射
TEXT_ITEM_KEYS = {
    "Model": "text_model",
    "Make": "text_make",
    "LensModel": "text_lens",
    "Param": "text_param",
    "Datetime": "text_datetime",
    "Date": "text_date",
    "Custom": "text_custom",
    "None": "text_none",
    "LensMake_LensModel": "text_lens_make_lens_model",
    "CameraModel_LensModel": "text_camera_model_lens_model",
    "TotalPixel": "text_total_pixel",
    "CameraMake_CameraModel": "text_camera_make_camera_model",
    "Filename": "text_filename",
    "Date_Filename": "text_date_filename",
    "Datetime_Filename": "text_datetime_filename",
    "GeoInfo": "text_geo_info",
}
