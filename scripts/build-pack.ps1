# =============================================================================
#  build-pack.ps1
#  Builds the packwiz modpack inside  pack/  (keeps the repo root clean):
#    - writes a correct NeoForge 1.21.1 pack.toml directly (no flaky `init`)
#    - adds every mod
#    - marks client-only mods as side = "client"
#    - refreshes the index
#
#  Run AFTER install-packwiz.ps1 (re-open PowerShell first so packwiz is on PATH):
#     .\scripts\build-pack.ps1
#
#  Safe to re-run: packwiz skips mods that are already present.
# =============================================================================

$ErrorActionPreference = "Stop"

# --- Pack identity -----------------------------------------------------------
$PackName   = "Ballsnia"
$PackAuthor = "Jack Duffy"
$McVersion  = "1.21.1"
$NeoForge   = "21.1.233"   # latest NeoForge for MC 1.21.1 - bump this any time

# --- Helpers -----------------------------------------------------------------
function Resolve-Packwiz {
    $pw = Get-Command packwiz -ErrorAction SilentlyContinue
    if ($pw) { return "packwiz" }
    $goBin = (& go env GOBIN)
    if ([string]::IsNullOrWhiteSpace($goBin)) { $goBin = Join-Path (& go env GOPATH) "bin" }
    $candidate = Join-Path $goBin "packwiz.exe"
    if (Test-Path $candidate) { return $candidate }
    throw "packwiz not found. Run .\scripts\install-packwiz.ps1 first (and re-open PowerShell)."
}
function Write-Utf8NoBom([string]$Path, [string]$Text) {
    # TOML must NOT have a BOM - PS 5.1's Set-Content -Encoding utf8 adds one.
    [System.IO.File]::WriteAllText($Path, $Text, (New-Object System.Text.UTF8Encoding $false))
}

$PW = Resolve-Packwiz
Write-Host "==> Using packwiz: $PW" -ForegroundColor Cyan

# --- Work inside pack/ (created if missing) ----------------------------------
$repo    = Split-Path -Parent $PSScriptRoot
$PackDir = Join-Path $repo "pack"
New-Item -ItemType Directory -Force -Path $PackDir | Out-Null
$startLoc = Get-Location          # remember where the user was; restore at the end
Set-Location $PackDir
Write-Host "==> Pack dir: $PackDir" -ForegroundColor Cyan

# --- Create a correct pack.toml (only if one isn't already there) ------------
if (-not (Test-Path "pack.toml")) {
    Write-Host "`n==> Writing pack.toml (Minecraft $McVersion, NeoForge $NeoForge)..." -ForegroundColor Cyan
    Write-Utf8NoBom (Join-Path $PackDir "index.toml") "hash-format = `"sha256`"`n"
    $packToml = @"
name = "$PackName"
author = "$PackAuthor"
version = "1.0.0"
pack-format = "packwiz:1.1.0"

[index]
file = "index.toml"
hash-format = "sha256"
hash = ""

[versions]
minecraft = "$McVersion"
neoforge = "$NeoForge"
"@
    Write-Utf8NoBom (Join-Path $PackDir "pack.toml") $packToml
    & $PW refresh   # fills in the index hash
} else {
    $pt = Get-Content "pack.toml" -Raw
    if ($pt -notmatch 'neoforge' -or $pt -notmatch [Regex]::Escape($McVersion)) {
        Write-Host "`n!! Existing pack/pack.toml is NOT NeoForge $McVersion." -ForegroundColor Red
        Write-Host "   Delete the pack\ folder and re-run this script for a clean build." -ForegroundColor Yellow
        Set-Location $startLoc
        exit 1
    }
    Write-Host "`n==> pack.toml already present (NeoForge $McVersion), keeping it." -ForegroundColor Yellow
}

