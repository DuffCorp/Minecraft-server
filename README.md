# Ballsnia — Bosnian Cobblemon Server + Modpack

🇧🇦 **Ballsnia** — the Bosnian Pokémon server for the Ballsnia groupchat.

A self-hosted, friends-only **Cobblemon** (Pokémon) Minecraft server with Create,
more biomes, legendary Pokémon, minimaps and toggleable Distant Horizons +
shaders — hosted on **Coolify**, with a **packwiz** modpack that auto-updates for
both the server and your friends.

- **Minecraft:** 1.21.1
- **Loader:** NeoForge
- **Hosting:** Coolify → `itzg/minecraft-server` Docker image
- **Pack management:** packwiz + GitHub Pages (one source of truth)
- **Shaders:** Iris + Sodium (not OptiFine)
- **Distant Horizons:** client-side, optional — friends can toggle it off

This repo *is* your packwiz pack. The whole point of this setup:

> You update the pack once → push to GitHub → friends auto-update on next launch,
> and the Coolify server auto-installs matching server mods. No more emailing a
> 2 GB folder of `.jar` files.

---

## What's in this repo

Folders keep things tidy — running the scripts never litters the root:

```
ballsnia-pack/
├─ docker-compose.yml      Paste into Coolify to run the server
├─ README.md  FRIENDS.md  SERVER-COMMANDS.md
├─ scripts/                The PowerShell/Python tooling (run these)
│  ├─ install-packwiz.ps1     Install packwiz (via Go)
│  ├─ build-pack.ps1          Build the pack in pack/ + add every mod
│  ├─ export-mrpack.ps1       Export a .mrpack into dist/ to test in Prism
│  ├─ build-instance.ps1      Build the friend ZIP (Prism instance + icon baked in)
│  ├─ update-pack.ps1         Add/update mods and push updates
│  └─ make-server-icon.py     Regenerate the Bosnian Pokéball icon
├─ pack/                   The packwiz pack (committed): pack.toml, index.toml, mods/
├─ assets/                 server-icon.png (64×64 server list) + ballsnia-icon.png (256, Prism)
└─ dist/                   Exported .mrpack (gitignored — regenerate any time)
```

> The scripts are PowerShell (Windows). Open **PowerShell in this folder** and run
> them as shown. Each is safe to re-run, and each works no matter which directory
> you launch it from.

---

## Prerequisites (your PC)
- **Go** — https://go.dev/dl/ (used to install packwiz)
- **Git** — https://git-scm.com/
- **Java 21** — https://adoptium.net/ (to test the pack)
- **Prism Launcher** — https://prismlauncher.org/ (to test + to build the friend ZIP)
- A **GitHub** account (for GitHub Pages auto-updates)
- A **Coolify** server + a domain (optional but nice)

Expect **~2–4 hours** the first time (modded MC always has a dependency or two to
chase). The quick version is ~30–45 min.

---

## Step 1 — Install packwiz
```powershell
.\scripts\install-packwiz.ps1
```
Then **close and re-open PowerShell** so `packwiz` is on your PATH. Verify:
```powershell
packwiz --version
```

## Step 2 — Build the pack
From this folder:
```powershell
.\scripts\build-pack.ps1
```
This writes a correct NeoForge 1.21.1 `pack.toml` into `pack/`, adds all the mods
(see the full list below), marks client-only mods as `side = "client"`, and
refreshes the index. If a mod slug has changed on Modrinth, the script prints which
ones to add manually with `packwiz modrinth add "<search term>"` (run from `pack/`).

## Step 3 — Test locally in Prism
```powershell
.\scripts\export-mrpack.ps1
```
This drops `dist/Ballsnia.mrpack`. In Prism Launcher: **Add Instance → Import →**
choose it.
Launch in **single-player** and confirm:
- Game launches; Cobblemon and Create work
- Worldgen looks right (Terralith biomes)
- Distant Horizons can be toggled in **Edit → Mods**
- Shaders menu appears (via Iris): **Options → Video Settings → Shader Packs**

