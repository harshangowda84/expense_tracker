#!/usr/bin/env powershell
# Create portable Spendly application package

$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommandPath
$BuildPath = Join-Path $ProjectRoot "build\windows\x64\runner\Release"
$PortablePath = Join-Path $ProjectRoot "Spendly-Portable"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Building Portable Spendly" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verify build exists
if (-not (Test-Path $BuildPath)) {
    Write-Host "ERROR: Release build not found!" -ForegroundColor Red
    Write-Host "Run: flutter build windows --release" -ForegroundColor Yellow
    exit 1
}

# Create portable directory
if (Test-Path $PortablePath) {
    Remove-Item $PortablePath -Recurse -Force
}

New-Item -ItemType Directory -Path $PortablePath | Out-Null
New-Item -ItemType Directory -Path "$PortablePath\data" | Out-Null

Write-Host "Copying files..." -ForegroundColor Yellow

# Copy executable
Copy-Item "$BuildPath\expense_tracker.exe" "$PortablePath\" -Force
Write-Host "  OK: expense_tracker.exe"

# Copy DLLs
$DllCount = 0
Get-Item "$BuildPath\*.dll" -ErrorAction SilentlyContinue | ForEach-Object {
    Copy-Item $_.FullName "$PortablePath\"
    $DllCount++
}
Write-Host "  OK: $DllCount DLL files"

# Copy Flutter assets
if (Test-Path "$BuildPath\data") {
    Copy-Item "$BuildPath\data\*" "$PortablePath\data\" -Recurse -Force
    Write-Host "  OK: Flutter assets"
}

# Create launcher batch file
$BatchLines = @"
@echo off
cd /d "%~dp0"
start expense_tracker.exe
"@
$BatchLines | Out-File "$PortablePath\Spendly.bat" -Encoding ASCII -Force
Write-Host "  OK: Spendly.bat launcher"

# Create README
$ReadmeText = @"
Spendly - Portable Edition

HOW TO RUN
==========
1. Double-click Spendly.bat or expense_tracker.exe
2. The application starts immediately
3. No installation required!

FEATURES
========
- Portable - run from USB or any folder
- No installation - no admin rights needed
- No registry changes
- Delete folder to uninstall

REQUIREMENTS
============
- Windows 10 or later
- ~100 MB disk space

SUPPORT
=======
For issues, visit the project repository.
"@
$ReadmeText | Out-File "$PortablePath\README.txt" -Encoding UTF8 -Force
Write-Host "  OK: README.txt"

# Create ZIP archive
$ZipPath = Join-Path $ProjectRoot "Spendly-Portable.zip"
Write-Host ""
Write-Host "Creating archive..." -ForegroundColor Yellow

if (Test-Path $ZipPath) {
    Remove-Item $ZipPath -Force
}

Compress-Archive -Path "$PortablePath\*" -DestinationPath $ZipPath -Force

$FileSizeMB = (Get-Item $ZipPath).Length / 1MB
Write-Host "  OK: Archive created"

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  SUCCESS! Portable Package Ready" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Output: $ZipPath"
Write-Host "Size: $([Math]::Round($FileSizeMB, 1)) MB"
Write-Host ""
Write-Host "Share the ZIP file. Users can:" -ForegroundColor Cyan
Write-Host "  1. Extract anywhere"
Write-Host "  2. Double-click Spendly.bat"
Write-Host "  3. No installation needed!"
Write-Host ""
