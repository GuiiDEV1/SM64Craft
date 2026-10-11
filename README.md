# SM64Craft

**Play Super Mario 64 as Steve, inside Minecraft.** SM64Craft brings the SM64 Coop DX game view into Minecraft and lets Steve explore, fight and build in Mario's worlds.

<p align="center">
  <img src="docs/screenshots/sm64craft-coop.jpg" alt="Two Minecraft players exploring the Super Mario 64 castle grounds together" width="49%">
  <img src="docs/screenshots/sm64craft-steve.jpg" alt="Steve in diamond armor on the Super Mario 64 castle grounds" width="49%">
</p>

**[Download the latest release](https://github.com/GuiiDEV1/SM64Craft/releases/latest)** and put its JAR in your Fabric instance's `mods` folder.

> SM64Craft is experimental fan software. It is not affiliated with Nintendo, Mojang Studios or Microsoft. You must provide your own Super Mario 64 USA ROM; the ROM is never included in the mod or uploaded by the installer.

## What it does

SM64Craft starts a locally installed copy of [SM64 Coop DX](https://github.com/coop-deluxe/sm64coopdx) and displays its game view inside Minecraft. Steve uses Minecraft movement, health, inventory and equipment while interacting with SM64 levels, enemies, courses and bosses.

- **Move like Mario:** double and triple jumps, long jumps, backflips, wall kicks, ground pounds, poles, cannons, slides and shells.
- **Fight with Minecraft gear:** swords, axes, bows and the mace work against SM64 enemies and bosses.
- **Mine and build:** break parts of the SM64 world for Minecraft blocks, then place blocks that have collision in the game world.
- **Use power-ups:** the wing, metal and vanish caps grant Minecraft-style effects.
- **Play together:** connect to an SM64 Coop DX session and share the Minecraft world through e4mc.
- **Keep your files local:** the native game, settings, saves and ROM stay in the active Minecraft instance.

## Requirements

- Windows 10 or 11, 64-bit, and an internet connection for the first setup.
- Minecraft: Java Edition **26.3** with **Fabric Loader** and **Fabric API** already installed in the instance.
- The instance's Java **25** runtime. Current launchers provide this for Minecraft 26.3.
- Your own supported Super Mario 64 USA ROM in `.z64`, `.n64` or `.v64` format.
- About 512 MB of free disk space for setup and the installed game files.

The current automatic installer supports Windows only. It does not install Minecraft, Fabric Loader, Fabric API or Java.

## Installation

1. Download the latest SM64Craft JAR from [Releases](https://github.com/GuiiDEV1/SM64Craft/releases/latest) and put it in the `mods` folder of your Fabric instance.
2. Start Minecraft. From the title screen, open the mod's setup screen and choose **Abrir pasta sm64craft** (open the `sm64craft` folder). In the current release, some in-game labels may still say “MarioCraft.”
3. Copy your own USA ROM into that folder. Return to the setup screen and choose **Instalar dependências** (install dependencies). The installer verifies the ROM and leaves the original dump unchanged.
4. The installer downloads the official Windows SM64 Coop DX release, applies SM64Craft's verified patch locally, and installs the e4mc multiplayer helper into that instance. It does not include or distribute your ROM or a complete native game executable.
5. When setup finishes, restart Minecraft once so Fabric can load e4mc. Then open SM64Craft from the title screen.

The native game, ROM, SM64 saves and install log are kept in that instance's `.minecraft/sm64craft` directory. The e4mc helper is installed in that instance's `mods` folder. Temporary installer downloads are removed after setup. Release builds use the prebuilt game package, so players do not need a compiler or a source checkout. Setup time depends on the internet connection and computer.

## Playing

Open SM64Craft from Minecraft's title screen. The SM64 Coop DX view appears in the Minecraft window; keep Minecraft focused while playing. Closing Minecraft also closes the native game process.

### Controls

Movement and basic actions use the Minecraft key bindings. Additional moves:

| Action | Controls |
| --- | --- |
| Double / triple jump | Press Space again as you land; run for the triple jump |
| Long jump | Shift + Space while running |
| Backflip | Shift + Space while standing still |
| Wall kick | Press Space in the air against a wall |
| Ground pound | Hold Shift as you land from a jump or fall |
| Talk or pick up an object | Right-click |
| Steer a slide, cannon or shell | WASD and mouse; Space jumps off |
| SM64 pause menu / Exit Course | P |
| First- / third-person camera | F5 |
| Debug status line | F7 |

### Multiplayer

Each player needs the same SM64Craft release, a compatible Fabric instance, their own USA ROM and a Minecraft Java account. The host opens their Minecraft world to LAN and hosts an SM64 Coop DX session; friends join that SM64 session through its multiplayer menu. The Minecraft clients then connect through the host's e4mc link. A separate Minecraft server and manual port forwarding are not part of the setup.

Multiplayer is experimental. Local multi-client checks covered world access, phase transitions, blocks, inventory, deaths, star progress and reconnects. Scripted tests also exercised the DDD and WDW passages. Play between separate PCs with Microsoft accounts, manually walking every course route, the complete campaign and every boss have not all been verified. See the [multiplayer validation report](docs/MULTIPLAYER-VALIDATION.md) for details and limits. Use the same mod and native game build on every computer.

## Saves and files

- **SM64 progress and ROM:** the active instance's `.minecraft/sm64craft` folder.
- **Minecraft worlds:** the instance's normal `saves` folder.
- **ROM filename after verification:** `sm64craft/baserom.us.z64`. The source file you copied is preserved beside it.
- **Install log:** `sm64craft/install.log`.

To remove SM64Craft, close Minecraft and delete its JAR from `mods`. To also remove the installed native game, ROM and SM64 saves, delete that instance's `.minecraft/sm64craft` folder. The installer also places e4mc in `mods`; remove that JAR too if you do not use it with another mod.

## Troubleshooting

- **The setup screen cannot find a ROM:** copy a supported USA ROM into the `sm64craft` folder opened by the setup screen, then retry. Only the supported USA revision passes verification.
- **Setup failed:** open `sm64craft/install.log` in the active instance directory. Temporary downloads are cleaned up; after correcting the reported issue, try installation again.
- **Multiplayer does not connect:** restart Minecraft once after installation, check that e4mc loaded, and allow Java through Windows Firewall on private networks if prompted.
- **The mod does not load:** confirm that the instance is Minecraft 26.3 with Fabric Loader, Fabric API and Java 25, then check that instance's `logs/latest.log`.
- **Found a bug?** [Open an issue](https://github.com/GuiiDEV1/SM64Craft/issues).

## Credits and licenses

- [SM64 Coop DX](https://github.com/coop-deluxe/sm64coopdx) by the Coop Deluxe team, built on the [Super Mario 64 decompilation](https://github.com/n64decomp/sm64).
- [SkyCraft](https://github.com/chasmlol/SkyCraft) by chasm is the foundation for rendering another game inside Minecraft. Its shared-memory bridge is credited to its original author and remains under its own license.
- [Fabric](https://fabricmc.net), [Fabric API](https://github.com/FabricMC/fabric), [e4mc](https://github.com/vgskye/e4mc-minecraft-architectury) and [Prism Launcher](https://prismlauncher.org).

SM64Craft's code is under the MIT License (`LICENSE`). Third-party code and assets retain their own terms; see [`THIRD-PARTY-NOTICES.md`](THIRD-PARTY-NOTICES.md) and the `licenses` folder. No Nintendo game data or Minecraft game data is included. You need your own copy of each game and your own ROM.
