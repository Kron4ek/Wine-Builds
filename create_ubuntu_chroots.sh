#!/bin/bash

## Script for fast creating Ubuntu chroots for Wine compilation.
##
## debootstrap is required

export CHROOT_DISTRO="xenial"
export CHROOT_MIRROR="http://archive.ubuntu.com/ubuntu/"

export MAINDIR="/home/builder"
export CHROOT_X64="$MAINDIR/xenial64_chroot"
export CHROOT_X32="$MAINDIR/xenial32_chroot"

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
	echo 'echo deb '${CHROOT_MIRROR}' '${CHROOT_DISTRO}'-backports main universe >> /etc/apt/sources.list' >> $MAINDIR/prepare_chroot.sh
	echo 'echo deb-src '${CHROOT_MIRROR}' '${CHROOT_DISTRO}' main universe >> /etc/apt/sources.list' >> $MAINDIR/prepare_chroot.sh
	echo 'echo deb-src '${CHROOT_MIRROR}' '${CHROOT_DISTRO}'-updates main universe >> /etc/apt/sources.list' >> $MAINDIR/prepare_chroot.sh
	echo 'echo deb-src '${CHROOT_MIRROR}' '${CHROOT_DISTRO}'-security main universe >> /etc/apt/sources.list' >> $MAINDIR/prepare_chroot.sh
	echo 'echo deb-src '${CHROOT_MIRROR}' '${CHROOT_DISTRO}'-backports main universe >> /etc/apt/sources.list' >> $MAINDIR/prepare_chroot.sh
	echo 'apt-get update' >> $MAINDIR/prepare_chroot.sh
	echo 'apt-get -y upgrade' >> $MAINDIR/prepare_chroot.sh
	echo 'apt-get -y dist-upgrade' >> $MAINDIR/prepare_chroot.sh
	echo 'apt-get -y build-dep wine-development' >> $MAINDIR/prepare_chroot.sh
	echo 'apt-get -y install libsdl2-dev libpulse-dev libudev-dev libvulkan-dev libsane-dev libv4l-dev libkrb5-dev libgphoto2-dev liblcms2-dev libpcap-dev libcapi20-dev' >> $MAINDIR/prepare_chroot.sh
	echo 'apt-get -y clean' >> $MAINDIR/prepare_chroot.sh
	echo 'apt-get -y autoclean' >> $MAINDIR/prepare_chroot.sh

	chmod +x "$MAINDIR/prepare_chroot.sh"
	cp "$MAINDIR/prepare_chroot.sh" "$CHROOT_X32/opt"
	mv "$MAINDIR/prepare_chroot.sh" "$CHROOT_X64/opt"
}

debootstrap --arch amd64 $CHROOT_DISTRO "$CHROOT_X64" $CHROOT_MIRROR
debootstrap --arch i386 $CHROOT_DISTRO "$CHROOT_X32" $CHROOT_MIRROR

create_build_scripts
prepare_chroot 32
prepare_chroot 64

rm "$CHROOT_X64/opt/prepare_chroot.sh"
rm "$CHROOT_X32/opt/prepare_chroot.sh"

echo "Done"
