#!/bin/bash

# ==================== 配置区域 ====================
IMAGE_NAME="chatgpt-web-mj-proxy"
VERSION="v1.0.0"
CONTAINER_NAME="midjourney-web_server"
REMOTE_DIR="/home/midjourney-web"
NETWORK_NAME="ai-network"                    # Docker 网络名称
HOST_PORT="6015"                             # 主机映射端口
CONTAINER_PORT="3002"                        # 容器内部端口
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

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查必要文件
check_files() {
    print_step "检查必要文件..."
    
    # 注意：这里是 .tar 不是 .tar.gz
    local tar_file="${REMOTE_DIR}/${IMAGE_NAME}_${VERSION}.tar"
    
    if [ ! -f "${tar_file}" ]; then
        print_error "镜像文件不存在: ${tar_file}"
        echo "请先上传镜像文件到 ${REMOTE_DIR}/"
        exit 1
    fi
    
    if [ ! -f "${REMOTE_DIR}/config.env" ]; then
        print_warn "配置文件不存在: ${REMOTE_DIR}/config.env"
        echo "将使用默认配置，建议创建配置文件"
    fi
    
    print_info "文件检查通过 ✓"
}

# 创建必要目录和网络
prepare_environment() {
    print_step "准备环境..."
    
    # 创建上传目录
    mkdir -p "${REMOTE_DIR}/uploads"
    print_info "上传目录创建完成: ${REMOTE_DIR}/uploads"
    
    # 设置目录权限（允许容器写入）
    chmod 755 "${REMOTE_DIR}/uploads"
    
    # 检查并创建 Docker 网络
    if ! docker network ls | grep -q "${NETWORK_NAME}"; then
        print_info "创建 Docker 网络: ${NETWORK_NAME}"
        docker network create "${NETWORK_NAME}"
    else
        print_info "Docker 网络已存在: ${NETWORK_NAME}"
    fi
    
    print_info "环境准备完成 ✓"
}

# 加载镜像（直接加载 .tar 文件，不需要解压）
load_image() {
    print_step "加载 Docker 镜像..."
    
    cd "${REMOTE_DIR}" || exit 1
    
    local tar_file="${IMAGE_NAME}_${VERSION}.tar"
    
    # 直接加载 tar 文件（不是 gz）
    docker load -i "${tar_file}"
    
    if [ $? -eq 0 ]; then
        print_info "镜像加载成功 ✓"
    else
        print_error "镜像加载失败 ✗"
        exit 1
    fi
}

# 停止并删除旧容器
stop_old_container() {
    print_step "停止旧容器..."
    
    if docker ps -a | grep -q "${CONTAINER_NAME}"; then
        docker stop "${CONTAINER_NAME}" 2>/dev/null || true
        docker rm "${CONTAINER_NAME}" 2>/dev/null || true
        print_info "旧容器已删除 ✓"
    else
        print_info "没有运行中的旧容器"
    fi
}

# 运行新容器
run_container() {
    print_step "启动新容器..."
    
    # 构建 docker run 命令
    local docker_cmd="docker run -d \
      --name ${CONTAINER_NAME} \
      --restart always \
      --network ${NETWORK_NAME} \
      -p ${HOST_PORT}:${CONTAINER_PORT} \
      -v ${REMOTE_DIR}/uploads:/uploads"
    
    # 如果存在配置文件，添加环境变量文件参数
    if [ -f "${REMOTE_DIR}/config.env" ]; then
        docker_cmd="${docker_cmd} --env-file ${REMOTE_DIR}/config.env"
    fi
    
    docker_cmd="${docker_cmd} ${IMAGE_NAME}:${VERSION}"
    
    # 执行命令
    if eval ${docker_cmd}; then
        print_info "容器启动成功 ✓"
    else
        print_error "容器启动失败 ✗"
        exit 1
    fi
}

# 检查容器状态
check_container() {
    print_step "检查容器状态..."
    sleep 3
    
    if docker ps | grep -q "${CONTAINER_NAME}"; then
        print_info "容器运行正常 ✓"
        docker ps | grep "${CONTAINER_NAME}"
        
        # 显示容器日志（最后几行）
        echo ""
        print_info "容器日志（最后10行）："
        docker logs --tail 10 "${CONTAINER_NAME}"
    else
        print_error "容器未正常运行"
        echo "查看完整日志: docker logs ${CONTAINER_NAME}"
        exit 1
    fi
}

# 清理镜像压缩文件（注意是 .tar）
cleanup() {
    print_step "清理临时文件..."
    rm -f "${REMOTE_DIR}/${IMAGE_NAME}_${VERSION}.tar"
    print_info "清理完成 ✓"
}

# 显示部署信息
show_info() {
    # 获取服务器 IP
    SERVER_IP=$(hostname -I | awk '{print $1}')
    
    echo ""
    echo "========================================="
    echo "✅ 部署完成！"
    echo "========================================="
    echo "服务访问地址: http://${SERVER_IP}:${HOST_PORT}"
    echo ""
    echo "常用管理命令："
    echo "  查看日志: docker logs -f ${CONTAINER_NAME}"
    echo "  重启服务: docker restart ${CONTAINER_NAME}"
    echo "  停止服务: docker stop ${CONTAINER_NAME}"
    echo "  进入容器: docker exec -it ${CONTAINER_NAME} sh"
    echo ""
    echo "上传文件目录: ${REMOTE_DIR}/uploads"
    echo "========================================="
}

# 主函数
main() {
    echo "开始部署 midjourney-web_server"
    echo "========================================="
    echo ""
    
    check_files
    prepare_environment
    load_image
    stop_old_container
    run_container
    check_container
    cleanup
    show_info
}

# 执行
main