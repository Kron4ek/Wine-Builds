#!/usr/bin/env bash

########################################################################
##
## Script for Wine compilation.
## By default it uses two chroots (x32 and x64).
##
## This script requires: git, wget, autoconf
##
## Root rights are required because of chroot.
##
## Root rights are not required if you explicitly disable chroots
## usage below (DISABLE_CHROOTS variable).
##
## You can change the environment variables below to your desired values.
##
########################################################################

# Wine version to compile.
# You can set it to "latest" to compile the latest available version.
#
# This doesn't affect tkg and wayland branches as they always build the
# latest available version.
export WINE_VERSION="5.20"

# Sometimes Wine and Staging versions doesn't match (for example, 5.15.2).
# Leave this empty to use Staging version that matches the Wine version.
export STAGING_VERSION=""

# Available branches: vanilla, staging, proton, tkg, wayland.
export WINE_BRANCH="staging"

# Set this to a path to your Wine sources (for example, /home/username/wine-custom-src).
# This is useful if you already have Wine sources somewhere on your storage
# and you want to compile them.
#
# You can also set this to a GitHub clone url instead of a local path.
#
# If you don't want to compile custom Wine sources, then just leave this
# variable empty.
export CUSTOM_SRC_PATH=""

# Set to true to download and prepare sources, but do not compile them.
# If this variable is set to true, root rights are not required.
export DO_NOT_COMPILE="false"

# Set to true to disable chroots usage for compilation and compile
# Wine on your host system instead.
#
# You need to manually install all Wine build dependencies on your
# system before compiling in this mode.
#
# Also make sure to set correct C and CXX compiler in the environment
# variables below.
export DISABLE_CHROOTS="false"

export WINE_BUILD_OPTIONS="--without-curses --without-oss --disable-winemenubuilder --disable-win16 --disable-tests"

# Keep in mind that the root's HOME directory is /root.
export MAINDIR="${HOME}"

# Temporary directory where Wine sources will be stored.
# Do not set this variable to an existing non-empty directory!
# This directory is removed and recreated on each script run.
export SOURCES_DIR="${MAINDIR}"/src

export CHROOT_X64="${MAINDIR}"/chroots/bionic64_chroot
export CHROOT_X32="${MAINDIR}"/chroots/bionic32_chroot

export C_COMPILER="gcc-8"
export CXX_COMPILER="g++-8"

export CFLAGS_X32="-march=i686 -msse2 -mfpmath=sse -O2 -ftree-vectorize"
export CFLAGS_X64="-march=x86-64 -msse3 -mfpmath=sse -O2 -ftree-vectorize"
export LDFLAGS_X32="-Wl,-O1,--sort-common,--as-needed"
export LDFLAGS_X64="${LDFLAGS_X32}"

export CROSSCFLAGS_X32="${CFLAGS_X32}"
export CROSSCFLAGS_X64="${CFLAGS_X64}"
export CROSSLDFLAGS_X32="${LDFLAGS_X32}"
export CROSSLDFLAGS_X64="${LDFLAGS_X64}"

build_in_chroot () {
	if [ "$1" = "32" ]; then
		CHROOT_PATH="${CHROOT_X32}"
	else
		CHROOT_PATH="${CHROOT_X64}"
	fi

	echo "Unmounting chroot directories"
	umount -Rl "${CHROOT_PATH}"

	echo "Mounting directories for chroots"
	mount --bind "${CHROOT_PATH}" "${CHROOT_PATH}"
	mount --bind /dev "${CHROOT_PATH}"/dev
	mount --bind /dev/shm "${CHROOT_PATH}"/dev/shm
	mount --bind /dev/pts "${CHROOT_PATH}"/dev/pts
	mount --bind /proc "${CHROOT_PATH}"/proc
	mount --bind /sys "${CHROOT_PATH}"/sys

	echo "Chrooting into ${CHROOT_PATH}"
	chroot "${CHROOT_PATH}" /usr/bin/env LANG=en_US.UTF-8 TERM=xterm PATH="/bin:/sbin:/usr/bin:/usr/sbin" /opt/build.sh

	echo "Unmounting chroot directories"
	umount -Rl "${CHROOT_PATH}"
}

