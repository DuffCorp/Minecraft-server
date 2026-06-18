# Ballsnia network plan (for later)

**Current state:** one server — the Ballsnia Cobblemon NeoForge server (`docker-compose.yml`).
**Decision (2026-06-18):** keep a single server for now; expand into a network later.
**Wishlist:** minigames · creative/build · PvP · lobby/hub.

When you're ready, just say *"set up the minigames server"* (etc.) and I'll write the
Coolify compose + config for that one.

---

## The modded caveat (read first)
The usual hub tech — **Velocity/BungeeCord proxies** and **minigame plugins** — is built
for **Paper/Spigot**, not modded. **NeoForge behind a proxy is poorly supported and flaky
on 1.21.1**, and there's no off-the-shelf NeoForge "hub portal" mod. So a *seamless* portal
hub that includes the modded Cobblemon server is the hard, fragile path.

Good news: a **NeoForge client can connect to a vanilla/Paper server** (vanilla protocol) —
the mods just sit idle there. So Paper-based minigames/lobby servers work for your friends
without them changing anything.

## Two ways to run the network
1. **Separate servers, players pick from their list (recommended).**
   Each world is its own Coolify resource on its own port/subdomain
   (`mc.ballsnia.x`, `games.ballsnia.x`, …). No proxy, nothing flaky. Players just have a
   few entries in their multiplayer list.
2. **Velocity proxy + seamless switching.** One address, walk-through-portal switching.
   Works beautifully for the **Paper** servers; the **modded** Ballsnia server behind it is
   the part that fights you. Only worth it if seamless switching really matters.

---

## Per-server plan

### Minigames — Paper server
- Coolify: new Docker Compose, `itzg/minecraft-server` with `TYPE: "PAPER"`, port e.g. `25566`.
- Plugins (drop into `/plugins`): a minigames suite + multiverse-style world manager; e.g.
  parkour, spleef, and arena plugins. (I'll pick current, maintained ones when we build it.)
- Players join `games.ballsnia.x` — modded client connects fine, mods idle.

### Creative / build world
- Easiest: a **second NeoForge server using the same Ballsnia pack** set to creative
  (`MODE: "creative"`, separate world/volume) — same blocks, relaxed building.
- Or a **Paper creative** server with WorldEdit + plot/claim plugins if you want lighter
  weight and easier moderation.

### PvP arena
- Either a **Paper arena** (PvP plugins, kits, no grief) — simplest;
- Or a **modded NeoForge** PvP server reusing your combat content (Cataclysm weapons,
  Create Big Cannons) if you want PvP *with* the mods.

### Lobby / hub
- Only really makes sense with the **Velocity** route (option 2): a small Paper lobby with a
  server-selector (compass GUI / NPCs / portals). Without a proxy, the "lobby" is just one
  more server in the list.

---

## Suggested rollout order
1. ✅ Get the single Cobblemon server stable + fun (current focus).
2. Add a **Paper minigames** server (separate address) — biggest fun-per-effort, low risk.
3. Add **creative/build** if the group wants it.
4. Only then consider a **Velocity proxy + lobby** for seamless switching, accepting the
   modded-backend fiddliness.