# --- Mod lists (verified Modrinth slugs) -------------------------------------
# Server + client mods (default side = "both"; the server installs these too).
$ServerMods = @(
    # Core
    "cobblemon",
    "create",
    # Cobblemon companions / legendaries / trainers
    "cobblemon-create-industries",          # Create automation for Cobblemon items
    "rctmod",                               # Radical Cobblemon Trainers (1500+ trainers)
    "rctapi",                               # Radical Cobblemon Trainers API
    "radical-gyms-cobblemon",               # gyms & structures for RCT trainers
    "zeta",                                 # library for Quark (auto-pulled by radical-gyms)
    "cobblemon-myths-and-legends-sidemod",  # Legendary & Mythical Pokemon spawns
    "cobblemon-spawn-notification",         # alerts on legendary/shiny spawns
    # Utility / QoL
    "jei",
    "jade",
    "appleskin",
    "waystones",
    "travelersbackpack",
    "sophisticated-backpacks",
    "sophisticated-core",
    "lootr",
    "simple-voice-chat",
    "clumps",
    # Worldgen / "more biomes"
    "terralith",
    "tectonic",
    "structory",
    "towns-and-towers",
    "natures-compass",
    "explorers-compass",
    # Performance / admin (server-safe)
    "modernfix",
    "ferrite-core",
    "spark",
    "chunky",

    # ===== Expansion pack =====
    # Transport / vehicles
    "immersive-aircraft",          # standalone planes & helicopters
    "create-aeronautics",          # Create-based aircraft (heavier; pulls Sable dep)
    # Create Aeronautics add-on suite (all ALPHA, build on Sable - test before live)
    "create-aeroworks",                       # gyroscopes, joysticks, servos, blocks
    "create-aeronautics-thrusters-and-things",# thrusters, bearings, control (Gadgets & Gizmos)
    "vs-hose-connectors",                     # transfer power/fluids/items between ships
    "small-ships",                 # sailable boats with cannons
    # Create tech add-ons
    "gears-n-kinetics",            # extra cogwheels/gears/kinetic parts (Create 6)
    "createaddition",              # electricity / energy bridge
    "create-new-age",              # power generation
    "create-power-loader",         # chunk-loading via contraptions
    "copycats",                    # Create: Copycats+
    "create-deco",                 # decoration blocks
    "slice-and-dice",              # recipe automation
    "create-connected",            # Create QoL tweaks
    "create-jetpack",              # wearable Create jetpack
    "create-big-cannons",          # cannons & artillery (can grief terrain)
    "create-enchantment-industry", # automate enchanting & XP (1.21.1 build is alpha)
    "create-dragons-plus",         # required library for Enchantment Industry's alpha build
    # Cobblemon add-ons
    "cobblemon-mega-showdown",     # Mega / Z-moves / Tera / Dynamax + fusions (built for 1.7.3)
    "poketwo",                     # Lost Lore - Armored Mewtwo + Shadow Lugia/Mewtwo (NeoForge mod; needs ATM x MSD datapack)
    "cobbledollars",               # currency + NPC merchants
    "cobblemon-counter",           # KO / catch / shiny streak counters
    "cobblemon-pokenav",           # DexNav-style nearby-Pokemon tracker
    "cobblemon-integrations",      # cross-mod hooks (Create etc.)
    # Multiplayer QoL
    "corpse",                      # death graves
    "open-parties-and-claims",     # land claims / anti-grief (Xaero); shows on minimap
    "trade-cycling",               # refresh villager trades

    # ===== Expansion pack 2 (content / adventure / multiplayer) =====
    # Cobblemon gameplay
    # (cobblemon-quests removed: requires FTB Quests, which is CurseForge-only)
    "cobblemon-gym-badges",                 # gym badges + leader progression
    "cobblemon-trainer-structures",         # battleable trainer NPC structures
    "cobblepedia",                          # in-game Pokedex
    "simpletms-tms-and-trs-for-cobblemon",  # TMs/TRs to teach moves
    "cobblemon-fight-or-flight-reborn",     # wild Pokemon aggro/flee AI
    "cobblemon-capture-xp",                 # player XP for catching
    # Create depth & economy
    "numismatics",                 # coins / bank / ATMs (Create economy)
    "create-stuff-additions",      # jetpacks, exoskeletons, gadgets
    "create-garnished",            # bigger crops + farm automation
    "create-confectionery",        # chocolate / candy chains
    "create-diesel-generators",    # diesel / ethanol engines + refining
    "create-ironworks",            # hammers, alloys, metalworking
    # Cooking
    "farmers-delight",             # cooking overhaul
    "create-central-kitchen",      # automate Farmer's Delight with Create
    # Group PvE: bosses & dungeons
    "l_enders-cataclysm",               # epic co-op bosses + loot
    "bosses-of-mass-destruction-forge", # skill-based boss fights
    "when-dungeons-arise",              # huge hand-built dungeons
    "yungs-better-dungeons",            # overhauled bigger dungeons (pulls yungs-api)
    "idas",                             # Integrated Dungeons & Structures
    "dungeons-and-taverns",             # expanded villages / outposts / dungeons
    "tide",                             # deep fishing / ocean overhaul
    "aquaculture",                      # fishing overhaul
    # Classic dimension
    "aether",                           # The Aether - floating-island dimension (classic)
    # Building / decoration
    "supplementaries",             # decorative + functional blocks (pulls moonlight)
    "macaws-furniture",            # furniture
    "macaws-roofs",                # sloped roofs
    "macaws-bridges",              # bridges
    "handcrafted",                 # cottagecore furniture set
    "chipped",                     # thousands of cosmetic block variants
    "framedblocks",                # camo frames / custom shapes
    "every-compat",                # building blocks for all modded woods
    # Economy social / quests
    # (sdm-shop + sdm-core removed: SDMShop also needs FTB Library, CurseForge-only)
    # (bountiful removed: beta-only + undeclared kambrik dependency; revisit later)
    # (daily-quests removed: its HUD takes up too much screen space)
    # Server performance (low-risk bundle)
    "lithium",                     # game-logic optimization
    "noisium",                     # faster worldgen
    "servercore",                  # dynamic server-side perf tuning
    # (scalablelux removed: hard-incompatible with Sable / Create: Aeronautics)

    # ===== Expansion pack 3 (dimensions / adventure / building) =====
    "eternal-starlight",           # magical starlight adventure dimension
    "deeperdarker",                # expands Deep Dark + adds "The Otherside" dimension
    "the-undergarden",             # forgotten underground dimension (biomes/mobs/ores)
    "the-bumblezone",              # quirky bee dimension
    "dimensional-dungeons",        # procedural, repeatable dungeon dimension (server-friendly)
    "legendary-monuments",         # Cobblemon legendary-summoning structures
    "connected-glass",             # seamless connected glass textures
    # Combat (heavy - griefing risk on survival; see notes)
    "scorched-guns-neoforged",     # 100+ self-contained guns incl. snipers (unofficial 1.21.1 port)
    "nuclearism"                   # nuclear bomb + radiation (content mod; replaces bmnw, no menu mixins)
    # bmnw removed: its title-screen SplashRenderer mixin hard-conflicts with The Aether
)

