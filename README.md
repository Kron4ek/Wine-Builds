## Download

Check the [**releases**](https://github.com/Kron4ek/Wine-Builds/releases) page to download some of the recent Wine builds.

All other builds (including wayland, nomultilib, stable and old versions) can be downloaded from: 
* **[MEGA](https://mega.nz/folder/ZZUV1K7J#kIenmTQoi0if-SAcMSuAHA)**
* **[Google Drive](https://drive.google.com/drive/folders/1HkgqEEdAkCSYUCRFN64GGFTLF7H_Q5Xr)** 

For some reason (unknown to me) Google marks some builds as malware, so not all builds can be downloaded from Google Drive. Don't be afraid, there is no malware in my builds, it's just Google weirdness. Use MEGA to download such builds.

Due to space limitations, i delete very old builds about once a year.

---

## How to use

Extract the desired build to any directory, and then you can run applications using the path to the Wine binary. For example:

    /home/username/wine-5.0-amd64/bin/wine application.exe
    
---
    
## Requirements

Some libraries (libfreetype6, libpng16-16, libopenal1, etc.) are required for these builds to work properly.

The easiest way to install almost all required libraries is to install Wine from your distribution's package repository.

**GLIBC** **2.27** or newer is required.

Older (4.11 and older) builds require **GLIBC 2.23** or newer.

---

## Builds description

### Compilation parameters

Build flags (amd64): `-march=x86-64 -msse3 -mfpmath=sse -O2 -ftree-vectorize`

Build flags (x86): `-march=i686 -msse2 -mfpmath=sse -O2 -ftree-vectorize`

Configure options: `--without-curses --without-oss --disable-winemenubuilder --disable-win16 --disable-tests`

---

### Architectures

* **amd64** - for 64-bit systems, it can run both 32-bit and 64-bit applications.
* **x86** - for 32-bit systems, it can run only 32-bit applications.

---

### Available builds

* **Vanilla** is unmodified Wine compiled from the official WineHQ sources.

* **Staging** is Wine with Staging patchset, it contains many useful patches that are not present in a regular (vanilla) Wine, it adds new functions, fixes some bugs and improves performance in some cases.

* **Proton** is Wine modified by Valve, it contains many useful patches (primarily for a better gaming experience). The differences from Steam's Proton are the lack of the Proton's python script and the lack of some builtin dlls (like DXVK), as well as the build environment.

* **TkG** is Wine with Staging patchset and with many additional useful patches. Full list of patches is in wine-tkg-config.txt inside the build directory. Compiled from [this sources](https://github.com/Kron4ek/wine-tkg). Main Wine-TkG repo is [here](https://github.com/Frogging-Family/wine-tkg-git).

* **Wayland** is Wine with patches from the [wine-wayland project](https://github.com/varmd/wine-wayland). These builds work only on Wayland (they don't work on Xorg at all) and support only Vulkan, OpenGL is not supported. So you can only run Vulkan games (by using DXVK as well). Before using, read all the caveats and notes on the wine-wayland project page.

---

## Compilation / Build environment

I use **create_ubuntu_chroots.sh** and **build_wine.sh** to compile my Wine builds, so you can use these scripts to compile the same Wine builds. The first script creates two Ubuntu chroots (32-bit and 64-bit) that are identical (but versions of the libraries may differ) to my chroots that i use to compile my Wine builds, and the second script compiles Wine builds using the created chroots.

These scripts are a pretty convenient way to compile your own Wine builds if you don't trust my binaries or if you want to apply different patches.

---

### Links to the sources:

* https://dl.winehq.org/wine/source
* https://github.com/wine-staging/wine-staging
* https://github.com/Frogging-Family/wine-tkg-git
* https://github.com/Kron4ek/wine-tkg
* https://github.com/Frogging-Family/community-patches
* https://github.com/zfigura/wine/tree/esync
* https://github.com/acomminos/wine-pba
* https://gitlab.com/Firer4t/wine-pba
* https://github.com/ValveSoftware/wine
* https://github.com/varmd/wine-wayland
* https://github.com/Kron4ek/wine-wayland
