# Native release delta

Release JARs contain a compressed binary delta, not a complete SM64 executable or a ROM.
The installer downloads the hash-pinned official SM64 Coop DX 1.5.1 Windows ZIP, verifies it,
applies the delta, checks the output SHA-256 and installs the game inside the active instance.
Its temporary directory is removed after success or failure. Saves remain outside this directory.

## Regenerating a release

1. Extract the pinned CoopDX source commit `8cd6e5977d9f920d51ca71f2c61801d019ed79c6` into a clean
   developer directory and apply `patches/sm64coopdx.patch`. Build it **without any baserom file**.
2. Download the official `v1.5.1/sm64coopdx_Windows.zip` from Coop Deluxe's release page.
3. With Python and `bsdiff4`, run `tools/build-native-delta.py <official.zip> <build/us_pc> dist/native-fast/bundle`.
   It checks runtime asset content (allowing Windows text line endings), validates the archive hash,
   generates the delta and verifies a complete byte-for-byte round trip.
4. Build `SkyCraft/fabric` with Java 25. Gradle includes the bundle and rejects stale source-patch hashes.
5. Run `tools/package-release.ps1`; packaging requires and verifies the fast resources and rejects
   complete native binaries and ROM files in the JAR.
6. Run `tools/test-native-fast.ps1 -Rom <your-local-ROM> -Jar dist/MarioCraft-<version>.jar` on Windows.
   The test creates an isolated instance, seeds the official download, verifies installation, save
   preservation, ROM/executable hashes, temporary cleanup and corrupt-input rejection.

Build tools and test instances under `dist` are developer-only artifacts; they are not packaged.
The developer source-install path is available using `install-native.ps1 -BuildFromSource`.
No source, physics, input or multiplayer changes are introduced by the binary patch codec.

## Local measurements for 0.1.5

- Official archive: 41,801,915 bytes.
- Binary delta: about 0.84 MiB.
- Installed directory including the player's normalized 8 MiB ROM: about 108 MiB.
- Extracting, patching and verifying with a cached archive: about 5 seconds on this PC.
- The release path requires 512 MiB free space; it downloads no compiler or source tree.

These measurements exclude download time and later world/save growth.
