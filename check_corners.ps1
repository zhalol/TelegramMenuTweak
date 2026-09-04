Add-Type -AssemblyName System.Drawing
$srcPath = "C:\Users\Жалол\Desktop\WSC\11.5\TelegramMenuTweak\фото\фото.jpeg"
$bmp = [System.Drawing.Image]::FromFile($srcPath)
$w = $bmp.Width
$h = $bmp.Height
Write-Host "Image: $w x $h"

$wm1 = $w - 1
$hm1 = $h - 1

$xs = @(0, $wm1, 0, $wm1, 10, 50, 100, 200, 300)
$ys = @(0, 0, $hm1, $hm1, 10, 50, 100, 200, 300)
$names = @("TL", "TR", "BL", "BR", "near-TL(10,10)", "50,50", "100,100", "200,200", "300,300")

for ($i = 0; $i -lt $names.Length; $i++) {
    $x = $xs[$i]
    $y = $ys[$i]
    $px = $bmp.GetPixel($x, $y)
    Write-Host ("{0} ({1},{2}): R={3} G={4} B={5}" -f $names[$i], $x, $y, $px.R, $px.G, $px.B)
}
$bmp.Dispose()
