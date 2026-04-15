#!/bin/bash

# ==================== 配置区域 ====================
IMAGE_NAME="chatgpt-web-mj-proxy"
VERSION="v1.0.0"
EXPORT_DIR="./dist"
# =================================================

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# 检查 Docker
check_requirements() {
    print_step "1/4: 检查 Docker 环境..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker 未安装，请先安装 Docker"
        exit 1
    fi
    
    # 检查 Docker 是否运行
    if ! docker info &> /dev/null; then
        print_error "Docker 未运行，请启动 Docker Desktop"
        exit 1
    fi
    
    print_info "Docker 环境正常 ✓"
}

# 构建 Docker 镜像
build_image() {
    print_step "2/4: 开始构建 Docker 镜像: ${IMAGE_NAME}:${VERSION}"
    
    # 创建导出目录
    mkdir -p "${EXPORT_DIR}"
    
    if docker build -t "${IMAGE_NAME}:${VERSION}" . ; then
        print_info "镜像构建成功 ✓"
    else
        print_error "镜像构建失败 ✗"
        exit 1
    fi
}

# 保存镜像为文件
save_image() {
    print_step "3/4: 导出镜像为文件..."
    
    local tar_file="${EXPORT_DIR}/${IMAGE_NAME}_${VERSION}.tar"
    
    if docker save "${IMAGE_NAME}:${VERSION}" -o "${tar_file}"; then
        print_info "镜像导出成功: ${tar_file}"
        # 显示文件大小
        ls -lh "${tar_file}"
        echo "${tar_file}"
    else
        print_error "镜像导出失败 ✗"
        exit 1
    fi
}

# 压缩镜像文件（可选，减小传输大小）
compress_image() {
    print_step "4/4: 压缩镜像文件..."
    
    local tar_file="$1"
    local gz_file="${tar_file}.gz"
    
    # 如果已存在压缩文件，先删除
    rm -f "${gz_file}"
    
    gzip -f "${tar_file}"
    
    if [ -f "${gz_file}" ]; then
        print_info "压缩完成: ${gz_file}"
        echo "${gz_file}"
    else
        print_warn "压缩失败，使用未压缩文件"
        echo "${tar_file}"
    fi
}

# 显示结果
show_result() {
    local final_file="$1"
    local file_size=$(ls -lh "${final_file}" | awk '{print $5}')
    
    echo ""
    echo "========================================="
    echo "✅ 打包完成！"
    echo "========================================="
    echo "镜像文件: ${final_file}"
    echo "文件大小: ${file_size}"
    echo ""
    echo "需要上传到服务器的文件："
    echo "  ${final_file}"
    echo ""
    echo "上传命令示例："
    echo "  scp ${final_file} root@your-server-ip:/home/chatgpt-web/"
    echo "========================================="
}

# 主函数
main() {
    echo "开始打包 ChatGPT-Web-Midjourney-Proxy"
    echo "========================================"
    echo ""
    
    check_requirements
    build_image
    local tar_file=$(save_image)
    local final_file=$(compress_image "${tar_file}")
    show_result "${final_file}"
    
    # 清理未压缩的临时文件（如果压缩成功）
    if [[ "${final_file}" == *.gz ]]; then
        rm -f "${tar_file}"
    fi
    
    print_info "脚本执行完毕！"
}

# 处理参数
case "${1}" in
    build-only)
        # 只构建镜像，不保存文件
        check_requirements
        build_image
        ;;
    help|--help|-h)
        echo "用法: ./build.sh [选项]"
        echo "选项:"
        echo "  build-only   只构建镜像，不保存为文件"
        echo "  help         显示帮助信息"
        ;;
    *)
        main
        ;;
esac