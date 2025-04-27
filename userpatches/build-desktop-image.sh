#!/bin/bash

# 构建OrangePi 5 Max桌面镜像的脚本
# 作者: 非虫
# 日期: 2025-04-27

# 设置变量
BOARD="orangepi5max"
BRANCH="current"
RELEASE="bookworm"  # 可选: bookworm, bullseye, jammy等
DESKTOP="yes"
DESKTOP_ENV="xfce"  # 可选: xfce, mate, gnome

# 显示构建信息
echo "================================================"
echo "开始构建OrangePi 5 Max桌面镜像"
echo "Board: $BOARD"
echo "Branch: $BRANCH"
echo "Release: $RELEASE"
echo "Desktop Environment: $DESKTOP_ENV"
echo "================================================"

# 检查是否已经存在user-config.yml
if [ ! -f "userpatches/overlay/user-config.yml" ]; then
    echo "错误: 未找到userpatches/overlay/user-config.yml文件"
    echo "请先创建用户配置文件"
    exit 1
fi

# 确保build.sh有执行权限
chmod +x build.sh

# 开始构建
./build.sh BOARD=$BOARD BRANCH=$BRANCH RELEASE=$RELEASE \
    BUILD_DESKTOP=$DESKTOP DESKTOP_ENVIRONMENT=$DESKTOP_ENV \
    DESKTOP_ENVIRONMENT_CONFIG_NAME=config_base

# 检查构建结果
if [ $? -eq 0 ]; then
    echo "================================================"
    echo "构建成功!"
    echo "镜像文件位于 output/images/ 目录"
    echo "================================================"
else
    echo "构建失败，请检查日志"
fi 