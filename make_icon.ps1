Add-Type -AssemblyName System.Drawing
$srcPath = "C:\Users\Жалол\Desktop\WSC\11.5\TelegramMenuTweak\фото\фото.jpeg"
$outDir = "C:\Users\Жалол\Desktop\WSC\11.5\TelegramMenuTweak\TelegramMenuTweakBundle.bundle"
$cropDir = "C:\Users\Жалол\Desktop\WSC\11.5\TelegramMenuTweak"
$tempPath = Join-Path $cropDir "_crop_tmp.png"

$src = [System.Drawing.Image]::FromFile($srcPath)
$sw = $src.Width
$sh = $src.Height
Write-Host "Source: $sw x $sh (background is black)"

$bmp = New-Object System.Drawing.Bitmap($src)
$minX = $sw; $maxX = 0; $minY = $sh; $maxY = 0

# Look for pixels that are NOT black (the actual content on black background)
$step = 4
for ($y = 0; $y -lt $sh; $y += $step) {
    for ($x = 0; $x -lt $sw; $x += $step) {
        $px = $bmp.GetPixel($x, $y)
        $brightness = ($px.R + $px.G + $px.B) / 3
        if ($brightness -gt 30) {  # not pure black
            if ($x -lt $minX) { $minX = $x }
            if ($x -gt $maxX) { $maxX = $x }
            if ($y -lt $minY) { $minY = $y }
            if ($y -gt $maxY) { $maxY = $y }
        }
    }
}
$bmp.Dispose()

$contentCX = [int](($minX + $maxX) / 2)
$contentCY = [int](($minY + $maxY) / 2)
$contentW = $maxX - $minX
$contentH = $maxY - $minY
Write-Host "Content bbox: x=$minX..$maxX y=$minY..$maxY (center=$contentCX,$contentCY, ${contentW}x${contentH})"

# Square crop centered on content with 8% padding
$square = [int]([Math]::Max($contentW, $contentH) * 1.08)
$cropX = [int]($contentCX - $square / 2)
$cropY = [int]($contentCY - $square / 2)
if ($cropX -lt 0) { $cropX = 0 }
if ($cropY -lt 0) { $cropY = 0 }
if ($cropX + $square -gt $sw) { $square = $sw - $cropX }
if ($cropY + $square -gt $sh) { $square = $sh - $cropY }
Write-Host "Square crop: ${square}x${square} at ($cropX,$cropY)"

# Clone a square from source
$cropRect = New-Object System.Drawing.Rectangle($cropX, $cropY, $square, $square)
$cropped = $src.Clone($cropRect, $src.PixelFormat)
$cropped.Save($tempPath, [System.Drawing.Imaging.ImageFormat]::Png)
$cropped.Dispose()
Write-Host "Temp cropped: $tempPath"

# Now load cropped and make black → transparent
$croppedSrc = [System.Drawing.Bitmap]::FromFile($tempPath)

# Make black background transparent (key on dark pixels)
$croppedW = $croppedSrc.Width
$croppedH = $croppedSrc.Height
$alpha = New-Object System.Drawing.Imaging.ColorMatrix
# Use default identity matrix
for ($y = 0; $y -lt $croppedH; $y++) {
    for ($x = 0; $x -lt $croppedW; $x++) {
        $px = $croppedSrc.GetPixel($x, $y)
        $brightness = ($px.R + $px.G + $px.B) / 3
        if ($brightness -lt 25) {
            # Make transparent
            $croppedSrc.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(0, 0, 0, 0))
        }
    }
}

# Save transparent cropped version
$tempPath2 = Join-Path $cropDir "_crop_alpha.png"
$croppedSrc.Save($tempPath2, [System.Drawing.Imaging.ImageFormat]::Png)
$croppedSrc.Dispose()

$croppedSrc = [System.Drawing.Image]::FromFile($tempPath2)

function Get-RoundedIcon([System.Drawing.Image]$img, [int]$size, [string]$outPath) {
    $bmp = New-Object System.Drawing.Bitmap($size, $size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $g.Clear([System.Drawing.Color]::Transparent)
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $path.AddEllipse(0, 0, $size, $size)
    $g.SetClip($path)
    $g.DrawImage($img, 0, 0, $size, $size)
    $g.Dispose()
    $bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
}

Get-RoundedIcon -img $croppedSrc -size 56  -outPath (Join-Path $outDir "icon.png")
Get-RoundedIcon -img $croppedSrc -size 112 -outPath (Join-Path $outDir "icon@2x.png")
Get-RoundedIcon -img $croppedSrc -size 168 -outPath (Join-Path $outDir "icon@3x.png")

$croppedSrc.Dispose()
$src.Dispose()

if (Test-Path -LiteralPath $tempPath)  { Remove-Item -LiteralPath $tempPath  -Force }
if (Test-Path -LiteralPath $tempPath2) { Remove-Item -LiteralPath $tempPath2 -Force }

Write-Host "`nFinal bundle files:"
Get-ChildItem $outDir | Format-Table Name, Length
