#-------------------------------------------------------#
#Sanity Checks
if (
    ($env:BUILD -ne "YES") -or
    ([string]::IsNullOrEmpty($env:BINDIR)) -or
    ([string]::IsNullOrEmpty($env:EGET_EXCLUDE)) -or
    ([string]::IsNullOrEmpty($env:EGET_TIMEOUT)) -or
    ([string]::IsNullOrEmpty($env:GIT_TERMINAL_PROMPT)) -or
    ([string]::IsNullOrEmpty($env:GIT_ASKPASS)) -or
    ([string]::IsNullOrEmpty($env:GITHUB_TOKEN)) -or
    ([string]::IsNullOrEmpty($env:SYSTMP)) -or
    ([string]::IsNullOrEmpty($env:TMPDIRS))
) {
    #exit
    Write-Output "`n[+]Skipping Builds...`n"
    exit 1
}
#-------------------------------------------------------#

#-------------------------------------------------------#
##Main
$env:SKIP_BUILD = "NO" # YES, in case of deleted repos, broken builds etc
if ($env:SKIP_BUILD -eq "NO") {
   #geonet: Network tools that run from multiple geographic locations using the GeoNet API. 
    $env:BIN = "geonet-rs" # Name of final binary/pkg/cli, sometimes differs from $REPO
    $env:SOURCE_URL = "https://gitlab.com/shodan-public/geonet-rs" # github/gitlab/homepage/etc for $BIN
    Write-Output "`n`n [+] (Building | Fetching) $env:BIN :: $env:SOURCE_URL`n"
    #Build
      Push-Location (& $TMPDIRS) ; git clone --quiet --filter "blob:none" "https://gitlab.com/shodan-public/geonet-rs" ; Set-Location "./geonet-rs" ; (Resolve-Path ".\").Path
      $env:RUST_TARGET = "x86_64-pc-windows-msvc" ; rustup target add "$env:RUST_TARGET"
      $env:RUSTFLAGS = "-C target-feature=+crt-static -C default-linker-libraries=yes -C prefer-dynamic=no -C embed-bitcode=yes -C lto=yes -C opt-level=3 -C debuginfo=none -C strip=symbols -C link-arg=-Wl,-S -C link-arg=-Wl,--build-id=none"
      (Get-Content -Path "./Cargo.toml" -Raw) -replace "(?s)\[profile\.release\].*?(?=\n\[|$)", "" | Set-Content -Path "./Cargo.toml" ; Add-Content "./Cargo.toml" "[profile.release]`nstrip = true`nopt-level = 3`nlto = true"
      cargo build --target "$env:RUST_TARGET" --release --jobs "$(Invoke-Expression "[int]$env:NUMBER_OF_PROCESSORS + 1")" --keep-going
      #geodns: lookup DNS records for a hostname
      Copy-Item "./target/$env:RUST_TARGET/release/geodns.exe" "$env:BINDIR/geodns.exe"
      file.exe "./target/$env:RUST_TARGET/release/geodns.exe" ; (Get-Item -Path "./target/$env:RUST_TARGET/release/geodns.exe").Length | ForEach-Object { "{0:N2} MB" -f ($_ / 1MB) }
      wldd.exe "./target/$env:RUST_TARGET/release/geodns.exe" | Sort-Object -Unique
      #geoping: ping an IP/ hostname from multiple locations
      Copy-Item "./target/$env:RUST_TARGET/release/geoping.exe" "$env:BINDIR/geoping.exe"
      file.exe "./target/$env:RUST_TARGET/release/geoping.exe" ; (Get-Item -Path "./target/$env:RUST_TARGET/release/geoping.exe").Length | ForEach-Object { "{0:N2} MB" -f ($_ / 1MB) }
      wldd.exe "./target/$env:RUST_TARGET/release/geoping.exe" | Sort-Object -Unique
      cargo clean ; Pop-Location
}
#-------------------------------------------------------#

#-------------------------------------------------------#
##Cleanup
Remove-Item "Env:\SKIP_BUILD" -ErrorAction SilentlyContinue ; $env:BUILT = "YES"
#In case of zig polluted env
Remove-Item "Env:\AR","Env:\CC","Env:\CFLAGS","Env:\CXX","Env:\CXXFLAGS","Env:\DLLTOOL","Env:\HOST_CC","Env:\HOST_CXX","Env:\LDFLAGS","Env:\LIBS","Env:\OBJCOPY","Env:\RANLIB" -ErrorAction SilentlyContinue
#In case of go polluted env
Remove-Item "Env:\GOARCH","Env:\GOOS","Env:\CGO_ENABLED","Env:\CGO_CFLAGS" -ErrorAction SilentlyContinue
#-------------------------------------------------------#