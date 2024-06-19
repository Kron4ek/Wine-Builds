#!/usr/bin/env bash

########################################################################
##
## A script for Wine compilation.
## By default it uses two Ubuntu bootstraps (x32 and x64), which it enters
## with bubblewrap (root rights are not required).
##
## This script requires: git, wget, autoconf, xz, bubblewrap
##
## You can change the environment variables below to your desired values.
##
########################################################################

# Prevent launching as root
if [ $EUID = 0 ] && [ -z "$ALLOW_ROOT" ]; then
	echo "Do not run this script as root!"
	echo
	echo "If you really need to run it as root and you know what you are doing,"
	echo "set the ALLOW_ROOT environment variable."

	exit 1
fi

# Wine version to compile.
# You can set it to "latest" to compile the latest available version.
# You can also set it to "git" to compile the latest git revision.
#
# This variable affects only vanilla and staging branches. Other branches
# use their own versions.
export WINE_VERSION="${WINE_VERSION:-latest}"

# Available branches: vanilla, staging, proton, staging-tkg, staging-tkg-ntsync
export WINE_BRANCH="${WINE_BRANCH:-staging}"

# Available proton branches: proton_3.7, proton_3.16, proton_4.2, proton_4.11
# proton_5.0, proton_5.13, experimental_5.13, proton_6.3, experimental_6.3
# proton_7.0, experimental_7.0, proton_8.0, experimental_8.0, experimental_9.0
# bleeding-edge
# Leave empty to use the default branch.
export PROTON_BRANCH="${PROTON_BRANCH:-proton_9.0}"

# Sometimes Wine and Staging versions don't match (for example, 5.15.2).
# Leave this empty to use Staging version that matches the Wine version.
export STAGING_VERSION="${STAGING_VERSION:-}"

# Specify custom arguments for the Staging's patchinstall.sh script.
# For example, if you want to disable ntdll-NtAlertThreadByThreadId
# patchset, but apply all other patches, then set this variable to
# "--all -W ntdll-NtAlertThreadByThreadId"
# Leave empty to apply all Staging patches
export STAGING_ARGS="${STAGING_ARGS:-}"

# Make 64-bit Wine builds with the new WoW64 mode (32-on-64)
export EXPERIMENTAL_WOW64="${EXPERIMENTAL_WOW64:-false}"

# Set this to a path to your Wine source code (for example, /home/username/wine-custom-src).
# This is useful if you already have the Wine source code somewhere on your
# storage and you want to compile it.
#
# You can also set this to a GitHub clone url instead of a local path.
#
# If you don't want to compile a custom Wine source code, then just leave this
# variable empty.
export CUSTOM_SRC_PATH=""

# Set to true to download and prepare the source code, but do not compile it.
# If this variable is set to true, root rights are not required.
export DO_NOT_COMPILE="false"

# Set to true to use ccache to speed up subsequent compilations.
# First compilation will be a little longer, but subsequent compilations
# will be significantly faster (especially if you use a fast storage like SSD).
#
# Note that ccache requires additional storage space.
# By default it has a 5 GB limit for its cache size.
#
# Make sure that ccache is installed before enabling this.
export USE_CCACHE="false"

export WINE_BUILD_OPTIONS="--without-ldap --without-oss --disable-winemenubuilder --disable-win16 --disable-tests"

# A temporary directory where the Wine source code will be stored.
# Do not set this variable to an existing non-empty directory!
# This directory is removed and recreated on each script run.
export BUILD_DIR="${HOME}"/build_wine

# Change these paths to where your Ubuntu bootstraps reside
export BOOTSTRAP_X64=/opt/chroots/bionic64_chroot
export BOOTSTRAP_X32=/opt/chroots/bionic32_chroot

export scriptdir="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

export CC="gcc-11"
export CXX="g++-11"

export CROSSCC_X32="i686-w64-mingw32-gcc"
export CROSSCXX_X32="i686-w64-mingw32-g++"
export CROSSCC_X64="x86_64-w64-mingw32-gcc"
export CROSSCXX_X64="x86_64-w64-mingw32-g++"

export CFLAGS_X32="-march=i686 -msse2 -mfpmath=sse -O2 -ftree-vectorize"
export CFLAGS_X64="-march=x86-64 -msse3 -mfpmath=sse -O2 -ftree-vectorize"
export LDFLAGS="-Wl,-O1,--sort-common,--as-needed"

export CROSSCFLAGS_X32="${CFLAGS_X32}"
export CROSSCFLAGS_X64="${CFLAGS_X64}"
export CROSSLDFLAGS="${LDFLAGS}"