create_build_scripts () {
	echo '#!/bin/sh' > "${MAINDIR}"/build32.sh
	echo 'cd /opt' >> "${MAINDIR}"/build32.sh
	echo 'export CC="'${C_COMPILER}'"' >> "${MAINDIR}"/build32.sh
	echo 'export CXX="'${CXX_COMPILER}'"' >> "${MAINDIR}"/build32.sh
	echo 'export CFLAGS="'${CFLAGS_X32}'"' >> "${MAINDIR}"/build32.sh
	echo 'export CXXFLAGS="'${CFLAGS_X32}'"' >> "${MAINDIR}"/build32.sh
	echo 'export LDFLAGS="'${LDFLAGS_X32}'"' >> "${MAINDIR}"/build32.sh
	echo 'export CROSSCFLAGS="'${CROSSCFLAGS_X32}'"' >> "${MAINDIR}"/build32.sh
	echo 'export CROSSLDFLAGS="'${CROSSLDFLAGS_X32}'"' >> "${MAINDIR}"/build32.sh
	echo 'mkdir build-tools && cd build-tools' >> "${MAINDIR}"/build32.sh
	echo '../wine/configure '${WINE_BUILD_OPTIONS}' --prefix /opt/wine32-build' >> "${MAINDIR}"/build32.sh
	echo 'make -j$(nproc)' >> "${MAINDIR}"/build32.sh
	echo 'make install' >> "${MAINDIR}"/build32.sh
	echo 'export CFLAGS="'${CFLAGS_X64}'"' >> "${MAINDIR}"/build32.sh
	echo 'export CXXFLAGS="'${CFLAGS_X64}'"' >> "${MAINDIR}"/build32.sh
	echo 'export LDFLAGS="'${LDFLAGS_X64}'"' >> "${MAINDIR}"/build32.sh
	echo 'export CROSSCFLAGS="'${CROSSCFLAGS_X64}'"' >> "${MAINDIR}"/build32.sh
	echo 'export CROSSLDFLAGS="'${CROSSLDFLAGS_X64}'"' >> "${MAINDIR}"/build32.sh
	echo 'cd ..' >> "${MAINDIR}"/build32.sh
	echo 'mkdir build-combo && cd build-combo' >> "${MAINDIR}"/build32.sh
	echo '../wine/configure '${WINE_BUILD_OPTIONS}' --with-wine64=../build64 --with-wine-tools=../build-tools --prefix /opt/wine-build' >> "${MAINDIR}"/build32.sh
	echo 'make -j$(nproc)' >> "${MAINDIR}"/build32.sh
	echo 'make install' >> "${MAINDIR}"/build32.sh

	echo '#!/bin/sh' > "${MAINDIR}"/build64.sh
	echo 'cd /opt' >> "${MAINDIR}"/build64.sh
	echo 'export CC="'${C_COMPILER}'"' >> "${MAINDIR}"/build64.sh
	echo 'export CXX="'${CXX_COMPILER}'"' >> "${MAINDIR}"/build64.sh
	echo 'export CFLAGS="'${CFLAGS_X64}'"' >> "${MAINDIR}"/build64.sh
	echo 'export CXXFLAGS="'${CFLAGS_X64}'"' >> "${MAINDIR}"/build64.sh
	echo 'export LDFLAGS="'${LDFLAGS_X64}'"' >> "${MAINDIR}"/build64.sh
	echo 'export CROSSCFLAGS="'${CROSSCFLAGS_X64}'"' >> "${MAINDIR}"/build64.sh
	echo 'export CROSSLDFLAGS="'${CROSSLDFLAGS_X64}'"' >> "${MAINDIR}"/build64.sh
	echo 'mkdir build64 && cd build64' >> "${MAINDIR}"/build64.sh
	echo '../wine/configure '${WINE_BUILD_OPTIONS}' --enable-win64 --prefix /opt/wine-build' >> "${MAINDIR}"/build64.sh
	echo 'make -j$(nproc)' >> "${MAINDIR}"/build64.sh
	echo 'make install' >> "${MAINDIR}"/build64.sh

	chmod +x "${MAINDIR}"/build64.sh
	chmod +x "${MAINDIR}"/build32.sh

	mv "${MAINDIR}"/build64.sh "${CHROOT_X64}"/opt/build.sh
	mv "${MAINDIR}"/build32.sh "${CHROOT_X32}"/opt/build.sh
}

