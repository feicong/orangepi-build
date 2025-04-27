# OrangePi Cloud-Init 集成说明

本目录包含了为OrangePi系统添加cloud-init支持的相关文件和配置。

## 功能简介

通过集成cloud-init，可以在OrangePi系统首次启动时自动执行以下操作：

- 创建自定义用户和密码
- 配置网络
- 设置时区和语言
- 安装软件包
- 执行自定义脚本
- 配置SSH密钥等

## 文件结构说明

- `customize-image.sh`: 在镜像构建过程中集成cloud-init
- `overlay/`: 包含要添加到系统中的文件
  - `overlay/user-config.yml`: cloud-init的主要配置文件
  - `overlay/etc/cloud/cloud.cfg.d/`: cloud-init配置目录
  - `overlay/etc/systemd/system/`: systemd服务配置

## 如何使用

1. 修改 `overlay/user-config.yml` 文件，根据需要自定义配置
2. 运行构建命令:

```bash
./build.sh BOARD=orangepi5max BRANCH=current RELEASE=bookworm \
    BUILD_DESKTOP=yes DESKTOP_ENVIRONMENT=xfce \
    DESKTOP_ENVIRONMENT_CONFIG_NAME=config_base
```

## 首次启动

系统首次启动时，cloud-init将根据配置文件执行各种初始化操作。
可通过以下命令查看cloud-init日志：

```bash
sudo cat /var/log/cloud-init.log
sudo cat /var/log/cloud-init-output.log
```

## 自定义说明

若要修改更多cloud-init配置，可编辑以下文件：

- `/boot/orangepi-user-config/user-data`: 主配置文件
- `/etc/cloud/cloud.cfg.d/`: cloud-init其他配置 