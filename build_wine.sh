#!/bin/bash

## Script for building Wine (vanilla, staging, esync, pba, proton).
## It uses two chroots (x32 and x64) for compilation.
##
## This script requires: git, wget, autoconf
##
## You can change env variables to desired values.
##
## Examples of how to use it:
##
## ./build_wine.sh latest				(build latest Wine version)
## ./build_wine.sh latest staging			(build latest Wine-Staging version)
## ./build_wine.sh latest improved			(build latest Wine-Staging version with additional patches)
## ./build_wine.sh 3.16-8 proton			(build Proton 3.16-8)
## ./build_wine.sh 3.21					(build Wine 3.21)

export MAINDIR="/home/builder"
export SOURCES_DIR="$MAINDIR/sources_dir"
export CHROOT_X64="$MAINDIR/chroots/bionic64_chroot"
export CHROOT_X32="$MAINDIR/chroots/bionic32_chroot"

export C_COMPILER="gcc-8"
export CXX_COMPILER="g++-8"

export CFLAGS_X32="-march=pentium4 -O2"
export CFLAGS_X64="-march=nocona -O2"
export LDFLAGS_X32="${CFLAGS_X32}"
export LDFLAGS_X64="${CFLAGS_X64}"

export CROSSCFLAGS_X32="-march=pentium4 -O2"
export CROSSCFLAGS_X64="-march=nocona -O2"
export CROSSLDFLAGS_X32="${CROSSCFLAGS_X32}"
export CROSSLDFLAGS_X64="${CROSSCFLAGS_X64}"

export WINE_BUILD_OPTIONS="--without-curses --without-gstreamer --without-oss --disable-winemenubuilder --disable-win16 --disable-tests"

export WINE_VERSION_NUMBER="$1"

build_in_chroot () {
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
	chroot "$CHROOT_PATH" /usr/bin/env LANG=en_US.UTF-8 TERM=xterm PATH="/bin:/sbin:/usr/bin:/usr/sbin" /opt/build.sh

	echo "Unmount chroot directories"
	umount -Rl "$CHROOT_PATH"
}

create_build_scripts () {
	echo '#!/bin/sh' > $MAINDIR/build32.sh
	echo 'cd /opt' >> $MAINDIR/build32.sh
	echo 'export CC="'${C_COMPILER}'"' >> $MAINDIR/build32.sh
	echo 'export CXX="'${CXX_COMPILER}'"' >> $MAINDIR/build32.sh
	echo 'export CFLAGS="'${CFLAGS_X32}'"' >> $MAINDIR/build32.sh
	echo 'export CXXFLAGS="'${CFLAGS_X32}'"' >> $MAINDIR/build32.sh
	echo 'export LDFLAGS="'${LDFLAGS_X32}'"' >> $MAINDIR/build32.sh
	echo 'export CROSSCFLAGS="'${CROSSCFLAGS_X32}'"' >> $MAINDIR/build32.sh
	echo 'export CROSSLDFLAGS="'${CROSSLDFLAGS_X32}'"' >> $MAINDIR/build32.sh
	echo 'mkdir build-tools && cd build-tools' >> $MAINDIR/build32.sh
	echo '../wine/configure '${WINE_BUILD_OPTIONS}' --prefix /opt/wine32-build' >> $MAINDIR/build32.sh
	echo 'make -j2' >> $MAINDIR/build32.sh
	echo 'make install' >> $MAINDIR/build32.sh
	echo 'export CFLAGS="'${CFLAGS_X64}'"' >> $MAINDIR/build32.sh
	echo 'export CXXFLAGS="'${CFLAGS_X64}'"' >> $MAINDIR/build32.sh
	echo 'export LDFLAGS="'${LDFLAGS_X64}'"' >> $MAINDIR/build32.sh
	echo 'export CROSSCFLAGS="'${CROSSCFLAGS_X64}'"' >> $MAINDIR/build32.sh
	echo 'export CROSSLDFLAGS="'${CROSSLDFLAGS_X64}'"' >> $MAINDIR/build32.sh
	echo 'cd ..' >> $MAINDIR/build32.sh
	echo 'mkdir build-combo && cd build-combo' >> $MAINDIR/build32.sh
	echo '../wine/configure '${WINE_BUILD_OPTIONS}' --with-wine64=../build64 --with-wine-tools=../build-tools --prefix /opt/wine-build' >> $MAINDIR/build32.sh
	echo 'make -j2' >> $MAINDIR/build32.sh
	echo 'make install' >> $MAINDIR/build32.sh

	echo '#!/bin/sh' > $MAINDIR/build64.sh
	echo 'cd /opt' >> $MAINDIR/build64.sh
	echo 'export CC="'${C_COMPILER}'"' >> $MAINDIR/build64.sh
	echo 'export CXX="'${CXX_COMPILER}'"' >> $MAINDIR/build64.sh
	echo 'export CFLAGS="'${CFLAGS_X64}'"' >> $MAINDIR/build64.sh
	echo 'export CXXFLAGS="'${CFLAGS_X64}'"' >> $MAINDIR/build64.sh
	echo 'export LDFLAGS="'${LDFLAGS_X64}'"' >> $MAINDIR/build64.sh
	echo 'export CROSSCFLAGS="'${CROSSCFLAGS_X64}'"' >> $MAINDIR/build64.sh
	echo 'export CROSSLDFLAGS="'${CROSSLDFLAGS_X64}'"' >> $MAINDIR/build64.sh
	echo 'mkdir build64 && cd build64' >> $MAINDIR/build64.sh
	echo '../wine/configure '${WINE_BUILD_OPTIONS}' --enable-win64 --prefix /opt/wine-build' >> $MAINDIR/build64.sh
	echo 'make -j2' >> $MAINDIR/build64.sh
	echo 'make install' >> $MAINDIR/build64.sh

	chmod +x "$MAINDIR/build64.sh"
	chmod +x "$MAINDIR/build32.sh"

	mv "$MAINDIR/build64.sh" "$CHROOT_X64/opt/build.sh"
	mv "$MAINDIR/build32.sh" "$CHROOT_X32/opt/build.sh"
}

