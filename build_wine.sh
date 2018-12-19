#!/bin/bash

export USERHOME="/home/builder"

build_in_chroot () {
	CHR="$USERHOME/$1"

	mount --bind "$CHR" "$CHR"
	mount --bind /dev "$CHR/dev"
	mount --bind /dev/shm "$CHR/dev/shm"
	mount --bind /dev/pts "$CHR/dev/pts"
	mount --bind /proc "$CHR/proc"
	mount --bind /sys "$CHR/sys"

	chroot "$CHR" /usr/bin/env LANG=en_US.UTF-8 TERM=xterm PATH="/bin:/sbin:/usr/bin:/usr/sbin" /root/build.sh
	umount -Rl "$CHR"
}

make_build_scripts () {
	export FLAGS_ONE="-march=pentium4 -O2"
	export FLAGS_TWO="-march=nocona -O2"
	export FLAGSLD="-O2"
	export CONFOPTIONS="--without-coreaudio --without-curses --without-gstreamer --without-oss --disable-winemenubuilder --disable-tests --disable-win16"
	export COMPILERC="gcc-8"
	export COMPILERCXX="g++-8"

	echo "#!/bin/sh" > "$USERHOME/xenial_chroot/root/build.sh"
	echo "cd /root" >> "$USERHOME/xenial_chroot/root/build.sh"
	echo 'export CC="'$COMPILERC'"' >> "$USERHOME/xenial_chroot/root/build.sh"
	echo 'export CXX="'$COMPILERCXX'"' >> "$USERHOME/xenial_chroot/root/build.sh"
	echo 'export CFLAGS="'$FLAGS_ONE'"' >> "$USERHOME/xenial_chroot/root/build.sh"
	echo 'export CXXFLAGS="'$FLAGS_ONE'"' >> "$USERHOME/xenial_chroot/root/build.sh"
	echo 'export LDFLAGS="'$FLAGSLD'"' >> "$USERHOME/xenial_chroot/root/build.sh"
	echo "mkdir build-tools && cd build-tools" >> "$USERHOME/xenial_chroot/root/build.sh"
	echo "../wine/configure $CONFOPTIONS --prefix /root/wine32-build" >> "$USERHOME/xenial_chroot/root/build.sh"
	echo "make -j2" >> "$USERHOME/xenial_chroot/root/build.sh"
	echo "make install" >> "$USERHOME/xenial_chroot/root/build.sh"
	echo 'export CFLAGS="'$FLAGS_TWO'"' >> "$USERHOME/xenial_chroot/root/build.sh"
	echo 'export CXXFLAGS="'$FLAGS_TWO'"' >> "$USERHOME/xenial_chroot/root/build.sh"
	echo "cd .." >> "$USERHOME/xenial_chroot/root/build.sh"
	echo "mkdir build-combo && cd build-combo" >> "$USERHOME/xenial_chroot/root/build.sh"
	echo "../wine/configure $CONFOPTIONS --with-wine64=../build64 --with-wine-tools=../build-tools --prefix /root/wine-build" >> "$USERHOME/xenial_chroot/root/build.sh"
	echo "make -j2" >> "$USERHOME/xenial_chroot/root/build.sh"
	echo "make install" >> "$USERHOME/xenial_chroot/root/build.sh"

	echo "#!/bin/sh" > "$USERHOME/xenial64_chroot/root/build.sh"
	echo "cd /root" >> "$USERHOME/xenial64_chroot/root/build.sh"
	echo 'export CC="'$COMPILERC'"' >> "$USERHOME/xenial64_chroot/root/build.sh"
	echo 'export CXX="'$COMPILERCXX'"' >> "$USERHOME/xenial64_chroot/root/build.sh"
	echo 'export CFLAGS="'$FLAGS_TWO'"' >> "$USERHOME/xenial64_chroot/root/build.sh"
	echo 'export CXXFLAGS="'$FLAGS_TWO'"' >> "$USERHOME/xenial64_chroot/root/build.sh"
	echo 'export LDFLAGS="'$FLAGSLD'"' >> "$USERHOME/xenial64_chroot/root/build.sh"
	echo "mkdir build64 && cd build64" >> "$USERHOME/xenial64_chroot/root/build.sh"
	echo "../wine/configure $CONFOPTIONS --enable-win64 --prefix /root/wine-build" >> "$USERHOME/xenial64_chroot/root/build.sh"
	echo "make -j2" >> "$USERHOME/xenial64_chroot/root/build.sh"
	echo "make install" >> "$USERHOME/xenial64_chroot/root/build.sh"

	chmod +x "$USERHOME/xenial64_chroot/root/build.sh"
	chmod +x "$USERHOME/xenial_chroot/root/build.sh"
}

