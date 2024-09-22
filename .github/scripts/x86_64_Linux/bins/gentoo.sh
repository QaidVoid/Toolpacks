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
export SKIP_BUILD="NO" #YES, in case of deleted repos, broken builds etc
if [ "$SKIP_BUILD" == "NO" ]; then
   #gentoo: Portable Ephemeral Gentoo Linux Docker Image (DockerC)
     export BIN="gentoo"
     export SOURCE_URL="https://github.com/gentoo/gentoo-docker-images"
     echo -e "\n\n [+] (Building | Fetching) $BIN :: $SOURCE_URL\n"
      #Build
       #base
       sudo dockerc --image "docker://gentoo/stage3:latest" --output "$BINDIR/gentoo.no_strip"
       sudo chown -R "$(whoami):$(whoami)" "$BINDIR/gentoo.no_strip" && chmod -R 755 "$BINDIR/gentoo.no_strip"
       file "$BINDIR/gentoo.no_strip" && du -sh "$BINDIR/gentoo.no_strip"
       #musl
       sudo dockerc --image "docker://gentoo/stage3:musl" --output "$BINDIR/gentoo-musl.no_strip"
       sudo chown -R "$(whoami):$(whoami)" "$BINDIR/gentoo-musl.no_strip" && chmod -R 755 "$BINDIR/gentoo-musl.no_strip"
       file "$BINDIR/gentoo-musl.no_strip" && du -sh "$BINDIR/gentoo-musl.no_strip" 
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