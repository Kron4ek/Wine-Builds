#!/usr/bin/env bash

## A script for creating Ubuntu bootstraps for Wine compilation.
##
## debootstrap and perl are required
## root rights are required
##
## About 5.5 GB of free space is required
## And additional 2.5 GB is required for Wine compilation

if [ "$EUID" != 0 ]; then
	echo "This script requires root rights!"
	exit 1
fi

if ! command -v debootstrap 1>/dev/null || ! command -v perl 1>/dev/null; then
	echo "Please install debootstrap and perl and run the script again"
	exit 1
fi

# Keep in mind that although you can choose any version of Ubuntu/Debian
# here, but this script has only been tested with Ubuntu 18.04 Bionic
export CHROOT_DISTRO="bionic"
export CHROOT_MIRROR="https://ftp.uni-stuttgart.de/ubuntu/"

# Set your preferred path for storing chroots
# Also don't forget to change the path to the chroots in the build_wine.sh
# script, if you are going to use it
export MAINDIR=/opt/chroots
export CHROOT_X64="${MAINDIR}"/${CHROOT_DISTRO}64_chroot
export CHROOT_X32="${MAINDIR}"/${CHROOT_DISTRO}32_chroot

prepare_chroot () {
	if [ "$1" = "32" ]; then
		CHROOT_PATH="${CHROOT_X32}"
	else
		CHROOT_PATH="${CHROOT_X64}"
	fi

	echo "Unmount chroot directories. Just in case."
	umount -Rl "${CHROOT_PATH}"

	echo "Mount directories for chroot"
	mount --bind "${CHROOT_PATH}" "${CHROOT_PATH}"
	mount -t proc /proc "${CHROOT_PATH}"/proc
	mount --bind /sys "${CHROOT_PATH}"/sys
	mount --make-rslave "${CHROOT_PATH}"/sys
	mount --bind /dev "${CHROOT_PATH}"/dev
	mount --bind /dev/pts "${CHROOT_PATH}"/dev/pts
	mount --bind /dev/shm "${CHROOT_PATH}"/dev/shm
	mount --make-rslave "${CHROOT_PATH}"/dev

	rm -f "${CHROOT_PATH}"/etc/resolv.conf
	cp /etc/resolv.conf "${CHROOT_PATH}"/etc/resolv.conf

	echo "Chrooting into ${CHROOT_PATH}"
	chroot "${CHROOT_PATH}" /usr/bin/env LANG=en_US.UTF-8 TERM=xterm PATH="/bin:/sbin:/usr/bin:/usr/sbin" /opt/prepare_chroot.sh

	echo "Unmount chroot directories"
	umount -l "${CHROOT_PATH}"
	umount "${CHROOT_PATH}"/proc
	umount "${CHROOT_PATH}"/sys
	umount "${CHROOT_PATH}"/dev/pts
	umount "${CHROOT_PATH}"/dev/shm
	umount "${CHROOT_PATH}"/dev
}