if [ -z "${WINE_VERSION}" ] && [ -z "${CUSTOM_SRC_PATH}" ] && [ "${WINE_BRANCH}" != "tkg" ]; then
	echo "No Wine version specified!"
	exit 1
fi

if [ "${MAINDIR}" = "${SOURCES_DIR}" ]; then
	echo "Do not use the same directory for MAINDIR and SOURCES_DIR!"
	exit 1
fi

rm -rf "${SOURCES_DIR}"
mkdir -p "${SOURCES_DIR}"
mkdir -p "${MAINDIR}"
cd "${SOURCES_DIR}" || exit 1

# Replace latest parameter with the actual latest Wine version
if [ "$WINE_VERSION" = "latest" ]; then
	wget -q --show-progress https://raw.githubusercontent.com/wine-mirror/wine/master/VERSION

	WINE_VERSION="$(cat VERSION | sed "s/Wine version //g")"
fi

# Stable and Development versions have different sources location
# Determine if the chosen version is stable or development
if [ "$(echo "$WINE_VERSION" | cut -c3)" = "0" ]; then
	WINE_SOURCES_VERSION=$(echo "$WINE_VERSION" | cut -c1).0
else
	WINE_SOURCES_VERSION=$(echo "$WINE_VERSION" | cut -c1).x
fi

clear
if [ ! -z "${CUSTOM_SRC_PATH}" ]; then
	echo "Wine custom ${CUSTOM_SRC_PATH}"
elif [ "${WINE_BRANCH}" = "tkg" ]; then
	echo "Wine-TkG"
elif [ "${WINE_BRANCH}" = "wayland" ]; then
	echo "Wine-Wayland"
else
	echo "Wine ${WINE_VERSION} ${WINE_BRANCH}"
fi
echo
echo "Downloading sources and patches"
echo "Preparing Wine for compilation"
echo

if [ ! -z "${CUSTOM_SRC_PATH}" ]; then
	is_url="$(echo "${CUSTOM_SRC_PATH}" | head -c 6)"

	if [ "${is_url}" = "git://" ] || [ "${is_url}" = "https:" ]; then
		git clone "${CUSTOM_SRC_PATH}" wine
	else
		if [ ! -d "${CUSTOM_SRC_PATH}" ]; then
			echo "CUSTOM_SRC_PATH is set to a non-existing directory!"
			echo "Please make sure to use a correct path."
			exit 1
		fi

		cp -r "${CUSTOM_SRC_PATH}" wine
	fi

	WINE_VERSION="$(cat wine/VERSION | sed "s/Wine version //g")"
	BUILD_NAME="${WINE_VERSION}"-custom
elif [ "$WINE_BRANCH" = "tkg" ]; then
	git clone https://github.com/Kron4ek/wine-tkg wine

	WINE_VERSION="$(cat wine/VERSION | sed "s/Wine version //g")"
	BUILD_NAME="${WINE_VERSION}"-staging-tkg
elif [ "$WINE_BRANCH" = "wayland" ]; then
	git clone https://github.com/Kron4ek/wine-wayland wine

	WINE_VERSION="$(cat wine/VERSION | sed "s/Wine version //g")"
	BUILD_NAME="${WINE_VERSION}"-wayland

	export WINE_BUILD_OPTIONS="--without-x --without-xcomposite \
                               --without-xfixes --without-xinerama \
                               --without-xinput --without-xinput2 \
                               --without-xrandr --without-xrender \
                               --without-xshape --without-xshm  \
                               --without-xslt --without-xxf86vm \
                               --without-xcursor --without-opengl \
                               ${WINE_BUILD_OPTIONS}"