# Client-only mods (forced to side = "client" so the server skips them).
$ClientMods = @(
    "sodium",
    "iris",
    # distanthorizons intentionally NOT here - set to side="both" for server-side
    # LOD sharing (so pre-generated/visited chunks show for everyone). To REVERT:
    # re-add "distanthorizons" here AND set side="client" in mods/distanthorizons.pw.toml.
    "xaeros-minimap",
    "xaeros-world-map",
    "betterf3",
    "controlling",
    "mouse-tweaks",
    "controlify",                  # controller / gamepad support (client-side)
    # Resource packs (enable in Options > Resource Packs)
    "minis-cobblemon-icons",       # Pokemon sprite icons on Xaero's minimap
    "vanilla-connected-glass"      # seamless connected textures for vanilla glass + panes
)

# Server-only tools/perf (clients don't need them; keeps the client pack lean).
# ONLY put genuinely standalone server-side mods here - NEVER a library, or a
# client mod that depends on it would be missing it (the lithostitched trap).
$ServerOnly = @(
    "servercore",  # server-side performance tuning
    "noisium"      # server-side worldgen speedup
)

$failed = @()

function Add-Mods($list, $label) {
    Write-Host "`n==> Adding $label mods..." -ForegroundColor Cyan
    foreach ($slug in $list) {
        Write-Host "    + $slug" -ForegroundColor Gray
        try {
            # -y = global non-interactive flag: auto-accepts dependency prompts.
            # Safe here because every slug above is exact, so add resolves directly
            # (no search) - it won't silently pick a wrong project.
            & $PW modrinth add $slug -y 2>&1 | Out-Host
            if ($LASTEXITCODE -ne 0) { throw "exit $LASTEXITCODE" }
        } catch {
            Write-Host "    ! could not add '$slug' automatically" -ForegroundColor Yellow
            $script:failed += $slug
        }
    }
}

Add-Mods $ServerMods "server + client"
Add-Mods $ClientMods "client-only"

