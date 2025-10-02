# Simple Spendly Icon Creator
Add-Type -AssemblyName System.Drawing

function Create-Icon {
    param(
        [int]$size,
        [string]$outputPath
    )
    
    # Create bitmap
    $bitmap = New-Object System.Drawing.Bitmap($size, $size)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    
    # Enable high quality rendering
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAlias
    
    # Create gradient brush for background
    $startColor = [System.Drawing.Color]::FromArgb(255, 25, 118, 210)
    $endColor = [System.Drawing.Color]::FromArgb(255, 21, 101, 192)
    
    $gradientBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        [System.Drawing.Point]::new(0, 0),
        [System.Drawing.Point]::new($size, $size),
        $startColor,
        $endColor
    )
    
    # Draw background circle
    $graphics.FillEllipse($gradientBrush, 0, 0, $size, $size)
    
    # Create font for S
    $fontSize = [int]($size * 0.5)
    $font = New-Object System.Drawing.Font("Arial", $fontSize, [System.Drawing.FontStyle]::Bold)
    
    # Create white brush for text
    $whiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    
    # Measure text size for centering
    $textSize = $graphics.MeasureString("S", $font)
    $x = ($size - $textSize.Width) / 2
    $y = ($size - $textSize.Height) / 2
    
    # Draw shadow
    $shadowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(100, 0, 0, 0))
    $graphics.DrawString("S", $font, $shadowBrush, $x + 3, $y + 3)
    
    # Draw main text
    $graphics.DrawString("S", $font, $whiteBrush, $x, $y)
    
    # Save the image
    $bitmap.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    
    # Cleanup
    $graphics.Dispose()
    $bitmap.Dispose()
    $gradientBrush.Dispose()
    $font.Dispose()
    $whiteBrush.Dispose()
    $shadowBrush.Dispose()
    
    Write-Host "Created: $outputPath"
}

# Create icons for all densities
$resDir = "android\app\src\main\res"
$sizes = @(
    @{size=48; dir="mipmap-mdpi"},
    @{size=72; dir="mipmap-hdpi"},
    @{size=96; dir="mipmap-xhdpi"},
    @{size=144; dir="mipmap-xxhdpi"},
    @{size=192; dir="mipmap-xxxhdpi"}
)

Write-Host "Creating Spendly app icons..."

foreach ($iconSize in $sizes) {
    $dirPath = Join-Path $resDir $iconSize.dir
    $iconPath = Join-Path $dirPath "ic_launcher.png"
    
    if (Test-Path $dirPath) {
        Create-Icon -size $iconSize.size -outputPath $iconPath
    } else {
        Write-Host "Directory not found: $dirPath"
    }
}

Write-Host "Icons created!"
Write-Host ""
Write-Host "IMPORTANT STEPS:"
Write-Host "1. Uninstall the old app from your phone first"
Write-Host "2. Run 'flutter clean'"
Write-Host "3. Run 'flutter run' to install fresh"
Write-Host "4. The app should now show as 'Spendly' with 'S' icon"