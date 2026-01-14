#!/bin/bash
set -euo pipefail

# 获取当前日期作为标签（格式：YYYYMMDD）
date_tag=$(date +%Y%m%d)

# 切换到脚本所在目录的上一级目录作为工作目录
cd "$(dirname "$0")/.." || {
    echo "错误：无法切换到上级目录"
    exit 1
}
echo "已切换工作目录到：$(pwd)"

# 可选：镜像tag（默认日期），可通过 TAG 覆盖
tag="${TAG:-$date_tag}"

# 可选：私有仓库（不配置则不推送）
docker_registry="${DOCKER_REGISTRY:-}"
if [ -z "${docker_registry}" ]; then
    read -r -p "请输入私有Docker注册库地址（如不推送请直接回车）: " input_registry || true
    docker_registry="${input_registry}"
fi

# 统一只构建一个镜像：polaris-wvp（包含：后端 + 前端静态资源 + nginx）
image_name="${IMAGE_NAME:-polaris-wvp}"
dockerfile_path="docker/wvp/Dockerfile"

# 构建镜像的函数
build_image() {
    # 检查Dockerfile是否存在
    if [ ! -f "$dockerfile_path" ]; then
        echo "错误：未找到Dockerfile - \"$dockerfile_path\"，跳过构建"
        return 1
    fi
    
    # 构建镜像
    local full_image_name="${image_name}:${tag}"
    echo
    echo "=============================================="
    echo "开始构建镜像：${full_image_name}"
    echo "Dockerfile路径：${dockerfile_path}"
    
    docker build -t "${full_image_name}" -f "${dockerfile_path}" .
    if [ $? -ne 0 ]; then
        echo "镜像${full_image_name}构建失败"
        return 1
    fi

    echo "给镜像打标签：${image_name}:latest"
    docker tag "${full_image_name}" "${image_name}:latest"
    
    # 推送镜像（如果设置了仓库地址）
    if [ -n "$docker_registry" ]; then
        local registry_image="${docker_registry}/${image_name}:${tag}"
        local registry_latest="${docker_registry}/${image_name}:latest"
        echo "给镜像打标签：${registry_image}"
        docker tag "${full_image_name}" "${registry_image}"
        echo "给镜像打标签：${registry_latest}"
        docker tag "${full_image_name}" "${registry_latest}"
        
        echo "推送镜像到注册库：${registry_image}"
        docker push "${registry_image}" || echo "警告：镜像${registry_image}推送失败"
        echo "推送镜像到注册库：${registry_latest}"
        docker push "${registry_latest}" || echo "警告：镜像${registry_latest}推送失败"
    else
        echo "未提供注册库地址，不执行推送"
    fi
    echo "=============================================="
    echo
}

build_image

echo "所有镜像处理完成"
exit 0