if [ ! "$1" ]; then
	echo "No version specified"
	exit
fi

BUILD_DIR="$USERHOME/build_dir"

mkdir "$BUILD_DIR"
cd "$BUILD_DIR" || exit

if [ "$2" = "esync" ]; then
	WINE_VERSION="$1-esync-staging"
	ESYNC_VERSION="ce79346"

	wget https://dl.winehq.org/wine/source/4.0/wine-$1.tar.xz
	wget https://github.com/wine-staging/wine-staging/archive/v$1.tar.gz
	wget https://github.com/zfigura/wine/releases/download/esync$ESYNC_VERSION/esync.tgz
	wget https://raw.githubusercontent.com/Tk-Glitch/PKGBUILDS/master/wine-tkg-git/wine-tkg-patches/esync-no_alloc_handle.patch
	wget https://raw.githubusercontent.com/Tk-Glitch/PKGBUILDS/master/wine-tkg-git/wine-tkg-patches/esync-staging-fixes-r3.patch
	wget https://raw.githubusercontent.com/Tk-Glitch/PKGBUILDS/master/wine-tkg-git/wine-tkg-patches/esync-compat-fixes-r3.patch
	wget https://raw.githubusercontent.com/Tk-Glitch/PKGBUILDS/master/wine-tkg-git/wine-tkg-patches/use_clock_monotonic.patch
	wget https://raw.githubusercontent.com/Tk-Glitch/PKGBUILDS/master/wine-tkg-git/wine-tkg-patches/FS_bypass_compositor.patch
	wget https://raw.githubusercontent.com/Tk-Glitch/PKGBUILDS/master/wine-tkg-git/wine-tkg-patches/valve_proton_fullscreen_hack-staging.patch
	wget https://raw.githubusercontent.com/Tk-Glitch/PKGBUILDS/master/wine-tkg-git/wine-tkg-patches/poe-fix.patch
	wget https://raw.githubusercontent.com/Tk-Glitch/PKGBUILDS/master/wine-tkg-git/wine-tkg-patches/steam.patch
	wget https://raw.githubusercontent.com/Tk-Glitch/PKGBUILDS/master/wine-tkg-git/wine-tkg-patches/CSMT-toggle.patch
