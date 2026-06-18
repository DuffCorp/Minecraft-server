# How to install Ballsnia 🇧🇦 (for the groupchat)

The **Ballsnia** Bosnian Cobblemon pack — install once, then it auto-updates.

You only need to do the full setup once. After that, just **launch the pack and
it updates itself** before the game opens.

## 1. Install Prism Launcher
Download and install **[Prism Launcher](https://prismlauncher.org/)**. Log in
with your normal Minecraft / Microsoft account.

## 2. Install Java 21
Install **Java 21** (e.g. [Adoptium Temurin 21](https://adoptium.net/)).
In Prism: **Settings → Java → Auto-detect** and pick the Java 21 option.

## 3. Download the modpack ZIP
Download the ZIP Jack sent you. **Do not unzip it.**

## 4. Import it into Prism
**Add Instance → Import → choose the ZIP.** Then click the new instance.

## 5. Set memory
Right-click the instance → **Edit → Settings → Memory**, then set max memory
based on your PC's total RAM:

| Your PC's RAM | Allocate to Minecraft (max) |
|---|---|
| 8 GB | 4096 MB |
| 16 GB | 6144–8192 MB |
| 32 GB | 8192–10240 MB |
| 64 GB | 10240–12288 MB |
| 128 GB | 12288–16384 MB |

Set minimum memory to about half the max. More than ~12–16 GB doesn't help a
single modded client — the spare RAM is better left for Windows and other apps.

## 6. Launch
Click **Launch**. The pack checks for updates first — let it finish, then
Minecraft opens.

## 7. Join the server
**Multiplayer → Add Server**, address:
```
mc.yourdomain.com
```
(or whatever IP/address Jack gives you, e.g. `SERVER-IP:25565`).

---

## Distant Horizons & shaders (optional, client-side)
Distant Horizons (huge view distance) and shaders are **client-side only** — they
do **not** affect joining the server, so you can turn them off freely.

- **Disable Distant Horizons:** right-click instance → **Edit → Mods** → untick
  **Distant Horizons**.
- **Shaders:** **Options → Video Settings → Shader Packs**. This pack uses
  **Iris + Sodium**, not OptiFine. **Do not install OptiFine** — it will break the pack.

---

## Rules (so nobody gets a "mod mismatch" error)
- Don't add random mods unless Jack says it's fine.
- Don't change the Minecraft or NeoForge version.
- Don't delete server-required mods.

If you see any of:
```
Mismatched mod channel list
Incompatible mod set
Server is missing mods
Client is missing mods
```
your pack is out of sync. Fix it:
1. Close Minecraft.
2. Open Prism Launcher.
3. Launch the pack again and **let the updater finish**.
4. Try joining again.

Still failing? Delete the instance and re-import the ZIP Jack sent you.

---

## 📌 Discord pinned message (copy-paste)

```
BALLSNIA MODPACK INSTALL

1. Install Prism Launcher
2. Install/select Java 21
3. Import the ZIP I sent
4. Allocate 6–8GB RAM
5. Launch the instance
6. Let the updater finish
7. Join: mc.yourdomain.com

Do not add OptiFine.
Do not change Minecraft/NeoForge version.
Do not manually delete mods.

Distant Horizons, minimap and shaders are client-side. You can disable them in:
Prism > Edit Instance > Mods

If you get a mod mismatch error:
Close Minecraft, relaunch the pack, let it update, then try again.
```
