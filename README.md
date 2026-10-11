# MarioCraft

![MarioCraft: Steve fighting King Bob-omb with a mace in Bob-omb Battlefield](docs/screenshot.webp)

Play Super Mario 64 as Minecraft's Steve.

**[⬇ Download the latest version](https://github.com/GuiiDEV1/SM64Craft/releases/latest)**: put `MarioCraft-<version>.jar` in your Fabric instance's `mods` folder.

> **Built on [SkyCraft](https://github.com/chasmlol/SkyCraft) by chasm.** SkyCraft's shared-memory bridge is the foundation MarioCraft adapts for Super Mario 64. All credit for that work goes to chasm. Go check out SkyCraft!

MarioCraft runs [sm64coopdx](https://github.com/coop-deluxe/sm64coopdx) from Minecraft and displays its view in the Minecraft window. Steve replaces Mario. He moves, fights, mines, builds and takes damage the Minecraft way, while everything in Mario's world (levels, enemies, bosses, stars, cannons, slides, caps) still works the SM64 way. You can beat the whole game as Steve, alone or with friends.

**No ROM or native executable is included in the mod download.** Setup downloads the pinned official SM64 Coop DX Windows release and applies MarioCraft's bundled binary delta locally. The game reads your own USA ROM at runtime.

> **Status: new and experimental.** Expect rough edges, and back up your saves (see [Your saves](#your-saves)). Found a bug? [Open an issue](../../issues/new/choose).
> MarioCraft is a fan project. It isn't affiliated with Nintendo, Mojang Studios or Microsoft, and you need to own both games.

## What it does

- **Steve in every level.** Minecraft movement, hearts, hunger, armour and inventory, in all of SM64's courses, the castle and the Bowser stages.
- **Mario's moves the Minecraft way:**
  - double jump, triple jump, long jump, backflip and wall kicks;
  - ground pound;
  - butt-sliding down slides;
  - poles, cannons, Hoot and Koopa shells.
- **Fighting.** Swords, axes, bows and the mace work on Goombas, Bob-ombs, Bullies, Boos and the rest.
- **Bosses.** Every boss can be beaten with Minecraft weapons. The mace takes a life with every hit; swords wear a boss down. Bowser is still thrown by the tail into his bombs.
- **Mining and building.** Mine Mario's world (castle walls drop stone or quartz bricks, stair rails drop fences, grass gives dirt...) and build in it. Placed blocks are solid to SM64.
- **Power-ups.** Mario's caps become Minecraft effects: the wing cap gives flight, the metal cap gives Resistance and Fire Resistance, the vanish cap gives Invisibility.
- **Coins and hearts** heal Steve and feed him. Underwater levels give Water Breathing.
- **Losing a life works like Mario's**, with Minecraft-style messages ("Steve was chomped by a Chain Chomp").
- **Minecraft's mobs fight on your side.** Hostile mobs (zombies, skeletons, creepers, even the Wither) attack SM64's enemies, never players.
- **C418's music** in place of SM64's, picked for each level, and Minecraft sounds throughout.
- **Multiplayer.** Your friends' Minecraft joins the host's world automatically, so you see each other's skins and beat the game together.

## You need

- **Windows 10 or 11** (64-bit), an internet connection, and 512 MB of free space for setup.
- **Your own Super Mario 64 (USA) ROM** (a `.z64`, `.n64` or `.v64` file, any name).
- **Minecraft: Java Edition 26.3** with **Fabric Loader and Fabric API**. Fabric API must be installed in the instance before adding this JAR.
- The Minecraft instance's **Java 25 runtime** (Minecraft 26.3 supplies this in current launchers).

## Install

1. Put the MarioCraft JAR in that instance's `mods` folder and start Minecraft.
2. On the title screen, click **Instalar dependências**. Click **Abrir pasta sm64craft** and copy your own USA ROM there. The supported formats are `.z64`, `.n64` and `.v64`; MarioCraft checks the ROM and leaves your original file unchanged.
3. Click **Instalar dependências** again. MarioCraft downloads the official Windows release (about 42 MB), extracts it and applies its verified binary delta. No compiler or source checkout is needed for release packages. Keep Minecraft open and do not delete that folder while it is installing. Download time depends on your connection.
4. When the button changes to **Reiniciar Minecraft**, click it to load the multiplayer helper. Then open **MarioCraft** from the title screen.

Everything is kept in that Minecraft instance: the native game, per-instance saves and your ROM are in `.minecraft/sm64craft`; e4mc is installed beside the other mods. Temporary downloads are removed after setup, including failed attempts. The JAR contains the installer and patches, without a ROM or complete native executable. To update, replace the JAR in `mods` and restart Minecraft. Developers can explicitly use `install-native.ps1 -BuildFromSource`; that slower path needs 4 GB free space and removes its temporary compiler after building.

## Play

Click **MarioCraft** on Minecraft's title screen. SM64 Coop DX starts from this instance and its frame appears inside Minecraft. Steve's skin comes from the account signed in to that launcher.

### Minecraft View (experimental)

The SM64 menu and gameplay render inside the Minecraft window. Keep Minecraft focused to play; the native process is started by the mod and closed when Minecraft exits.

### Controls

Minecraft's controls, plus:

| | |
|---|---|
| Double / triple jump | Space again right as you land (triple: while running) |
| Long jump | Shift + Space while running |
| Backflip | Shift + Space standing still |
| Wall kick | Space in the air against a wall |
| Ground pound | Hold Shift as you land from a jump or fall |
| Talk, pick up (MIPS, baby penguin) | Right-click |
| Steer a slide, cannon or shell | WASD and the mouse; Space jumps off |
| SM64's pause menu (Exit Course) | P |
| Camera (first / third person) | F5 |
| Show the debug status line (for bug reports) | F7 |

### Multiplayer

Everyone needs the same MarioCraft package installed, their own USA ROM, and a Minecraft Java account. Start MarioCraft on each PC. One player hosts in sm64coopdx (Host on the main menu) and friends join that SM64 Coop DX session as usual. The mod then opens the host's Minecraft world to those players and joins their Minecraft instances through e4mc. No separate Minecraft server or manual port forwarding is needed. Both the SM64 executable and the Fabric mod must come from the same MarioCraft package.

Use the same MarioCraft build on every PC: the Minecraft mod and SM64 executable must match, including the guest teleport messages. Three development clients on one PC were verified through e4mc, including independent phase transitions, blocks, inventory, death, star progress and reconnects. Version 0.1.10 also verified joining a real private CoopNet room by password and loading all 90 main-course missions with local development identities. Scripted two-client checks triggered the real DDD and WDW passages in both directions and confirmed the Minecraft collision regions loaded. Those checks position players at the real warp floors; walking the routes manually and play between separate PCs with Microsoft accounts remain unverified. The full campaign and every boss are outside this release check. See [the validation report](docs/MULTIPLAYER-VALIDATION.md) for evidence and limits.

### Your saves

- Main-course missions have separate building regions from 0.1.10 onward, matching SM64's separate multiplayer instances. Older shared builds remain in mission 1; they are preserved rather than duplicated into every mission.
- **Mario progress:** `sm64craft\saves` in the active Minecraft instance
- **Minecraft world:** the instance's regular `saves` folder
- **Your ROM:** `sm64craft\baserom.us.z64`. The original dump you copied is preserved beside it.

## If something goes wrong

- **The setup failed.** Open `.minecraft\sm64craft\install.log`; temporary build files are removed, and the next attempt starts cleanly.
- **Minecraft/e4mc can't connect.** Check that the multiplayer helper loaded after restarting and that the host opened their world to LAN. If Windows asks about Java's firewall access, allow private-network access.
- **Minecraft crashed or the mod didn't load.** Read `logs\latest.log` in that instance's `.minecraft` folder.

## Uninstall

Close Minecraft. To remove the mod, delete its JAR from `mods`. To remove the native game, ROM and SM64 saves too, delete that instance's `.minecraft\sm64craft` folder.

## Credits

- **[sm64coopdx](https://github.com/coop-deluxe/sm64coopdx)** by the Coop Deluxe team, built on the [Super Mario 64 decompilation](https://github.com/n64decomp/sm64).
- **[SkyCraft](https://github.com/chasmlol/SkyCraft)** by **chasm** ([chasmlol](https://github.com/chasmlol), MIT License). The original Minecraft-inside-another-game mod. MarioCraft's Minecraft mod is SkyCraft with MarioCraft's changes on top: the shared-memory link, the collision and rendering exchange, the combat stand-ins and the Prism setup are all chasm's work.
- **[Fabric](https://fabricmc.net)**, **[Fabric API](https://github.com/FabricMC/fabric)**, **[e4mc](https://github.com/vgskye/e4mc-minecraft-architectury)** and **[Prism Launcher](https://prismlauncher.org)**.

MarioCraft's own code is under the MIT License (`LICENSE`). sm64coopdx and SkyCraft stay under their own terms. See `THIRD-PARTY-NOTICES.md` and the `licenses` folder.

Development disclosure: OpenAI Codex (GPT-6) assisted with implementation, testing and documentation. No game art or audio is generated or bundled by MarioCraft.

MarioCraft is a fan project. It is not affiliated with or endorsed by Nintendo, Mojang Studios or Microsoft. Super Mario 64 is a trademark of Nintendo; Minecraft is a trademark of Mojang Studios. No Nintendo or Mojang game data is included. Super Mario 64 comes from your own ROM, and Minecraft (with its music) from your own copy of the game.
