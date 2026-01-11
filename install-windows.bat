@echo off
REM nut.js Installation Script for Windows
REM This script automates building nut.js from source on Windows
REM MUST be run in "Developer Command Prompt for VS 2022"
REM Do NOT run in regular Command Prompt or PowerShell

setlocal enabledelayedexpansion

echo ==========================================
echo nut.js Installation Script for Windows
echo ==========================================
echo.

REM Check if running in Developer Command Prompt
echo Checking Developer Command Prompt environment...
where devenv >nul 2>&1
if errorlevel 1 (
    echo.
    echo ERROR: This script must be run in "Developer Command Prompt for VS 2022"
    echo.
    echo Please:
    echo 1. Search for "Developer Command Prompt" in Start menu
    echo 2. Open "Developer Command Prompt for VS 2022" (NOT VS 2026 or newer)
    echo 3. Navigate to this directory and run this script again
    echo.
    echo To verify VS 2022 is installed, run: where devenv
    echo.
    pause
    exit /b 1
)

echo [OK] Running in Developer Command Prompt
echo.

REM Check prerequisites
echo Checking prerequisites...
echo.

REM Check for Node.js
where node >nul 2>&1
if errorlevel 1 (
    echo ERROR: Node.js is not installed
    echo Please install Node.js from https://nodejs.org/
    pause
    exit /b 1
)

for /f "tokens=*" %%i in ('node --version') do set NODE_VERSION=%%i
echo [OK] Node.js found: %NODE_VERSION%

REM Check Node.js version (basic check)
echo %NODE_VERSION% | findstr /r "v1[0-9]\." >nul
if errorlevel 1 (
    echo %NODE_VERSION% | findstr /r "v[2-9][0-9]\." >nul
    if errorlevel 1 (
        echo WARNING: Node.js 10.15.3+ is required (you have %NODE_VERSION%)
        echo Continuing anyway, but you may encounter issues...
    )
)

REM Check for npm
where npm >nul 2>&1
if errorlevel 1 (
    echo ERROR: npm is not installed
    pause
    exit /b 1
)

for /f "tokens=*" %%i in ('npm --version') do set NPM_VERSION=%%i
echo [OK] npm found: %NPM_VERSION%

REM Check for git
where git >nul 2>&1
if errorlevel 1 (
    echo ERROR: git is not installed
    echo Please install Git from https://git-scm.com/download/win
    pause
    exit /b 1
)

for /f "tokens=*" %%i in ('git --version') do set GIT_VERSION=%%i
echo [OK] git found: %GIT_VERSION%

REM Check for Python
where python >nul 2>&1
if errorlevel 1 (
    echo WARNING: Python not found. It may be needed for building native modules.
    echo Consider installing Python from https://www.python.org/downloads/
) else (
    for /f "tokens=*" %%i in ('python --version 2^>^&1') do set PYTHON_VERSION=%%i
    echo [OK] Python found: %PYTHON_VERSION%
)

REM Check for Visual Studio 2022 Build Tools
echo.
echo Checking for Visual Studio 2022 Build Tools...
where devenv >nul 2>&1
if errorlevel 1 (
    echo.
    echo ERROR: Visual Studio 2022 Build Tools not found
    echo.
    echo Please install Visual Studio 2022 Build Tools:
    echo 1. Go to https://visualstudio.microsoft.com/downloads/
    echo 2. Download "Build Tools for Visual Studio 2022"
    echo 3. During installation, select "Desktop development with C++" workload
    echo 4. Ensure "Windows 10/11 SDK" is selected
    echo 5. After installation, open "Developer Command Prompt for VS 2022" and run this script again
    echo.
    echo To verify installation, run: where devenv
    echo.
    pause
    exit /b 1
)

for /f "tokens=*" %%i in ('where devenv') do set DEVENV_PATH=%%i
echo [OK] Visual Studio 2022 Build Tools found
echo       Path: %DEVENV_PATH%
echo.

REM Check for pnpm
where pnpm >nul 2>&1
if errorlevel 1 (
    echo pnpm not found. Will use npx pnpm (no global installation needed)
    set USE_NPX=1
) else (
    for /f "tokens=*" %%i in ('pnpm --version') do set PNPM_VERSION=%%i
    echo [OK] pnpm found: %PNPM_VERSION%
    set USE_NPX=0
)

echo.
echo ==========================================
echo Step 1: Cloning libnut-core
echo ==========================================
echo.

REM Set build directory
set BUILD_DIR=%~dp0nutjs-build
if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"
cd /d "%BUILD_DIR%"

if exist "libnut-core" (
    echo libnut-core directory exists. Pulling latest changes...
    cd libnut-core
    git pull
    cd ..
) else (
    git clone https://github.com/nut-tree/libnut-core.git
    if errorlevel 1 (
        echo ERROR: Failed to clone libnut-core
        pause
        exit /b 1
    )
    echo [OK] libnut-core cloned
)

echo.
echo ==========================================
echo Step 2: Building libnut-core
echo ==========================================
echo.

cd libnut-core

echo Installing npm dependencies...
call npm install
if errorlevel 1 (
    echo ERROR: Failed to install npm dependencies
    pause
    exit /b 1
)