# --- CurseForge-only mods (not on Modrinth) ----------------------------------
# Verified: packwiz resolves these without an API key, and they allow third-party
# distribution so the server + friends auto-download them. side defaults to both.
$CurseForgeMods = @(
    "the-twilight-forest",         # The Twilight Forest - adventure dimension (CF only)
    "framework",                   # MrCrayfish's Framework - required by Scorched Guns (CF only)
    # Create Aeronautics add-on suite (CF; ALPHA; build on Sable - test before live)
    "create-aeronauticstoolgun",              # blueprint/manipulation toolgun (exact CF mod, no hyphen)
    "create-cardan-shafts",                   # mechanical cardan shafts
    "create-aeronautics-transmission-linkage",# transmission & linkage
    "create-tracks",                          # track system
    "create-propulsion-simulated",            # propulsion (pulls Aeronautics/Sable/Create - already present)
    "create-aeronautics-delivery-required"    # delivery quests - PULLS KubeJS+Rhino+LDLib+PonderJS
)
if ($CurseForgeMods.Count -gt 0) {
    Write-Host "`n==> Adding CurseForge-only mods..." -ForegroundColor Cyan
    foreach ($slug in $CurseForgeMods) {
        Write-Host "    + $slug" -ForegroundColor Gray
        try {
            & $PW curseforge add $slug -y 2>&1 | Out-Host
            if ($LASTEXITCODE -ne 0) { throw "exit $LASTEXITCODE" }
        } catch {
            Write-Host "    ! could not add '$slug' from CurseForge" -ForegroundColor Yellow
            $script:failed += $slug
        }
    }
}

# --- URL-pinned resource packs (datapack-style Cobblemon addons) -------------
# AllTheMons x Mega Showdown is a datapack/resourcepack (no mod build), so packwiz
# can't 'modrinth add' it. Clients get it as a RESOURCE PACK here; the SERVER gets
# the same zip as a DATAPACK via the DATAPACKS env in docker-compose.yml. Lost Lore
# (poketwo, in $ServerMods) needs ATM x MSD present for Mewtwo/Lugia + forms.
$UrlResourcepacks = @(
    @{ name = "atm-x-msd";   url = "https://cdn.modrinth.com/data/odZZdRCE/versions/VhwUZj8K/ATM%20x%20MSD%20%5Bv3.6.1%5D.zip" }
    @{ name = "bottlecaps";  url = "https://cdn.modrinth.com/data/H8sPAjjY/versions/LpUeBeOr/BottleCaps%201.1.zip" }  # Silver/Gold Bottle Caps - IV hyper training (datapack; also in DATAPACKS env)
)
if ($UrlResourcepacks.Count -gt 0) {
    Write-Host "`n==> Adding URL-pinned resource packs..." -ForegroundColor Cyan
    foreach ($rp in $UrlResourcepacks) {
        Write-Host "    + $($rp.name)" -ForegroundColor Gray
        & $PW url add $rp.name $rp.url --meta-folder resourcepacks --force 2>&1 | Out-Host
    }
}

# --- Remove mods we've intentionally dropped (cleans up earlier builds) ------
# Tried then removed for broken deps / conflicts. Both packwiz-remove AND a file
# delete, so re-running an old pack actually drops them. No-op on a fresh build.
$Remove = @(
    "bmnw",               # title-screen SplashRenderer mixin hard-conflicts with The Aether (kept Aether)
    "cobblemon-quests",   # requires FTB Quests (CurseForge-only)
    "bountiful",          # beta + undeclared kambrik dependency
    "scalablelux",        # hard-incompatible with Sable / Create: Aeronautics
    "worldedit",          # not used
    "sdm-shop",           # also needs FTB Library (CurseForge-only) - unsatisfiable via Modrinth
    "sdm-core",           # only needed by sdm-shop
    "daily-quests"        # removed: HUD takes up too much screen space
)
Write-Host "`n==> Removing dropped mods (if present)..." -ForegroundColor Cyan
foreach ($slug in $Remove) {
    & $PW remove $slug 2>&1 | Out-Null
    Remove-Item (Join-Path "mods" "$slug.pw.toml") -ErrorAction SilentlyContinue
}

