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
    #proxychains-ng: Preloader which hooks calls to sockets in dynamically linked programs and redirects it through one or more socks/http proxies
     export BIN="proxychains-ng"
     export SOURCE_URL="https://github.com/rofl0r/proxychains-ng"
     echo -e "\n\n [+] (Building | Fetching) $BIN :: $SOURCE_URL\n"
      #Build 
       pushd "$($TMPDIRS)" >/dev/null 2>&1
       NIXPKGS_ALLOW_BROKEN="1" NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM="1" nix-build '<nixpkgs>' --attr "pkgsStatic.proxychains-ng" --cores "$(($(nproc)+1))" --max-jobs "$(($(nproc)+1))" --log-format bar-with-logs
       BIN_DIR="$(find "." -maxdepth 1 -type d -o -type l -exec realpath {} \; | grep -Ev '^\.$')"
       find "$BIN_DIR" -type f -path '*/bin*' -name "*[0-9]*" -exec sudo bash -c 'for file; do mv "$file" "$(dirname "$file")/$(basename "$file" | tr -d "0-9")"; done' bash {} +
       sudo rsync -av --copy-links --no-relative "$(find "$BIN_DIR" -type d -path '*/bin*' -print0 | xargs --null -I {} realpath {})/." "${BINDIR}" ; unset BIN_DIR
       sudo chown -R "$(whoami):$(whoami)" "${BINDIR}" && chmod -R 755 "${BINDIR}"
       sudo objcopy --remove-section=".comment" --remove-section=".note.*" "$BINDIR/proxychains"
       sudo objcopy --remove-section=".comment" --remove-section=".note.*" "$BINDIR/proxychains-daemon"
       sudo strip --strip-debug --strip-dwo --strip-unneeded -R ".comment" -R ".gnu.version" "$BINDIR/proxychains"
       sudo strip --strip-debug --strip-dwo --strip-unneeded -R ".comment" -R ".gnu.version" "$BINDIR/proxychains-daemon"
       file "${BINDIR}/proxychain"* && du -sh "${BINDIR}/proxychain"*
       nix-collect-garbage >/dev/null 2>&1 ; popd >/dev/null 2>&1
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