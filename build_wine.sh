#!/usr/bin/env bash

## Script for Wine compilation.
## It uses two Ubuntu chroots (x32 and x64).
##
## You can change some environment variables (for example, CFLAGS) to
## the desired values.
##
## This script requires: git, wget, autoconf
##
## Examples of usage:
##
## ./build_wine.sh 5.5               (build Wine 5.5)
## ./build_wine.sh latest            (build latest Wine version)
## ./build_wine.sh latest staging    (build latest Wine-Staging version)
## ./build_wine.sh 5.0-8 proton      (build Proton 5.0-8)

export MAINDIR="/home/builder"
export SOURCES_DIR="$MAINDIR/sources_dir"
export CHROOT_X64="$MAINDIR/chroots/bionic64_chroot"
export CHROOT_X32="$MAINDIR/chroots/bionic32_chroot"

export C_COMPILER="gcc-8"
export CXX_COMPILER="g++-8"

export CFLAGS_X32="-march=i686 -msse2 -mfpmath=sse -O2"
export CFLAGS_X64="-march=x86-64 -msse3 -mfpmath=sse -O2"
export LDFLAGS_X32="-Wl,-O1,--sort-common,--as-needed"
export LDFLAGS_X64="${LDFLAGS_X32}"

export CROSSCFLAGS_X32="${CFLAGS_X32}"
export CROSSCFLAGS_X64="${CFLAGS_X64}"
export CROSSLDFLAGS_X32="${LDFLAGS_X32}"
export CROSSLDFLAGS_X64="${LDFLAGS_X64}"

export WINE_BUILD_OPTIONS="--without-curses --without-oss --without-mingw --disable-winemenubuilder --disable-win16 --disable-tests"

export WINE_VERSION_NUMBER="$1"

build_in_chroot () {
	if [ "$1" = "32" ]; then
		CHROOT_PATH="$CHROOT_X32"
	else
		CHROOT_PATH="$CHROOT_X64"
	fi

	echo "Unmounting chroot directories"
	umount -Rl "$CHROOT_PATH"

	echo "Mounting directories for chroots"
	mount --bind "$CHROOT_PATH" "$CHROOT_PATH"
	mount --bind /dev "$CHROOT_PATH/dev"
	mount --bind /dev/shm "$CHROOT_PATH/dev/shm"
	mount --bind /dev/pts "$CHROOT_PATH/dev/pts"
	mount --bind /proc "$CHROOT_PATH/proc"
	mount --bind /sys "$CHROOT_PATH/sys"

	echo "Chrooting into $CHROOT_PATH"
	chroot "$CHROOT_PATH" /usr/bin/env LANG=en_US.UTF-8 TERM=xterm PATH="/bin:/sbin:/usr/bin:/usr/sbin" /opt/build.sh

	echo "Unmounting chroot directories"
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
	echo 'make -j$(nproc)' >> $MAINDIR/build32.sh
	echo 'make install' >> $MAINDIR/build32.sh
	echo 'export CFLAGS="'${CFLAGS_X64}'"' >> $MAINDIR/build32.sh
	echo 'export CXXFLAGS="'${CFLAGS_X64}'"' >> $MAINDIR/build32.sh
	echo 'export LDFLAGS="'${LDFLAGS_X64}'"' >> $MAINDIR/build32.sh
	echo 'export CROSSCFLAGS="'${CROSSCFLAGS_X64}'"' >> $MAINDIR/build32.sh
	echo 'export CROSSLDFLAGS="'${CROSSLDFLAGS_X64}'"' >> $MAINDIR/build32.sh
	echo 'cd ..' >> $MAINDIR/build32.sh
	echo 'mkdir build-combo && cd build-combo' >> $MAINDIR/build32.sh
	echo '../wine/configure '${WINE_BUILD_OPTIONS}' --with-wine64=../build64 --with-wine-tools=../build-tools --prefix /opt/wine-build' >> $MAINDIR/build32.sh
	echo 'make -j$(nproc)' >> $MAINDIR/build32.sh
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
	echo 'make -j$(nproc)' >> $MAINDIR/build64.sh
	echo 'make install' >> $MAINDIR/build64.sh

	chmod +x "$MAINDIR/build64.sh"
	chmod +x "$MAINDIR/build32.sh"

	mv "$MAINDIR/build64.sh" "$CHROOT_X64/opt/build.sh"
	mv "$MAINDIR/build32.sh" "$CHROOT_X32/opt/build.sh"
}

