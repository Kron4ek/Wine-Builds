#!/usr/bin/env bash

## Script for creating Ubuntu chroots for Wine compilation.
##
## debootstrap is required
## root rights are required

if [ "$EUID" != 0 ]; then
	echo "This script requires root rights!"
	exit 1
fi

export CHROOT_DISTRO="bionic"
export CHROOT_MIRROR="http://archive.ubuntu.com/ubuntu/"

export MAINDIR="/home/builder/chroots"
export CHROOT_X64="${MAINDIR}"/${CHROOT_DISTRO}64_chroot
export CHROOT_X32="${MAINDIR}"/${CHROOT_DISTRO}32_chroot

prepare_chroot () {
	if [ "$1" = "32" ]; then
		CHROOT_PATH="$CHROOT_X32"
	else
		CHROOT_PATH="$CHROOT_X64"
	fi

	echo "Unmount chroot directories. Just in case."
	umount -Rl "$CHROOT_PATH"

	echo "Mount directories for chroot"
	mount --bind "$CHROOT_PATH" "$CHROOT_PATH"
	mount --bind /dev "$CHROOT_PATH/dev"
	mount --bind /dev/shm "$CHROOT_PATH/dev/shm"
	mount --bind /dev/pts "$CHROOT_PATH/dev/pts"
	mount --bind /proc "$CHROOT_PATH/proc"
	mount --bind /sys "$CHROOT_PATH/sys"

	echo "Chrooting into $CHROOT_PATH"
	chroot "$CHROOT_PATH" /usr/bin/env LANG=en_US.UTF-8 TERM=xterm PATH="/bin:/sbin:/usr/bin:/usr/sbin" /opt/prepare_chroot.sh

	echo "Unmount chroot directories"
	umount -Rl "$CHROOT_PATH"
}

