## Download

Check the [**releases**](https://github.com/Kron4ek/Wine-Builds/releases) page to download some of the recent Wine builds.

All other builds (including nomultilib, stable and old versions) can be downloaded from: 
* **[Google Drive](https://drive.google.com/drive/folders/1HkgqEEdAkCSYUCRFN64GGFTLF7H_Q5Xr)** 

---

## How to use

Extract the desired build to any directory, and then you can run applications using the path to the Wine binary. For example:

    /home/username/wine-4.4-amd64/bin/wine application.exe
    
---
    
## Requirements

Some libraries (libfreetype6, libpng16-16, libopenal1, etc.) are required for these builds to work properly.

The easiest way to install almost all required libraries is to install Wine from your distribution's package repository.

**GLIBC** **2.27** or newer is required.

Older (4.11 and older) builds require **GLIBC 2.23** or newer.

---

## Builds description

### Compilation parameters

Build flags (amd64): -march=nocona -O2

Build flags (x86): -march=pentium4 -O2

Configure options: --without-curses --without-gstreamer --without-oss --without-mingw --disable-winemenubuilder --disable-win16 --disable-tests

---

### Architectures

* **amd64** - for 64-bit systems, it can run both 32-bit and 64-bit applications.
* **amd64-nomultilib** - for 64-bit systems, it can run only 64-bit
applications and it doesn't require 32-bit dependencies.
* **x86** - for 32-bit systems, it can run only 32-bit applications.

---

**Vanilla** is unmodified Wine compiled from the official WineHQ sources.

**Staging** is Wine with Staging patchset, it contains many useful patches 
that are not present in a regular (vanilla) Wine, it adds new functions, fixes some bugs and improves performance in some cases.

**Proton** is Wine modified by Valve, it contains many useful patches (primarily for a better gaming experience). This repo's Proton is almost the same as the Steam's Proton, but it doesn't require the Steam Runtime to work and it's intended to be used outside of Steam.

**Improved** is Wine with Staging patchset and with some additional useful patches. The full list of used patches is in the [IMPROVED_BUILD_INFO](https://github.com/Kron4ek/Wine-Builds/blob/master/IMPROVED_BUILD_INFO) file.

---

## Useful notes

**ESYNC / FSYNC** improves performance in games by removing wineserver overhead for synchronization objects.

**PBA** improves performance in many Direct3D games.

**LARGE_ADDRESS_AWARE** is useful for 32-bit games hitting address space limitations.

---

**ESYNC** can be enabled using WINEESYNC=1 environment variable, and it's also necessary to [increase](https://github.com/zfigura/wine/blob/esync/README.esync)
file descriptors limits (soft and hard). If file descriptors limit is not high enough, then games will
crash often.

**FSYNC** can be enabled using WINEFSYNC=1 environment variable. At the moment FSYNC requires [patched kernel](https://steamcommunity.com/app/221410/discussions/0/3158631000006906163/).

**PBA** can be enabled using PBA_ENABLE=1 environment variable.

**LARGE_ADDRESS_AWARE** can be enabled using WINE_LARGE_ADDRESS_AWARE=1
environment variable.

---

**PBA** is present only in PBA builds.

**ESYNC** is present in Proton and also in Improved and Staging builds since 4.6 version.

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
