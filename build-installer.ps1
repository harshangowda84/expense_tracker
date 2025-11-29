#!/usr/bin/env powershell
# Build Spendly MSI Installer
# This script automates the creation of the Windows installer

param(
    [switch]$AutoInstallInno = $false
)

$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommandPath
$IsccPath = "C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
$InstallerScript = Join-Path $ProjectRoot "spendly-installer.iss"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Spendly Installer Builder" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Inno Setup is installed
if (-not (Test-Path $IsccPath)) {
    Write-Host "❌ Inno Setup is not installed" -ForegroundColor Red
    Write-Host ""
    Write-Host "Install it using:" -ForegroundColor Yellow
    Write-Host "  winget install JetBrains.InnoSetup" -ForegroundColor Cyan
    Write-Host ""
    if ($AutoInstallInno) {
        Write-Host "Installing Inno Setup..." -ForegroundColor Yellow
        winget install JetBrains.InnoSetup
        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ Failed to install Inno Setup" -ForegroundColor Red
            exit 1
        }
    } else {
        exit 1
    }
}

# Verify the Flutter build exists
$ExeFile = Join-Path $ProjectRoot "build\windows\x64\runner\Release\expense_tracker.exe"
if (-not (Test-Path $ExeFile)) {
    Write-Host "❌ Release build not found at: $ExeFile" -ForegroundColor Red
    Write-Host ""
    Write-Host "Run: flutter build windows --release" -ForegroundColor Yellow
    exit 1
}

Write-Host "✓ Found Flutter release build" -ForegroundColor Green

# Create output directory
$OutputDir = Join-Path $ProjectRoot "build\windows\installer"
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    Write-Host "✓ Created output directory" -ForegroundColor Green
}

# Build the installer
Write-Host ""
Write-Host "Building installer..." -ForegroundColor Yellow
& $IsccPath $InstallerScript

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  ✓ Installer created successfully!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Installer location:" -ForegroundColor Cyan
    Write-Host "  $OutputDir\Spendly-Setup-1.1.5.exe" -ForegroundColor Yellow
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "❌ Failed to build installer" -ForegroundColor Red
    exit 1
}