if [ "$USE_CCACHE" = "true" ]; then
	export CC="ccache ${CC}"
	export CXX="ccache ${CXX}"

	export i386_CC="ccache ${CROSSCC_X32}"
	export x86_64_CC="ccache ${CROSSCC_X64}"

	export CROSSCC_X32="ccache ${CROSSCC_X32}"
	export CROSSCXX_X32="ccache ${CROSSCXX_X32}"
	export CROSSCC_X64="ccache ${CROSSCC_X64}"
	export CROSSCXX_X64="ccache ${CROSSCXX_X64}"

	if [ -z "${XDG_CACHE_HOME}" ]; then
		export XDG_CACHE_HOME="${HOME}"/.cache
	fi

	mkdir -p "${XDG_CACHE_HOME}"/ccache
	mkdir -p "${HOME}"/.ccache
fi

build_with_bwrap () {
	if [ "${1}" = "32" ]; then
		BOOTSTRAP_PATH="${BOOTSTRAP_X32}"
	else
		BOOTSTRAP_PATH="${BOOTSTRAP_X64}"
	fi

	if [ "${1}" = "32" ] || [ "${1}" = "64" ]; then
		shift
	fi

    bwrap --ro-bind "${BOOTSTRAP_PATH}" / --dev /dev --ro-bind /sys /sys \
		  --proc /proc --tmpfs /tmp --tmpfs /home --tmpfs /run --tmpfs /var \
		  --tmpfs /mnt --tmpfs /media --bind "${BUILD_DIR}" "${BUILD_DIR}" \
		  --bind-try "${XDG_CACHE_HOME}"/ccache "${XDG_CACHE_HOME}"/ccache \
		  --bind-try "${HOME}"/.ccache "${HOME}"/.ccache \
		  --setenv PATH "/opt/Red-Rose-MinGW-w64-Posix-Urct-v12.0.0.r0.g819a6ec2e-Gcc-11.4.1/bin:/bin:/sbin:/usr/bin:/usr/sbin" \
			"$@"
}

if ! command -v git 1>/dev/null; then
	echo "Please install git and run the script again"
	exit 1
fi

if ! command -v autoconf 1>/dev/null; then
	echo "Please install autoconf and run the script again"
	exit 1
fi

if ! command -v wget 1>/dev/null; then
	echo "Please install wget and run the script again"
	exit 1
fi

if ! command -v xz 1>/dev/null; then
	echo "Please install xz and run the script again"
	exit 1
fi

# Replace the "latest" parameter with the actual latest Wine version
if [ "${WINE_VERSION}" = "latest" ] || [ -z "${WINE_VERSION}" ]; then
	WINE_VERSION="$(wget -q -O - "https://raw.githubusercontent.com/wine-mirror/wine/master/VERSION" | tail -c +14)"
fi

# Stable and Development versions have a different source code location
# Determine if the chosen version is stable or development
if [ "$(echo "$WINE_VERSION" | cut -c3)" = "0" ]; then
	WINE_URL_VERSION=$(echo "$WINE_VERSION" | cut -c1).0
else
	WINE_URL_VERSION=$(echo "$WINE_VERSION" | cut -c1).x
fi

rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}" || exit 1

echo
echo "Downloading the source code and patches"
echo "Preparing Wine for compilation"
echo

if [ -n "${CUSTOM_SRC_PATH}" ]; then
	is_url="$(echo "${CUSTOM_SRC_PATH}" | head -c 6)"

	if [ "${is_url}" = "git://" ] || [ "${is_url}" = "https:" ]; then
		git clone "${CUSTOM_SRC_PATH}" wine
	else
		if [ ! -f "${CUSTOM_SRC_PATH}"/configure ]; then
			echo "CUSTOM_SRC_PATH is set to an incorrect or non-existent directory!"
			echo "Please make sure to use a directory with the correct Wine source code."
			exit 1
		fi

		cp -r "${CUSTOM_SRC_PATH}" wine
	fi

	WINE_VERSION="$(cat wine/VERSION | tail -c +14)"
	BUILD_NAME="${WINE_VERSION}"-custom
elif [ "$WINE_BRANCH" = "staging-tkg" ] || [ "$WINE_BRANCH" = "staging-tkg-ntsync" ]; then
	if [ "$WINE_BRANCH" = "staging-tkg" ]; then
		git clone https://github.com/Kron4ek/wine-tkg wine
	else
		git clone https://github.com/Kron4ek/wine-tkg wine -b ntsync
	fi

	WINE_VERSION="$(cat wine/VERSION | tail -c +14)"
	BUILD_NAME="${WINE_VERSION}"-"${WINE_BRANCH}"