elif [ "$WINE_BRANCH" = "proton" ]; then
	if [ "$(echo $WINE_VERSION | head -c3)" = "3.7" ]; then
		git clone https://github.com/ValveSoftware/wine -b proton_3.7
	elif [ "$(echo $WINE_VERSION | head -c4)" = "3.16" ]; then
		git clone https://github.com/ValveSoftware/wine -b proton_3.16
	elif [ "$(echo $WINE_VERSION | head -c3)" = "4.2" ]; then
		git clone https://github.com/ValveSoftware/wine -b proton_4.2
	elif [ "$(echo $WINE_VERSION | head -c4)" = "4.11" ]; then
		git clone https://github.com/ValveSoftware/wine -b proton_4.11
	elif [ "$(echo $WINE_VERSION | head -c3)" = "5.0" ]; then
		git clone https://github.com/ValveSoftware/wine -b proton_5.0
	elif [ "$(echo $WINE_VERSION | head -c4)" = "5.13" ]; then
		git clone https://github.com/ValveSoftware/wine -b proton_5.13
	else
		git clone https://github.com/ValveSoftware/wine

		WINE_VERSION="$(cat wine/VERSION | sed "s/Wine version //g")"
	fi

	BUILD_NAME="${WINE_VERSION}"-proton
else
	BUILD_NAME="${WINE_VERSION}"

	wget -q --show-progress https://dl.winehq.org/wine/source/${WINE_SOURCES_VERSION}/wine-${WINE_VERSION}.tar.xz

	tar xf wine-${WINE_VERSION}.tar.xz
	mv wine-${WINE_VERSION} wine

	if [ "${WINE_BRANCH}" = "staging" ]; then
		if [ ! -z "$STAGING_VERSION" ]; then
			WINE_VERSION="${STAGING_VERSION}"
		fi

		BUILD_NAME="${WINE_VERSION}"-staging

		wget -q --show-progress https://github.com/wine-staging/wine-staging/archive/v${WINE_VERSION}.tar.gz
		tar xf v${WINE_VERSION}.tar.gz

		if [ ! -f v${WINE_VERSION}.tar.gz ]; then
			git clone https://github.com/wine-staging/wine-staging wine-staging-${WINE_VERSION}
		fi

		wine-staging-${WINE_VERSION}/patches/patchinstall.sh DESTDIR="${SOURCES_DIR}"/wine --all

		if [ $? -ne 0 ]; then
			echo
			echo "Wine-Staging patches were not applied correctly!"
			exit 1
		fi
	fi
fi

if [ "${DO_NOT_COMPILE}" = "true" ]; then
	clear
	echo "DO_NOT_COMPILE is set to true"
	echo "Force exit"
	exit
fi

if [ ! -d wine ]; then
	clear
	echo "No Wine sources found!"
	echo "Make sure that the correct Wine version is specified."
	exit 1
fi

if [ "$EUID" != 0 ] && [ "$DISABLE_CHROOTS" != "true" ]; then
	clear
	echo "Root rights are required for compilation!"
	exit 1
fi

if [ "$DISABLE_CHROOTS" != "true" ]; then
	if [ ! -d "${CHROOT_X64}" ] || [ ! -d "${CHROOT_X32}" ]; then
		clear
		echo "Chroots are required for compilation!"
		exit 1
	fi
fi

if [ "$DISABLE_CHROOTS" != "true" ]; then
	clear
	echo "Creating build scripts"
	create_build_scripts

	clear
	echo "Compiling 64-bit Wine"
	cp -r "${SOURCES_DIR}"/wine "${CHROOT_X64}"/opt
	build_in_chroot 64

	mv "${CHROOT_X64}"/opt/wine-build "${CHROOT_X32}"/opt
	cp -r "${CHROOT_X32}"/opt/wine-build "${MAINDIR}"/wine-${BUILD_NAME}-amd64-nomultilib
	mv "${CHROOT_X64}"/opt/build64 "${CHROOT_X32}"/opt

	clear
	echo "Compiling 32-bit Wine"
	mv "${CHROOT_X64}"/opt/wine "${CHROOT_X32}"/opt
	build_in_chroot 32

	mv "${CHROOT_X32}"/opt/wine-build "${MAINDIR}"/wine-${BUILD_NAME}-amd64
	mv "${CHROOT_X32}"/opt/wine32-build "${MAINDIR}"/wine-${BUILD_NAME}-x86

	rm -rf "${CHROOT_X64}"/opt
	mkdir "${CHROOT_X64}"/opt
	rm -rf "${CHROOT_X32}"/opt
	mkdir "${CHROOT_X32}"/opt
