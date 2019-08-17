## Download

Check **releases** page to download some of recent Wine builds.

All other builds (including nomultilib, stable and old versions) can be downloaded from: 
* **[Google Drive](https://drive.google.com/drive/folders/1HkgqEEdAkCSYUCRFN64GGFTLF7H_Q5Xr)** 
* **[Yandex Disk](https://yadi.sk/d/IrofgqFSqHsPu/wine_builds)**

---

## How to use

Just unpack desired build to any directory and then you can run applications using path to Wine binary. For example:

    /home/user/wine-4.4-amd64/bin/wine application.exe
    
---
    
## Requirements

Some libraries (libfreetype6, **libpng16-16**, libopenal1, etc.) are required for these builds to work properly.

The easiest way to install required libraries is to install Wine from package repository of your distribution.

**GLIBC** **2.27** or newer is required.

Older (4.11 and older) builds requires **GLIBC 2.23** or newer.

---

## Builds description

### Compilation parameters

Build flags (amd64): -march=nocona -O2

Build flags (x86): -march=pentium4 -O2

Configure options: --without-curses --without-gstreamer --without-oss --disable-winemenubuilder --disable-win16 --disable-tests

---

### Architectures

* **amd64** - for 64-bit systems, it can run both 32-bit and 64-bit applications.
* **amd64-nomultilib** - for 64-bit systems, it can run only 64-bit
applications and doesn't require 32-bit dependencies.
* **x86** - for 32-bit systems, it can run only 32-bit applications.

---

**Vanilla** is a regular Wine compiled from official WineHQ sources without any modifications.

**Staging** is a Wine with Staging patchset, it contains many useful patches 
that are not present in regular (vanilla) Wine, it adds new
functions, fixes some bugs and improves performance in some cases.

**Proton** is a Wine modified by Valve, it contains many useful patches (primarily for better gaming experience). This Proton is pretty much the same as Steam's Proton, but it doesn't require Steam Runtime to work and it's intended to be used outside of Steam.

**Improved** is a Wine with Staging patchset and with some additional useful patches. Full list of used patches is in the [IMPROVED_BUILD_INFO](https://github.com/Kron4ek/Wine-Builds/blob/master/IMPROVED_BUILD_INFO) file.

---

## Useful notes

**ESYNC / FSYNC** improves performance in games by removing wineserver overhead for synchronization objects.

**PBA** improves performance in many Direct3D games.

**LARGE_ADDRESS_AWARE** is useful for 32-bit games hitting address space limitations.

---

**ESYNC** can be enabled using WINEESYNC=1 environment variable, and it's also necessary to [increase](https://github.com/zfigura/wine/blob/esync/README.esync)
file descriptors limits (soft and hard). If file descriptors limit is not high enough then games will
crash often.

**FSYNC** can be enabled using WINEFSYNC=1 environment variable. At the moment FSYNC requires [custom kernel](https://steamcommunity.com/app/221410/discussions/0/3158631000006906163/).

**PBA** can be enabled using PBA_ENABLE=1 environment variable.

**LARGE_ADDRESS_AWARE** can be enabled using WINE_LARGE_ADDRESS_AWARE=1
environment variable.

---

**PBA** is present only in PBA builds.

**ESYNC** is present in Proton, Improved and Staging builds since 4.6 version, it's also present in old ESYNC builds (4.5 and older).

**FSYNC** is present in Proton (4.11 and newer) and Improved (4.14 and newer) builds.

**LARGE_ADDRESS_AWARE** is present in Proton and Improved builds.

---

### Links to sources and patches:

* https://dl.winehq.org/wine/source/
* https://github.com/wine-staging/wine-staging
* https://github.com/Tk-Glitch/PKGBUILDS/tree/master/wine-tkg-git
* https://github.com/zfigura/wine/tree/esync
* https://github.com/acomminos/wine-pba
* https://gitlab.com/Firer4t/wine-pba
* https://github.com/ValveSoftware/wine
