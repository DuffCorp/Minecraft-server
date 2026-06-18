# =============================================================================
#  update-pack.ps1
#  Add or update a mod (in pack/), refresh, then optionally commit & push so
#  BOTH your friends' launchers and the Coolify server pull the change.
#
#  Add a new mod:        .\scripts\update-pack.ps1 -Add some-modrinth-slug
#  Just update existing: .\scripts\update-pack.ps1 -UpdateAll
#  Update + push:        .\scripts\update-pack.ps1 -UpdateAll -Push
# =============================================================================

param(
    [string]$Add,
    [switch]$UpdateAll,
    [switch]$Push,
    [string]$Message = "Update modpack"
)

$ErrorActionPreference = "Stop"

function Resolve-Packwiz {
    $pw = Get-Command packwiz -ErrorAction SilentlyContinue
    if ($pw) { return "packwiz" }
    $goBin = (& go env GOBIN)
    if ([string]::IsNullOrWhiteSpace($goBin)) { $goBin = Join-Path (& go env GOPATH) "bin" }
    $candidate = Join-Path $goBin "packwiz.exe"
    if (Test-Path $candidate) { return $candidate }
    throw "packwiz not found. Run .\scripts\install-packwiz.ps1 first."
}
$PW = Resolve-Packwiz

$repo    = Split-Path -Parent $PSScriptRoot
$PackDir = Join-Path $repo "pack"
if (-not (Test-Path (Join-Path $PackDir "pack.toml"))) {
    throw "No pack yet. Run .\scripts\build-pack.ps1 first."
}
$startLoc = Get-Location
Set-Location $PackDir

if ($Add)       { Write-Host "==> Adding $Add..." -ForegroundColor Cyan; & $PW modrinth add $Add -y }
if ($UpdateAll) { Write-Host "==> Updating all mods..." -ForegroundColor Cyan; & $PW update --all -y }

Write-Host "==> Refreshing..." -ForegroundColor Cyan
& $PW refresh

if ($Push) {
    Write-Host "==> Committing & pushing..." -ForegroundColor Cyan
    Set-Location $repo
    git add .
    git commit -m "$Message"
    git push
    Write-Host "`nPushed. Now: restart the Coolify server, and tell friends to relaunch their pack." -ForegroundColor Green
} else {
    Write-Host "`nDone. Review changes, then commit & push from the repo root when ready:" -ForegroundColor Green
    Write-Host "    git add . ; git commit -m `"$Message`" ; git push" -ForegroundColor Gray
}
Set-Location $startLoc
