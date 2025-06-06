FROM ubuntu:22.04
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get -y install \
       joe \
       software-properties-common \
       gnupg \
       gnupg1 \
       gpgv1 \
       curl \
    && rm -rf /var/lib/apt/lists/*
RUN sh -c " \
    if [ $(dpkg --print-architecture) = amd64 ]; then \
        apt-get update \
        && apt-get install -y --no-install-recommends \
        lib32ncurses6 \
        lib32stdc++6 \
        lib32tinfo6 \
        libc6-i386; \
    fi"
RUN apt-get update \
    && apt-get -y upgrade \
    && apt-get install -y --no-install-recommends \
       acl \
       aptly \
       aria2 \
       bc \
       binfmt-support \
       binutils \
       bison \
       btrfs-progs \
       build-essential \
       ca-certificates \
       ccache \
       cpio \
       cryptsetup \
       cryptsetup-bin \
       debian-archive-keyring \
       debian-keyring \
       debootstrap \
       device-tree-compiler \
       dialog \
       distcc \
       dosfstools \
       dwarves \
       f2fs-tools \
       fakeroot \
       flex \
       gawk \
       gcc-arm-linux-gnueabihf \
       gcc-arm-linux-gnueabi \
       gcc-arm-none-eabi \
       gdisk \
       git \
       imagemagick \
       jq \
       kmod \
       libbison-dev \
       libc6-amd64-cross \
       libc6-dev-armhf-cross \
       libfdt-dev \
       libelf-dev \
       libfile-fcntllock-perl \
       libfl-dev \
       liblz4-tool \
       libncurses5-dev \
       libpython2.7-dev \
       libpython3-dev \
       libssl-dev \
       libusb-1.0-0-dev \
       linux-base \
       locales \
       lsb-release \
       lzop \
       ncurses-base \
       ncurses-term \
       nfs-kernel-server \
       ntpdate \
       openssh-client \
       p7zip-full \
       parted \
       patchutils \
       pigz \
       pixz \
       pkg-config \
       psmisc \
       pv \
       python2 \
       python3 \
       python3-dev \
       python3-distutils \
       python3-pkg-resources \
       python3-setuptools \
       qemu \
       qemu-utils \
       qemu-user-static \
       rsync \
       swig \
       sudo \
       systemd-container \
       tzdata \
       u-boot-tools \
       udev \
       unzip \
       uuid \
       uuid-dev \
       uuid-runtime \
       wget \
       whiptail \
       xfsprogs \
       xxd \
       zip \
       zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*
RUN locale-gen en_US.UTF-8

RUN git config --system --add safe.directory /root/orangepi

# Static port for NFSv3 server used for USB FEL boot
RUN sed -i 's/\(^STATDOPTS=\).*/\1"--port 32765 --outgoing-port 32766"/' /etc/default/nfs-common \
    && sed -i 's/\(^RPCMOUNTDOPTS=\).*/\1"--port 32767"/' /etc/default/nfs-kernel-server

ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8' TERM=screen
WORKDIR /root/orangepi
LABEL org.opencontainers.image.source="https://github.com/orangepi-xunlong/orangepi-build/blob/main/external/config/templates/Dockerfile" \
 
    org.opencontainers.image.authors="Igor Pecovnik" \
    org.opencontainers.image.licenses="GPL-2.0"
ENTRYPOINT [ "/bin/bash", "/root/orangepi/build.sh" ]
