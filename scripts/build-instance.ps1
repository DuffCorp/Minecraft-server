# =============================================================================
#  build-instance.ps1
#  Builds a ready-to-import Prism/MultiMC instance ZIP in dist/, WITH the
#  Ballsnia Pokéball icon baked in and the packwiz auto-updater pre-wired.
#  This is the file you send friends - they just "Add Instance -> Import from zip".
#
#  Usage (pass YOUR GitHub Pages pack URL):
#     .\scripts\build-instance.ps1 -PackUrl "https://YOURNAME.github.io/ballsnia-pack/pack/pack.toml"
#
#  If you omit -PackUrl it tries to read PACKWIZ_URL from docker-compose.yml.
#  Optional: -MinMemMB 4096 -MaxMemMB 8192
#
#  IMPORTANT: import the resulting ZIP into your own Prism once to confirm it
#  launches and shows the Pokéball, THEN forward it to friends.
# =============================================================================

param(
    [string]$PackUrl,
    [int]$MinMemMB = 8192,
    [int]$MaxMemMB = 10240,
    [string]$InstanceName = "Ballsnia",
    [string]$ServerAddress = "ballsnia.jack-duffy.com:25565"
)

$ErrorActionPreference = "Stop"

# Must match build-pack.ps1
$McVersion = "1.21.1"
$NeoForge  = "21.1.233"
$IconKey   = "ballsnia"
$BootstrapUrl = "https://github.com/packwiz/packwiz-installer-bootstrap/releases/latest/download/packwiz-installer-bootstrap.jar"

function Write-Utf8NoBom([string]$Path, [string]$Text) {
    [System.IO.File]::WriteAllText($Path, $Text, (New-Object System.Text.UTF8Encoding $false))
}

$repo    = Split-Path -Parent $PSScriptRoot
$DistDir = Join-Path $repo "dist"
$IconSrc = Join-Path $repo "assets\ballsnia-icon.png"

# --- Resolve the pack URL ----------------------------------------------------
if ([string]::IsNullOrWhiteSpace($PackUrl)) {
    $compose = Get-Content (Join-Path $repo "docker-compose.yml") -Raw
    $m = [Regex]::Match($compose, 'PACKWIZ_URL:\s*"([^"]+)"')
    if ($m.Success) { $PackUrl = $m.Groups[1].Value }
}
if ([string]::IsNullOrWhiteSpace($PackUrl) -or $PackUrl -match 'YOUR_USERNAME') {
    Write-Host "!! No real pack URL." -ForegroundColor Red
    Write-Host "   Pass it explicitly (use your GitHub username):" -ForegroundColor Yellow
    Write-Host '   .\scripts\build-instance.ps1 -PackUrl "https://YOURNAME.github.io/ballsnia-pack/pack/pack.toml"' -ForegroundColor Gray
    exit 1
}
if (-not (Test-Path $IconSrc)) { throw "Missing $IconSrc - run: python scripts/make-server-icon.py" }
Write-Host "==> Pack URL: $PackUrl" -ForegroundColor Cyan

# --- Assemble the instance folder --------------------------------------------
$build = Join-Path $DistDir "_instance"
if (Test-Path $build) { Remove-Item $build -Recurse -Force }
$mcDir = Join-Path $build ".minecraft"
New-Item -ItemType Directory -Force -Path $mcDir | Out-Null

# instance.cfg
$instanceCfg = @"
InstanceType=OneSix
name=$InstanceName
iconKey=$IconKey
OverrideCommands=true
PreLaunchCommand="`$INST_JAVA" -jar packwiz-installer-bootstrap.jar $PackUrl
OverrideMemory=true
MinMemAlloc=$MinMemMB
MaxMemAlloc=$MaxMemMB
"@
Write-Utf8NoBom (Join-Path $build "instance.cfg") $instanceCfg

# mmc-pack.json (NeoForge on 1.21.1; Prism resolves the rest on import)
$mmcPack = @"
{
    "components": [
        {
            "important": true,
            "uid": "net.minecraft",
            "version": "$McVersion"
        },
        {
            "uid": "net.neoforged",
            "version": "$NeoForge"
        }
    ],
    "formatVersion": 1
}
"@
Write-Utf8NoBom (Join-Path $build "mmc-pack.json") $mmcPack

# icon at instance root, named to match iconKey (this is what makes it travel)
Copy-Item $IconSrc (Join-Path $build "$IconKey.png") -Force

