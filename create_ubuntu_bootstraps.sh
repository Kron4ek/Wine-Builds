#!/usr/bin/env bash

## A script for creating Ubuntu bootstraps for Wine compilation.
##
## debootstrap and perl are required
## root rights are required
##
## About 5.5 GB of free space is required
## And additional 2.5 GB is required for Wine compilation


# Keep in mind that although you can choose any version of Ubuntu/Debian
# here, but this script has only been tested with Ubuntu 18.04 Bionic
export CHROOT_DISTRO="resolute"
export CHROOT_MIRROR="http://archive.ubuntu.com/ubuntu"
# Possible mirrors http://archive.ubuntu.com/ubuntu https://ftp.uni-stuttgart.de/ubuntu/

if [ "$1" = --print-CHROOT_DISTRO ]; then
	printf '%s\n' "$CHROOT_DISTRO"
	exit 1
fi

if [ "$EUID" != 0 ]; then
	echo "This script requires root rights!"
	exit 1
fi

if ! command -v debootstrap 1>/dev/null || ! command -v perl 1>/dev/null; then
	echo "Please install debootstrap and perl and run the script again"
	exit 1
fi


# Set your preferred path for storing chroots
# Also don't forget to change the path to the chroots in the build_wine.sh
# script, if you are going to use it
export MAINDIR=/opt/chroots
export CHROOT_X64="${MAINDIR}"/${CHROOT_DISTRO}64_chroot
export CHROOT_X32="${MAINDIR}"/${CHROOT_DISTRO}32_chroot

# Used only for development and troubleshooting
enter_chroot () {
	if [ "$1" = "32" ]; then
		CHROOT_PATH="${CHROOT_X32}"
	else
		CHROOT_PATH="${CHROOT_X64}"
	fi

	echo "Unmount chroot directories. Just in case."
	umount -Rlf "${CHROOT_PATH}"

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
	chroot "${CHROOT_PATH}" /usr/bin/env LANG=en_US.UTF-8 TERM=xterm PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin" bash

	echo "Unmount chroot directories"
	umount -Rlf "${CHROOT_PATH}"
	umount "${CHROOT_PATH}"/proc
	umount "${CHROOT_PATH}"/sys
	umount "${CHROOT_PATH}"/dev/pts
	umount "${CHROOT_PATH}"/dev/shm
	umount "${CHROOT_PATH}"/dev
}

prepare_chroot () {
	if [ "$1" = "32" ]; then
		CHROOT_PATH="${CHROOT_X32}"
	else
		CHROOT_PATH="${CHROOT_X64}"
	fi

	echo "Unmount chroot directories. Just in case."
	umount -Rlf "${CHROOT_PATH}"

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
	chroot "${CHROOT_PATH}" /usr/bin/env LANG=en_US.UTF-8 TERM=xterm PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin" /opt/prepare_chroot.sh

	echo "Unmount chroot directories"
	umount -Rlf "${CHROOT_PATH}"
	umount "${CHROOT_PATH}"/proc
	umount "${CHROOT_PATH}"/sys
	umount "${CHROOT_PATH}"/dev/pts
	umount "${CHROOT_PATH}"/dev/shm
	umount "${CHROOT_PATH}"/dev
}

