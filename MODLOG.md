# MarioCraft mod log

## Current task

Make the existing MarioCraft project more reliable for Mario's jump moves, confirm the
friend-joining multiplayer path, and prepare a user-friendly source ZIP that never
contains the player's Super Mario 64 ROM.

## Route

MarioCraft remains two parts: sm64coopdx runs the N64 game from the player's own USA ROM,
and a Fabric client runs the Minecraft mirror world. SM64 Coop DX relays the multiplayer
session details; the Fabric lobby opens or joins the corresponding Minecraft world using
e4mc. Release 0.1.5 carries source patches and a ROM-free binary delta. Its installer downloads
the official Windows executable and patches it locally, with hashes checked before installation.
Source compilation remains an explicit developer option. Gameplay and bridge logic are unchanged.

## Current changes

- Mission isolation 0.1.10: main-course acts 2..6 now use distinct world IDs; legacy
  builds remain in act 1. Castle/secret-course IDs are unchanged. C helper checked
  all six acts across 144 level/area combinations. A private CoopNet lobby was
  entered through the embedded menu with local identities and automatic e4mc join.
  The 119-case loading sweep is documented separately from campaign completion.
- Multiplayer 0.1.9: reset lobby and skin state on native restart; isolate memory/video channels;
  align guest server collision with the host; wait for stable native surfaces and matching
  collision epochs; prevent late guest regions from replacing local geometry; clear guest
  geometry between sessions. Three real dev clients passed e4mc integration checks.
  Final Java build passed 43 tests, native policy helpers passed 31 + 13 assertions.
  See docs/MULTIPLAYER-VALIDATION.md for reproducible evidence and untested scenarios.
- Embedded launch 0.1.8: include the three graphics capture files in the native source patch.
  Missing capture hooks left the frame counter at zero and prevented hiding the native window.
  Open the Minecraft frontend immediately, skip resizing Minecraft to the native viewport, and
  set MARIOCRAFT_EMBEDDED_VIEW on the owned native process so its window stays hidden from startup.
  A reserved close request at frame input offset 32 lets the native thread flush saves and exit
  even though a hidden window has no Process.MainWindowHandle.
- View aspect ratio: initialize native window dimensions from Minecraft, capped at 960 x 540.
  Reserved fields 20/24/28 in the independent frame input header carry a sequence-protected size
  request, throttled to four writes per second. The native render thread resizes its own hidden
  window without changing focus. Menu input and the gameplay/multiplayer bridge are unchanged.
- Native bundle validation: require all 45 patched source files to match before delta generation.
  This catches source patches skipped by Git when a build directory is nested in another repository.
- Native movement: record shared Minecraft View jump press sequences; accept quick taps;
  select double/triple moves from the jump chain even if the intermediate grounded state
  lasted less than one SM64 frame; use the Minecraft camera yaw for directional moves.
- View input routing: drain native action events while the Minecraft window is focused, but
  discard only keyboard/mouse events already delivered directly to Minecraft. A live backflip
  test raised the mirrored Steve from Y=2 to about Y=6.2; a normal jump peaked near Y=3.25.
- Build tests: `tools/test-mario-moves.py` compiles and exercises the native edge and move
  selection helpers extracted from the implementation.
- ROM flow: Prism setup creates `instances/MarioCraft/.minecraft/sm64craft`; the installer
  waits for the user's `.z64`, `.n64` or `.v64`, validates the USA SHA-1 and normalizes it
  into `baserom.us.z64`. Original input is not overwritten. Generated ROM stays outside
  the public ZIP.
- Distribution: `tools/package-release.ps1` stages an allow-list of sources, patches and
  scripts, then rejects ROMs, game binaries and generated data in the archive.

## Multiplayer validation

The latest verified path uses three Minecraft clients and three SM64 processes on one PC,
with native socket connections and automatic guest Minecraft connections through the public
e4mc relay. Blocks, inventory, death, star progress, separate phase transitions and reconnects
were exercised. This does not prove Microsoft authentication, CoopNet code entry between PCs,
every mission/boss, or prolonged network interruption. The detailed report records these limits.
