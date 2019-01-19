## Download builds

Check **releases** page for download 3-5 latest Wine builds.

All other builds (including stable and old versions) can be downloaded from: 
* **[Google Drive](https://drive.google.com/drive/folders/1HkgqEEdAkCSYUCRFN64GGFTLF7H_Q5Xr)** 
* **[Yandex Disk](https://yadi.sk/d/IrofgqFSqHsPu/wine_builds)**

All builds compiled with **build_wine.sh** script, which lies in this repo.

=======================================================================

## Builds description

Compiled on Ubuntu 16.04 with GCC 8.1. Compiled with Vulkan support.

Builds require at least **GLIBC 2.23**.

=======================================================================

Build flags (x86): -march=pentium4 -O2

Build flags (amd64): -march=nocona -O2

Configure options: --without-coreaudio --without-curses --without-gstreamer \
					--without-oss --disable-winemenubuilder \
					--disable-tests --disable-win16

=======================================================================

* **amd64-nomultilib** builds do not require 32-bit dependencies and can
run only pure 64-bit applications.
* **amd64** builds can run both 32-bit and 64-bit applications.
* **x86** builds can run only 32-bit applications.

=======================================================================

**ESYNC** builds compiled with Staging, ESYNC and PBA patches.
They are also contain ESYNC compatibility fixes from Tk-Glitch
GitHub repository.

Other **patches** that are used in these builds:

* Use Clock Monotonic		(for better performance)
* PoE fix			(fix for Path of Exile DX11 renderer)
* Steam fix			(fix for Steam Web Browser)
* CSMT toggle fix		(fix for CSMT toggle logic in winecfg)
* GLSL toggle			(add GLSL toggle into winecfg)
* LARGE_ADDRESS_AWARE		(solve hitting address space limitations in 32-bit games)
* FS_bypass_compositor		(bypass compositor in fullscreen mode)
* Fullscreen_hack		(change resoltuion for fullscreen games without changing desktop resolution)

LibXinerama (32-bit or 64-bit - depends on game architecture) is required
for fullscreen games to work properly.

Remember that ESYNC is disabled by default. To use ESYNC it's necessary to export
WINEESYNC=1 environment variable and increase file descriptors limits (soft and hard)
in /etc/security/limits.conf. If file descriptors limit is not high enough 
then games will crash often.

PBA can be disabled by exporting PBA_DISABLE=1 environment variable.

LARGE_ADDRESS_AWARE can be enabled by exporting WINE_LARGE_ADDRESS_AWARE=1
environment variable.

=======================================================================

**Proton** builds compiled from sources from Valve github repository.

Proton is a Wine with additional patches from Valve (mostly). It mostly
used in Steam to run Windows games on Linux. Of course it can be used
outside of Steam with no problems.

It contain: esync, fullscreen hack, performance improvements,
better support for controllers, faking an AMD card in place of Nvidia
cards, and more.

=======================================================================

Links to sources and patches:

* https://dl.winehq.org/wine/source/
* https://github.com/wine-staging/wine-staging
* https://github.com/Tk-Glitch/PKGBUILDS/tree/master/wine-tkg-git
* https://github.com/zfigura/wine/tree/esync
* https://github.com/Firerat/wine-pba
* https://github.com/ValveSoftware/wine
