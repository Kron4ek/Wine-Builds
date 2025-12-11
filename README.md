## Download

The builds can be downloaded either from [**the releases page**](https://github.com/Kron4ek/Wine-Builds/releases).

They are also available on [the Actions page](https://github.com/Kron4ek/Wine-Builds/actions), you need to be logged into your GitHub account to be able to download from there.

---

## How to use

Extract to any directory and run applications using the path to the Wine binary. For example:

    /home/username/wine-7.0-amd64/bin/wine application.exe

---

## Requirements

All regular Wine dependencies are required for these builds to work properly, including their 32-bit versions if you plan to run 32-bit applications.

The easiest way to install (almost) all required libraries is to install Wine from your distribution's package repository. I highly recommend to do this, otherwise you will have to manually figure out what libraries are needed, which may be not an easy task.

More precisely, not all the Wine dependencies are strictly required, some of them are optional and needed only for some Windows applications or only for some functions. Still, it's better to keep them all (or at least most of them) installed.

Also, do note that **glibc (libc6)** **2.27** or newer is required.

If you want to use Wine, but don't want to install any of its dependencies, take a look at my [**Conty project**](https://github.com/Kron4ek/Conty). Conty is a container that includes, among other things, Wine and all of its dependencies (including 32-bit ones), you can use it to run any games and programs.

---

### What to do if Wine hangs during prefix creation/updating

There is [a bug in gstreamer](https://bugs.winehq.org/show_bug.cgi?id=51086), which causes Wine to hang during prefix creation/updating, and even if you wait long enough for Wine to finish, your prefix will still be broken.

There are two ways to workaround this issue:

* You can remove the **gst-editing-services** package from your system. The package may have a different name on some Linux distros (for example, on Debian-based distros the package is called libges-1.0-0).
* You can disable **winegstreamer** before creating/updating your prefix. For example, you can do that with the `WINEDLLOVERRIDES` environment variable:

        export WINEDLLOVERRIDES="winegstreamer="
        winecfg

The second way, although works, may break video or audio playblack in some games, so it is better to use the first way if possible.

---

## Builds description

### Compilation parameters

Build flags (amd64): `-march=x86-64 -msse3 -mfpmath=sse -O2 -ftree-vectorize`

Build flags (x86): `-march=i686 -msse2 -mfpmath=sse -O2 -ftree-vectorize`

Configure options: `--without-ldap --without-oss --disable-winemenubuilder --disable-win16 --disable-tests`

---

### Architectures

* **amd64** - for 64-bit systems, it can run both 32-bit and 64-bit applications.
* **amd64-wow64** - same as amd64, but does not require 32-bit libraries to run 32-bit applications, therefore it can work on systems without multilib.
* **x86** - for 32-bit systems, it can run only 32-bit applications.

---

### Available builds

* **Vanilla** is a Wine build compiled from the official WineHQ sources.

* **Staging** is a Wine build with [the Staging patchset](https://github.com/wine-staging/wine-staging) applied. It contains many useful patches that are not present in vanilla.

* **Staging-TkG** is a Wine build with [the Staging patchset](https://github.com/wine-staging/wine-staging) applied and with many additional useful patches. A complete list of patches is in wine-tkg-config.txt inside the build directory. Compiled from [this source code](https://github.com/Kron4ek/wine-tkg), which is generated using [the wine-tkg build system](https://github.com/Frogging-Family/wine-tkg-git).

* **Proton** is a Wine build modified by Valve and other contributors. It contains many useful patches (primarily for a better gaming experience), some of them are unique and not present in other builds. The differences from the official Steam's Proton are the lack of the Proton's python script and the lack of some builtin dlls (like DXVK and vkd3d-proton), the build environment is also different. However, you can still install DXVK and vkd3d-proton manually to your prefix, like you do with regular Wine builds.

---

## Compilation / Build environment

I use `create_ubuntu_bootstraps.sh` and `build_wine.sh` to compile my Wine builds, you can use these scripts to compile your own Wine builds. The first script creates two Ubuntu bootstraps (32-bit and 64-bit) and the second script compiles Wine builds inside the created bootstraps by using `bubblewrap`.

These scripts are a pretty convenient way to compile your own Wine builds if you don't trust my binaries or if you want to apply different patches.

---

### Issue reporting

Please do not report issues that are not specific to my builds - for example, if the issue is reproducible not only with my builds, but also with other builds (like the official WineHQ builds). Also, if you merely want to ask or discuss something, do not create an issue thread, you can do this in [discussions](https://github.com/Kron4ek/Wine-Builds/discussions).

---

### Links to the sources

* https://dl.winehq.org/wine/source/
* https://github.com/wine-staging/wine-staging
* https://github.com/Frogging-Family/wine-tkg-git
* https://github.com/Kron4ek/wine-tkg
* https://github.com/ValveSoftware/wine