#	git clone https://github.com/Firerat/wine-pba.git

	tar xf wine-$1.tar.xz && mv wine-$1 wine
	tar xf v$1.tar.gz
	tar xf esync.tgz

	# Apply some patches
	cd wine
	patch -Np1 < ../'use_clock_monotonic.patch'
	patch -Np1 < ../'poe-fix.patch'
	patch -Np1 < ../'steam.patch'

	cd "$BUILD_DIR/wine-staging-$1"
	patch -Np1 < ../'CSMT-toggle.patch'
	cd "$BUILD_DIR"

	# Apply fixes for esync patches
	cd esync
	patch -Np1 < ../'esync-staging-fixes-r3.patch'
	patch -Np1 < ../'esync-compat-fixes-r3.patch'

	# Apply staging patches
	cd "$BUILD_DIR/wine-staging-$1/patches"
	./patchinstall.sh DESTDIR="$BUILD_DIR/wine" --all

	# Apply esync patches
	cd "$BUILD_DIR/wine"
	for f in "$BUILD_DIR/esync"/*.patch; do
		git apply -C1 --verbose < "${f}"
	done
	patch -Np1 < ../'esync-no_alloc_handle.patch'

	if [ "$3" != "nopba" ] && [ "$4" != "nopba" ] && [ "$5" != "nopba" ]; then
		WINE_VERSION="$WINE_VERSION-pba"

		# Create pba patches
		#mkdir -p "$BUILD_DIR/wine-pba/patches"
		#cd "$BUILD_DIR/wine-pba"
		#patch -Np1 < ../'PBA320+.patch'

		# Apply pba patches
		cd "$BUILD_DIR/wine"
		for f in $(ls "$BUILD_DIR/wine-pba/patches"); do
			patch -Np1 < "$BUILD_DIR/wine-pba/patches"/"${f}"
		done
	fi

	if [ "$3" = "fshack" ] || [ "$4" = "fshack" ] || [ "$5" = "fshack" ]; then
		WINE_VERSION="$WINE_VERSION-fshack"

		patch -Np1 < ../'FS_bypass_compositor.patch'
		patch -Np1 < ../'valve_proton_fullscreen_hack-staging.patch'
	fi
elif [ "$2" = "proton" ]; then
	WINE_VERSION="$1-proton"

	git clone https://github.com/ValveSoftware/wine.git
else
	WINE_VERSION="$1"

	wget https://dl.winehq.org/wine/source/4.0/wine-$1.tar.xz

	tar xf wine-$1.tar.xz && mv wine-$1 wine

	if [ "$2" = "staging" ]; then
		WINE_VERSION="$1-staging"

		wget https://github.com/wine-staging/wine-staging/archive/v$1.tar.gz

		tar xf v$1.tar.gz
		cd wine-staging-$1/patches
		./patchinstall.sh DESTDIR="$BUILD_DIR/wine" --all
	fi
fi

if [ "$2" = "exit" ] || [ "$3" = "exit" ] || [ "$4" = "exit" ] || [ "$5" = "exit" ] || [ "$6" = "exit" ]; then
	clear; echo "Force exiting"
	exit
fi

make_build_scripts
cd "$BUILD_DIR" && mv wine "$USERHOME/xenial64_chroot/root" && build_in_chroot xenial64_chroot
mv "$USERHOME/xenial64_chroot/root/wine-build" "$USERHOME/xenial_chroot/root"
cp -r "$USERHOME/xenial_chroot/root/wine-build" "$USERHOME/wine-$WINE_VERSION-amd64-nomultilib"
mv "$USERHOME/xenial64_chroot/root/build64" "$USERHOME/xenial_chroot/root"
mv "$USERHOME/xenial64_chroot/root/wine" "$USERHOME/xenial_chroot/root" && build_in_chroot xenial_chroot
mv "$USERHOME/xenial_chroot/root/wine-build" "$USERHOME/wine-$WINE_VERSION-amd64"
mv "$USERHOME/xenial_chroot/root/wine32-build" "$USERHOME/wine-$WINE_VERSION-x86"

rm -r "$USERHOME/xenial_chroot/root/build64"
rm -r "$USERHOME/xenial_chroot/root/build-tools"
rm -r "$USERHOME/xenial_chroot/root/build-combo"
rm -r "$USERHOME/xenial_chroot/root/wine"

cd "$USERHOME" && rm -r "$BUILD_DIR"

cd "$USERHOME/wine-$WINE_VERSION-x86" && rm -r include && rm -r share/applications && rm -r share/man
cd "$USERHOME/wine-$WINE_VERSION-amd64" && rm -r include && rm -r share/applications && rm -r share/man
cd "$USERHOME/wine-$WINE_VERSION-amd64-nomultilib" && rm -r include && rm -r share/applications && rm -r share/man && cd bin && ln -sr wine64 wine
cd "$USERHOME"

tar -cf wine-$WINE_VERSION-x86.tar wine-$WINE_VERSION-x86
xz -9 wine-$WINE_VERSION-x86.tar
rm -r wine-$WINE_VERSION-x86
tar -cf wine-$WINE_VERSION-amd64.tar wine-$WINE_VERSION-amd64
xz -9 wine-$WINE_VERSION-amd64.tar
rm -r wine-$WINE_VERSION-amd64
tar -cf wine-$WINE_VERSION-amd64-nomultilib.tar wine-$WINE_VERSION-amd64-nomultilib
xz -9 wine-$WINE_VERSION-amd64-nomultilib.tar
rm -r wine-$WINE_VERSION-amd64-nomultilib
