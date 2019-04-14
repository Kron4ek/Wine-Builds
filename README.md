## Download

Check **releases** page to download some of recent Wine builds.

All other builds (including stable and old versions) can be downloaded from: 
* **[Google Drive](https://drive.google.com/drive/folders/1HkgqEEdAkCSYUCRFN64GGFTLF7H_Q5Xr)** 
* **[Yandex Disk](https://yadi.sk/d/IrofgqFSqHsPu/wine_builds)**

---

## How to use

Just unpack archive to any desired directory and run applications using path to Wine binary. For example:

    /home/user/wine-4.4-amd64/bin/wine application.exe
    
---

## Builds description

### Requirements

Some libraries (libfreetype6, **libpng12-0**, libopenal1, etc.) are required for these builds to work properly.

The easiest way to install required libraries is to install Wine from package repository of your distribution.

**GLIBC** version newer than **2.22** is required.

---

### Compilation parameters

Build flags (amd64): -march=nocona -O2

Build flags (x86): -march=pentium3 -O2

Configure options: --without-curses --without-gstreamer --without-oss --disable-winemenubuilder

---

### Architectures

* **amd64** - for 64-bit systems. It can run both 32-bit and 64-bit applications.
* **amd64-nomultilib** - for 64-bit systems. It can run only pure 64-bit
applications. It doesn't require 32-bit dependencies.
* **x86** - for 32-bit systems. It can run only 32-bit applications.

---

### Vanilla

**Vanilla** builds compiled from official WineHQ sources without additional
patches. It's a clean unmodified Wine.

---

### Staging

**Staging** builds compiled with Staging patchset. Staging contains many
patches that are not present in regular (vanilla) Wine, it adds new
functions to Wine, fixes many bugs and sometimes improves performance.

---

### ESYNC / PBA / Improved

Since **4.6** version **ESYNC** has been included in **Staging**.

**ESYNC** builds compiled with **Staging** and **ESYNC** patches, and some versions
also compiled with **PBA** patches.

**ESYNC** improves performance in games by reducing CPU load. **PBA** improves
performance in many Direct3D games.

**Improved** builds compiled with **Staging** and some additional patches listed below.

Patches that are present in **ESYNC** and **Improved** builds:

* Use Clock Monotonic		(use CLOCK_MONOTONIC; for better performance)
* CSMT toggle fix		(fix for CSMT toggle logic in winecfg)
* GLSL toggle			(add GLSL toggle into winecfg)
* LARGE_ADDRESS_AWARE		(solve hitting address space limitations in 32-bit games)
* FS_bypass_compositor		(bypass compositor in fullscreen mode; for better performance)
* Fullscreen_hack		(change resoltuion for fullscreen games without changing desktop resolution)

**LibXinerama** (32-bit or 64-bit - depends on game architecture) is required
for fullscreen games to work properly.

**ESYNC** can be enabled using WINEESYNC=1 environment variable, and it's also necessary to [increase](https://github.com/zfigura/wine/blob/esync/README.esync)
file descriptors limit (soft and hard). If file descriptors limit is not high enough then games will
crash often.

**PBA** can be enabled using PBA_ENABLE=1 environment variable.

**LARGE_ADDRESS_AWARE** can be enabled using WINE_LARGE_ADDRESS_AWARE=1
environment variable.

---

### Proton

**Proton** builds compiled from sources from Valve github repository. This Proton 
is virtually the same as Proton in Steam, but opposed to Steam's Proton these 
builds doesn't requires Steam Runtime.

**Proton** contains many useful patches, primarily for better gaming experience.

---

### FAudio

Wine (only Vanilla, Staging doesn't use FAudio yet) versions newer than **4.2** uses **FAudio** (XAudio reimplementation), so it's necessary to install **libFAudio.so** to use these versions. If **libFAudio.so** is not installed then many games will not work or there will be no sound.

**Proton** builds (**3.16-5** and newer) uses **FAudio** as well.

If there is no **FAudio** in package repository of your distribution then you can [manually compile](https://github.com/FNA-XNA/FAudio) it.

---

### Links to sources and patches:

* https://dl.winehq.org/wine/source/
* https://github.com/wine-staging/wine-staging
* https://github.com/Tk-Glitch/PKGBUILDS/tree/master/wine-tkg-git
* https://github.com/zfigura/wine/tree/esync
* https://github.com/Firerat/wine-pba
* https://github.com/ValveSoftware/wine
