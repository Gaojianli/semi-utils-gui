#!/bin/bash

EXIFTOOL_FILE_NAME="Image-ExifTool-12.92.tar.gz"
EXIFTOOL_FILE_DOWNLOAD_URL="http://file.lsvm.xyz/Image-ExifTool-12.92.tar.gz"

if [ -f "inited" ]; then
  echo "已完成初始化, 开始运行(如需重新初始化, 请删除 inited 文件)"
  exit 0
fi

# 检测操作系统类型
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    else
        echo "unknown"
    fi
}

# 检测 Linux 包管理器
detect_package_manager() {
    if command -v apt &> /dev/null; then
        echo "apt"
    elif command -v dnf &> /dev/null; then
        echo "dnf"
    elif command -v yum &> /dev/null; then
        echo "yum"
    elif command -v pacman &> /dev/null; then
        echo "pacman"
    elif command -v zypper &> /dev/null; then
        echo "zypper"
    else
        echo "unknown"
    fi
}

# 安装 exiftool
install_exiftool() {
    local os_type=$(detect_os)

    # 检查是否已安装 exiftool
    if command -v exiftool &> /dev/null; then
        echo "exiftool 已安装: $(exiftool -ver)"
        return 0
    fi

    echo "正在安装 exiftool..."

    if [[ "$os_type" == "macos" ]]; then
        # macOS 使用 Homebrew
        if command -v brew &> /dev/null; then
            echo "使用 Homebrew 安装 exiftool..."
            brew install exiftool
        else
            echo "未找到 Homebrew，请先安装 Homebrew: https://brew.sh"
            echo "或者使用以下命令安装:"
            echo '  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
            echo "回退到手动下载安装..."
            install_exiftool_manual
        fi
    elif [[ "$os_type" == "linux" ]]; then
        local pkg_manager=$(detect_package_manager)

        case "$pkg_manager" in
            apt)
                echo "使用 apt 安装 exiftool..."
                sudo apt update && sudo apt install -y libimage-exiftool-perl
                ;;
            dnf)
                echo "使用 dnf 安装 exiftool..."
                sudo dnf install -y perl-Image-ExifTool
                ;;
            yum)
                echo "使用 yum 安装 exiftool..."
                sudo yum install -y perl-Image-ExifTool
                ;;
            pacman)
                echo "使用 pacman 安装 exiftool..."
                sudo pacman -S --noconfirm perl-image-exiftool
                ;;
            zypper)
                echo "使用 zypper 安装 exiftool..."
                sudo zypper install -y exiftool
                ;;
            *)
                echo "未检测到支持的包管理器，回退到手动下载安装..."
                install_exiftool_manual
                ;;
        esac
    else
        echo "未知操作系统，回退到手动下载安装..."
        install_exiftool_manual
    fi

    # 验证安装
    if command -v exiftool &> /dev/null; then
        echo "exiftool 安装成功: $(exiftool -ver)"
    else
        echo "警告: exiftool 可能未正确安装，请手动检查"
    fi
}

# 手动下载安装 exiftool
install_exiftool_manual() {
    echo "正在从 $EXIFTOOL_FILE_DOWNLOAD_URL 下载 exiftool..."

    # 下载文件
    curl -O -L "$EXIFTOOL_FILE_DOWNLOAD_URL"

    # 测试 gzip 压缩的有效性
    if ! gzip -t "$EXIFTOOL_FILE_NAME"; then
        echo "下载的 ExifTool gzip 压缩文件格式不正确"
        echo "请检查 url 的有效性： $EXIFTOOL_FILE_DOWNLOAD_URL"
        echo "当前下载的 ExifTool gzip 的格式为："
        file "$EXIFTOOL_FILE_NAME"
        echo "安装未完成，初始化脚本中断"
        exit 1
    fi

    # 创建目录
    mkdir -p ./exiftool

    # 解压文件
    tar -xzf "$EXIFTOOL_FILE_NAME" -C ./exiftool --strip-components=1

    # 删除压缩包
    rm "$EXIFTOOL_FILE_NAME"

    echo "exiftool 已下载到 ./exiftool 目录"
}

# 主流程
echo "=========================================="
echo "Semi-Utils 初始化脚本"
echo "=========================================="

# 检测并显示系统信息
OS_TYPE=$(detect_os)
echo "检测到操作系统: $OS_TYPE"

if [[ "$OS_TYPE" == "linux" ]]; then
    PKG_MANAGER=$(detect_package_manager)
    echo "检测到包管理器: $PKG_MANAGER"
fi

echo ""

# 安装 exiftool
install_exiftool

echo ""

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
