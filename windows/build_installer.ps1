# MangaBaka App Installer Builder
# Automates the generation of MSIX and Inno Setup Windows installers.

# Get paths relative to script location
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if ($null -eq $ScriptDir -or $ScriptDir -eq "") {
    $ScriptDir = Get-Location
}
$ProjectRoot = Resolve-Path (Join-Path $ScriptDir "..")
$WindowsDir = Join-Path $ProjectRoot "windows"

Clear-Host
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "     MANGA BAKA INSTALLER BUILDER            " -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# 1. Build the Flutter App in Release Mode
Write-Host "[1/3] Compiling Flutter Windows app in Release mode..." -ForegroundColor Yellow
Push-Location $ProjectRoot
try {
    flutter build windows --release
    if ($LASTEXITCODE -ne 0) {
        Write-Host "✗ Flutter compilation failed!" -ForegroundColor Red
        Pop-Location
        exit $LASTEXITCODE
    }
    Write-Host "✓ Flutter app compiled in Release mode successfully!" -ForegroundColor Green
} catch {
    Write-Host "✗ Could not run flutter build. Make sure the Flutter SDK is installed and in your PATH." -ForegroundColor Red
    Pop-Location
    exit 1
}
Pop-Location

# 2. Package with MSIX (Modern Package)
Write-Host ""
Write-Host "[2/3] Creating MSIX (Modern Windows Package)..." -ForegroundColor Yellow
Push-Location $ProjectRoot
try {
    dart run msix:create
    if ($LASTEXITCODE -ne 0) {
        Write-Host "⚠ MSIX packaging failed or was skipped." -ForegroundColor Yellow
    } else {
        Write-Host "✓ MSIX Package generated successfully!" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠ Failed to run dart run msix:create." -ForegroundColor Yellow
}
Pop-Location

# 3. Package with Inno Setup (Classic Wizard)
Write-Host ""
Write-Host "[3/3] Creating Classic Inno Setup Wizard..." -ForegroundColor Yellow

# Find iscc.exe
$isccPath = $null
$isccCmd = Get-Command iscc.exe -ErrorAction SilentlyContinue
if ($isccCmd) {
    $isccPath = $isccCmd.Source
} else {
    $commonPaths = @(
        "C:\Program Files (x86)\Inno Setup 6\iscc.exe",
        "C:\Program Files\Inno Setup 6\iscc.exe",
        "C:\Program Files (x86)\Inno Setup 5\iscc.exe",
        "C:\Program Files\Inno Setup 5\iscc.exe"
    )
    foreach ($path in $commonPaths) {
        if (Test-Path $path) {
            $isccPath = $path
            break
        }
    }
}

if ($isccPath) {
    Write-Host "Found Inno Setup Compiler at: $isccPath" -ForegroundColor DarkGray
    Push-Location $WindowsDir
    try {
        & "$isccPath" installer.iss
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Inno Setup Installer generated successfully!" -ForegroundColor Green
        } else {
            Write-Host "✗ Inno Setup compilation failed!" -ForegroundColor Red
        }
    } finally {
        Pop-Location
    }
} else {
    Write-Host "Inno Setup Compiler (iscc.exe) was not found on your system." -ForegroundColor Yellow
    Write-Host "To generate the classic setup.exe wizard, please install Inno Setup:" -ForegroundColor Yellow
    Write-Host "  -> Run this command to install it in one click: winget install JRSoftware.InnoSetup" -ForegroundColor Cyan
    Write-Host "  -> Or download it from: https://jrsoftware.org/isdl.php" -ForegroundColor Cyan
    Write-Host "After installing, re-run this script to build the classic setup wizard!" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "                 BUILD COMPLETE              " -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "You can find your packaged installers in:" -ForegroundColor Gray
Write-Host "  • MSIX Package: build\windows\x64\runner\Release\" -ForegroundColor Gray
Write-Host "  • Classic Setup Wizard (if built): build\MangaBaka_Setup.exe" -ForegroundColor Gray
Write-Host "=============================================" -ForegroundColor Cyan