# --- Pin version-sensitive Cobblemon addons ----------------------------------
# Some Cobblemon sidemods' LATEST build targets a newer Cobblemon than the
# stable release the rest of the pack uses. e.g. cobblemon-tim-core's latest
# needs Cobblemon 1.8.0-SNAPSHOT, but stable (and everything else here) is 1.7.3
# -> crashes. We write the matching version's metadata file directly (most
# reliable - no dependence on packwiz's --version-id syntax) and OMIT the
# [update] section so `update --all` can't drag it forward again. When Cobblemon
# 1.8.0 becomes stable, delete these .pw.toml overrides and rebuild.
$Pinned = @(
    @{  # Cobblemon Tim Core - the 1.7.3 build (satisfies spawn_notification >= 1.31.0)
        slug     = "cobblemon-tim-core"
        name     = "Cobblemon Tim Core"
        filename = "timcore-neoforge-1.7.3-1.32.0.jar"
        url      = "https://cdn.modrinth.com/data/lVP9aUaY/versions/QQO61rRS/timcore-neoforge-1.7.3-1.32.0.jar"
        sha512   = "ef26aca74367631f2202bef22319f61cfe32845d7cef6a4319c25b3731380e061f735b6d7db6b063a2f70b56bf685b07bc6b141a30ff543d345f4d9f44511629"
    }
)
if ($Pinned.Count -gt 0) {
    Write-Host "`n==> Pinning Cobblemon-version-sensitive addons..." -ForegroundColor Cyan
    foreach ($p in $Pinned) {
        $toml = @"
name = "$($p.name)"
filename = "$($p.filename)"
side = "both"

[download]
hash-format = "sha512"
hash = "$($p.sha512)"
url = "$($p.url)"
"@
        Write-Utf8NoBom (Join-Path $PackDir "mods\$($p.slug).pw.toml") $toml
        Write-Host "    pinned $($p.slug) -> $($p.filename)" -ForegroundColor Gray
    }
}

# --- Set sides explicitly ----------------------------------------------------
# packwiz auto-detects each mod's side from Modrinth metadata, but that mis-tags
# shared libraries (e.g. lithostitched -> "server", searchables -> "client").
# A library then goes missing on a side a dependent needs -> hard crash
# ("Mod X requires Y ... is not installed"). So we OVERRIDE every mod:
#   - the curated rendering/UI mods  -> side = "client"
#   - EVERYTHING else (mods + all libraries) -> side = "both"
# That way neither the client nor the server is ever missing a required mod.
Write-Host "`n==> Setting mod sides (UI mods = client, everything else = both)..." -ForegroundColor Cyan
function Set-Side([string]$File, [string]$Side) {
    $content = Get-Content $File -Raw
    if ($content -match '(?m)^\s*side\s*=') {
        $content = [Regex]::Replace($content, '(?m)^\s*side\s*=.*$', "side = `"$Side`"")
    } else {
        $content = $content.TrimEnd() + "`nside = `"$Side`"`n"
    }
    Write-Utf8NoBom $File $content
}
foreach ($f in Get-ChildItem -Path "mods" -Filter "*.pw.toml") {
    $stem = $f.Name -replace '\.pw\.toml$', ''
    if ($ClientMods -contains $stem) {
        Set-Side $f.FullName "client"
        Write-Host "    client: $stem" -ForegroundColor Gray
    } elseif ($ServerOnly -contains $stem) {
        Set-Side $f.FullName "server"
        Write-Host "    server: $stem" -ForegroundColor Gray
    } else {
        Set-Side $f.FullName "both"
    }
}

# --- Refresh the index -------------------------------------------------------
Write-Host "`n==> Refreshing pack index..." -ForegroundColor Cyan
& $PW refresh

Write-Host "`n=============================================================" -ForegroundColor Green
Write-Host " Pack built in: $PackDir" -ForegroundColor Green
if ($failed.Count -gt 0) {
    Write-Host "`n Could NOT add automatically (slug may have changed on Modrinth):" -ForegroundColor Yellow
    $failed | ForEach-Object { Write-Host "     - $_" -ForegroundColor Yellow }
    Write-Host " Add each by name, then re-run packwiz refresh, e.g. from pack\:" -ForegroundColor Yellow
    Write-Host "     packwiz modrinth add `"<search term>`"" -ForegroundColor Yellow
}
Write-Host "`n Next: test locally  ->  .\scripts\export-mrpack.ps1" -ForegroundColor Green
Write-Host "=============================================================" -ForegroundColor Green
Set-Location $startLoc            # back to where you started, not pack/
