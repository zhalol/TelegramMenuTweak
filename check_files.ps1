$root = "C:\Users\Жалол\Desktop\WSC\11.5\TelegramMenuTweak"

Write-Host "=== 1. dylib ===" -ForegroundColor Cyan
$dylib = Join-Path $root "TelegramMenuTweak.dylib"
if (Test-Path $dylib) {
    Get-Item $dylib | Format-Table Name, Length
} else {
    Write-Host "  MISSING" -ForegroundColor Red
}

Write-Host "`n=== 2. Bundle (icon) ===" -ForegroundColor Cyan
$bundle = Join-Path $root "TelegramMenuTweakBundle.bundle"
if (Test-Path $bundle) {
    Get-ChildItem $bundle | Format-Table Name, Length
} else {
    Write-Host "  MISSING" -ForegroundColor Red
}

Write-Host "`n=== 3. inject.sh ===" -ForegroundColor Cyan
$inj = Join-Path $root "inject.sh"
if (Test-Path $inj) {
    Get-Item $inj | Format-Table Name, Length
} else {
    Write-Host "  MISSING" -ForegroundColor Red
}

Write-Host "`n=== 4. IPA (one level up) ===" -ForegroundColor Cyan
$ipa = Join-Path $root "..\11.5 (@wscios).ipa"
if (Test-Path $ipa) {
    Get-Item $ipa | Format-Table Name, Length
} else {
    Write-Host "  NOT FOUND at: $ipa" -ForegroundColor Yellow
    Write-Host "  (check inject.sh IPA_PATH variable if it's elsewhere)" -ForegroundColor Yellow
}
