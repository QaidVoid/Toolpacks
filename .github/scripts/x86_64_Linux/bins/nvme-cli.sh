#!/usr/bin/env bash

#-------------------------------------------------------#
#Sanity Checks
if [ "$BUILD" != "YES" ] || \
   [ -z "$BINDIR" ] || \
   [ -z "$EGET_EXCLUDE" ] || \
   [ -z "$EGET_TIMEOUT" ] || \
   [ -z "$GIT_TERMINAL_PROMPT" ] || \
   [ -z "$GIT_ASKPASS" ] || \
   [ -z "$GITHUB_TOKEN" ] || \
   [ -z "$SYSTMP" ] || \
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
    #nvme-cli : NVMe management command line interface.
     export BIN="nvme-cli"
     export SOURCE_URL="https://github.com/linux-nvme/nvme-cli"
     echo -e "\n\n [+] (Building | Fetching) $BIN :: $SOURCE_URL\n"
      ##Build (debian-glibc)
       pushd "$($TMPDIRS)" >/dev/null 2>&1
       docker stop "debian-builder-unstable" 2>/dev/null ; docker rm "debian-builder-unstable" 2>/dev/null
       docker run --privileged --net="host" --name "debian-builder-unstable" --pull="always" "azathothas/debian-builder-unstable:latest" \
        bash -l -c '
        #Setup ENV
         mkdir -p "/build-bins" && pushd "$(mktemp -d)" >/dev/null 2>&1
         sudo apt update -y -qq
        #Build
         git clone --filter "blob:none" --quiet "https://github.com/linux-nvme/nvme-cli" && cd "./nvme-cli"
         #https://github.com/linux-nvme/nvme-cli/blob/master/Makefile
         meson setup --buildtype="release" \
            --default-library="static" \
            -Db_lto="true" \
            -Db_pie="true" \
            -Db_staticpic="true" \
            -Dc_link_args="-static -s -Wl,-S -Wl,--build-id=none" \
            -Ddocs-build="false" \
            -Dnvme-tests="false" \
            -Dlibnvme:tests="false" \
            -Dlibnvme:keyutils="disabled" \
            --wrap-mode="forcefallback" \
            --prefer-static --strip --reconfigure --wipe --clearcache "./STATIC_BUILD" "./"
         ninja -C "./STATIC_BUILD" -j "$(($(nproc)+1))" install
        #Copy
         #cp "./nvme-cli" "/build-bins/nvme-cli"
         find "./STATIC_BUILD" -maxdepth 1 -type f -exec file -i "{}" \; | grep "application/.*executable" | cut -d":" -f1 | xargs realpath | xargs -I {} cp --force {} /build-bins/
        #strip & info 
         find "/build-bins/" -type f -exec objcopy --remove-section=".comment" --remove-section=".note.*" "{}" \;
         find "/build-bins/" -type f ! -name "*.no_strip" -exec strip --strip-debug --strip-dwo --strip-unneeded --preserve-dates "{}" \; 2>/dev/null
         cp "/build-bins/nvme" "/build-bins/nvme-cli"
         file "/build-bins/"* && du -sh "/build-bins/"*
         popd >/dev/null 2>&1
        '
      #Copy & Meta
       docker cp "debian-builder-unstable:/build-bins/." "$(pwd)/"
       find "." -maxdepth 1 -type f -exec file -i "{}" \; | grep "application/.*executable" | cut -d":" -f1 | xargs realpath
       #Meta
       find "." -maxdepth 1 -type f -exec sh -c 'file "{}"; du -sh "{}"' \;
       sudo rsync -av --copy-links --exclude="*/" "./." "$BINDIR"       
      #Delete Containers
       docker stop "debian-builder-unstable" 2>/dev/null ; docker rm "debian-builder-unstable"
       popd >/dev/null 2>&1
fi
#-------------------------------------------------------#

#-------------------------------------------------------#
##Cleanup
unset SKIP_BUILD ; export BUILT="YES"
#In case of zig polluted env
unset AR CC CFLAGS CXX CPPFLAGS CXXFLAGS DLLTOOL HOST_CC HOST_CXX LDFLAGS LIBS OBJCOPY RANLIB
#In case of go polluted env
unset GOARCH GOOS CGO_ENABLED CGO_CFLAGS
#PKG Config
unset PKG_CONFIG_PATH PKG_CONFIG_LIBDIR PKG_CONFIG_SYSROOT_DIR PKG_CONFIG_SYSTEM_INCLUDE_PATH PKG_CONFIG_SYSTEM_LIBRARY_PATH
#-------------------------------------------------------#