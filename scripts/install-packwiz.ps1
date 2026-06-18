# =============================================================================
#  install-packwiz.ps1
#  Installs packwiz via Go and makes sure it is on your PATH.
#  Run this ONCE. Re-run it any time you want to update packwiz.
#
#  Usage (from this folder, in PowerShell):
#     .\scripts\install-packwiz.ps1
# =============================================================================

$ErrorActionPreference = "Stop"

Write-Host "==> Checking for Go..." -ForegroundColor Cyan
$go = Get-Command go -ErrorAction SilentlyContinue
if (-not $go) {
    Write-Host "Go is not installed." -ForegroundColor Red
    Write-Host "Install it from https://go.dev/dl/ (Windows version), then re-open PowerShell and run this again."
    exit 1
}
go version

Write-Host "`n==> Installing packwiz (this compiles from source, give it a minute)..." -ForegroundColor Cyan
go install github.com/packwiz/packwiz@latest

# Work out where 'go install' put the binary
$goBin = (& go env GOBIN)
if ([string]::IsNullOrWhiteSpace($goBin)) {
    $goBin = Join-Path (& go env GOPATH) "bin"
}
Write-Host "==> packwiz installed to: $goBin" -ForegroundColor Green

# Add Go's bin folder to the USER PATH if it isn't already there
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$goBin*") {
    Write-Host "==> Adding $goBin to your user PATH..." -ForegroundColor Cyan
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$goBin", "User")
    Write-Host "    Done. CLOSE and RE-OPEN PowerShell for it to take effect." -ForegroundColor Yellow
} else {
    Write-Host "==> $goBin is already on your PATH." -ForegroundColor Green
}

# Make it usable in THIS session too
$env:Path = "$env:Path;$goBin"

Write-Host "`n==> Verifying..." -ForegroundColor Cyan
& "$goBin\packwiz.exe" --version
Write-Host "`nDone. Next run:  .\scripts\build-pack.ps1" -ForegroundColor Green
