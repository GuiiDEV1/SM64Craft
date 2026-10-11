# Changelog

## 0.1.11

- Rename the SM64 Coop DX main-menu title to **SM64 CRAFT**.
- Record the verified scripted DDD/WDW passage round trips and clearly mark manual route and separate-PC checks as pending.
- No Minecraft gameplay or multiplayer protocol changes.

## 0.1.10

- Give main-course missions 2..6 separate Minecraft regions, matching SM64's separate act instances.
- Preserve the existing region and builds for mission 1, castle areas and secret courses. Legacy builds shared by old missions remain available in mission 1.
- Add isolated CoopNet private-lobby and campaign loading/mission regression scenarios; see the validation report for tested cases and remaining playthrough work.

## 0.1.9

- Reset lobby requests and skin uploads when the native process restarts.
- Apply the host collision policy to connected bridge guests and restore it on disconnect.
- Wait for stable native area geometry and matching collision epochs before completing teleports.
- Prevent delayed guest geometry from replacing locally exported regions; clear guest caches between sessions.
- Support separate gameplay and video channels for multiple instances on one PC.
- Validate three development clients through e4mc, with independent phase transitions, blocks, inventory, death, star progress and reconnects. See docs/MULTIPLAYER-VALIDATION.md for evidence and limits.

## 0.1.8

- Include the native Direct3D/SDL video capture hooks in the source patch and fast installation bundle.
- Open the embedded SM64 menu immediately on launch, keep the Minecraft window size, and save native logs inside the instance.

## 0.1.7

- Attach the MarioCraft setup button directly to the title screen's initialization, after its widgets are created.

## 0.1.6

- Match the native render aspect ratio to Minecraft at launch and when resizing the window, with a 960 x 540 internal resolution cap.
- Preserve unrelated native configuration and all save data.
- Verify every patched native source file before generating a release delta, preventing an incorrectly applied source patch from producing a release bundle.

## 0.1.5

- Release setup downloads the pinned official Windows executable and applies a verified ROM-free binary delta, avoiding compilation on the player's PC.
- Verify the archive, source executable, patch and resulting executable with SHA-256; preserve saves and keep the user's ROM local.
- Remove temporary downloads after setup; reserve 512 MB instead of 4 GB for the release installation. Keep the source build as a developer option.
- Keep native gameplay changes identical to the current source patch; no input, physics or multiplayer protocol changes.

## 0.1.4

- Add an in-game setup button that downloads a temporary compiler, validates the player's own USA ROM, and builds SM64 Coop DX inside the active Minecraft instance.
- Keep the native game, ROM and SM64 saves in that instance; remove compiler, source, package cache and intermediate objects after setup or failure.
- Install e4mc beside the Fabric mods, request one restart to load it, and open/launch MarioCraft from Minecraft's title screen.
- Lower compilation concurrency to reduce memory pressure, retry failed builds with fewer jobs, and make installation safe to resume.
- Package a distributable JAR and ZIP without ROM data or native game files.

## 0.1.3

- Buffer Minecraft View jump presses so brief Space taps reach SM64 even when its render tick is slower.
- Keep consuming Mario action events while Minecraft View is focused, without replaying its native keyboard and mouse input. This restores the extra Minecraft velocity impulses for Mario's jumps.
- Allow fast double and triple jumps when Minecraft lands and jumps within one tick.
- Use Minecraft View camera yaw to aim backflips and long jumps.
- Create the user's `sm64craft` ROM folder in the MarioCraft Prism instance and verify ROMs locally.
- Add a source-only ZIP package that excludes ROMs, game executables, generated assets, and build output.
- Verify the host-to-guest path with a second client joining the e4mc address; a separate-PC/Microsoft-account play session remains unverified.