echo Patching package name for Windows...
set CI=true
call npm run patch
if errorlevel 1 (
    echo ERROR: Failed to patch package
    pause
    exit /b 1
)

echo Building release version (this may take several minutes)...
call npm run build:release
if errorlevel 1 (
    echo ERROR: Build failed
    pause
    exit /b 1
)

if exist "build\Release\libnut.node" (
    echo [OK] libnut-core built successfully
) else if exist "build\Release\libnut-win32.node" (
    echo [OK] libnut-core built successfully
) else (
    echo ERROR: Build output not found
    pause
    exit /b 1
)

cd ..

echo.
echo ==========================================
echo Step 3: Cloning nut.js
echo ==========================================
echo.

if exist "nut.js" (
    echo nut.js directory exists. Pulling latest changes...
    cd nut.js
    git pull
    cd ..
) else (
    git clone https://github.com/nut-tree/nut.js.git
    if errorlevel 1 (
        echo ERROR: Failed to clone nut.js
        pause
        exit /b 1
    )
    echo [OK] nut.js cloned
)

echo.
echo ==========================================
echo Step 4: Configuring nut.js
echo ==========================================
echo.

cd nut.js

REM Update providers/libnut/package.json using PowerShell
echo Updating providers\libnut\package.json...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
"$json = Get-Content 'providers\libnut\package.json' -Raw | ConvertFrom-Json; ^
$json.dependencies = @{'@nut-tree/libnut-win32' = 'file:../../../libnut-core'}; ^
$json.optionalDependencies = @{'@nut-tree/libnut-darwin' = '2.7.1'; '@nut-tree/libnut-linux' = '2.7.1'}; ^
if ($json.PSObject.Properties.Name -contains 'peerDependencies') { $json.peerDependencies.'@nut-tree/nut-js' = '^4' }; ^
$json | ConvertTo-Json -Depth 10 | Set-Content 'providers\libnut\package.json'"

if errorlevel 1 (
    echo ERROR: Failed to update providers\libnut\package.json
    pause
    exit /b 1
)
echo [OK] Updated providers\libnut\package.json

REM Update providers/clipboardy/package.json
echo Updating providers\clipboardy\package.json...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
"$json = Get-Content 'providers\clipboardy\package.json' -Raw | ConvertFrom-Json; ^
if ($json.PSObject.Properties.Name -contains 'peerDependencies') { $json.peerDependencies.'@nut-tree/nut-js' = '^4' }; ^
$json | ConvertTo-Json -Depth 10 | Set-Content 'providers\clipboardy\package.json'"

if errorlevel 1 (
    echo ERROR: Failed to update providers\clipboardy\package.json
    pause
    exit /b 1
)
echo [OK] Updated providers\clipboardy\package.json

REM Update examples/screen-test/package.json
echo Updating examples\screen-test\package.json...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
"$json = Get-Content 'examples\screen-test\package.json' -Raw | ConvertFrom-Json; ^
if ($json.dependencies.PSObject.Properties.Name -contains '@nut-tree/nl-matcher') { ^
    $val = $json.dependencies.'@nut-tree/nl-matcher'; ^
    $json.dependencies.PSObject.Properties.Remove('@nut-tree/nl-matcher'); ^
    if (-not $json.optionalDependencies) { $json | Add-Member -MemberType NoteProperty -Name 'optionalDependencies' -Value @{} }; ^
    $json.optionalDependencies.'@nut-tree/nl-matcher' = $val ^
}; ^
$json | ConvertTo-Json -Depth 10 | Set-Content 'examples\screen-test\package.json'"

if errorlevel 1 (
    echo ERROR: Failed to update examples\screen-test\package.json
    pause
    exit /b 1
)
echo [OK] Updated examples\screen-test\package.json

echo.
echo ==========================================
echo Step 5: Installing dependencies and building
echo ==========================================
echo.

echo Removing old lock file...
if exist "pnpm-lock.yaml" del /f /q "pnpm-lock.yaml" >nul 2>&1

echo Installing dependencies (this may take several minutes)...
if "%USE_NPX%"=="1" (
    call npx pnpm@8.15.2 install
) else (
    call pnpm install
)
if errorlevel 1 (
    echo ERROR: Failed to install dependencies
    pause
    exit /b 1
)

echo.
echo Compiling TypeScript packages...
if "%USE_NPX%"=="1" (
    call npx pnpm@8.15.2 run compile
) else (
    call pnpm run compile
)
if errorlevel 1 (
    echo ERROR: Failed to compile TypeScript packages
    pause
    exit /b 1
)

echo.
echo ==========================================
echo Installation Complete!
echo ==========================================
echo.
echo nut.js has been successfully built from source!
echo.
echo Build location: %BUILD_DIR%\nut.js
echo.
echo All files are contained in: %BUILD_DIR%
echo You can delete this entire directory if you need to start over.
echo.
echo To use in your project:
echo   cd %BUILD_DIR%\nut.js\core\nut.js
if "%USE_NPX%"=="1" (
    echo   npx pnpm@8.15.2 link
    echo.
    echo Then in your project:
    echo   npx pnpm@8.15.2 link @nut-tree/nut-js
) else (
    echo   pnpm link
    echo.
    echo Then in your project:
    echo   pnpm link @nut-tree/nut-js
)
echo.

pause
