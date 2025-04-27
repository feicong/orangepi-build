#!/bin/bash

# 注意: 这个脚本为CI环境优化

# 设置函数变量
RELEASE=$1
FAMILY=$2
BOARD=$3
VERSION=$4
ROOTPWD=$5

# 设置日志文件
LOGFILE="/root/customize-image-ci.log"

# 简单日志函数
log() {
    echo "$(date): $1" | tee -a $LOGFILE
}

log "开始执行CI定制脚本 - Release: $RELEASE, Board: $BOARD"

# 主函数
Main() {
    # 安装cloud-init包
    log "安装基本软件包..."
    apt-get update
    apt-get install -y cloud-init

    # 简化CI环境中的操作，避免不必要的错误
    log "CI定制脚本执行完成"
}

# 执行主函数
Main "$@" 