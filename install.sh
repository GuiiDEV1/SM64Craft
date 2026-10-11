#!/bin/bash
# MarioCraft installer. Run by install.bat (or from any MSYS2 shell: bash install.sh).
#
# Builds everything on this PC from source, with your own copies of the games:
#   1. Java 25 and Prism Launcher are there    4. SM64: sm64coopdx v1.5.1 + MarioCraft
#   2. the build tools (MSYS2 packages)        5. the MarioCraft Minecraft mod (SkyCraft 0.1.2 + MarioCraft)
#   3. your Super Mario 64 ROM                 6. "MarioCraft Launcher.exe" and the Prism Launcher instance
# Safe to run again: it picks up where it left off, and updates an older MarioCraft install.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
export PATH="/mingw64/bin:/usr/bin:$PATH"

SM64_REPO=${MARIOCRAFT_SM64_REPO:-https://github.com/coop-deluxe/sm64coopdx.git}
SM64_COMMIT=8cd6e5977d9f920d51ca71f2c61801d019ed79c6   # v1.5.1
SKY_REPO=${MARIOCRAFT_SKY_REPO:-https://github.com/chasmlol/SkyCraft.git}
SKY_COMMIT=bfcaf178524b92c2cdeb88e4ce0f13ef9ded6f32    # v0.1.2
ROM_SHA1=9bef1128717f958171a4afac3ed78ee2bb4e86ce      # Super Mario 64 (USA), .z64

fail() {
    echo
    echo "PROBLEM: $*"
    exit 1
}

# Opens a web page in the player's browser.
open_page() {
    [ -n "${MARIOCRAFT_NO_BROWSER:-}" ] && return  # (for testing the installer)
    # (Windows' own URL handler: no cmd in between to cut the link at its "&"s)
    rundll32.exe url.dll,FileProtocolHandler "$1" >/dev/null 2>&1 &
}

# ---- Where MarioCraft is: SM64's build can't cope with spaces in the folder's path (a "John Smith"
# ---- user folder, "New folder"...) or with a long one (Windows' path length limit).
winhere="$(cygpath -w "$here")"
case "$here" in
    *" "*) fail "MarioCraft's folder has a space in its path ($winhere), and SM64 can't be built there. Move the MarioCraft folder to  C:\\MarioCraft  and run install.bat from there." ;;
esac
if [ ${#winhere} -gt 80 ]; then
    fail "MarioCraft's folder path is too long ($winhere) for SM64's build. Move the MarioCraft folder to  C:\\MarioCraft  and run install.bat from there."
fi

# ---- What has to be installed first: checked before anything long, so nobody waits 20 minutes
# ---- to find out. Whatever is missing has its download page opened, with what to pick on it.
echo "== 1/6  Java 25 and Prism Launcher"
JAVA_PAGE="https://adoptium.net/temurin/releases/?os=windows&arch=x64&package=jdk&version=25"
PRISM_PAGE="https://prismlauncher.org/download/windows/"

java_home=""
local_app="$(cygpath -u "${LOCALAPPDATA:-C:\\}")"
roaming_app="$(cygpath -u "${APPDATA:-C:\\Users}")"
on_path=""
if command -v java >/dev/null 2>&1; then
    on_path="$(dirname "$(dirname "$(command -v java)")")"
fi
for candidate in "${JAVA_HOME:-}" "$on_path" "$local_app/Programs/Eclipse Adoptium"/jdk-25* "/c/Program Files/Eclipse Adoptium"/jdk-25* \
                 "/c/Program Files/Java"/jdk-25* "/c/Program Files/Microsoft"/jdk-25* "/c/Program Files/Zulu"/zulu-25* \
                 "$roaming_app"/PrismLauncher/java/java-runtime-*; do
    [ -n "$candidate" ] || continue
    unixpath="$(cygpath -u "$candidate" 2>/dev/null || echo "$candidate")"
    if [ -x "$unixpath/bin/java.exe" ] && [ -x "$unixpath/bin/javac.exe" ] && "$unixpath/bin/java.exe" -version 2>&1 | grep -q 'version "25'; then
        java_home="$unixpath"
        break
    fi
done

prism=""
for candidate in "$local_app/Programs/PrismLauncher/prismlauncher.exe" "/c/Program Files/PrismLauncher/prismlauncher.exe" \
                 "/c/Program Files (x86)/PrismLauncher/prismlauncher.exe" "$local_app/SkyCraft/Prism/prismlauncher.exe"; do
    if [ -f "$candidate" ]; then
        prism="$candidate"
        break
    fi
done

if [ -z "$java_home" ] || [ -z "$prism" ]; then
    echo
    echo "Before MarioCraft can be installed, this PC needs:"
    if [ -z "$java_home" ]; then
        echo
        echo "  * JAVA 25 (JDK).  Opening its download page in your browser..."
        echo "      On that page pick:  Version 25 - Windows - x64 - JDK  and download the  .msi  installer."
        echo "      (It must be version 25, and the JDK, not the JRE. Older or newer Java won't work.)"
        echo "      While installing, on \"Custom Setup\", click \"Set JAVA_HOME variable\" and choose"
        echo "      \"Will be installed on local hard drive\"."
        open_page "$JAVA_PAGE"
    fi
    if [ -z "$prism" ]; then
        echo
        echo "  * PRISM LAUNCHER (it runs Minecraft for MarioCraft).  Opening its download page in your browser..."
        echo "      Download the Windows installer (\"Setup\", not \"Portable\") and install it."
        echo "      Then open Prism Launcher once: Accounts (top right) - Manage Accounts - Add Microsoft,"
        echo "      and sign in with the Microsoft account that owns Minecraft: Java Edition."
        open_page "$PRISM_PAGE"
    fi
    echo
    fail "install what's listed above, then run install.bat again."
fi
export JAVA_HOME="$(cygpath -w "$java_home")"
echo "OK: Java 25 ($JAVA_HOME)"
echo "OK: Prism Launcher ($(cygpath -w "$prism"))"

echo "== 2/6  Build tools"
missing=0
for tool in git make python3 unzip gcc sdl2-config; do
    command -v "$tool" >/dev/null || missing=1
done
if [ $missing = 1 ]; then
    echo "Installing them with MSYS2's pacman (a few minutes the first time)..."
    pacman -S --needed --noconfirm git make python unzip mingw-w64-x86_64-gcc mingw-w64-x86_64-SDL2 mingw-w64-x86_64-glew \
        || fail "pacman couldn't install the build tools. Open \"MSYS2 MINGW64\" from the Start menu, run  pacman -Syu  (twice if it asks), then run install.bat again."
fi
echo "OK"

# Gets an upstream project at the pinned version with MarioCraft's patch on it.
get_source() {
    local dir="$1" repo="$2" commit="$3" tag="$4" patch="$here/patches/$5"
    if [ ! -d "$here/$dir/.git" ]; then
        [ ! -e "$here/$dir" ] || fail "$here/$dir already exists and isn't a MarioCraft-managed Git checkout. Rename it to keep its files, then retry."
        echo "Downloading $dir..."
        git clone -q --depth=1 --branch "$tag" "$repo" "$here/$dir" || fail "couldn't download $dir from $repo (are you online?)"
    fi
    cd "$here/$dir" || exit 1
    if git apply --reverse --check "$patch" 2>/dev/null; then
        echo "OK: $dir already has this MarioCraft"
        return
    fi
    # A fresh copy, or an older MarioCraft: back to the upstream version, then this patch.
    git fetch -q --depth=1 origin "refs/tags/$tag" 2>/dev/null
    git reset -q --hard "$commit" || fail "couldn't get $dir at version $commit"
    git clean -q -fd -e build -e baserom.us.z64
    git apply --whitespace=nowarn "$patch" || fail "MarioCraft's patch didn't apply to $dir"
    echo "OK: $dir patched"
}

echo "== 3/6  Build the Minecraft mod (no ROM needed yet)"
get_source SkyCraft "$SKY_REPO" "$SKY_COMMIT" v0.1.2 skycraft.patch
echo "Building (Gradle downloads Minecraft 26.3's build files the first time; the log is in minecraft-mod-build.log)..."
# MSYS2 exports TEMP/TMP as /tmp, which breaks Java's Windows loopback socket setup.
(cd "$here/SkyCraft/fabric" && env -u TEMP -u TMP cmd //c "$(cygpath -w "$here/SkyCraft/fabric/gradlew.bat")" build > "$here/minecraft-mod-build.log" 2>&1) || {
    tail -n 25 "$here/minecraft-mod-build.log"
    fail "the Minecraft mod didn't build (all of it is in minecraft-mod-build.log)"
}
echo "OK"

echo "== 4/6  Prepare the Minecraft instance and ROM folder"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$(cygpath -w "$here/launcher/setup-prism.ps1")" -Quiet -AllowMissingRom \
    || fail "Prism couldn't create the MarioCraft instance. Sign in to Prism once, then retry."
rom_folder_win="$(tr -d '\r\n' < "$here/launcher/rom-folder-path.txt")"
[ -n "$rom_folder_win" ] || fail "Prism didn't return the MarioCraft ROM folder path."
rom_folder="$(cygpath -u "$rom_folder_win")"
mkdir -p "$rom_folder"
echo
echo "Your own Super Mario 64 (USA) ROM goes here:"
echo "  $(cygpath -w "$rom_folder")"
if ! python3 "$here/tools/prepare-rom.py" "$rom_folder" "$here"; then
    echo
    echo "Copy your original USA ROM (.z64, .n64 or .v64) into that folder, then press Enter."
    read -r
    python3 "$here/tools/prepare-rom.py" "$rom_folder" "$here" || fail "No verified USA ROM found. MarioCraft does not include one."
fi
rom="$rom_folder/baserom.us.z64"
[ "$(sha1sum "$rom" | cut -d' ' -f1)" = "$ROM_SHA1" ] || fail "the ROM in the Minecraft instance folder couldn't be verified"
if [ -n "${APPDATA:-}" ]; then
    appdata="$(cygpath -u "$APPDATA")"
    mkdir -p "$appdata/sm64coopdx"
    if [ ! -f "$appdata/sm64coopdx/baserom.us.z64" ] || [ "$(sha1sum "$appdata/sm64coopdx/baserom.us.z64" | cut -d' ' -f1)" != "$ROM_SHA1" ]; then
        cp "$rom" "$appdata/sm64coopdx/baserom.us.z64"
    fi
fi
echo "OK: personal ROM verified; it stays outside MarioCraft's distributed package."

echo "== 5/6  Super Mario 64 (sm64coopdx + MarioCraft)"
get_source sm64coopdx "$SM64_REPO" "$SM64_COMMIT" v1.5.1 sm64coopdx.patch
cp -f "$rom" "$here/sm64coopdx/baserom.us.z64"
: > "$here/sm64coopdx-build.log"
if tasklist 2>/dev/null | grep -qi "sm64coopdx.exe"; then
    fail "SM64 is running: close it, then run install.bat again."
fi
# As many compile jobs as the PC has room for: one per core ran some PCs out of memory (some of
# sm64coopdx's files need a lot each). About 2 GB a job, at most 8.
cores="$(nproc 2>/dev/null || echo 2)"
mem_gb=$(( $(awk '/MemTotal/ {print $2}' /proc/meminfo 2>/dev/null || echo 4194304) / 1048576 ))
jobs=$(( mem_gb / 2 ))
[ "$jobs" -gt "$cores" ] && jobs=$cores
[ "$jobs" -gt 8 ] && jobs=8
[ "$jobs" -lt 1 ] && jobs=1
echo "Building with $jobs jobs (10-20 minutes the first time; the log is in sm64coopdx-build.log)..."
built=0
for try_jobs in "$jobs" 2 1; do
    if (cd "$here/sm64coopdx" && make -j"$try_jobs" >> "$here/sm64coopdx-build.log" 2>&1); then
        built=1
        break
    fi
    [ "$try_jobs" = 1 ] && break
    # (already compiled files are kept: a retry only does what's left)
    echo "  The build stopped (the PC may have run short of memory): trying again with fewer jobs..."
done
if [ $built != 1 ]; then
    tail -n 25 "$here/sm64coopdx-build.log"
    fail "SM64 didn't build (the end of the log is above; all of it is in sm64coopdx-build.log). Close other programs and run install.bat again."
fi
cp -f "$rom" "$here/sm64coopdx/build/us_pc/baserom.us.z64" || fail "couldn't copy your ROM next to the game executable"
echo "OK"

echo "== 6/6  Build the MarioCraft launcher"
bash "$here/launcher/build.sh" || fail "the launcher didn't build"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$(cygpath -w "$here/launcher/setup-prism.ps1")" \
    || fail "Prism Launcher isn't set up: install it from https://prismlauncher.org, sign in to your Microsoft account in it once, then run install.bat again."

echo
echo "Done! Double-click \"MarioCraft Launcher.exe\" in this folder to play."
