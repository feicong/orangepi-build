#!/bin/bash

# 注意: 这个脚本在目标目录系统的chroot环境中运行

# 设置函数变量
RELEASE=$1
FAMILY=$2
BOARD=$3
VERSION=$4
ROOTPWD=$5

# 设置日志文件
LOGFILE="/root/customize-image.log"

log() {
    echo "$(date): $1" | tee -a $LOGFILE
}

# 开始记录日志
log "开始执行customize-image.sh脚本 - Release: $RELEASE, Board: $BOARD"

case $RELEASE in
    bookworm|bullseye|buster|sid)
        # Debian系列
        DISTRO="debian"
        ;;
    focal|jammy|noble)
        # Ubuntu系列
        DISTRO="ubuntu"
        ;;
esac

log "识别到操作系统发行版: $DISTRO"

# 主函数
Main() {
    # 创建cloud-init配置目录
    mkdir -p /boot/orangepi-user-config
    log "创建了cloud-init配置目录: /boot/orangepi-user-config"
    
    # 复制已有的cloud-init配置文件
    if [ -d /etc/cloud/cloud.cfg.d ]; then
        log "复制已有cloud-init配置"
    else
        mkdir -p /etc/cloud/cloud.cfg.d
        log "创建cloud-init配置目录: /etc/cloud/cloud.cfg.d"
    fi
    
    # 复制用户提供的配置
    if [ -f /tmp/overlay/user-config.yml ]; then
        cp /tmp/overlay/user-config.yml /boot/orangepi-user-config/user-data
        # 创建meta-data文件（cloud-init需要）
        echo "instance-id: orangepi-$BOARD-$(date +%s)" > /boot/orangepi-user-config/meta-data
        # 确保权限正确
        chmod 644 /boot/orangepi-user-config/user-data
        chmod 644 /boot/orangepi-user-config/meta-data
        
        log "成功复制用户云配置文件到目标路径"
        
        # 安装cloud-init包
        log "开始安装cloud-init包..."
        apt-get update
        apt-get install -y cloud-init
        
        # 确保cloud-init能够在启动时找到配置文件
        if [ -f /tmp/overlay/etc/cloud/cloud.cfg.d/99-orangepi-user-config.cfg ]; then
            mkdir -p /etc/cloud/cloud.cfg.d/
            cp /tmp/overlay/etc/cloud/cloud.cfg.d/99-orangepi-user-config.cfg /etc/cloud/cloud.cfg.d/
            log "成功复制cloud-init配置文件"
        else
            log "警告: 未找到cloud-init配置文件，创建默认配置"
            mkdir -p /etc/cloud/cloud.cfg.d/
            cat > /etc/cloud/cloud.cfg.d/99-orangepi-user-config.cfg << EOF
# 这个文件指示cloud-init使用用户提供的配置
datasource_list: [ NoCloud, ConfigDrive ]
datasource:
  NoCloud:
    seedfrom: /boot/orangepi-user-config/
EOF
        fi
        
        # 确保cloud-init服务启用
        systemctl enable cloud-init.service cloud-final.service cloud-config.service cloud-init-local.service 2>> $LOGFILE
        
        log "已添加用户云配置 - OrangePi $BOARD with $RELEASE"
    else
        log "警告: 未找到user-config.yml文件，跳过cloud-init配置"
    fi
    
    # 配置中文支持
    if [ -f /boot/orangepi-user-config/user-data ]; then
        if grep -q "zh_CN" /boot/orangepi-user-config/user-data; then
            log "配置中文支持环境"
            if [ "$DISTRO" == "ubuntu" ]; then
                # Ubuntu系统安装中文语言包
                apt-get install -y language-pack-zh-hans fonts-noto-cjk
            else
                # Debian系统安装中文语言包
                apt-get install -y fonts-noto-cjk locales
                echo "zh_CN.UTF-8 UTF-8" >> /etc/locale.gen
                locale-gen
            fi
        fi
    fi
    
    log "customize-image.sh脚本执行完成"
}

# 执行主函数
Main "$@"
log "customize-image.sh执行结束" 