else
	export CC="${C_COMPILER}"
	export CXX="${CXX_COMPILER}"

	if [ "$(getconf LONG_BIT)" = 32 ]; then
		export CFLAGS="${CFLAGS_X32}"
		export CXXFLAGS="${CFLAGS_X32}"
		export LDFLAGS="${LDFLAGS_X32}"
		export CROSSCFLAGS="${CROSSCFLAGS_X32}"
		export CROSSLDFLAGS="${CROSSLDFLAGS_X32}"

		mkdir build
		cd build
		"${SOURCES_DIR}"/wine/configure ${WINE_BUILD_OPTIONS} --prefix "${MAINDIR}"/wine-${BUILD_NAME}-x86
		make -j$(nproc)
		make install
	else
		export CFLAGS="${CFLAGS_X64}"
		export CXXFLAGS="${CFLAGS_X64}"
		export LDFLAGS="${LDFLAGS_X64}"
		export CROSSCFLAGS="${CROSSCFLAGS_X64}"
		export CROSSLDFLAGS="${CROSSLDFLAGS_X64}"

		mkdir build64
		mkdir build32

		cd build64
		"${SOURCES_DIR}"/wine/configure --enable-win64 ${WINE_BUILD_OPTIONS} --prefix "${MAINDIR}"/wine-${BUILD_NAME}-amd64
		make -j$(nproc)

		cd "${SOURCES_DIR}"/build32
		"${SOURCES_DIR}"/wine/configure --with-wine64="${SOURCES_DIR}"/build64 ${WINE_BUILD_OPTIONS} --prefix "${MAINDIR}"/wine-${BUILD_NAME}-amd64
		make -j$(nproc)

		make -C "${SOURCES_DIR}"/build64 install
		make -C "${SOURCES_DIR}"/build32 install
	fi
fi

cd "${MAINDIR}"/wine-${BUILD_NAME}-x86 && rm -r include && rm -r share/applications && rm -r share/man
cd "${MAINDIR}"/wine-${BUILD_NAME}-amd64 && rm -r include && rm -r share/applications && rm -r share/man
cd "${MAINDIR}"/wine-${BUILD_NAME}-amd64-nomultilib && rm -r include && rm -r share/applications && rm -r share/man && cd bin && ln -sr wine64 wine

# Strip all Wine binaries and libraries
clear
echo "Stripping libraries"

find "${MAINDIR}"/wine-${BUILD_NAME}-x86 -type f -exec strip --strip-unneeded {} \; 2>/dev/null
find "${MAINDIR}"/wine-${BUILD_NAME}-amd64 -type f -exec strip --strip-unneeded {} \; 2>/dev/null
find "${MAINDIR}"/wine-${BUILD_NAME}-amd64-nomultilib -type f -exec strip --strip-unneeded {} \; 2>/dev/null

if [ "${WINE_BRANCH}" = "tkg" ]; then
	cp "${SOURCES_DIR}"/wine/wine-tkg-config.txt "${MAINDIR}"/wine-${BUILD_NAME}-x86
	cp "${SOURCES_DIR}"/wine/wine-tkg-config.txt "${MAINDIR}"/wine-${BUILD_NAME}-amd64
	cp "${SOURCES_DIR}"/wine/wine-tkg-config.txt "${MAINDIR}"/wine-${BUILD_NAME}-amd64-nomultilib
fi

cd "${MAINDIR}"

clear
echo "Compilation complete"
echo "Creating archives..."

if [ -d wine-${BUILD_NAME}-amd64 ]; then
	tar -cf wine-${BUILD_NAME}-amd64.tar wine-${BUILD_NAME}-amd64
	xz -T0 -9 wine-${BUILD_NAME}-amd64.tar
	rm -r wine-${BUILD_NAME}-amd64
fi

if [ -d wine-${BUILD_NAME}-amd64-nomultilib ]; then
	tar -cf wine-${BUILD_NAME}-amd64-nomultilib.tar wine-${BUILD_NAME}-amd64-nomultilib
	xz -T0 -9 wine-${BUILD_NAME}-amd64-nomultilib.tar
	rm -r wine-${BUILD_NAME}-amd64-nomultilib
fi

if [ -d wine-${BUILD_NAME}-x86 ]; then
	tar -cf wine-${BUILD_NAME}-x86.tar wine-${BUILD_NAME}-x86
	xz -T0 -9 wine-${BUILD_NAME}-x86.tar
	rm -r wine-${BUILD_NAME}-x86
fi

clear
echo "Done"