create_build_scripts () {
	echo '#!/bin/bash' > $MAINDIR/prepare_chroot.sh
	echo 'apt-get update' >> $MAINDIR/prepare_chroot.sh
	echo 'apt-get -y install nano' >> $MAINDIR/prepare_chroot.sh
	echo 'apt-get -y install locales' >> $MAINDIR/prepare_chroot.sh
	echo 'echo ru_RU.UTF_8 UTF-8 >> /etc/locale.gen' >> $MAINDIR/prepare_chroot.sh
	echo 'echo en_US.UTF_8 UTF-8 >> /etc/locale.gen' >> $MAINDIR/prepare_chroot.sh
	echo 'locale-gen' >> $MAINDIR/prepare_chroot.sh
	echo 'echo deb '${CHROOT_MIRROR}' '${CHROOT_DISTRO}' main universe > /etc/apt/sources.list' >> $MAINDIR/prepare_chroot.sh
	echo 'echo deb '${CHROOT_MIRROR}' '${CHROOT_DISTRO}'-updates main universe >> /etc/apt/sources.list' >> $MAINDIR/prepare_chroot.sh
	echo 'echo deb '${CHROOT_MIRROR}' '${CHROOT_DISTRO}'-security main universe >> /etc/apt/sources.list' >> $MAINDIR/prepare_chroot.sh
	echo 'echo deb-src '${CHROOT_MIRROR}' '${CHROOT_DISTRO}' main universe >> /etc/apt/sources.list' >> $MAINDIR/prepare_chroot.sh
	echo 'echo deb-src '${CHROOT_MIRROR}' '${CHROOT_DISTRO}'-updates main universe >> /etc/apt/sources.list' >> $MAINDIR/prepare_chroot.sh
	echo 'echo deb-src '${CHROOT_MIRROR}' '${CHROOT_DISTRO}'-security main universe >> /etc/apt/sources.list' >> $MAINDIR/prepare_chroot.sh
	echo 'apt-get update' >> $MAINDIR/prepare_chroot.sh
	echo 'apt-get -y upgrade' >> $MAINDIR/prepare_chroot.sh
	echo 'apt-get -y dist-upgrade' >> $MAINDIR/prepare_chroot.sh
	echo 'apt-get -y build-dep wine-development libsdl2 libvulkan1' >> $MAINDIR/prepare_chroot.sh
	echo 'apt-get -y install gcc-8 g++-8 wget git' >> $MAINDIR/prepare_chroot.sh
	echo 'apt-get -y install libusb-1.0-0-dev libgcrypt20-dev libpulse-dev libudev-dev libsane-dev libv4l-dev libkrb5-dev libgphoto2-dev liblcms2-dev libpcap-dev libcapi20-dev' >> $MAINDIR/prepare_chroot.sh
	echo 'apt-get -y purge libvulkan-dev libvulkan1 libsdl2-dev libsdl2-2.0-0 --purge --autoremove' >> $MAINDIR/prepare_chroot.sh
	echo 'apt-get -y clean' >> $MAINDIR/prepare_chroot.sh
	echo 'apt-get -y autoclean' >> $MAINDIR/prepare_chroot.sh
	echo 'mkdir /opt/build_libs' >> $MAINDIR/prepare_chroot.sh
	echo 'cd /opt/build_libs' >> $MAINDIR/prepare_chroot.sh
	echo 'wget -O sdl.tar.gz https://www.libsdl.org/release/SDL2-2.0.12.tar.gz' >> $MAINDIR/prepare_chroot.sh
	echo 'wget -O faudio.tar.gz https://github.com/FNA-XNA/FAudio/archive/20.06.tar.gz' >> $MAINDIR/prepare_chroot.sh
	echo 'wget -O vulkan-loader.tar.gz https://github.com/KhronosGroup/Vulkan-Loader/archive/v1.2.141.tar.gz' >> $MAINDIR/prepare_chroot.sh
	echo 'wget -O vulkan-headers.tar.gz https://github.com/KhronosGroup/Vulkan-Headers/archive/v1.2.141.tar.gz' >> $MAINDIR/prepare_chroot.sh
	echo 'wget -O spirv-headers.tar.gz https://github.com/KhronosGroup/SPIRV-Headers/archive/1.5.3.tar.gz' >> $MAINDIR/prepare_chroot.sh
	echo 'if [ -d /usr/lib/i386-linux-gnu ]; then wget -O wine.deb https://dl.winehq.org/wine-builds/ubuntu/dists/bionic/main/binary-i386/wine-stable_4.0.3~bionic_i386.deb; fi' >> $MAINDIR/prepare_chroot.sh
	echo 'if [ -d /usr/lib/x86_64-linux-gnu ]; then wget -O wine.deb https://dl.winehq.org/wine-builds/ubuntu/dists/bionic/main/binary-amd64/wine-stable_4.0.3~bionic_amd64.deb; fi' >> $MAINDIR/prepare_chroot.sh
	echo 'git clone https://github.com/HansKristian-Work/vkd3d.git' >> $MAINDIR/prepare_chroot.sh
	echo 'tar xf sdl.tar.gz' >> $MAINDIR/prepare_chroot.sh
	echo 'tar xf faudio.tar.gz' >> $MAINDIR/prepare_chroot.sh
	echo 'tar xf vulkan-loader.tar.gz' >> $MAINDIR/prepare_chroot.sh
	echo 'tar xf vulkan-headers.tar.gz' >> $MAINDIR/prepare_chroot.sh
	echo 'tar xf spirv-headers.tar.gz' >> $MAINDIR/prepare_chroot.sh
	echo 'mkdir build && cd build' >> $MAINDIR/prepare_chroot.sh
	echo 'cmake ../SDL2-2.0.12 && make -j$(nproc) && make install' >> $MAINDIR/prepare_chroot.sh
	echo 'cd ../ && rm -r build && mkdir build && cd build' >> $MAINDIR/prepare_chroot.sh
	echo 'cmake ../FAudio-20.06 && make -j$(nproc) && make install' >> $MAINDIR/prepare_chroot.sh
	echo 'cd ../ && rm -r build && mkdir build && cd build' >> $MAINDIR/prepare_chroot.sh
	echo 'cmake ../Vulkan-Headers-1.2.141 && make -j$(nproc) && make install' >> $MAINDIR/prepare_chroot.sh
	echo 'cd ../ && rm -r build && mkdir build && cd build' >> $MAINDIR/prepare_chroot.sh
	echo 'cmake ../Vulkan-Loader-1.2.141 && make -j$(nproc) && make install' >> $MAINDIR/prepare_chroot.sh
	echo 'cd ../ && rm -r build && mkdir build && cd build' >> $MAINDIR/prepare_chroot.sh
	echo 'cmake ../SPIRV-Headers-1.5.3 && make -j$(nproc) && make install' >> $MAINDIR/prepare_chroot.sh
	echo 'cd ../ && dpkg -x wine.deb .' >> $MAINDIR/prepare_chroot.sh
	echo 'cp opt/wine-stable/bin/widl /usr/bin' >> $MAINDIR/prepare_chroot.sh
	echo 'cd vkd3d && ./autogen.sh' >> $MAINDIR/prepare_chroot.sh
	echo 'cd ../ && rm -r build && mkdir build && cd build' >> $MAINDIR/prepare_chroot.sh
	echo '../vkd3d/configure && make -j$(nproc) && make install' >> $MAINDIR/prepare_chroot.sh
	echo 'cd /opt && rm -r /opt/build_libs' >> $MAINDIR/prepare_chroot.sh

	chmod +x "$MAINDIR/prepare_chroot.sh"
	cp "$MAINDIR/prepare_chroot.sh" "$CHROOT_X32/opt"
	mv "$MAINDIR/prepare_chroot.sh" "$CHROOT_X64/opt"
}

mkdir -p "${MAINDIR}"

debootstrap --arch amd64 $CHROOT_DISTRO "$CHROOT_X64" $CHROOT_MIRROR
debootstrap --arch i386 $CHROOT_DISTRO "$CHROOT_X32" $CHROOT_MIRROR

create_build_scripts
prepare_chroot 32
prepare_chroot 64

rm "$CHROOT_X64/opt/prepare_chroot.sh"
rm "$CHROOT_X32/opt/prepare_chroot.sh"

clear; echo "Done"
