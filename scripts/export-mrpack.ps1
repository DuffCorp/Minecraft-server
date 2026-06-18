# =============================================================================
#  export-mrpack.ps1
#  Refreshes the pack (in pack/) and exports a .mrpack into dist/ that you can
#  import into Prism Launcher (Add Instance -> Import) to TEST before sharing.
#
#     .\scripts\export-mrpack.ps1
# =============================================================================

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
$DistDir = Join-Path $repo "dist"
if (-not (Test-Path (Join-Path $PackDir "pack.toml"))) {
    throw "No pack yet. Run .\scripts\build-pack.ps1 first."
}
New-Item -ItemType Directory -Force -Path $DistDir | Out-Null
$startLoc = Get-Location
Set-Location $PackDir

Write-Host "==> Refreshing..." -ForegroundColor Cyan
& $PW refresh

$out = Join-Path $DistDir "Ballsnia.mrpack"
Write-Host "==> Exporting -> $out" -ForegroundColor Cyan
& $PW modrinth export -o $out

if (Test-Path $out) {
    Write-Host "`nExported: $out" -ForegroundColor Green
    Write-Host "Import it in Prism Launcher:  Add Instance -> Import -> choose this .mrpack" -ForegroundColor Green
} else {
    Write-Host "No .mrpack produced - check the output above for errors." -ForegroundColor Yellow
}
Set-Location $startLoc
