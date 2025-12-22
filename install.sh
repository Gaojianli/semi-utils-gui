#!/bin/bash

if [ -f "inited" ]; then
  echo "已完成初始化, 开始运行(如需重新初始化, 请删除 inited 文件)"
  exit 0
fi

# 主流程
echo "=========================================="
echo "Semi-Utils 初始化脚本"
echo "=========================================="

# 下载 python 依赖
echo "正在安装 Python 依赖..."
uv sync

# 初始化完成
touch inited
echo ""
echo "=========================================="
echo "初始化完成!"
echo "inited 文件已生成, 如需重新初始化, 请删除 inited 文件"
echo "=========================================="
exit 0
