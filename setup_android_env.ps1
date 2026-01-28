# Script untuk setup Android Environment Variables
# Jalankan sebagai Administrator jika diperlukan

Write-Host "=== Setup Android Environment Variables ===" -ForegroundColor Cyan

$androidSdkPath = "$env:LOCALAPPDATA\Android\sdk"
$androidHome = $androidSdkPath

Write-Host "`nAndroid SDK Path: $androidSdkPath" -ForegroundColor Yellow

# Set ANDROID_HOME
if ([Environment]::GetEnvironmentVariable("ANDROID_HOME", "User") -eq $null) {
    [Environment]::SetEnvironmentVariable("ANDROID_HOME", $androidHome, "User")
    Write-Host "✓ ANDROID_HOME telah di-set" -ForegroundColor Green
} else {
    Write-Host "✓ ANDROID_HOME sudah ada" -ForegroundColor Green
}

# Add to PATH
$path = [Environment]::GetEnvironmentVariable("Path", "User")
$pathsToAdd = @(
    "$androidHome\platform-tools",
    "$androidHome\cmdline-tools\latest\bin"
)

$pathUpdated = $false
foreach ($pathToAdd in $pathsToAdd) {
    if ($path -notlike "*$pathToAdd*") {
        $path += ";$pathToAdd"
        $pathUpdated = $true
        Write-Host "✓ Menambahkan ke PATH: $pathToAdd" -ForegroundColor Green
    } else {
        Write-Host "✓ Sudah ada di PATH: $pathToAdd" -ForegroundColor Green
    }
}

if ($pathUpdated) {
    [Environment]::SetEnvironmentVariable("Path", $path, "User")
    Write-Host "`n✓ PATH telah di-update" -ForegroundColor Green
    Write-Host "`n⚠ PENTING: Restart terminal/command prompt agar perubahan berlaku!" -ForegroundColor Yellow
} else {
    Write-Host "`n✓ PATH sudah lengkap" -ForegroundColor Green
}

Write-Host "`n=== Setup Selesai ===" -ForegroundColor Cyan
Write-Host "Langkah selanjutnya:" -ForegroundColor Yellow
Write-Host "1. Install cmdline-tools melalui Android Studio SDK Manager" -ForegroundColor White
Write-Host "2. Restart terminal" -ForegroundColor White
Write-Host "3. Jalankan: flutter doctor --android-licenses" -ForegroundColor White