elif [ "$WINE_BRANCH" = "proton" ]; then
	if [ -z "${PROTON_BRANCH}" ]; then
		git clone https://github.com/ValveSoftware/wine
	else
		git clone https://github.com/ValveSoftware/wine -b "${PROTON_BRANCH}"
	fi

	WINE_VERSION="$(cat wine/VERSION | tail -c +14)-$(git -C wine rev-parse --short HEAD)"
	if [[ "${PROTON_BRANCH}" == "experimental_"* ]] || [ "${PROTON_BRANCH}" = "bleeding-edge" ]; then
		BUILD_NAME=proton-exp-"${WINE_VERSION}"
	else
		BUILD_NAME=proton-"${WINE_VERSION}"
	fi
else
	if [ "${WINE_VERSION}" = "git" ]; then
		git clone https://gitlab.winehq.org/wine/wine.git wine
		BUILD_NAME="${WINE_VERSION}-$(git -C wine rev-parse --short HEAD)"
	else
		BUILD_NAME="${WINE_VERSION}"

		wget -q --show-progress "https://dl.winehq.org/wine/source/${WINE_URL_VERSION}/wine-${WINE_VERSION}.tar.xz"

		tar xf "wine-${WINE_VERSION}.tar.xz"
		mv "wine-${WINE_VERSION}" wine
	fi

	if [ "${WINE_BRANCH}" = "staging" ]; then
		if [ "${WINE_VERSION}" = "git" ]; then
			git clone https://github.com/wine-staging/wine-staging wine-staging-"${WINE_VERSION}"

			upstream_commit="$(cat wine-staging-"${WINE_VERSION}"/staging/upstream-commit | head -c 7)"
			git -C wine checkout "${upstream_commit}"
			BUILD_NAME="${WINE_VERSION}-${upstream_commit}-staging"
		else
			if [ -n "${STAGING_VERSION}" ]; then
				WINE_VERSION="${STAGING_VERSION}"
			fi

			BUILD_NAME="${WINE_VERSION}"-staging

			wget -q --show-progress "https://github.com/wine-staging/wine-staging/archive/v${WINE_VERSION}.tar.gz"
			tar xf v"${WINE_VERSION}".tar.gz

			if [ ! -f v"${WINE_VERSION}".tar.gz ]; then
				git clone https://github.com/wine-staging/wine-staging wine-staging-"${WINE_VERSION}"
			fi
		fi

		if [ -f wine-staging-"${WINE_VERSION}"/patches/patchinstall.sh ]; then
			staging_patcher=("${BUILD_DIR}"/wine-staging-"${WINE_VERSION}"/patches/patchinstall.sh
							DESTDIR="${BUILD_DIR}"/wine)
		else
			staging_patcher=("${BUILD_DIR}"/wine-staging-"${WINE_VERSION}"/staging/patchinstall.py)
		fi

		if [ "${EXPERIMENTAL_WOW64}" = "true" ]; then
  			if ! grep Disabled "${BUILD_DIR}"/wine-staging-"${WINE_VERSION}"/patches/ntdll-Syscall_Emulation/definition 1>/dev/null; then
				STAGING_ARGS="--all -W ntdll-Syscall_Emulation"
			fi
		fi

		cd wine || exit 1
		if [ -n "${STAGING_ARGS}" ]; then
			"${staging_patcher[@]}" ${STAGING_ARGS}
		else
			"${staging_patcher[@]}" --all
		fi

		if [ $? -ne 0 ]; then
			echo
			echo "Wine-Staging patches were not applied correctly!"
			exit 1
		fi

		cd "${BUILD_DIR}" || exit 1
	fi
fi

if [ ! -d wine ]; then
	clear
	echo "No Wine source code found!"
	echo "Make sure that the correct Wine version is specified."
	exit 1
fi

cd wine || exit 1
dlls/winevulkan/make_vulkan
tools/make_requests
tools/make_specfiles
autoreconf -f
cd "${BUILD_DIR}" || exit 1

if [ "${DO_NOT_COMPILE}" = "true" ]; then
	clear
	echo "DO_NOT_COMPILE is set to true"
	echo "Force exiting"
	exit
fi

if ! command -v bwrap 1>/dev/null; then
	echo "Bubblewrap is not installed on your system!"
	echo "Please install it and run the script again"
	exit 1
fi

