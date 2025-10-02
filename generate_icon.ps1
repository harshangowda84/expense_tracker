# Spendly App Icon Generator
# This script creates a simple SVG-based app icon for Spendly

$svgContent = @"
<svg width="512" height="512" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <radialGradient id="grad1" cx="50%" cy="50%" r="50%">
      <stop offset="0%" style="stop-color:#1976D2;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#1565C0;stop-opacity:1" />
    </radialGradient>
    <filter id="shadow" x="-50%" y="-50%" width="200%" height="200%">
      <feDropShadow dx="4" dy="4" stdDeviation="8" flood-color="#000000" flood-opacity="0.3"/>
    </filter>
  </defs>
  
  <!-- Background circle -->
  <circle cx="256" cy="256" r="240" fill="url(#grad1)" filter="url(#shadow)"/>
  
  <!-- Dollar sign background (subtle) -->
  <text x="256" y="280" font-family="Arial, sans-serif" font-size="200" font-weight="bold" 
        text-anchor="middle" fill="#ffffff" opacity="0.1">$</text>
  
  <!-- Main "S" letter -->
  <text x="256" y="320" font-family="Arial, sans-serif" font-size="280" font-weight="bold" 
        text-anchor="middle" fill="#ffffff" filter="url(#shadow)">S</text>
</svg>
"@

# Create the icon directory if it doesn't exist
$iconDir = "d:\Project\expense_tracker\icons"
if (!(Test-Path $iconDir)) {
    New-Item -ItemType Directory -Path $iconDir
}

# Save the SVG file
$svgPath = "$iconDir\app_icon.svg"
$svgContent | Out-File -FilePath $svgPath -Encoding UTF8

Write-Host "SVG icon created at: $svgPath"
Write-Host "To convert to PNG, you can use online converters or tools like Inkscape"
Write-Host "Recommended sizes: 48x48, 72x72, 96x96, 144x144, 192x192, 512x512"