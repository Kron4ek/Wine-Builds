## Download builds

Check **releases** page to download 3-5 latest Wine builds.

All other builds (including stable and old versions) can be downloaded from: 
* **[Google Drive](https://drive.google.com/drive/folders/1HkgqEEdAkCSYUCRFN64GGFTLF7H_Q5Xr)** 
* **[Yandex Disk](https://yadi.sk/d/IrofgqFSqHsPu/wine_builds)**

All builds compiled using **build_wine.sh** script.

---

## Builds description

All builds (except "old_glibc" and "gallium_nine) compiled on Ubuntu
16.04 with GCC 5.4 and require **GLIBC 2.23** or newer.

Builds from "**old_glibc**" directory require at least **GLIBC 2.13** and work
on very old Linux distros. Don't use "**old_glibc**" builds if your GLIBC
version is **2.23** or newer.

Builds from "**gallium_nine**" directory compiled on Ubuntu 18.04 with GCC
8.2 and require at least **GLIBC 2.27**.

All builds (except "old_glibc") compiled with Vulkan support.

---

Build flags (amd64): -march=nocona -O2

Build flags (x86): -march=pentium4 -O2

Build flags "old_glibc" (x86): -march=pentium3 -O2

Configure options: --without-coreaudio --without-curses --without-gstreamer \
					--without-oss --disable-winemenubuilder \
					--disable-tests --disable-win16

---

### Architectures

* **amd64** - for 64-bit systems. It can run both 32-bit and 64-bit applications.
* **amd64-nomultilib** - for 64-bit systems. It can run only pure 64-bit
applications. It doesn't require 32-bit dependencies.
* **x86** - for 32-bit systems. It can run only 32-bit applications.

---

**Vanilla** builds compiled from upstream Wine sources without additional
patches.

---

**Staging** builds compiled with Staging patchset. Staging contain many
patches that are not present in regular (vanilla) Wine. It adds new
functions to Wine, fixes many bugs and sometimes improves performance.

---

**ESYNC** builds compiled with **Staging** and **ESYNC** patches, and some versions
also compiled with **PBA** patches. They are also contain ESYNC compatibility
fixes from Tk-Glitch github repository.

**ESYNC** improves performance in games by reducing CPU load. **PBA** improves
performance in many Direct3D games (but not all).

Other patches that are used in **ESYNC** builds:

* Use Clock Monotonic		(for better performance)
* PoE fix			(fix for Path of Exile DX11 renderer)
* Steam fix			(fix for Steam Web Browser)
* CSMT toggle fix		(fix for CSMT toggle logic in winecfg)
* GLSL toggle			(add GLSL toggle into winecfg)
* LARGE_ADDRESS_AWARE		(solve hitting address space limitations in 32-bit games)
* FS_bypass_compositor		(bypass compositor in fullscreen mode)
* Fullscreen_hack		(change resoltuion for fullscreen games without changing desktop resolution)

Builds from "**gallium_nine**" directory also contain **Gallium Nine** patches
for native Direct3D 9 support. If your graphics drivers support Gallium3D
(Mesa support it for AMD gpus and for Nouveau) you should use these builds
as they are drastically improve performance in Direct3D 9 games. **Gallium
Nine** is disabled by default, it can be enabled in winecfg under "Staging"
tab.

**LibXinerama** (32-bit or 64-bit - depends on game architecture) is required
for fullscreen games to work properly.

Remember that **ESYNC** is **disabled** by default. To use ESYNC it's necessary to export
WINEESYNC=1 environment variable and increase file descriptors limits (soft and hard)
in /etc/security/limits.conf. If file descriptors limit is not high enough 
then games will crash often.

**PBA** can be disabled by exporting PBA_DISABLE=1 environment variable.

**LARGE_ADDRESS_AWARE** can be enabled by exporting WINE_LARGE_ADDRESS_AWARE=1
environment variable.

---

**Proton** builds compiled from sources from Valve github repository. It's
virtually the same as Proton in Steam, but opposed to Steam's Proton,
these builds work without Steam Runtime.

**Proton** contain many useful patches, primarily for better gaming experience.

---

Links to sources and patches:

* https://dl.winehq.org/wine/source/
* https://github.com/wine-staging/wine-staging
* https://github.com/Tk-Glitch/PKGBUILDS/tree/master/wine-tkg-git
* https://github.com/zfigura/wine/tree/esync
* https://github.com/Firerat/wine-pba
* https://github.com/ValveSoftware/wine
* https://github.com/sarnex/wine-d3d9-patches
