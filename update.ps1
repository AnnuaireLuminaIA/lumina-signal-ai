# Lumina Signal - update local clone from a downloaded ZIP
# Usage:
#   cd $env:USERPROFILE\LuminaSignal\lumina-signal-ai
#   .\update.ps1
# Optional:
#   .\update.ps1 -ZipPath "C:\path\to\lumina-signal.zip"

param(
  [string]$ZipPath = "$env:USERPROFILE\Downloads\lumina-signal.zip"
)

$ErrorActionPreference = "Stop"
$RepoRoot = $PSScriptRoot

if (-not (Test-Path (Join-Path $RepoRoot ".git"))) {
  Write-Host "ERROR: Run this script from the git clone folder (lumina-signal-ai)." -ForegroundColor Red
  exit 1
}

if (-not (Test-Path $ZipPath)) {
  Write-Host "ERROR: ZIP not found: $ZipPath" -ForegroundColor Red
  Write-Host "Download lumina-signal.zip into Downloads or pass -ZipPath" -ForegroundColor Yellow
  exit 1
}

Write-Host "-> git pull" -ForegroundColor Cyan
git -C $RepoRoot pull origin main

$Temp = Join-Path $env:TEMP ("lumina-upd-" + [guid]::NewGuid().ToString("N").Substring(0, 8))
New-Item -ItemType Directory -Path $Temp | Out-Null

try {
  Write-Host "-> Expand ZIP" -ForegroundColor Cyan
  Expand-Archive -Path $ZipPath -DestinationPath $Temp -Force

  $Src = Join-Path $Temp "lumina-signal"
  if (-not (Test-Path $Src)) {
    $Src = $Temp
  }

  Write-Host "-> Copy files into repo" -ForegroundColor Cyan
  $paths = @(
    "prototypes",
    "data",
    "scripts",
    "assets",
    "c",
    "legal",
    "sitemap.xml",
    ".github",
    "docs",
    "index.html",
    "about.html",
    "favicon.svg",
    "README.md",
    ".nojekyll",
    "update.ps1"
  )

  foreach ($rel in $paths) {
    $from = Join-Path $Src $rel
    $to = Join-Path $RepoRoot $rel
    if (Test-Path $from) {
      if (Test-Path $from -PathType Container) {
        if (-not (Test-Path $to)) {
          New-Item -ItemType Directory -Path $to | Out-Null
        }
        Copy-Item -Path (Join-Path $from "*") -Destination $to -Recurse -Force
      }
      else {
        Copy-Item -Path $from -Destination $to -Force
      }
      Write-Host ("  + " + $rel)
    }
  }

  Set-Location $RepoRoot
  Write-Host "-> git status" -ForegroundColor Cyan
  git status --short

  $pending = git status --porcelain
  if ([string]::IsNullOrWhiteSpace($pending)) {
    Write-Host "No changes to commit." -ForegroundColor Yellow
  }
  else {
    $msg = "chore: update from ZIP " + (Get-Date -Format "yyyy-MM-dd HH:mm")
    git add -A
    git commit -m $msg
    Write-Host "-> git push" -ForegroundColor Cyan
    git push origin main
    Write-Host "Done. Wait 1-2 min then Ctrl+F5 on the site." -ForegroundColor Green
  }
}
finally {
  if (Test-Path $Temp) {
    Remove-Item -Recurse -Force $Temp -ErrorAction SilentlyContinue
  }
}