patching_error () {
	echo "Some patches were not applied correctly. Exiting."
	exit
}

if [ ! "$WINE_VERSION_NUMBER" ]; then
	echo "No version specified"
	exit
fi

if [ "$MAINDIR" = "$SOURCES_DIR" ]; then
	echo "Don't use the same directory for MAINDIR and SOURCES_DIR"
	exit
fi

rm -rf "$SOURCES_DIR"
mkdir "$SOURCES_DIR"
cd "$SOURCES_DIR" || exit

# Replace latest argument with actual latest Wine version
if [ "$WINE_VERSION_NUMBER" = "latest" ]; then
	if [ "$2" != "proton" ]; then
		wget https://raw.githubusercontent.com/wine-mirror/wine/master/VERSION

		WINE_VERSION_NUMBER="$(cat VERSION | sed "s/Wine version //g")"
	else
		echo "Please, specify version to build Proton"
		exit
	fi
fi

# Stable and Development version has different sources location
# Determine if we trying to build stable or development version
if [ "$(echo "$WINE_VERSION_NUMBER" | cut -c3)" = "0" ]; then
	WINE_SOURCES_VERSION=$(echo "$WINE_VERSION_NUMBER" | cut -c1).0
else
	WINE_SOURCES_VERSION=$(echo "$WINE_VERSION_NUMBER" | cut -c1).x
fi

clear
echo "Downloading sources and patches"
echo "Preparing Wine for compilation"
echo

if [ "$2" = "improved" ]; then
	WINE_VERSION="$WINE_VERSION_NUMBER-staging-improved"
	WINE_VERSION_STRING="Staging Improved"

	PATCHES_DIR="$SOURCES_DIR/PKGBUILDS/wine-tkg-git/wine-tkg-patches"

	wget https://dl.winehq.org/wine/source/$WINE_SOURCES_VERSION/wine-$WINE_VERSION_NUMBER.tar.xz
	wget https://github.com/wine-staging/wine-staging/archive/v$WINE_VERSION_NUMBER.tar.gz
	git clone https://github.com/Tk-Glitch/PKGBUILDS.git

	tar xf wine-$WINE_VERSION_NUMBER.tar.xz
	tar xf v$WINE_VERSION_NUMBER.tar.gz

	mv wine-$WINE_VERSION_NUMBER wine
	cd wine

	patch -Np1 < "$PATCHES_DIR"/proton/use_clock_monotonic.patch || patching_error
	patch -Np1 < "$PATCHES_DIR"/proton/use_clock_monotonic-2.patch || patching_error

	../wine-staging-$WINE_VERSION_NUMBER/patches/patchinstall.sh DESTDIR=../wine --all -W winex11.drv-mouse-coorrds || patching_error

	patch -Np1 < "$PATCHES_DIR"/proton/fsync-staging.patch || patching_error
	patch -Np1 < "$PATCHES_DIR"/proton/fsync-staging-no_alloc_handle.patch || patching_error

	patch -Np1 < "$PATCHES_DIR"/proton/FS_bypass_compositor.patch || patching_error
	patch -Np1 < "$PATCHES_DIR"/proton/valve_proton_fullscreen_hack-staging.patch || patching_error
	patch -Np1 < "$PATCHES_DIR"/proton/valve_proton_fullscreen_hack_realmodes.patch || patching_error
	
	patch -Np1 < "$PATCHES_DIR"/proton-tkg-specific/winevulkan-1.1.113-proton.patch || patching_error

	patch -Np1 < "$PATCHES_DIR"/proton/LAA-staging.patch || patching_error
	patch -Np1 < "$PATCHES_DIR"/proton/proton_mf_hacks.patch || patching_error
	patch -Np1 < "$PATCHES_DIR"/misc/enable_stg_shared_mem_def.patch || patching_error
	patch -Np1 < "$PATCHES_DIR"/misc/nvidia-hate.patch || patching_error
