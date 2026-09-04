$root = "C:\Users\Жалол\Desktop\WSC\11.5\TelegramMenuTweak"

$oldBundle = Join-Path $root "TelegramMenuTweakBundle.bundle"
$newBundle = Join-Path $root "botcczz.bundle"
if (Test-Path $oldBundle) {
    Rename-Item $oldBundle $newBundle
    Write-Host "Renamed bundle -> botcczz.bundle"
} else {
    Write-Host "Bundle already renamed or missing"
}

$oldDylib = Join-Path $root "TelegramMenuTweak.dylib"
if (Test-Path $oldDylib) {
    Remove-Item $oldDylib -Force
    Write-Host "Removed old dylib"
}

$oldPlist = Join-Path $root "TelegramMenuTweak.plist"
if (Test-Path $oldPlist) {
    Remove-Item $oldPlist -Force
    Write-Host "Removed old plist"
}

Write-Host "`nCurrent relevant files:"
Get-ChildItem $root | Where-Object { $_.Name -match '^(botcczz|Tweak|Makefile|inject|build|control)' } | Format-Table Name, Length