patching_error () {
	echo "Some patches were not applied correctly"
	exit 1
}

if [ -z "$WINE_VERSION_NUMBER" ]; then
	echo "No version specified"
	exit
fi

if [ "$MAINDIR" = "$SOURCES_DIR" ]; then
	echo "Do not use the same directory for MAINDIR and SOURCES_DIR"
	exit
fi

rm -rf "$SOURCES_DIR"
mkdir "$SOURCES_DIR"
cd "$SOURCES_DIR" || exit 1

# Replace latest parameter with the actual latest Wine version
if [ "$WINE_VERSION_NUMBER" = "latest" ]; then
	if [ "$2" != "proton" ]; then
		wget https://raw.githubusercontent.com/wine-mirror/wine/master/VERSION

		WINE_VERSION_NUMBER="$(cat VERSION | sed "s/Wine version //g")"
	else
		echo "Please specify version number to build Proton"
		exit
	fi
fi

# Stable and Development versions have different sources location
# Determine if the chosen version is stable or development
if [ "$(echo "$WINE_VERSION_NUMBER" | cut -c3)" = "0" ]; then
	WINE_SOURCES_VERSION=$(echo "$WINE_VERSION_NUMBER" | cut -c1).0
else
	WINE_SOURCES_VERSION=$(echo "$WINE_VERSION_NUMBER" | cut -c1).x
fi

clear
echo "Downloading sources and patches"
echo "Preparing Wine for compilation"
echo

if [ "$2" = "tkg" ]; then
	git clone https://github.com/Tk-Glitch/wine-tkg.git
	mv wine-tkg wine

	WINE_VERSION_NUMBER="$(cat wine/VERSION | sed "s/Wine version //g")"
	WINE_VERSION="$WINE_VERSION_NUMBER-staging-tkg"
	WINE_VERSION_STRING="Staging TkG"
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
	elif [ "$(echo $WINE_VERSION_NUMBER | head -c3)" = "5.0" ]; then
		git clone https://github.com/ValveSoftware/wine.git -b proton_5.0
	else
		git clone https://github.com/ValveSoftware/wine.git
	fi
else
	WINE_VERSION="$WINE_VERSION_NUMBER"

	wget https://dl.winehq.org/wine/source/$WINE_SOURCES_VERSION/wine-$WINE_VERSION_NUMBER.tar.xz

	tar xf wine-$WINE_VERSION_NUMBER.tar.xz

	mv wine-$WINE_VERSION_NUMBER wine

	if [ -n "$2" ] ; then
		wget https://github.com/wine-staging/wine-staging/archive/v$WINE_VERSION_NUMBER.tar.gz

		if [ ! -f v$WINE_VERSION_NUMBER.tar.gz ]; then
			git clone https://github.com/wine-staging/wine-staging.git
			mv wine-staging wine-staging-$WINE_VERSION_NUMBER
		else
			tar xf v$WINE_VERSION_NUMBER.tar.gz
		fi

		cd wine-staging-$WINE_VERSION_NUMBER/patches

		if [ "$2" = "staging" ]; then
			WINE_VERSION="$WINE_VERSION_NUMBER-staging"
			./patchinstall.sh DESTDIR=../../wine --all || patching_error
		elif [ "$2" = "esync" ]; then
			WINE_VERSION="$WINE_VERSION_NUMBER-esync"
			WINE_VERSION_STRING="Esync"
			./patchinstall.sh DESTDIR=../../wine eventfd_synchronization || patching_error
		fi
	fi