create_build_scripts () {
	sdl2_version="2.32.10"
	faudio_version="26.05"
	vulkan_headers_version="1.4.352"
	vulkan_loader_version="1.4.352"
	spirv_headers_version="vulkan-sdk-1.4.350.0"
	libpcap_version="1.10.6"
	libxkbcommon_version="1.13.1"
	python3_version="3.14.0"
	meson_version="1.11.1"
	cmake_version="4.3.2"
	ccache_version="4.13.6"
	libglvnd_version="1.7.0"
	bison_version="3.8.2"
	wayland_version="1.25.0"
	wayland_protocols_version="1.48"
	gnutls_version="3.8.13"
	nettle_version="4.0"
	p11_kit_version="0.26.2"
	libgpg_error_version="1.61"
	libgcrypt_version="1.12.2"

	cat > "${MAINDIR}"/prepare_chroot.sh <<EOF
#!/bin/bash
set -ex;
cat > /etc/apt/sources.list.d/ubuntu.sources << FINISHED
# Modernized from /etc/apt/sources.list
Types: deb deb-src
URIs: ${CHROOT_MIRROR}
Suites: ${CHROOT_DISTRO}
Components: main universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

# Modernized from /etc/apt/sources.list
Types: deb deb-src
URIs: ${CHROOT_MIRROR}
Suites: ${CHROOT_DISTRO}-updates
Components: main universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

# Modernized from /etc/apt/sources.list
Types: deb deb-src
URIs: ${CHROOT_MIRROR}
Suites: ${CHROOT_DISTRO}-security
Components: main universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

# Modernized from /etc/apt/sources.list
Types: deb deb-src
URIs: ${CHROOT_MIRROR}
Suites: ${CHROOT_DISTRO}-backports
Components: main universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
FINISHED
rm -vf /etc/apt/sources.list
export DEBIAN_FRONTEND=noninteractive
apt update
apt --fix-broken -y full-upgrade
apt -y install locales
echo en_US.UTF_8 UTF-8 >> /etc/locale.gen
locale-gen
apt update
apt --fix-broken -y full-upgrade
apt -y install software-properties-common wget gnupg curl vim
add-apt-repository -y ppa:ubuntu-toolchain-r/test
wget -O /etc/apt/keyrings/winehq.key https://dl.winehq.org/wine-builds/winehq.key
gpg --dearmor --yes --output /etc/apt/keyrings/winehq-archive.key /etc/apt/keyrings/winehq.key
chmod 644 /etc/apt/keyrings/winehq-archive.key
rm -vf /etc/apt/keyrings/winehq.key
wget -O /etc/apt/sources.list.d/winehq-${CHROOT_DISTRO}.sources https://dl.winehq.org/wine-builds/ubuntu/dists/${CHROOT_DISTRO}/winehq-${CHROOT_DISTRO}.sources
apt update
apt -y build-dep winehq-devel libsdl2 libvulkan1 python3
apt -y install ccache gcc-16 g++-16 git gcc-mingw-w64 g++-mingw-w64 ninja-build yasm nasm rustup gawk
apt -y install libxpresent-dev libjxr-dev libusb-1.0-0-dev libgcrypt20-dev libpulse-dev libudev-dev libsane-dev libv4l-dev libkrb5-dev libgphoto2-dev liblcms2-dev libcapi20-dev
apt -y install libjpeg62-dev samba-dev
apt -y install libpcsclite-dev libcups2-dev
apt -y install python3-pip libxcb-xkb-dev libbz2-dev texinfo
apt -y install graphviz xmlto gitlint pre-commit valgrind glslc glslang-dev libgirepository1.0-dev gobject-introspection qmake6 dotnet-sdk-10.0 --no-install-recommends
apt -y install libxdamage-dev libxtst-dev libsoup-3.0-dev
apt -y install libtheora-dev libvorbis-dev liba52-0.7.4-dev libgslcblas0 libgsl-dev libnsl-dev libmp3lame-dev
apt -y install libcdio-paranoia-dev libfaac-dev libgsm1-dev libmpcdec-dev libass-dev libaom-dev libbs2b-dev libfluidsynth-dev libmpg123-dev libraw1394-dev libavc1394-dev libiec61883-dev
apt -y install libdw-dev libx11-xcb-dev libgraphene-1.0-dev libvisual-0.4-dev libcaca-dev libdv4-dev libvpx-dev libwavpack-dev libxkbcommon-x11-dev libshout-dev libspeex-dev libtag1-dev
apt -y install libtwolame-dev libcurl4-openssl-dev libde265-dev liblilv-dev libmodplug-dev libgupnp-igd-1.6-dev
apt -y purge libvulkan-dev libvulkan1 libsdl2-dev libsdl2-2.0-0 libpcap0.8-dev libpcap0.8 libgl-dev libglx-dev --purge --autoremove
apt -y purge *gstreamer* --purge --autoremove
apt -y clean
apt -y autoclean
dotnet tool install -g dotnet-format
rustup default stable
cargo install mdbook
export PATH="/usr/local/bin:/root/.dotnet/tools:/root/.cargo/bin/:\${PATH}"
rm -rf /opt/build_libs
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
wget -O libgpg-error.tar.bz2 https://www.gnupg.org/ftp/gcrypt/libgpg-error/libgpg-error-${libgpg_error_version}.tar.bz2
wget -O libgcrypt.tar.bz2 https://www.gnupg.org/ftp/gcrypt/libgcrypt/libgcrypt-${libgcrypt_version}.tar.bz2
wget -O /usr/include/linux/ntsync.h https://raw.githubusercontent.com/zen-kernel/zen-kernel/refs/heads/6.15/main/include/uapi/linux/ntsync.h
wget -O /usr/include/linux/userfaultfd.h https://raw.githubusercontent.com/zen-kernel/zen-kernel/refs/heads/6.15/main/include/uapi/linux/userfaultfd.h
if [ -d /usr/lib/i386-linux-gnu ]; then wget -O wine.deb https://dl.winehq.org/wine-builds/ubuntu/dists/focal/main/binary-i386/wine-stable_10.0.0.0~focal-1_i386.deb; fi
if [ -d /usr/lib/x86_64-linux-gnu ]; then wget -O wine.deb https://dl.winehq.org/wine-builds/ubuntu/dists/focal/main/binary-amd64/wine-stable_10.0.0.0~focal-1_amd64.deb; fi
git clone https://gitlab.freedesktop.org/gstreamer/gstreamer.git -b 1.28
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
tar xf libgpg-error.tar.bz2
tar xf libgcrypt.tar.bz2
tar xf meson.tar.gz -C /usr/local
rm -rf /usr/local/bin/meson
ln -s /usr/local/meson-${meson_version}/meson.py /usr/local/bin/meson
bash mingw-w64-build x86_64
bash mingw-w64-build i686
export CC=gcc-16
export CXX=g++-16
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
meson setup --optimization=3 -Db_lto=true build
ninja -C build
ninja -C build install
cd ../bison-${bison_version}
./configure
make -j$(nproc) install
cd ../wayland-${wayland_version}
meson setup --optimization=3 -Db_lto=true build
meson compile -C build
meson install -C build
cd ../wayland-protocols-${wayland_protocols_version}
meson setup build
meson compile -C build
meson install -C build
cd ../libxkbcommon-xkbcommon-${libxkbcommon_version}
meson setup -Denable-docs=false --optimization=3 -Db_lto=true build
meson compile -C build
meson install -C build
cd ../libglvnd-v${libglvnd_version}
meson setup --optimization=3 -Db_lto=true build
meson compile -C build
meson install -C build
cd ../nettle-${nettle_version}
./configure
make -j$(nproc) install
cd ../p11-kit-${p11_kit_version}
meson setup --optimization=3 -Db_lto=true build
meson compile -C build
meson install -C build
cd ../gnutls-${gnutls_version}
./configure --with-included-unistring --disable-doc
make -j$(nproc) install
cd ../libgpg-error-${libgpg_error_version}
./configure
make
make -j$(nproc) install
cp -f src/gpg-error-config /usr/local/bin/
rm -f /bin/gpgrt-config
cd ../libgcrypt-${libgcrypt_version}
./configure
make -j$(nproc) install
cd /opt && rm -r /opt/build_libs
EOF

	chmod +x "${MAINDIR}"/prepare_chroot.sh
	cp "${MAINDIR}"/prepare_chroot.sh "${CHROOT_X32}"/opt
	mv "${MAINDIR}"/prepare_chroot.sh "${CHROOT_X64}"/opt
}

mkdir -p "${MAINDIR}"

debootstrap --arch amd64 $CHROOT_DISTRO "${CHROOT_X64}" $CHROOT_MIRROR
debootstrap --arch i386 --exclude=console-setup,console-setup-linux,kbd,console-tools $CHROOT_DISTRO "${CHROOT_X32}" $CHROOT_MIRROR

create_build_scripts
prepare_chroot 32
prepare_chroot 64

rm "${CHROOT_X64}"/opt/prepare_chroot.sh
rm "${CHROOT_X32}"/opt/prepare_chroot.sh

#clear
echo "Done"
