#!/bin/bash
#
# Copyright (c) 2021 Igor Pecovnik, igor.pecovnik@gma**.com
#
# This file is licensed under the terms of the GNU General Public
# License version 2. This program is licensed "as is" without any
# warranty of any kind, whether express or implied.


#
# Functions:
# create_board_package




create_board_package()
{
	display_alert "Creating board support package for CLI" "$CHOSEN_ROOTFS" "info"

	bsptempdir=$(mktemp -d)
	chmod 700 ${bsptempdir}
	trap "rm -rf \"${bsptempdir}\" ; exit 0" 0 1 2 3 15
	local destination=${bsptempdir}/${RELEASE}/${BSP_CLI_PACKAGE_FULLNAME}
	mkdir -p "${destination}"/DEBIAN
	cd $destination

	# copy general overlay from packages/bsp-cli
	copy_all_packages_files_for "bsp-cli"

	# install copy of boot script & environment file
	if [[ "${BOOTCONFIG}" != "none" ]]; then
		# @TODO: add extension method bsp_prepare_bootloader(), refactor into u-boot extension
		local bootscript_src=${BOOTSCRIPT%%:*}
		local bootscript_dst=${BOOTSCRIPT##*:}
		mkdir -p "${destination}"/usr/share/orangepi/

		# create extlinux config file
		if [[ $SRC_EXTLINUX != yes ]]; then
			if [ -f "${USERPATCHES_PATH}/bootscripts/${bootscript_src}" ]; then
			  cp "${USERPATCHES_PATH}/bootscripts/${bootscript_src}" "${destination}/usr/share/orangepi/${bootscript_dst}"
			else
			  cp "${EXTER}/config/bootscripts/${bootscript_src}" "${destination}/usr/share/orangepi/${bootscript_dst}"
			fi
			[[ -n $BOOTENV_FILE && -f $SRC/config/bootenv/$BOOTENV_FILE ]] && \
				cp "${EXTER}/config/bootenv/${BOOTENV_FILE}" "${destination}"/usr/share/orangepi/orangepiEnv.txt
		fi

		# add configuration for setting uboot environment from userspace with: fw_setenv fw_printenv
		if [[ -n $UBOOT_FW_ENV ]]; then
			UBOOT_FW_ENV=($(tr ',' ' ' <<< "$UBOOT_FW_ENV"))
			mkdir -p "${destination}"/etc
			echo "# Device to access      offset           env size" > "${destination}"/etc/fw_env.config
			echo "/dev/mmcblk0	${UBOOT_FW_ENV[0]}	${UBOOT_FW_ENV[1]}" >> "${destination}"/etc/fw_env.config
		fi
	fi

	# Replaces: base-files is needed to replace /etc/update-motd.d/ files on Xenial
	# Replaces: unattended-upgrades may be needed to replace /etc/apt/apt.conf.d/50unattended-upgrades
	# (distributions provide good defaults, so this is not needed currently)
	# Depends: linux-base is needed for "linux-version" command in initrd cleanup script
	# Depends: fping is needed for orangepimonitor to upload orangepi-hardware-monitor.log
	cat <<-EOF > "${destination}"/DEBIAN/control
	Package: ${BSP_CLI_PACKAGE_NAME}
	Version: $REVISION
	Architecture: $ARCH
	Maintainer: $MAINTAINER <$MAINTAINERMAIL>
	Installed-Size: 1
	Section: kernel
	Priority: optional
	Depends: bash, linux-base, u-boot-tools, initramfs-tools, lsb-release, fping
	Provides: linux-${RELEASE}-root-legacy-$BOARD, linux-${RELEASE}-root-current-$BOARD, linux-${RELEASE}-root-next-$BOARD
	Suggests: orangepi-config
	Replaces: zram-config, base-files, orangepi-tools-$RELEASE, linux-${RELEASE}-root-legacy-$BOARD (<< $REVISION~), linux-${RELEASE}-root-current-$BOARD (<< $REVISION~), linux-${RELEASE}-root-next-$BOARD (<< $REVISION~)
	Breaks: linux-${RELEASE}-root-legacy-$BOARD (<< $REVISION~), linux-${RELEASE}-root-current-$BOARD (<< $REVISION~), linux-${RELEASE}-root-next-$BOARD (<< $REVISION~)
	Recommends: bsdutils, parted, util-linux, toilet
	Description: OrangePi board support files for $BOARD
	EOF

	# set up pre install script
	cat <<-EOF > "${destination}"/DEBIAN/preinst
	#!/bin/sh

	# tell people to reboot at next login
	[ "\$1" = "upgrade" ] && touch /var/run/.reboot_required

	# convert link to file
	if [ -L "/etc/network/interfaces" ]; then

	    cp /etc/network/interfaces /etc/network/interfaces.tmp
	    rm /etc/network/interfaces
	    mv /etc/network/interfaces.tmp /etc/network/interfaces

	fi

	# fixing ramdisk corruption when using lz4 compression method
	sed -i "s/^COMPRESS=.*/COMPRESS=gzip/" /etc/initramfs-tools/initramfs.conf

	# swap
	grep -q vm.swappiness /etc/sysctl.conf
	case \$? in
	0)
	    sed -i 's/vm\.swappiness.*/vm.swappiness=100/' /etc/sysctl.conf
	    ;;
	*)
	    echo vm.swappiness=100 >>/etc/sysctl.conf
	    ;;
	esac
	sysctl -p >/dev/null 2>&1

	# disable deprecated services
	[ -f "/etc/profile.d/activate_psd_user.sh" ] && rm /etc/profile.d/activate_psd_user.sh
	[ -f "/etc/profile.d/check_first_login.sh" ] && rm /etc/profile.d/check_first_login.sh
	[ -f "/etc/profile.d/check_first_login_reboot.sh" ] && rm /etc/profile.d/check_first_login_reboot.sh
	[ -f "/etc/profile.d/ssh-title.sh" ] && rm /etc/profile.d/ssh-title.sh
	[ -f "/etc/update-motd.d/10-header" ] && rm /etc/update-motd.d/10-header
	[ -f "/etc/update-motd.d/30-sysinfo" ] && rm /etc/update-motd.d/30-sysinfo
	[ -f "/etc/update-motd.d/35-tips" ] && rm /etc/update-motd.d/35-tips
	[ -f "/etc/update-motd.d/40-updates" ] && rm /etc/update-motd.d/40-updates
	[ -f "/etc/update-motd.d/98-autoreboot-warn" ] && rm /etc/update-motd.d/98-autoreboot-warn
	[ -f "/etc/update-motd.d/99-point-to-faq" ] && rm /etc/update-motd.d/99-point-to-faq
	[ -f "/etc/update-motd.d/80-esm" ] && rm /etc/update-motd.d/80-esm
	[ -f "/etc/update-motd.d/80-livepatch" ] && rm /etc/update-motd.d/80-livepatch
	[ -f "/etc/apt/apt.conf.d/02compress-indexes" ] && rm /etc/apt/apt.conf.d/02compress-indexes
	[ -f "/etc/apt/apt.conf.d/02periodic" ] && rm /etc/apt/apt.conf.d/02periodic
	[ -f "/etc/apt/apt.conf.d/no-languages" ] && rm /etc/apt/apt.conf.d/no-languages
	[ -f "/etc/init.d/armhwinfo" ] && rm /etc/init.d/armhwinfo
	[ -f "/etc/logrotate.d/armhwinfo" ] && rm /etc/logrotate.d/armhwinfo
	[ -f "/etc/init.d/firstrun" ] && rm /etc/init.d/firstrun
	[ -f "/etc/init.d/resize2fs" ] && rm /etc/init.d/resize2fs
	[ -f "/lib/systemd/system/firstrun-config.service" ] && rm /lib/systemd/system/firstrun-config.service
	[ -f "/lib/systemd/system/firstrun.service" ] && rm /lib/systemd/system/firstrun.service
	[ -f "/lib/systemd/system/resize2fs.service" ] && rm /lib/systemd/system/resize2fs.service
	[ -f "/usr/lib/orangepi/apt-updates" ] && rm /usr/lib/orangepi/apt-updates
	[ -f "/usr/lib/orangepi/firstrun-config.sh" ] && rm /usr/lib/orangepi/firstrun-config.sh
	# fix for https://bugs.launchpad.net/ubuntu/+source/lightdm-gtk-greeter/+bug/1897491
	[ -d "/var/lib/lightdm" ] && (chown -R lightdm:lightdm /var/lib/lightdm ; chmod 0750 /var/lib/lightdm)
	exit 0
	EOF

	chmod 755 "${destination}"/DEBIAN/preinst

	# postrm script
	cat <<-EOF > "${destination}"/DEBIAN/postrm
	#!/bin/sh
	if [ remove = "\$1" ] || [ abort-install = "\$1" ]; then

	    systemctl disable orangepi-hardware-monitor.service orangepi-hardware-optimize.service >/dev/null 2>&1
	    systemctl disable orangepi-zram-config.service orangepi-ramlog.service >/dev/null 2>&1

	fi
	exit 0
	EOF

	chmod 755 "${destination}"/DEBIAN/postrm

	# set up post install script
	cat <<-EOF > "${destination}"/DEBIAN/postinst
	#!/bin/sh
	#
	# ${BOARD} BSP post installation script
	#

	[ -f /etc/lib/systemd/system/orangepi-ramlog.service ] && systemctl --no-reload enable orangepi-ramlog.service

	# check if it was disabled in config and disable in new service
	if [ -n "\$(grep -w '^ENABLED=false' /etc/default/log2ram 2> /dev/null)" ]; then

	     sed -i "s/^ENABLED=.*/ENABLED=false/" /etc/default/orangepi-ramlog

	fi

	# fix boot delay "waiting for suspend/resume device"
	if [ -f "/etc/initramfs-tools/initramfs.conf" ]; then

	    if ! grep --quiet "RESUME=none" /etc/initramfs-tools/initramfs.conf; then
	         echo "RESUME=none" >> /etc/initramfs-tools/initramfs.conf
	    fi

	fi

	EOF
	# install bootscripts if they are not present. Fix upgrades from old images
	if [[ $FORCE_BOOTSCRIPT_UPDATE == yes ]]; then
	    cat <<-EOF >> "${destination}"/DEBIAN/postinst
	if [ true ]; then

    # this package recreate boot scripts
	EOF
	else
	    cat <<-EOF >> "${destination}"/DEBIAN/postinst
	if [ ! -f /boot/$bootscript_dst ]; then

	# if boot script does not exits its recreated
	EOF
	fi
	cat <<-EOF >> "${destination}"/DEBIAN/postinst
    # move bootscript to /usr/share/orangepi
    # create a backup
    [ -f /etc/orangepi-release ] &&  . /etc/orangepi-release
    [ -z \${VERSION} ] && VERSION=$(echo \`date +%s\`)
    if [ -f /boot/$bootscript_dst ]; then
       cp /boot/$bootscript_dst /usr/share/orangepi/${bootscript_dst}-\${VERSION} >/dev/null 2>&1
       echo "NOTE: You can find previous bootscript versions in /usr/share/orangepi !"
    fi

    # cleanup old bootscript backup
    ls /usr/share/orangepi/boot.cmd-* >/dev/null 2>&1 | head -n -5 | xargs rm -f --
    ls /usr/share/orangepi/boot.ini-* >/dev/null 2>&1 | head -n -5 | xargs rm -f --

    echo "Recreating boot script"
    cp /usr/share/orangepi/$bootscript_dst /boot  >/dev/null 2>&1
    rootdev=\$(sed -e 's/^.*root=//' -e 's/ .*\$//' < /proc/cmdline)
    rootfstype=\$(sed -e 's/^.*rootfstype=//' -e 's/ .*$//' < /proc/cmdline)

    # recreate orangepiEnv.txt if it and extlinux does not exists
    if [ ! -f /boot/orangepiEnv.txt ] && [ ! -f /boot/extlinux/extlinux.conf ]; then
      cp /usr/share/orangepi/orangepiEnv.txt /boot  >/dev/null 2>&1
      echo "rootdev="\$rootdev >> /boot/orangepiEnv.txt
      echo "rootfstype="\$rootfstype >> /boot/orangepiEnv.txt
    fi

    [ -f /boot/boot.ini ] && sed -i "s/setenv rootdev.*/setenv rootdev \\"\$rootdev\\"/" /boot/boot.ini
    [ -f /boot/boot.ini ] && sed -i "s/setenv rootfstype.*/setenv rootfstype \\"\$rootfstype\\"/" /boot/boot.ini
    [ -f /boot/boot.cmd ] && mkimage -C none -A arm -T script -d /boot/boot.cmd /boot/boot.scr  >/dev/null 2>&1

	fi

	[ ! -f "/etc/network/interfaces" ] && [ -f "/etc/network/interfaces.default" ] && cp /etc/network/interfaces.default /etc/network/interfaces
	ln -sf /var/run/motd /etc/motd
	rm -f /etc/update-motd.d/00-header /etc/update-motd.d/10-help-text
	if [ -f "/boot/bin/$BOARD.bin" ] && [ ! -f "/boot/script.bin" ]; then ln -sf bin/$BOARD.bin /boot/script.bin >/dev/null 2>&1 || cp /boot/bin/$BOARD.bin /boot/script.bin; fi
	if [ ! -f "/etc/default/orangepi-motd" ]; then
		mv /etc/default/orangepi-motd.dpkg-dist /etc/default/orangepi-motd
	fi
	if [ ! -f "/etc/default/orangepi-ramlog" ] && [ -f /etc/default/orangepi-ramlog.dpkg-dist ]; then
		mv /etc/default/orangepi-ramlog.dpkg-dist /etc/default/orangepi-ramlog
	fi
	if [ ! -f "/etc/default/orangepi-zram-config" ] && [ -f /etc/default/orangepi-zram-config.dpkg-dist ]; then
		mv /etc/default/orangepi-zram-config.dpkg-dist /etc/default/orangepi-zram-config
	fi

	if [ -L "/usr/lib/chromium-browser/master_preferences.dpkg-dist" ]; then
		mv /usr/lib/chromium-browser/master_preferences.dpkg-dist /usr/lib/chromium-browser/master_preferences
	fi

	# Read release value
	if [ -f /etc/lsb-release ]; then
		RELEASE=\$(cat /etc/lsb-release | grep CODENAME | cut -d"=" -f2 | sed 's/.*/\u&/')
		sed -i "s/^PRETTY_NAME=.*/PRETTY_NAME=\"${VENDOR} $REVISION "\${RELEASE}"\"/" /etc/os-release
		echo "${VENDOR} ${REVISION} \${RELEASE} \\l \n" > /etc/issue
		echo "${VENDOR} ${REVISION} \${RELEASE}" > /etc/issue.net
	fi

	# Reload services
	systemctl --no-reload enable orangepi-hardware-monitor.service orangepi-hardware-optimize.service orangepi-zram-config.service >/dev/null 2>&1
	exit 0
	EOF

	chmod 755 "${destination}"/DEBIAN/postinst

	# won't recreate files if they were removed by user
	# TODO: Add proper handling for updated conffiles
	#cat <<-EOF > "${destination}"/DEBIAN/conffiles
	#EOF

	# copy common files from a premade directory structure
	rsync -a "${EXTER}"/packages/bsp/common/* ${destination}

	# trigger uInitrd creation after installation, to apply
	# /etc/initramfs/post-update.d/99-uboot
	cat <<-EOF > "${destination}"/DEBIAN/triggers
	activate update-initramfs
	EOF

	# copy distribution support status
	local releases=($(find ${EXTER}/config/distributions -mindepth 1 -maxdepth 1 -type d))
	for i in ${releases[@]}
	do
		echo "$(echo $i | sed 's/.*\///')=$(cat $i/support)" >> "${destination}"/etc/orangepi-distribution-status
	done

	# armhwinfo, firstrun, orangepimonitor, etc. config file
	cat <<-EOF > "${destination}"/etc/orangepi-release
	# PLEASE DO NOT EDIT THIS FILE
	BOARD=${BOARD}
	BOARD_NAME="$BOARD_NAME"
	BOARDFAMILY=${BOARDFAMILY}
	BUILD_REPOSITORY_URL=${BUILD_REPOSITORY_URL}
	BUILD_REPOSITORY_COMMIT=${BUILD_REPOSITORY_COMMIT}
	DISTRIBUTION_CODENAME=${RELEASE}
	DISTRIBUTION_STATUS=${DISTRIBUTION_STATUS}
	VERSION=${REVISION}
	LINUXFAMILY=${LINUXFAMILY}
	ARCH=${ARCHITECTURE}
	IMAGE_TYPE=$IMAGE_TYPE
	BOARD_TYPE=$BOARD_TYPE
	INITRD_ARCH=${INITRD_ARCH}
	KERNEL_IMAGE_TYPE=${KERNEL_IMAGE_TYPE}
	BRANCH=${BRANCH}
	EOF

	# this is required for NFS boot to prevent deconfiguring the network on shutdown
	sed -i 's/#no-auto-down/no-auto-down/g' "${destination}"/etc/network/interfaces.default

	if [[ ( $LINUXFAMILY == sun8i ) && $BRANCH == legacy ]]; then
		# add mpv config for vdpau_sunxi
		mkdir -p "${destination}"/etc/mpv/
		cp "${EXTER}"/packages/bsp/mpv/mpv_sunxi.conf "${destination}"/etc/mpv/mpv.conf
		echo "export VDPAU_OSD=1" > "${destination}"/etc/profile.d/90-vdpau.sh
		chmod 755 "${destination}"/etc/profile.d/90-vdpau.sh
	fi
	if [[ $LINUXFAMILY == sunxi* ]]; then
		# add mpv config for x11 output - slow, but it works compared to no config at all
		# TODO: Test which output driver is better with DRM
		mkdir -p "${destination}"/etc/mpv/
		cp "${EXTER}"/packages/bsp/mpv/mpv_mainline.conf "${destination}"/etc/mpv/mpv.conf
	fi

	case $RELEASE in
	xenial)
		if [[ $BRANCH == legacy && $LINUXFAMILY == sun8i ]]; then
			# this is required only for old kernels
			# not needed for Stretch since there will be no Stretch images with kernels < 4.4
			mkdir -p "${destination}"/lib/systemd/system/haveged.service.d/
			cp "${EXTER}"/packages/bsp/10-no-new-privileges.conf "${destination}"/lib/systemd/system/haveged.service.d/
		fi
	;;
	esac
	# execute $LINUXFAMILY-specific tweaks
	[[ $(type -t family_tweaks_bsp) == function ]] && family_tweaks_bsp

	call_extension_method "post_family_tweaks_bsp" << 'POST_FAMILY_TWEAKS_BSP'
*family_tweaks_bsp overrrides what is in the config, so give it a chance to override the family tweaks*
This should be implemented by the config to tweak the BSP, after the board or family has had the chance to.
POST_FAMILY_TWEAKS_BSP

	# add some summary to the image
	fingerprint_image "${destination}/etc/orangepi.txt"

	# fixing permissions (basic), reference: dh_fixperms
	find "${destination}" -print0 2>/dev/null | xargs -0r chown --no-dereference 0:0
	find "${destination}" ! -type l -print0 2>/dev/null | xargs -0r chmod 'go=rX,u+rw,a-s'

	# create board DEB file
	fakeroot dpkg-deb -b -Z${DEB_COMPRESS} "${destination}" "${destination}.deb" >> "${DEST}"/${LOG_SUBPATH}/output.log 2>&1
	mkdir -p "${DEB_STORAGE}/${RELEASE}/"
	rsync --remove-source-files -rq "${destination}.deb" "${DEB_STORAGE}/${RELEASE}/"

	# cleanup
	rm -rf ${bsptempdir}
}
