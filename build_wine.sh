#!/bin/bash

## Script for building Wine (vanilla, staging, esync, pba, proton).
## It use two chroots for compiling (x32 chroot and x64 chroot).
##
## This script require packages: git, wget, autoconf
##
## You can change env variables to desired values.
##
## Examples of how to use it:
##
## ./build_wine.sh latest				(download and build latest Wine version)
## ./build_wine.sh 4.0					(download and build Wine 4.0)
## ./build_wine.sh 4.0 exit				(download and prepare Wine sources and exit)
## ./build_wine.sh 4.0 staging			(build Wine 4.0 with Staging patches)
## ./build_wine.sh 4.0 esync			(build Wine 4.0 with ESYNC patches)
## ./build_wine.sh 3.16-6 proton		(build latest Proton and name it 3.16-6)
## ./build_wine.sh 3.16 esync pba		(build Wine 3.16 with Staging, Esync and PBA patches)

export MAINDIR="/home/builder"
export SOURCES_DIR="$MAINDIR/sources_dir"
export CHROOT_X64="$MAINDIR/xenial64_chroot"
export CHROOT_X32="$MAINDIR/xenial32_chroot"

export C_COMPILER="gcc"
export CXX_COMPILER="g++"

export CFLAGS_X32="-march=pentium4 -O2 -DWINE_NO_TRACE_MSGS -DWINE_NO_DEBUG_MSGS"
export CFLAGS_X64="-march=nocona -O2 -DWINE_NO_TRACE_MSGS -DWINE_NO_DEBUG_MSGS"
export FLAGS_LD="-O2"
export WINE_BUILD_OPTIONS="--without-coreaudio --without-curses --without-gstreamer --without-oss --disable-winemenubuilder --disable-tests --disable-win16"

export WINE_VERSION_NUMBER="$1"
export ESYNC_VERSION="ce79346"

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
	echo 'export LDFLAGS="'${FLAGS_LD}'"' >> $MAINDIR/build32.sh
	echo 'mkdir build-tools && cd build-tools' >> $MAINDIR/build32.sh
	echo '../wine/configure '${WINE_BUILD_OPTIONS}' --prefix /opt/wine32-build' >> $MAINDIR/build32.sh
	echo 'make -j2' >> $MAINDIR/build32.sh
	echo 'make install' >> $MAINDIR/build32.sh
	echo 'export CFLAGS="'${CFLAGS_X64}'"' >> $MAINDIR/build32.sh
	echo 'export CXXFLAGS="'${CFLAGS_X64}'"' >> $MAINDIR/build32.sh
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
	echo 'export LDFLAGS="'${FLAGS_LD}'"' >> $MAINDIR/build64.sh
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
	clear
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
		echo "Please, specify real version to build Proton"
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
echo "Downloading sources and patches."
echo "Preparing Wine for compiling."
echo

if [ "$2" = "esync" ]; then
	WINE_VERSION="$WINE_VERSION_NUMBER-esync-staging"
	WINE_VERSION_STRING="Staging Esync"

	PATCHES_DIR="$SOURCES_DIR/PKGBUILDS/wine-tkg-git/wine-tkg-patches"

	wget https://dl.winehq.org/wine/source/$WINE_SOURCES_VERSION/wine-$WINE_VERSION_NUMBER.tar.xz
	wget https://github.com/wine-staging/wine-staging/archive/v$WINE_VERSION_NUMBER.tar.gz
	wget https://github.com/zfigura/wine/releases/download/esync$ESYNC_VERSION/esync.tgz
	git clone https://github.com/Tk-Glitch/PKGBUILDS.git

	tar xf wine-$WINE_VERSION_NUMBER.tar.xz
	tar xf v$WINE_VERSION_NUMBER.tar.gz
	tar xf esync.tgz

	mv wine-$WINE_VERSION_NUMBER wine

	cd wine
	patch -Np1 < "$PATCHES_DIR"/use_clock_monotonic.patch || patching_error

	cd ../wine-staging-$WINE_VERSION_NUMBER
	patch -Np1 < "$PATCHES_DIR"/CSMT-toggle.patch || patching_error

	cd patches
	./patchinstall.sh DESTDIR=../../wine --all || patching_error

	# Apply fixes for esync patches
	cd ../../esync
	patch -Np1 < "$PATCHES_DIR"/esync-staging-fixes-r3.patch || patching_error
	patch -Np1 < "$PATCHES_DIR"/esync-compat-fixes-r3.patch || patching_error

	# Apply esync patches
	cd ../wine
	for f in ../esync/*.patch; do
		git apply -C1 --verbose < "${f}" || patching_error
	done
	patch -Np1 < "$PATCHES_DIR"/esync-no_alloc_handle.patch || patching_error

	if [ "$3" = "pba" ] || [ "$4" = "pba" ] || [ "$5" = "pba" ]; then
		WINE_VERSION="$WINE_VERSION-pba"
		WINE_VERSION_STRING="$WINE_VERSION_STRING PBA"

		git clone https://github.com/Firerat/wine-pba.git

		# Apply pba patches
		for f in $(ls ../wine-pba/patches); do
			patch -Np1 < ../wine-pba/patches/"${f}" || patching_error
		done
	fi

	patch -Np1 < "$PATCHES_DIR"/GLSL-toggle.patch || patching_error

	patch -Np1 < "$PATCHES_DIR"/FS_bypass_compositor.patch || patching_error
	patch -Np1 < "$PATCHES_DIR"/valve_proton_fullscreen_hack-staging.patch || patching_error

	patch -Np1 < "$PATCHES_DIR"/enable_stg_shared_mem_def.patch || patching_error
elif [ "$2" = "proton" ]; then
	WINE_VERSION="$WINE_VERSION_NUMBER-proton"
	WINE_VERSION_STRING="Proton"

	if [ "$(echo $WINE_VERSION_NUMBER | head -c3)" = "3.7" ]; then
		git clone https://github.com/ValveSoftware/wine.git -b proton_3.7
	elif [ "$(echo $WINE_VERSION_NUMBER | head -c4)" = "3.16" ]; then
		git clone https://github.com/ValveSoftware/wine.git -b proton_3.16
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
		WINE_VERSION_STRING="Staging"

		wget https://github.com/wine-staging/wine-staging/archive/v$WINE_VERSION_NUMBER.tar.gz

		tar xf v$WINE_VERSION_NUMBER.tar.gz

		cd wine-staging-$WINE_VERSION_NUMBER/patches
		./patchinstall.sh DESTDIR=../../wine --all || patching_error
	fi
fi

# Replace version string in winecfg and "wine --version" output
if [ ! -z "$2" ] && [ "$2" != "exit" ]; then
	sed -i "s/  (Staging)//g" "$SOURCES_DIR/wine/libs/wine/Makefile.in"
	sed -i "s/\\\1/\\\1  (${WINE_VERSION_STRING})/g" "$SOURCES_DIR/wine/libs/wine/Makefile.in"
	sed -i "s/ \" (Staging)\"//g" "$SOURCES_DIR/wine/programs/winecfg/about.c"
	sed -i "s/PACKAGE_VERSION/PACKAGE_VERSION \" (${WINE_VERSION_STRING})\"/g" "$SOURCES_DIR/wine/programs/winecfg/about.c"
fi

if [ "$2" = "exit" ] || [ "$3" = "exit" ] || [ "$4" = "exit" ] || [ "$5" = "exit" ] || [ "$6" = "exit" ]; then
	echo "Force exiting"
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

clear; echo "Compiling is done. Packing Wine."

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

clear; echo "Done."