elif [ "$2" = "proton" ]; then
	WINE_VERSION="$WINE_VERSION_NUMBER-proton"
	WINE_VERSION_STRING="Proton"

	if [ "$(echo $WINE_VERSION_NUMBER | head -c3)" = "3.7" ]; then
		git clone https://github.com/ValveSoftware/wine.git -b proton_3.7
	elif [ "$(echo $WINE_VERSION_NUMBER | head -c4)" = "3.16" ]; then
		git clone https://github.com/ValveSoftware/wine.git -b proton_3.16
	elif [ "$(echo $WINE_VERSION_NUMBER | head -c3)" = "4.2" ]; then
		git clone https://github.com/ValveSoftware/wine.git -b proton_4.2
	elif [ "$(echo $WINE_VERSION_NUMBER | head -c4)" = "4.11" ]; then
		git clone https://github.com/ValveSoftware/wine.git -b proton_4.11
	else
		git clone https://github.com/ValveSoftware/wine.git
	fi
else
	WINE_VERSION="$WINE_VERSION_NUMBER"

	wget https://dl.winehq.org/wine/source/$WINE_SOURCES_VERSION/wine-$WINE_VERSION_NUMBER.tar.xz

	tar xf wine-$WINE_VERSION_NUMBER.tar.xz

	mv wine-$WINE_VERSION_NUMBER wine

	if [ "$2" = "staging" ]; then
		WINE_VERSION="$WINE_VERSION_NUMBER-staging"

		wget https://github.com/wine-staging/wine-staging/archive/v$WINE_VERSION_NUMBER.tar.gz

		tar xf v$WINE_VERSION_NUMBER.tar.gz

		cd wine-staging-$WINE_VERSION_NUMBER/patches
		./patchinstall.sh DESTDIR=../../wine --all || patching_error
	fi
fi

# Replace version string in winecfg and "wine --version" output
if [ ! -z "$2" ] && [ "$2" != "staging" ] && [ "$2" != "exit" ]; then
	sed -i "s/  (Staging)//g" "$SOURCES_DIR/wine/libs/wine/Makefile.in"
	sed -i "s/\\\1/\\\1  (${WINE_VERSION_STRING})/g" "$SOURCES_DIR/wine/libs/wine/Makefile.in"
	sed -i "s/ \" (Staging)\"//g" "$SOURCES_DIR/wine/programs/winecfg/about.c"
	sed -i "s/PACKAGE_VERSION/PACKAGE_VERSION \" (${WINE_VERSION_STRING})\"/g" "$SOURCES_DIR/wine/programs/winecfg/about.c"
fi

if [ "$2" = "exit" ] || [ "$3" = "exit" ] || [ "$4" = "exit" ]; then
	echo "Force exit"
	exit
fi

clear; echo "Creating build scripts"
create_build_scripts

clear; echo "Compiling 64-bit Wine"
cp -r "$SOURCES_DIR/wine" "$CHROOT_X64/opt"
build_in_chroot 64

mv "$CHROOT_X64/opt/wine-build" "$CHROOT_X32/opt"
cp -r "$CHROOT_X32/opt/wine-build" "$MAINDIR/wine-$WINE_VERSION-amd64-nomultilib"
mv "$CHROOT_X64/opt/build64" "$CHROOT_X32/opt"

clear; echo "Compiling 32-bit Wine"
mv "$CHROOT_X64/opt/wine" "$CHROOT_X32/opt"
build_in_chroot 32

clear; echo "Compilation complete"
echo "Compressing Wine..."

mv "$CHROOT_X32/opt/wine-build" "$MAINDIR/wine-$WINE_VERSION-amd64"
mv "$CHROOT_X32/opt/wine32-build" "$MAINDIR/wine-$WINE_VERSION-x86"

rm -r "$CHROOT_X64/opt"
mkdir "$CHROOT_X64/opt"
rm -r "$CHROOT_X32/opt"
mkdir "$CHROOT_X32/opt"

cd "$MAINDIR/wine-$WINE_VERSION-x86" && rm -r include && rm -r share/applications && rm -r share/man
cd "$MAINDIR/wine-$WINE_VERSION-amd64" && rm -r include && rm -r share/applications && rm -r share/man
cd "$MAINDIR/wine-$WINE_VERSION-amd64-nomultilib" && rm -r include && rm -r share/applications && rm -r share/man && cd bin && ln -sr wine64 wine

cd "$MAINDIR"
tar -cf wine-$WINE_VERSION-amd64.tar wine-$WINE_VERSION-amd64
tar -cf wine-$WINE_VERSION-amd64-nomultilib.tar wine-$WINE_VERSION-amd64-nomultilib
tar -cf wine-$WINE_VERSION-x86.tar wine-$WINE_VERSION-x86
xz -9 wine-$WINE_VERSION-amd64.tar
xz -9 wine-$WINE_VERSION-amd64-nomultilib.tar
xz -9 wine-$WINE_VERSION-x86.tar

rm -r wine-$WINE_VERSION-amd64
rm -r wine-$WINE_VERSION-amd64-nomultilib
rm -r wine-$WINE_VERSION-x86

clear; echo "Done"