## Step 4 — Publish to GitHub (enables auto-update)
```powershell
git init
git add .
git commit -m "Initial Cobblemon modpack"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/ballsnia-pack.git
git push -u origin main
```
Then on GitHub: **Settings → Pages → Deploy from branch → `main` / `/root` → Save**.

Your pack URL becomes (note the `pack/` folder):
```
https://YOUR_USERNAME.github.io/ballsnia-pack/pack/pack.toml
```
That URL is the magic bit — both your friends' launchers **and** Coolify use it.

## Step 5 — Build the friend ZIP (auto-updating Prism instance, icon included)
One command — use your real pack URL from Step 4:
```powershell
.\scripts\build-instance.ps1 -PackUrl "https://YOUR_USERNAME.github.io/ballsnia-pack/pack/pack.toml"
```
This produces `dist/Ballsnia-Prism.zip` — a Prism instance pre-wired with the packwiz
auto-updater **and** the Bosnian Pokéball icon baked in. (Omit `-PackUrl` and it reads
`PACKWIZ_URL` from `docker-compose.yml`.)

Import it into **your own** Prism once (**Add Instance → Import from zip**) to confirm
it launches and shows the Pokéball — then send the **same ZIP** to friends. They just
do **Add Instance → Import from zip → Launch**: icon and auto-updates included, zero
manual setup. See [FRIENDS.md](FRIENDS.md) for the message to send them.

<details><summary>Prefer to build the instance by hand in Prism?</summary>

1. Create a Prism instance: **Minecraft 1.21.1 + NeoForge + Java 21**; set RAM per
   [FRIENDS.md](FRIENDS.md).
