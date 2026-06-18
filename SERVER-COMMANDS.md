# Server commands & admin reference

Run these from the **Coolify container terminal/console** (or in-game once you're
OP). In Coolify: open the `cobblemon` resource → **Terminal**.

## Whitelist (stop randoms joining)
The whitelist is enabled in `docker-compose.yml`
(`ENABLE_WHITELIST` / `ENFORCE_WHITELIST`). Manage who's on it:

```
whitelist add JackDuffy
whitelist add FriendOne
whitelist add FriendTwo
whitelist reload
```

Other whitelist commands:
```
whitelist remove FriendUsername
whitelist list
whitelist on
whitelist off
```

You can also edit `/data/whitelist.json` directly, but commands are safer
(they avoid JSON formatting mistakes).

## Operators (admins)
```
op YourMinecraftUsername
deop SomeUsername
```
`OPS` in `docker-compose.yml` makes you an operator automatically on first start.

## First-run checklist (after the server boots)
```
whitelist add YourMinecraftUsername
op YourMinecraftUsername
```

## Pre-generate the world with Chunky (recommended)
Heavy worldgen + Pokémon spawning is smoother if you pre-generate. Once you're
in-game as OP:
```
/chunky radius 5000
/chunky start
```
Let it finish (you can keep playing). Check progress with `/chunky` and stop with
`/chunky pause`.

## Legendary datapacks
Drop datapack ZIPs into:
```
/data/world/datapacks/
```
Then restart the server or run `/reload`. (Many legendary addons in this pack are
full mods and need no datapack — only add datapacks the addon's page tells you to.)

## Useful
```
say Hello everyone           # broadcast a message
list                         # who's online
save-all                     # force a world save
stop                         # graceful shutdown (Coolify will restart it)
```
