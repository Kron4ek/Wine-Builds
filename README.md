Compiled on Ubuntu 16.04 with GCC 8.1.

=======================================================================

Build flags (x86): -march=pentium4 -O2
Build flags (amd64): -march=nocona -O2

Configure options: --without-coreaudio --without-curses --without-gstreamer \
					--without-oss --disable-winemenubuilder \
					--disable-tests --disable-win16

All builds compiled with Vulkan support.
All builds requires GLIBC version 2.23 or newer.

=======================================================================

* amd64-nomultilib builds do not requires 32-bit dependencies and can
run only pure 64-bit applications.
* amd64 builds can run both 32-bit and 64-bit applications.
* x86 builds can run only 32-bit applications.

=======================================================================

ESYNC-Staging-PBA builds compiled with Staging, ESYNC and PBA patches.
They are also contains ESYNC compatibility fixes from Tk-Glitch
github repository.

Other patches that are used in these builds:

* Use Clock Monotonic		(for better performance)
* PoE fix					(fix for Path of Exile DX11 renderer)
* Steam fix					(fix for Steam Web Browser)
* CSMT toggle fix			(fix for CSMT toggle logic in winecfg)

Fshack builds additionally contains patch for changing a game's internal resolution 
without  changing the screen resolution. These builds requires libxinerama 
to work properly.

Remember that ESYNC is disabled by default. It's necessary to export
WINEESYNC=1 environment variable and increase file descriptors limits
in /etc/security/limits.conf to use ESYNC.

PBA can be disabled by exporting PBA_DISABLE=1 environment variable.

=======================================================================

Proton builds compiled from sources from Valve github repository.

Proton is a Wine with additional patches from Valve (mostly). It mostly
used in Steam to run Windows games on Linux. Of course it can be used
outside of Steam with no problems.

It contains: esync, fullscreen hack, performance improvements,
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