2. Put `packwiz-installer-bootstrap.jar` (from the
   [releases](https://github.com/packwiz/packwiz-installer-bootstrap/releases)) in the
   instance's `.minecraft` folder.
3. **Edit Instance → Settings → Custom Commands → enable**, Pre-launch command:
   `"$INST_JAVA" -jar packwiz-installer-bootstrap.jar https://YOUR_USERNAME.github.io/ballsnia-pack/pack/pack.toml`
4. **Edit Instance →** click the icon (top-left) **→ Add Icon →** `assets/ballsnia-icon.png` → select.
5. **Right-click instance → Export →** send the ZIP.
</details>

## Step 6 — Deploy the server on Coolify
1. In Coolify: **New Project → New Resource → Docker Compose** and paste
   [`docker-compose.yml`](docker-compose.yml).
2. Edit the three placeholders in it: `OPS`, `MOTD`, and **`PACKWIZ_URL`**
   (your GitHub Pages URL from Step 4).
3. Deploy. The server pulls its server-side mods from your pack automatically.

## Step 7 — Networking
- Open **TCP 25565** on the VPS firewall.
- In your DNS (e.g. Cloudflare): an **A record** `mc.yourdomain.com` → your VPS IP,
  **proxy OFF (grey cloud)**. Minecraft isn't HTTP, so don't route it through
  Coolify's web proxy.
- Friends join `mc.yourdomain.com` (or `your-server-ip:25565`).

## Step 8 — First boot
In the Coolify terminal (and see [SERVER-COMMANDS.md](SERVER-COMMANDS.md)):
```
whitelist add YourMinecraftUsername
op YourMinecraftUsername
```
Then in-game, pre-generate the world:
```
/chunky radius 5000
/chunky start
```

---

## RAM & sizing

**Server** — set `MEMORY` in `docker-compose.yml` by your VPS/host RAM (leave
headroom for the OS; never allocate 100%). For a ~10-player Cobblemon + Create server:

| Host RAM | `MEMORY` | Notes |
|---|---|---|
| 8 GB | `6G` | fine for a few friends |
| 16 GB | `10G` | comfortable (10–12G) |
| 32 GB | `18G` | lots of headroom (16–20G) |
| 64 GB | `28G` | overkill for friends (24–32G) |
| 128 GB | `40G` | one JVM rarely benefits past ~32G (32–48G) |

Beyond ~16–24 GB a small friends server sees little gain, and giving a single JVM
most of a 128 GB box can *hurt* (longer garbage-collection pauses). More players or
heavy automation → lean toward the higher end.

**Players (client)** — the per-PC allocation table lives in
[FRIENDS.md](FRIENDS.md) (8 GB PC → 4 GB, up to 128 GB PC → 12–16 GB).

---

## Server icon (the Bosnian Pokéball)
`assets/server-icon.png` (64×64) is the image shown next to the server in the
multiplayer list. The compose file's `ICON` env var points at this file in your
GitHub repo, so once you push (Step 4) the server downloads and applies it
automatically — no need to upload anything into the Coolify volume.

To tweak it, edit `scripts/make-server-icon.py` (colours/triangle/stars are near the
top) and regenerate:
```powershell
python scripts/make-server-icon.py
git add assets ; git commit -m "Update server icon" ; git push
```
This regenerates both `assets/server-icon.png` (64×64, the server-list icon) and
`assets/ballsnia-icon.png` (256×256, the Prism instance icon). Then restart the
server (or it picks it up on next start because `OVERRIDE_ICON` is on). Alternatively,
drop any 64×64 PNG named `server-icon.png` into the server's `/data` folder instead
of using the `ICON` URL.

**Prism instance icon:** the friend ZIP from `scripts/build-instance.ps1` already has
the Pokéball baked in (it ships `ballsnia.png` at the instance root, which Prism reads
on import). The `.mrpack` from `export-mrpack.ps1` can't carry a launcher icon, so if
you test via that one, set it manually: **Edit Instance →** click the icon (top-left)
**→ Add Icon →** `assets/ballsnia-icon.png` → select.

## Updating the pack later
```powershell
# add a new mod:
.\scripts\update-pack.ps1 -Add some-modrinth-slug -Push

# or just update everything to latest compatible versions:
.\scripts\update-pack.ps1 -UpdateAll -Push
```
Then **restart the Coolify server** and tell friends to **relaunch** their pack.
If the server updates but a friend doesn't relaunch, the server will block them
until their mod versions match — which is exactly the safety you want.

---

## The mod list

### Server + client (`side = "both"`)
**Core:** Cobblemon · Create

**Cobblemon companions / legendaries / trainers:**
Cobblemon: Create Industries · Radical Cobblemon Trainers · Radical Cobblemon
Trainers API · Radical Gyms & Structures · Myths and Legends (legendary & mythical
spawns) · Cobblemon Spawn Notification

**Utility / QoL:** JEI · Jade · AppleSkin · Waystones · Traveler's Backpack ·
Sophisticated Backpacks · Sophisticated Core · Lootr · Simple Voice Chat · Clumps

**Worldgen / more biomes:** Terralith · Tectonic · Structory · Towns and Towers ·
Nature's Compass · Explorer's Compass

**Performance / admin:** ModernFix · FerriteCore · Spark · Chunky

### Expansion add-ons
**Transport:** Immersive Aircraft · Create: Aeronautics¹ · Small Ships
(trains are already in base Create)

**Create tech:** Crafts & Additions · New Age · Power Loader · Copycats+ · Deco ·
Slice & Dice · Connected · Jetpack · Big Cannons² · Enchantment Industry³

**Cobblemon:** Mega Showdown (Mega/Z/Tera/Dynamax) · CobbleDollars (economy) ·
Cobblemon Counter · Pokénav (tracker) · Cobblemon Integrations

**Multiplayer QoL:** Corpse (death graves) · Open Parties & Claims (land claims,
shows on Xaero's minimap) · Trade Cycling

> ¹ Create: Aeronautics is a heavier, early-stage physics mod (pulls in the *Sable*
> dependency). ² Big Cannons can damage terrain — fine with a trusted group.
> ³ Enchantment Industry's 1.21.1 build is alpha and needs the `create-dragons-plus`
> library (its alpha doesn't auto-declare it, so the build script adds it explicitly).
> It's the most likely future troublemaker — if it keeps breaking, delete those two
> lines from `build-pack.ps1` and rebuild.
>
> **Minimap Pokémon:** not a mod — enable **Entity Radar / Display Creatures** in
> Xaero's Minimap settings and Pokémon show as dots.

### Adventure & content add-ons
**Cobblemon gameplay:** Gym Badges · Trainer Structures · Cobblepedia (in-game
Pokédex) · SimpleTMs · Fight-or-Flight · Capture XP

**Create economy/depth:** Numismatics (coins/ATMs) · Stuff & Additions (jetpacks) ·
Garnished · Confectionery · Diesel Generators · Ironworks

**Cooking:** Farmer's Delight · Create: Central Kitchen

**Group PvE:** L_Ender's Cataclysm · Bosses of Mass Destruction · When Dungeons
Arise · YUNG's Better Dungeons · Integrated Dungeons & Structures · Dungeons &
Taverns · Tide · Aquaculture

**Dimensions:** The Aether (classic floating-island dimension)

**Building:** Supplementaries · Macaw's (Furniture/Roofs/Bridges) · Handcrafted ·
Chipped · FramedBlocks · Every Compat

**Economy:** Numismatics (coins/ATMs) + CobbleDollars (NPC merchants)

**Client extras:** Mini's Cobblemon Icons (Pokémon sprite icons on Xaero's minimap —
enable in **Options → Resource Packs**)

**Server performance:** Lithium · Noisium · ServerCore

> The build script auto-pulls shared dependencies (Moonlight, YUNG's API, Sable,
> etc.). This is now a large pack (~120 mods incl. deps) — allocate more RAM and
> **test in single-player before pushing to the server/friends**.

### Client-only (`side = "client"`)
Sodium · Iris · Distant Horizons · Xaero's Minimap · Xaero's World Map ·
BetterF3 · Controlling · Mouse Tweaks

### Do **not** add
OptiFine · two minimap mods at once · multiple overlapping performance mods ·
many legendary datapacks stacked together · lots of random biome mods piled together.

> **Why `side` matters:** the Coolify server installs from the *same* pack, but
> `itzg/minecraft-server` only installs mods that aren't marked `client`. Marking
> shaders/minimap/Distant Horizons as `side = "client"` keeps them off the server
> while still shipping them to your friends. `build-pack.ps1` sets this for you.

---

## Handheld PC note (from the original plan)
For playing this pack on a handheld, a **Windows** handheld is far less hassle than
SteamOS for modded Java + Prism + shaders + Distant Horizons. Ranking:
**ASUS ROG Ally X** (best for this pack) → **Lenovo Legion Go** (bigger screen) →
**Steam Deck OLED** (best console feel, but more fiddly for heavy modded MC).
Suggested in-game: 6 GB to Minecraft, render distance 8–10, Distant Horizons
low/medium (64–128 chunks), Sodium/Iris, lightweight shaders only.

---

## Troubleshooting
- **"Mismatched mod channel list" / "incompatible mod set":** client and server
  mod sets differ. Relaunch the pack (let the updater run) and restart the server
  so both pull the same pack version.
- **"Mod X requires cobblemon 1.8.0..." (version drift):** a Cobblemon sidemod's
  latest build jumped ahead of the stable Cobblemon the pack uses (1.7.3). Find the
  build that matches 1.7.3 on its Modrinth page, grab the version id from the URL,
  add it to the `$Pinned` map in `scripts/build-pack.ps1`, and rebuild. (tim_core is
  already pinned there as the worked example.) `packwiz pin` keeps `update --all`
  from undoing it.
- **"Mod Y requires Z ... is not installed" (missing dependency):** a library was
  mis-tagged client/server. `build-pack.ps1` already forces all libraries to
  `side = "both"`; if a new one slips through, that's the lever.
- **A `packwiz modrinth add` failed:** the Modrinth slug changed. Run
  `packwiz modrinth add "<name>"` and pick from the search results, then
  `packwiz refresh`.
- **Server ignores PACKWIZ_URL:** make sure it's a real `https://` GitHub Pages
  URL ending in `/pack.toml` (not a `file://` path), and that Pages is enabled.
- **Friends can't connect:** confirm TCP 25565 is open and the DNS A record is
  grey-cloud (DNS only), and that they're whitelisted.