fi

# Replace version string in the winecfg and in the "wine --version" output
if [ ! -z "$2" ] && [ "$2" != "staging" ] && [ "$2" != "exit" ]; then
	sed -i "s/  (Staging)//g" "$SOURCES_DIR/wine/libs/wine/Makefile.in"
	sed -i "s/\\\1/\\\1  (${WINE_VERSION_STRING})/g" "$SOURCES_DIR/wine/libs/wine/Makefile.in"
	sed -i "s/ \" (Staging)\"//g" "$SOURCES_DIR/wine/programs/winecfg/about.c"
	sed -i "s/PACKAGE_VERSION/PACKAGE_VERSION \" (${WINE_VERSION_STRING})\"/g" "$SOURCES_DIR/wine/programs/winecfg/about.c"
fi

if [ "$2" = "exit" ] || [ "$3" = "exit" ] || [ "$4" = "exit" ]; then
	clear; echo "Force exit"
	exit
fi

if [ "$EUID" != 0 ]; then
	echo "Root rights are required for compilation!"
	exit 1
fi

if [ ! -d "${CHROOT_X64}" ] || [ ! -d "${CHROOT_X32}" ]; then
	echo "Chroots are required for compilation!"
	exit 1
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

mv "$CHROOT_X32/opt/wine-build" "$MAINDIR/wine-$WINE_VERSION-amd64"
mv "$CHROOT_X32/opt/wine32-build" "$MAINDIR/wine-$WINE_VERSION-x86"

rm -r "$CHROOT_X64/opt"
mkdir "$CHROOT_X64/opt"
rm -r "$CHROOT_X32/opt"
mkdir "$CHROOT_X32/opt"

cd "$MAINDIR/wine-$WINE_VERSION-x86" && rm -r include && rm -r share/applications && rm -r share/man
cd "$MAINDIR/wine-$WINE_VERSION-amd64" && rm -r include && rm -r share/applications && rm -r share/man
cd "$MAINDIR/wine-$WINE_VERSION-amd64-nomultilib" && rm -r include && rm -r share/applications && rm -r share/man && cd bin && ln -sr wine64 wine

# Strip all binaries and libraries
find "$MAINDIR/wine-$WINE_VERSION-x86" -type f -exec strip --strip-unneeded {} \;
find "$MAINDIR/wine-$WINE_VERSION-amd64" -type f -exec strip --strip-unneeded {} \;
find "$MAINDIR/wine-$WINE_VERSION-amd64-nomultilib" -type f -exec strip --strip-unneeded {} \;

if [ "$2" = "tkg" ]; then
	cp "$SOURCES_DIR"/wine/wine-tkg-config.txt "$MAINDIR/wine-$WINE_VERSION-x86"
	cp "$SOURCES_DIR"/wine/wine-tkg-config.txt "$MAINDIR/wine-$WINE_VERSION-amd64"
	cp "$SOURCES_DIR"/wine/wine-tkg-config.txt "$MAINDIR/wine-$WINE_VERSION-amd64-nomultilib"
fi

cd "$MAINDIR"

clear
echo "Compilation complete"
echo "Creating archives..."

tar -cf wine-$WINE_VERSION-amd64.tar wine-$WINE_VERSION-amd64
tar -cf wine-$WINE_VERSION-amd64-nomultilib.tar wine-$WINE_VERSION-amd64-nomultilib
tar -cf wine-$WINE_VERSION-x86.tar wine-$WINE_VERSION-x86
xz -T0 -9 wine-$WINE_VERSION-amd64.tar
xz -T0 -9 wine-$WINE_VERSION-amd64-nomultilib.tar
xz -T0 -9 wine-$WINE_VERSION-x86.tar

rm -r wine-$WINE_VERSION-amd64
rm -r wine-$WINE_VERSION-amd64-nomultilib
rm -r wine-$WINE_VERSION-x86

clear; echo "Done"
