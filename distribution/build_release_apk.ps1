# Builds release APK and copies it into distribution/hosting for Firebase direct download.
# Run from repo root:  powershell -ExecutionPolicy Bypass -File distribution/build_release_apk.ps1

$ErrorActionPreference = "Stop"
Set-Location (Split-Path -Parent $PSScriptRoot)

$hostingDir = Join-Path $PSScriptRoot "hosting"
if (-not (Test-Path $hostingDir)) {
  New-Item -ItemType Directory -Force -Path $hostingDir | Out-Null
}

Write-Host "Building release APK (this may take several minutes)..." -ForegroundColor Cyan
flutter build apk --release
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$src = Join-Path $PWD "build\app\outputs\flutter-apk\app-release.apk"
$dest = Join-Path $hostingDir "FinShe-release.apk"
Copy-Item -Force $src $dest

Write-Host ""
Write-Host "APK ready for direct download URL:" -ForegroundColor Green
Write-Host "  $dest"
Write-Host ""
Write-Host "Deploy:  firebase deploy --only hosting" -ForegroundColor Yellow
Write-Host "Then share:  https://YOUR_SITE.web.app/FinShe-release.apk" -ForegroundColor Yellow
Write-Host "(That link should start the download immediately.)" -ForegroundColor Yellow