if [ ! -d "${BOOTSTRAP_X64}" ] || [ ! -d "${BOOTSTRAP_X32}" ]; then
	clear
	echo "Bootstraps are required for compilation!"
	exit 1
fi

BWRAP64="build_with_bwrap 64"
BWRAP32="build_with_bwrap 32"

export CROSSCC="${CROSSCC_X64}"
export CROSSCXX="${CROSSCXX_X64}"
export CFLAGS="${CFLAGS_X64}"
export CXXFLAGS="${CFLAGS_X64}"
export CROSSCFLAGS="${CROSSCFLAGS_X64}"
export CROSSCXXFLAGS="${CROSSCFLAGS_X64}"

mkdir "${BUILD_DIR}"/build64
cd "${BUILD_DIR}"/build64 || exit
${BWRAP64} "${BUILD_DIR}"/wine/configure --enable-win64 ${WINE_BUILD_OPTIONS} --prefix "${BUILD_DIR}"/wine-"${BUILD_NAME}"-amd64
${BWRAP64} make -j$(nproc)
${BWRAP64} make install

export CROSSCC="${CROSSCC_X32}"
export CROSSCXX="${CROSSCXX_X32}"
export CFLAGS="${CFLAGS_X32}"
export CXXFLAGS="${CFLAGS_X32}"
export CROSSCFLAGS="${CROSSCFLAGS_X32}"
export CROSSCXXFLAGS="${CROSSCFLAGS_X32}"

mkdir "${BUILD_DIR}"/build32-tools
cd "${BUILD_DIR}"/build32-tools || exit
PKG_CONFIG_LIBDIR=/usr/lib/i386-linux-gnu/pkgconfig:/usr/local/lib/pkgconfig:/usr/local/lib/i386-linux-gnu/pkgconfig ${BWRAP32} "${BUILD_DIR}"/wine/configure ${WINE_BUILD_OPTIONS} --prefix "${BUILD_DIR}"/wine-"${BUILD_NAME}"-x86
${BWRAP32} make -j$(nproc)
${BWRAP32} make install

export CFLAGS="${CFLAGS_X64}"
export CXXFLAGS="${CFLAGS_X64}"
export CROSSCFLAGS="${CROSSCFLAGS_X64}"
export CROSSCXXFLAGS="${CROSSCFLAGS_X64}"

mkdir "${BUILD_DIR}"/build32
cd "${BUILD_DIR}"/build32 || exit
PKG_CONFIG_LIBDIR=/usr/lib/i386-linux-gnu/pkgconfig:/usr/local/lib/pkgconfig:/usr/local/lib/i386-linux-gnu/pkgconfig ${BWRAP32} "${BUILD_DIR}"/wine/configure --with-wine64="${BUILD_DIR}"/build64 --with-wine-tools="${BUILD_DIR}"/build32-tools ${WINE_BUILD_OPTIONS} --prefix "${BUILD_DIR}"/wine-${BUILD_NAME}-amd64
${BWRAP32} make -j$(nproc)
${BWRAP32} make install

echo
echo "Compilation complete"
echo "Creating and compressing archives..."

cd "${BUILD_DIR}" || exit

if touch "${scriptdir}"/write_test; then
	rm -f "${scriptdir}"/write_test
	result_dir="${scriptdir}"
else
	result_dir="${HOME}"
fi

export XZ_OPT="-9"

if [ "${EXPERIMENTAL_WOW64}" = "true" ]; then
	mv wine-${BUILD_NAME}-amd64 wine-${BUILD_NAME}-exp-wow64-amd64

	builds_list="wine-${BUILD_NAME}-exp-wow64-amd64"
else
	builds_list="wine-${BUILD_NAME}-x86 wine-${BUILD_NAME}-amd64"
fi

for build in ${builds_list}; do
	if [ -d "${build}" ]; then
		rm -rf "${build}"/include "${build}"/share/applications "${build}"/share/man

		if [ -f wine/wine-tkg-config.txt ]; then
			cp wine/wine-tkg-config.txt "${build}"
		fi

		if [ "${EXPERIMENTAL_WOW64}" = "true" ]; then
			rm "${build}"/bin/wine "${build}"/bin/wine-preloader
			cp "${build}"/bin/wine64 "${build}"/bin/wine
		fi

		tar -Jcf "${build}".tar.xz "${build}"
		mv "${build}".tar.xz "${result_dir}"
	fi
done

rm -rf "${BUILD_DIR}"

echo
echo "Done"
echo "The builds should be in ${result_dir}"