create_build_scripts () {
	sdl2_version="2.32.10"
	faudio_version="23.03"
	vulkan_headers_version="1.4.343"
	vulkan_loader_version="1.4.343"
	spirv_headers_version="sdk-1.3.239.0"
 	libpcap_version="1.10.4"
  	libxkbcommon_version="1.13.1"
   	python3_version="3.12.4"
    meson_version="1.3.2"
    cmake_version="3.30.3"
    ccache_version="4.12.3"
    libglvnd_version="1.7.0"
	bison_version="3.8.2"
	wayland_version="1.24.0"
	wayland_protocols_version="1.47"
	gnutls_version="3.8.12"
	nettle_version="3.10.2"
	p11_kit_version="0.26.2"

	cat <<EOF > "${MAINDIR}"/prepare_chroot.sh
#!/bin/bash

apt-get update
apt-get -y install nano
apt-get -y install locales
echo ru_RU.UTF_8 UTF-8 >> /etc/locale.gen
echo en_US.UTF_8 UTF-8 >> /etc/locale.gen
locale-gen
echo deb '${CHROOT_MIRROR}' ${CHROOT_DISTRO} main universe > /etc/apt/sources.list
echo deb '${CHROOT_MIRROR}' ${CHROOT_DISTRO}-updates main universe >> /etc/apt/sources.list
echo deb '${CHROOT_MIRROR}' ${CHROOT_DISTRO}-security main universe >> /etc/apt/sources.list
echo deb-src '${CHROOT_MIRROR}' ${CHROOT_DISTRO} main universe >> /etc/apt/sources.list
echo deb-src '${CHROOT_MIRROR}' ${CHROOT_DISTRO}-updates main universe >> /etc/apt/sources.list
echo deb-src '${CHROOT_MIRROR}' ${CHROOT_DISTRO}-security main universe >> /etc/apt/sources.list
apt-get update
apt-get -y upgrade
apt-get -y dist-upgrade
apt-get -y install software-properties-common
add-apt-repository -y ppa:ubuntu-toolchain-r/test
add-apt-repository -y ppa:cybermax-dexter/mingw-w64-backport
apt-get update
apt-get -y build-dep wine-development libsdl2 libvulkan1 python3
apt-get -y install ccache gcc-11 g++-11 wget git gcc-mingw-w64 g++-mingw-w64 ninja-build
apt-get -y install libxpresent-dev libjxr-dev libusb-1.0-0-dev libgcrypt20-dev libpulse-dev libudev-dev libsane-dev libv4l-dev libkrb5-dev libgphoto2-dev liblcms2-dev libcapi20-dev
apt-get -y install libjpeg62-dev samba-dev
apt-get -y install libpcsclite-dev libcups2-dev
apt-get -y install python3-pip libxcb-xkb-dev libbz2-dev texinfo curl
apt-get -y install graphviz xmlto --no-install-recommends
apt-get -y purge libvulkan-dev libvulkan1 libsdl2-dev libsdl2-2.0-0 libpcap0.8-dev libpcap0.8 --purge --autoremove
apt-get -y purge *gstreamer* --purge --autoremove
apt-get -y clean
apt-get -y autoclean
export PATH="/usr/local/bin:\${PATH}"
mkdir /opt/build_libs
cd /opt/build_libs
wget -O sdl.tar.gz https://www.libsdl.org/release/SDL2-${sdl2_version}.tar.gz
wget -O faudio.tar.gz https://github.com/FNA-XNA/FAudio/archive/${faudio_version}.tar.gz
wget -O vulkan-loader.tar.gz https://github.com/KhronosGroup/Vulkan-Loader/archive/v${vulkan_loader_version}.tar.gz
wget -O vulkan-headers.tar.gz https://github.com/KhronosGroup/Vulkan-Headers/archive/v${vulkan_headers_version}.tar.gz
wget -O spirv-headers.tar.gz https://github.com/KhronosGroup/SPIRV-Headers/archive/${spirv_headers_version}.tar.gz
wget -O libpcap.tar.gz https://www.tcpdump.org/release/libpcap-${libpcap_version}.tar.gz
wget -O libxkbcommon.tar.gz https://github.com/xkbcommon/libxkbcommon/archive/refs/tags/xkbcommon-${libxkbcommon_version}.tar.gz
wget -O python3.tar.gz https://www.python.org/ftp/python/${python3_version}/Python-${python3_version}.tgz
wget -O meson.tar.gz https://github.com/mesonbuild/meson/releases/download/${meson_version}/meson-${meson_version}.tar.gz
wget -O cmake.tar.gz https://github.com/Kitware/CMake/releases/download/v${cmake_version}/cmake-${cmake_version}.tar.gz
wget -O ccache.tar.gz https://github.com/ccache/ccache/releases/download/v${ccache_version}/ccache-${ccache_version}.tar.gz
wget -O libglvnd.tar.gz https://gitlab.freedesktop.org/glvnd/libglvnd/-/archive/v${libglvnd_version}/libglvnd-v${libglvnd_version}.tar.gz
wget -O bison.tar.xz https://ftp.gnu.org/gnu/bison/bison-${bison_version}.tar.xz
wget -O wayland.tar.xz https://gitlab.freedesktop.org/wayland/wayland/-/releases/${wayland_version}/downloads/wayland-${wayland_version}.tar.xz
wget -O wayland-protocols.tar.xz https://gitlab.freedesktop.org/wayland/wayland-protocols/-/releases/${wayland_protocols_version}/downloads/wayland-protocols-${wayland_protocols_version}.tar.xz
wget -O gnutls.tar.xz https://www.gnupg.org/ftp/gcrypt/gnutls/v3.8/gnutls-${gnutls_version}.tar.xz
wget -O nettle.tar.gz https://ftp.gnu.org/gnu/nettle/nettle-${nettle_version}.tar.gz
wget -O p11-kit.tar.xz https://github.com/p11-glue/p11-kit/releases/download/${p11_kit_version}/p11-kit-${p11_kit_version}.tar.xz
wget -O /usr/include/linux/ntsync.h https://raw.githubusercontent.com/zen-kernel/zen-kernel/refs/heads/6.15/main/include/uapi/linux/ntsync.h
wget -O /usr/include/linux/userfaultfd.h https://raw.githubusercontent.com/zen-kernel/zen-kernel/refs/heads/6.15/main/include/uapi/linux/userfaultfd.h
if [ -d /usr/lib/i386-linux-gnu ]; then wget -O wine.deb https://dl.winehq.org/wine-builds/ubuntu/dists/bionic/main/binary-i386/wine-stable_4.0.3~bionic_i386.deb; fi
if [ -d /usr/lib/x86_64-linux-gnu ]; then wget -O wine.deb https://dl.winehq.org/wine-builds/ubuntu/dists/bionic/main/binary-amd64/wine-stable_4.0.3~bionic_amd64.deb; fi
git clone https://gitlab.freedesktop.org/gstreamer/gstreamer.git -b 1.22
wget https://raw.githubusercontent.com/Kron4ek/Wine-Builds/refs/heads/master/mingw-w64-build
tar xf sdl.tar.gz
tar xf faudio.tar.gz
tar xf vulkan-loader.tar.gz
tar xf vulkan-headers.tar.gz
tar xf spirv-headers.tar.gz
tar xf libpcap.tar.gz
tar xf libxkbcommon.tar.gz
tar xf python3.tar.gz
tar xf cmake.tar.gz
tar xf ccache.tar.gz
tar xf libglvnd.tar.gz
tar xf bison.tar.xz
tar xf wayland.tar.xz
tar xf wayland-protocols.tar.xz
tar xf gnutls.tar.xz
tar xf nettle.tar.gz
tar xf p11-kit.tar.xz
tar xf meson.tar.gz -C /usr/local
ln -s /usr/local/meson-${meson_version}/meson.py /usr/local/bin/meson
bash mingw-w64-build x86_64
bash mingw-w64-build i686
export CC=gcc-11
export CXX=g++-11
export CFLAGS="-O2"
export CXXFLAGS="-O2"
cd cmake-${cmake_version}
./bootstrap --parallel=$(nproc)
make -j$(nproc) install
cd ../ && mkdir build && cd build
cmake ../ccache-${ccache_version} && make -j$(nproc) && make install
cd ../ && rm -r build && mkdir build && cd build
cmake ../SDL2-${sdl2_version} && make -j$(nproc) && make install
cd ../ && rm -r build && mkdir build && cd build
cmake ../FAudio-${faudio_version} && make -j$(nproc) && make install
cd ../ && rm -r build && mkdir build && cd build
cmake ../Vulkan-Headers-${vulkan_headers_version} && make -j$(nproc) && make install
cd ../ && rm -r build && mkdir build && cd build
cmake ../Vulkan-Loader-${vulkan_loader_version}
make -j$(nproc)
make install
cd ../ && rm -r build && mkdir build && cd build
cmake ../SPIRV-Headers-${spirv_headers_version} && make -j$(nproc) && make install
cd ../ && dpkg -x wine.deb .
cp opt/wine-stable/bin/widl /usr/bin
rm -r build && mkdir build && cd build
../libpcap-${libpcap_version}/configure && make -j$(nproc) install
cd ../ && rm -r build && mkdir build && cd build
../Python-${python3_version}/configure --enable-optimizations
make -j$(nproc)
make -j$(nproc) install
pip3 install setuptools
cd ../gstreamer
meson setup build
ninja -C build
ninja -C build install
cd ../bison-${bison_version}
./configure
make -j$(nproc) install
cd ../wayland-${wayland_version}
meson setup build
meson compile -C build
meson install -C build
cd ../wayland-protocols-${wayland_protocols_version}
meson setup build
meson compile -C build
meson install -C build
cd ../libxkbcommon-xkbcommon-${libxkbcommon_version}
meson setup build -Denable-docs=false
meson compile -C build
meson install -C build
cd ../libglvnd-v${libglvnd_version}
meson setup build
meson compile -C build
meson install -C build
cd ../nettle-${nettle_version}
./configure
make -j$(nproc) install
cd ../p11-kit-${p11_kit_version}
meson setup build
meson compile -C build
meson install -C build
cd ../gnutls-${gnutls_version}
./configure --with-included-unistring --disable-doc
make -j$(nproc) install
cd /opt && rm -r /opt/build_libs
EOF

	chmod +x "${MAINDIR}"/prepare_chroot.sh
	cp "${MAINDIR}"/prepare_chroot.sh "${CHROOT_X32}"/opt
	mv "${MAINDIR}"/prepare_chroot.sh "${CHROOT_X64}"/opt
}

mkdir -p "${MAINDIR}"

debootstrap --arch amd64 $CHROOT_DISTRO "${CHROOT_X64}" $CHROOT_MIRROR
debootstrap --arch i386 $CHROOT_DISTRO "${CHROOT_X32}" $CHROOT_MIRROR

create_build_scripts
prepare_chroot 32
prepare_chroot 64

rm "${CHROOT_X64}"/opt/prepare_chroot.sh
rm "${CHROOT_X32}"/opt/prepare_chroot.sh

clear
echo "Done"