# packwiz updater
Write-Host "==> Downloading packwiz-installer-bootstrap.jar..." -ForegroundColor Cyan
try {
    Invoke-WebRequest -Uri $BootstrapUrl -OutFile (Join-Path $mcDir "packwiz-installer-bootstrap.jar") -UseBasicParsing
} catch {
    throw "Could not download packwiz-installer-bootstrap.jar. Download it manually from`n  $BootstrapUrl`nand place it in $mcDir, then re-run."
}

# Pre-enable any resource packs the pack ships (so friends get them on by default).
# Reads the real filenames from pack/resourcepacks/*.pw.toml so it stays correct.
$rpMeta = Join-Path $repo "pack\resourcepacks"
$rpFiles = @()
if (Test-Path $rpMeta) {
    Get-ChildItem $rpMeta -Filter "*.pw.toml" | ForEach-Object {
        $m = [Regex]::Match((Get-Content $_.FullName -Raw), 'filename\s*=\s*"([^"]+)"')
        if ($m.Success) { $rpFiles += $m.Groups[1].Value }
    }
}
if ($rpFiles.Count -gt 0) {
    $entries = ($rpFiles | ForEach-Object { '"file/' + $_ + '"' }) -join ','
    Write-Utf8NoBom (Join-Path $mcDir "options.txt") ('resourcePacks:["vanilla",' + $entries + "]`n")
    Write-Host "==> Pre-enabled resource packs: $($rpFiles -join ', ')" -ForegroundColor Cyan
}

# Pre-add the server to the multiplayer list (servers.dat = raw, UNcompressed NBT).
if (-not [string]::IsNullOrWhiteSpace($ServerAddress)) {
    $enc = [System.Text.Encoding]::UTF8
    $nm = $enc.GetBytes($InstanceName)
    $ip = $enc.GetBytes($ServerAddress)
    $d  = New-Object System.Collections.Generic.List[byte]
    foreach ($x in 10,0,0)  { $d.Add([byte]$x) }                                     # root TAG_Compound, empty name
    $d.Add([byte]9); $d.Add([byte]0); $d.Add([byte]7); $d.AddRange($enc.GetBytes("servers"))  # TAG_List "servers"
    $d.Add([byte]10)                                                                 # list element type = TAG_Compound
    foreach ($x in 0,0,0,1) { $d.Add([byte]$x) }                                     # list length = 1
    $d.Add([byte]8); $d.Add([byte]0); $d.Add([byte]4); $d.AddRange($enc.GetBytes("name"))     # TAG_String "name"
    $d.Add([byte](($nm.Length -shr 8) -band 0xFF)); $d.Add([byte]($nm.Length -band 0xFF)); $d.AddRange($nm)
    $d.Add([byte]8); $d.Add([byte]0); $d.Add([byte]2); $d.AddRange($enc.GetBytes("ip"))       # TAG_String "ip"
    $d.Add([byte](($ip.Length -shr 8) -band 0xFF)); $d.Add([byte]($ip.Length -band 0xFF)); $d.AddRange($ip)
    $d.Add([byte]0)                                                                  # TAG_End (element)
    $d.Add([byte]0)                                                                  # TAG_End (root)
    [System.IO.File]::WriteAllBytes((Join-Path $mcDir "servers.dat"), $d.ToArray())
    Write-Host "==> Pre-added server '$InstanceName' -> $ServerAddress" -ForegroundColor Cyan
}

# --- Zip it (contents at the zip root) ---------------------------------------
$zip = Join-Path $DistDir "$InstanceName-Prism.zip"
if (Test-Path $zip) { Remove-Item $zip -Force }
$items = @(
    (Join-Path $build "instance.cfg"),
    (Join-Path $build "mmc-pack.json"),
    (Join-Path $build "$IconKey.png"),
    (Join-Path $build ".minecraft")
)
Compress-Archive -Path $items -DestinationPath $zip -Force
Remove-Item $build -Recurse -Force

# Publish a copy into download/ so GitHub Pages serves it for the friend install page
$pub = Join-Path $repo "download"
New-Item -ItemType Directory -Force -Path $pub | Out-Null
Copy-Item $zip (Join-Path $pub "$InstanceName-Prism.zip") -Force
Write-Host "==> Published download\$InstanceName-Prism.zip (commit + push so the install page can serve it)" -ForegroundColor Cyan

Write-Host "`n=============================================================" -ForegroundColor Green
Write-Host " Built: $zip" -ForegroundColor Green
Write-Host " 1. In Prism: Add Instance -> Import from zip -> pick this file." -ForegroundColor Green
Write-Host " 2. Confirm it shows the Pokéball and launches." -ForegroundColor Green
Write-Host " 3. Then send the ZIP to friends - icon + auto-updater included." -ForegroundColor Green
Write-Host "=============================================================" -ForegroundColor Green
