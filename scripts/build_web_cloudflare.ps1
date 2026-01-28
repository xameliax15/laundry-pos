$ErrorActionPreference = "Stop"

Set-Location -Path (Split-Path -Parent $PSScriptRoot)

Write-Host "Building Flutter web (release)..."
flutter build web --release

# Cloudflare Pages supports a Netlify-style _headers file, but Flutter does not
# copy web/_headers into build/web automatically. Copy it explicitly so it ends
# up in the deployed output.
$src = Join-Path $PWD "web\\_headers"
$dst = Join-Path $PWD "build\\web\\_headers"

if (Test-Path $src) {
  Copy-Item -Force $src $dst
  Write-Host "Copied $src -> $dst"
} else {
  Write-Warning "Missing $src (no Cloudflare headers will be applied)."
}

Write-Host "Done. Deploy the folder: build\\web"
