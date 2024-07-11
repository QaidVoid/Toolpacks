#!/usr/bin/env bash

#-------------------------------------------------------#
#Sanity Checks
if [ "$BUILD" != "YES" ] || \
   [ -z "$ANDROID_NDK_TOOLCHAIN_ROOT" ] || \
   [ -z "$ANDROID_NDK_TOOLCHAIN_BIN" ] || \
   [ -z "$ANDROID_NDK_SYSROOT" ] || \
   [ -z "$BINDIR" ] || \
   [ -z "$EGET_EXCLUDE" ] || \
   [ -z "$EGET_TIMEOUT" ] || \
   [ -z "$GIT_TERMINAL_PROMPT" ] || \
   [ -z "$GIT_ASKPASS" ] || \
   [ -z "$GITHUB_TOKEN" ] || \
   [ -z "$SYSTMP" ] || \
   [ -z "$TOOLPACKS_ANDROID_ABI" ] || \
   [ -z "$TOOLPACKS_ANDROID_APILEVEL_DYNAMIC" ] || \
   [ -z "$TOOLPACKS_ANDROID_APILEVEL_STATIC" ] || \
   [ -z "$TOOLPACKS_ANDROID_BUILD_DYNAMIC" ] || \
   [ -z "$TOOLPACKS_ANDROID_BUILD_STATIC" ] || \
   [ -z "$TMPDIRS" ]; then
 #exit
  echo -e "\n[+]Skipping Builds...\n"
  exit 1
fi
#-------------------------------------------------------#

#-------------------------------------------------------#
##Main
SKIP_BUILD="NO" #YES, in case of deleted repos, broken builds etc
if [ "$SKIP_BUILD" == "NO" ]; then
    #b3sum: A command line utility for calculating BLAKE3 hashes
     export BIN="b3sum" #Name of final binary/pkg/cli, sometimes differs from $REPO
     export SOURCE_URL="https://github.com/BLAKE3-team/BLAKE3" #github/gitlab/homepage/etc for $BIN
     echo -e "\n\n [+] (Building | Fetching) $BIN :: $SOURCE_URL\n"
      #Build (ndk-pkg)
       pushd "$($TMPDIRS)" >/dev/null 2>&1
       docker exec -it "ndk-pkg" ndk-pkg install "${TOOLPACKS_ANDROID_BUILD_STATIC}/b3sum" --profile="release" -j "$(($(nproc)+1))" --fsle
       TOOLPACKS_ANDROID_BUILDIR="$(docker exec -it "ndk-pkg" ndk-pkg tree "${TOOLPACKS_ANDROID_BUILD_STATIC}/b3sum" --dirsfirst -L 1 | grep -o '/.*/.*' | tail -n1 | tr -d '[:space:]')" && export TOOLPACKS_ANDROID_BUILDIR="${TOOLPACKS_ANDROID_BUILDIR}"
       docker exec -it "ndk-pkg" ls "${TOOLPACKS_ANDROID_BUILDIR}/bin"
      #Copy
       docker cp "ndk-pkg:/${TOOLPACKS_ANDROID_BUILDIR}/bin/." "./"
       #Meta 
       file "./b3sum" && du -sh "./b3sum" ; aarch64-linux-gnu-readelf -d "./b3sum" | grep -i 'needed'
       cp "./b3sum" "$BINDIR/b3sum" ; cp "./b3sum" "$BASEUTILSDIR/b3sum"
      #Test
       timeout -k 10s 20s docker run --privileged -it --rm --platform="linux/arm64" --network="bridge" -v "$BINDIR:/mnt" "termux/termux-docker:aarch64" "/mnt/b3sum" --version
      #Cleanup Container
       docker exec -it "ndk-pkg" ndk-pkg uninstall "${TOOLPACKS_ANDROID_BUILD_STATIC}/b3sum"
       docker exec -it "ndk-pkg" ndk-pkg cleanup
       popd >/dev/null 2>&1
fi
#-------------------------------------------------------#

#-------------------------------------------------------#
##Cleanup
unset SKIP_BUILD ; export BUILT="YES"
#In case of Android Polluted env
unset TOOLPACKS_ANDROID_BUILDIR
#In case of build polluted env
unset ANDROID_API_LEVEL ANDROID_LIBRARY_DIR ANDROID_TARGET AR AS CC CFLAGS CPP CXX CPPFLAGS CXXFLAGS CROSS_COMPILE DLLTOOL HOST_CC HOST_CXX LD LDFLAGS LIBS NM OBJCOPY OBJDUMP RANLIB READELF SIZE STRINGS STRIP SYSROOT TARGET
#In case of go polluted env
unset GOARCH GOOS CGO_ENABLED CGO_CFLAGS
#PKG Config
unset PKG_CONFIG_PATH PKG_CONFIG_LIBDIR PKG_CONFIG_SYSROOT_DIR PKG_CONFIG_SYSTEM_INCLUDE_PATH PKG_CONFIG_SYSTEM_LIBRARY_PATH
#-------------------------------------------------------#