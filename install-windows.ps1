# nut.js Installation Script for Windows
# 
# ⚠️ DEPRECATED: This PowerShell script is deprecated.
# Please use install-windows.bat instead, which must be run in "Developer Command Prompt for VS 2022".
# 
# This script is kept for reference only and may not work correctly due to:
# - Requires Developer Command Prompt environment variables
# - References deprecated windows-build-tools
# - May not properly detect Visual Studio 2022
#
# See WINDOWS.md for the updated manual installation guide.
# See README.md for the new automated script (install-windows.bat).

$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "nut.js Installation Script for Windows" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Check if running on Windows
if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Host "Error: PowerShell 5.0 or higher is required" -ForegroundColor Red
    exit 1
}

# Check prerequisites
Write-Host "Checking prerequisites..." -ForegroundColor Yellow

# Check for Node.js
try {
    $nodeVersion = node --version
    Write-Host "✓ Node.js found: $nodeVersion" -ForegroundColor Green
    
    # Check Node.js version (need 10.15.3+ for libnut-core, 16+ recommended for nut.js)
    $versionMatch = $nodeVersion -match 'v(\d+)\.(\d+)\.(\d+)'
    if ($versionMatch) {
        $nodeMajor = [int]$matches[1]
        $nodeMinor = [int]$matches[2]
        
        if ($nodeMajor -lt 10 -or ($nodeMajor -eq 10 -and $nodeMinor -lt 15)) {
            Write-Host "Error: Node.js version 10.15.3 or higher is required" -ForegroundColor Red
            Write-Host "Current version: $nodeVersion" -ForegroundColor Red
            Write-Host "Please upgrade Node.js from https://nodejs.org/" -ForegroundColor Yellow
            exit 1
        }
        if ($nodeMajor -lt 16) {
            Write-Host "Warning: Node.js 16+ is recommended for nut.js (you have $nodeVersion)" -ForegroundColor Yellow
            Write-Host "Continuing anyway, but you may encounter issues..." -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "Error: Node.js is not installed" -ForegroundColor Red
    Write-Host "Please install Node.js from https://nodejs.org/" -ForegroundColor Yellow
    exit 1
}

# Check for npm
try {
    $npmVersion = npm --version
    Write-Host "✓ npm found: $npmVersion" -ForegroundColor Green
} catch {
    Write-Host "Error: npm is not installed" -ForegroundColor Red
    exit 1
}

# Check for git
try {
    git --version | Out-Null
    Write-Host "✓ git found" -ForegroundColor Green
} catch {
    Write-Host "Error: git is not installed" -ForegroundColor Red
    Write-Host "Please install Git from https://git-scm.com/download/win" -ForegroundColor Yellow
    exit 1
}

# Check for Python (needed for node-gyp and JSON manipulation)
$pythonFound = $false
try {
    $pythonVersion = python --version 2>&1
    Write-Host "✓ Python found: $pythonVersion" -ForegroundColor Green
    $pythonFound = $true
} catch {
    try {
        $pythonVersion = python3 --version 2>&1
        Write-Host "✓ Python3 found: $pythonVersion" -ForegroundColor Green
        $pythonFound = $true
    } catch {
        Write-Host "Warning: Python not found. It may be needed for building native modules." -ForegroundColor Yellow
        Write-Host "Consider installing windows-build-tools or Python separately." -ForegroundColor Yellow
        Write-Host "Note: This script uses PowerShell's ConvertFrom-Json, so Python is optional." -ForegroundColor Yellow
    }
}

# Check for Visual Studio Build Tools
$vsBuildTools = Get-Command msbuild -ErrorAction SilentlyContinue
if (-not $vsBuildTools) {
    Write-Host "Error: MSBuild (Visual Studio Build Tools) not found" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install build tools using one of these methods:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Option 1 (Recommended): Install windows-build-tools" -ForegroundColor Cyan
    Write-Host "  Run PowerShell as Administrator, then:" -ForegroundColor White
    Write-Host "  npm install --global --production windows-build-tools" -ForegroundColor White
    Write-Host ""
    Write-Host "Option 2: Install Visual Studio Build Tools manually" -ForegroundColor Cyan
    Write-Host "  Download from: https://visualstudio.microsoft.com/downloads/" -ForegroundColor White
    Write-Host "  Install 'Desktop development with C++' workload" -ForegroundColor White
    Write-Host "  Ensure 'Windows 10/11 SDK' is selected" -ForegroundColor White
    Write-Host ""
    Write-Host "After installing, run this script again." -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "✓ Build tools found" -ForegroundColor Green
}

# Check for pnpm (use npx if not available to avoid global install)
Write-Host ""
Write-Host "Checking for pnpm..." -ForegroundColor Yellow
$useNpx = $false
try {
    $pnpmVersion = pnpm --version
    Write-Host "✓ pnpm found: $pnpmVersion" -ForegroundColor Green
} catch {
    Write-Host "pnpm not found. Will use npx pnpm (no global installation needed)" -ForegroundColor Yellow
    $useNpx = $true
}

# Set build directory (use current directory to keep everything self-contained)
$buildDir = Join-Path (Get-Location) "nutjs-build"
Write-Host ""
Write-Host "Build directory: $buildDir" -ForegroundColor Cyan
Write-Host "Note: All files will be installed in this directory. You can delete it entirely if something goes wrong." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path $buildDir | Out-Null
Set-Location $buildDir

# Clone libnut-core
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Step 1: Cloning libnut-core" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

if (Test-Path "libnut-core") {
    Write-Host "libnut-core directory exists. Pulling latest changes..." -ForegroundColor Yellow
    Set-Location libnut-core
    git pull
    Set-Location ..
} else {
    git clone https://github.com/nut-tree/libnut-core.git
    Write-Host "✓ libnut-core cloned" -ForegroundColor Green
}

# Build libnut-core
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Step 2: Building libnut-core" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

Set-Location libnut-core

Write-Host "Installing npm dependencies..." -ForegroundColor Yellow
npm install

Write-Host "Patching package name for Windows..." -ForegroundColor Yellow
$env:CI = "true"
npm run patch

Write-Host "Building release version (this may take several minutes)..." -ForegroundColor Yellow
npm run build:release

if ((Test-Path "build\Release\libnut.node") -or (Test-Path "build\Release\libnut-win32.node")) {
    Write-Host "✓ libnut-core built successfully" -ForegroundColor Green
} else {
    Write-Host "Error: Build output not found" -ForegroundColor Red
    exit 1
}

Set-Location ..

# Clone nut.js
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Step 3: Cloning nut.js" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

if (Test-Path "nut.js") {
    Write-Host "nut.js directory exists. Pulling latest changes..." -ForegroundColor Yellow
    Set-Location nut.js
    git pull
    Set-Location ..
} else {
    git clone https://github.com/nut-tree/nut.js.git
    Write-Host "✓ nut.js cloned" -ForegroundColor Green
}

# Configure nut.js
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Step 4: Configuring nut.js" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

Set-Location nut.js

# Update providers/libnut/package.json
$libnutPkg = "providers\libnut\package.json"
Write-Host "Updating $libnutPkg..." -ForegroundColor Yellow

$libnutJson = Get-Content $libnutPkg -Raw | ConvertFrom-Json

# Update dependencies
$libnutJson.dependencies = @{
    "@nut-tree/libnut-win32" = "file:../../../libnut-core"
}
$libnutJson.optionalDependencies = @{
    "@nut-tree/libnut-darwin" = "2.7.1"
    "@nut-tree/libnut-linux" = "2.7.1"
}

# Update peer dependency
if ($libnutJson.PSObject.Properties.Name -contains "peerDependencies") {
    $libnutJson.peerDependencies."@nut-tree/nut-js" = "^4"
}

$libnutJson | ConvertTo-Json -Depth 10 | Set-Content $libnutPkg
Write-Host "✓ Updated $libnutPkg" -ForegroundColor Green

# Update providers/clipboardy/package.json
$clipboardyPkg = "providers\clipboardy\package.json"
Write-Host "Updating $clipboardyPkg..." -ForegroundColor Yellow

$clipboardyJson = Get-Content $clipboardyPkg -Raw | ConvertFrom-Json
if ($clipboardyJson.PSObject.Properties.Name -contains "peerDependencies") {
    $clipboardyJson.peerDependencies."@nut-tree/nut-js" = "^4"
}

$clipboardyJson | ConvertTo-Json -Depth 10 | Set-Content $clipboardyPkg
Write-Host "✓ Updated $clipboardyPkg" -ForegroundColor Green

# Update examples/screen-test/package.json
$screenTestPkg = "examples\screen-test\package.json"
Write-Host "Updating $screenTestPkg..." -ForegroundColor Yellow

$screenTestJson = Get-Content $screenTestPkg -Raw | ConvertFrom-Json

if ($screenTestJson.dependencies.PSObject.Properties.Name -contains "@nut-tree/nl-matcher") {
    $nlMatcherVal = $screenTestJson.dependencies."@nut-tree/nl-matcher"
    $screenTestJson.dependencies.PSObject.Properties.Remove("@nut-tree/nl-matcher")
    
    if (-not $screenTestJson.optionalDependencies) {
        $screenTestJson | Add-Member -MemberType NoteProperty -Name "optionalDependencies" -Value @{}
    }
    $screenTestJson.optionalDependencies."@nut-tree/nl-matcher" = $nlMatcherVal
}

$screenTestJson | ConvertTo-Json -Depth 10 | Set-Content $screenTestPkg
Write-Host "✓ Updated $screenTestPkg" -ForegroundColor Green

# Install and build
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Step 5: Installing dependencies and building" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

Write-Host "Removing old lock file..." -ForegroundColor Yellow
Remove-Item -Force pnpm-lock.yaml -ErrorAction SilentlyContinue

Write-Host "Installing dependencies (this may take several minutes)..." -ForegroundColor Yellow
if ($useNpx) {
    npx pnpm@8.15.2 install
} else {
    pnpm install
}

Write-Host ""
Write-Host "Compiling TypeScript packages..." -ForegroundColor Yellow
if ($useNpx) {
    npx pnpm@8.15.2 run compile
} else {
    pnpm run compile
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Installation Complete!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "nut.js has been successfully built from source!" -ForegroundColor Green
Write-Host ""
Write-Host "Build location: $buildDir\nut.js" -ForegroundColor Cyan
Write-Host ""
Write-Host "All files are contained in: $buildDir" -ForegroundColor Yellow
Write-Host "You can delete this entire directory if you need to start over." -ForegroundColor Yellow
Write-Host ""
Write-Host "To use in your project:" -ForegroundColor Yellow
Write-Host "  cd $buildDir\nut.js\core\nut.js" -ForegroundColor White
if ($useNpx) {
    Write-Host "  npx pnpm@8.15.2 link" -ForegroundColor White
    Write-Host ""
    Write-Host "Then in your project:" -ForegroundColor Yellow
    Write-Host "  npx pnpm@8.15.2 link @nut-tree/nut-js" -ForegroundColor White
} else {
    Write-Host "  pnpm link" -ForegroundColor White
    Write-Host ""
    Write-Host "Then in your project:" -ForegroundColor Yellow
    Write-Host "  pnpm link @nut-tree/nut-js" -ForegroundColor White
}
Write-Host ""
