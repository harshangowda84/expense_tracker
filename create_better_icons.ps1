# Enhanced Spendly Icon Creator with verification
# This script creates better quality icons and verifies they were created

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms

function Create-SpendlyIcon {
    param(
        [int]$size,
        [string]$outputPath
    )
    
    try {
        # Create bitmap with higher quality
        $bitmap = New-Object System.Drawing.Bitmap($size, $size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        
        # Enable highest quality rendering
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
        
        # Clear background to transparent
        $graphics.Clear([System.Drawing.Color]::Transparent)
        
        # Create gradient brush for background circle
        $centerPoint = [System.Drawing.PointF]::new($size/2, $size/2)
        $gradientBrush = New-Object System.Drawing.Drawing2D.PathGradientBrush([System.Drawing.PointF[]]@($centerPoint))
        $gradientBrush.CenterColor = [System.Drawing.Color]::FromArgb(255, 25, 118, 210)  # #1976D2
        $gradientBrush.SurroundColors = @([System.Drawing.Color]::FromArgb(255, 21, 101, 192))  # #1565C0
        
        # Draw background circle
        $rect = New-Object System.Drawing.Rectangle(0, 0, $size, $size)
        $graphics.FillEllipse($gradientBrush, $rect)
        
        # Add subtle border
        $borderPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(50, 255, 255, 255), 2)
        $graphics.DrawEllipse($borderPen, 1, 1, $size-2, $size-2)
        
        # Create font for "S" - use system font that's guaranteed to exist
        $fontSize = [math]::Round($size * 0.55)
        $fontFamily = "Arial"
        $font = New-Object System.Drawing.Font($fontFamily, $fontSize, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
        
        # Create white brush for text with slight transparency for depth
        $textBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 255, 255))
        
        # Measure text size for perfect centering
        $textSize = $graphics.MeasureString("S", $font)
        $x = ($size - $textSize.Width) / 2
        $y = ($size - $textSize.Height) / 2
        
        # Draw shadow for depth
        $shadowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(80, 0, 0, 0))
        $shadowOffset = [math]::Max(1, $size * 0.02)
        $graphics.DrawString("S", $font, $shadowBrush, $x + $shadowOffset, $y + $shadowOffset)
        
        # Draw main text
        $graphics.DrawString("S", $font, $textBrush, $x, $y)
        
        # Create directory if it doesn't exist
        $directory = [System.IO.Path]::GetDirectoryName($outputPath)
        if (!(Test-Path $directory)) {
            New-Item -ItemType Directory -Path $directory -Force | Out-Null
        }
        
        # Save the image as PNG
        $bitmap.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
        
        # Verify file was created and get size
        if (Test-Path $outputPath) {
            $fileInfo = Get-Item $outputPath
            Write-Host "✓ Created: $outputPath ($size x $size) - Size: $($fileInfo.Length) bytes" -ForegroundColor Green
            return $true
        } else {
            Write-Host "✗ Failed to create: $outputPath" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "✗ Error creating $outputPath : $_" -ForegroundColor Red
        return $false
    }
    finally {
        # Cleanup resources
        if ($graphics) { $graphics.Dispose() }
        if ($bitmap) { $bitmap.Dispose() }
        if ($gradientBrush) { $gradientBrush.Dispose() }
        if ($borderPen) { $borderPen.Dispose() }
        if ($font) { $font.Dispose() }
        if ($textBrush) { $textBrush.Dispose() }
        if ($shadowBrush) { $shadowBrush.Dispose() }
    }
}

# Define all required icon sizes and directories
$iconSizes = @(
    @{size=48; dir="mipmap-mdpi"; name="mdpi"},
    @{size=72; dir="mipmap-hdpi"; name="hdpi"},
    @{size=96; dir="mipmap-xhdpi"; name="xhdpi"},
    @{size=144; dir="mipmap-xxhdpi"; name="xxhdpi"},
    @{size=192; dir="mipmap-xxxhdpi"; name="xxxhdpi"}
)

Write-Host "🚀 Creating Spendly App Icons..." -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

$successCount = 0
$totalCount = $iconSizes.Count

foreach ($iconInfo in $iconSizes) {
    $dirPath = "android\app\src\main\res\$($iconInfo.dir)"
    $iconPath = "$dirPath\ic_launcher.png"
    
    Write-Host "`nProcessing $($iconInfo.name) ($($iconInfo.size)x$($iconInfo.size))..." -ForegroundColor Yellow
    
    if (Test-Path $dirPath) {
        if (Create-SpendlyIcon -size $iconInfo.size -outputPath $iconPath) {
            $successCount++
        }
    } else {
        Write-Host "✗ Directory not found: $dirPath" -ForegroundColor Red
    }
}

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "📊 Summary: $successCount/$totalCount icons created successfully" -ForegroundColor $(if($successCount -eq $totalCount){"Green"}else{"Yellow"})

if ($successCount -eq $totalCount) {
    Write-Host "✅ All icons created successfully!" -ForegroundColor Green
    Write-Host "📱 Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Uninstall the old app from your device" -ForegroundColor White
    Write-Host "  2. Run 'flutter clean' to clear build cache" -ForegroundColor White
    Write-Host "  3. Run 'flutter run' to install with new icons" -ForegroundColor White
} else {
    Write-Host "⚠️  Some icons failed to create. Check the errors above." -ForegroundColor Yellow
}

Write-Host "`n🔧 Remember: You may need to restart your device or clear launcher cache to see the new icons." -ForegroundColor Magenta