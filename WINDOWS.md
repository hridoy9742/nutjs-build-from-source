# Building nut.js from Source on Windows

This guide will walk you through building nut.js from source on Windows, including building the native dependencies.

## Prerequisites

### System Dependencies

#### Visual Studio Build Tools Installation

**⚠️ Important:** The `windows-build-tools` npm package is deprecated and no longer works. You must install Visual Studio Build Tools manually by downloading the installer from Microsoft's website.

1. **Visual Studio 2022 Build Tools** (Required):
   - Go to [Visual Studio Downloads](https://visualstudio.microsoft.com/downloads/)
   - Scroll down to "Tools for Visual Studio" section
   - Download **"Build Tools for Visual Studio 2022"** (not Visual Studio 2026 or newer)
   - Run the downloaded installer (`.exe` file)
   - During installation, select the **"Desktop development with C++"** workload
   - Ensure **"Windows 10/11 SDK"** is selected (usually selected by default)
   - Click "Install" and wait for the installation to complete (this may take 10-30 minutes)

   **Note:** Visual Studio 2026 and newer versions are not yet recognized by node-gyp/cmake-js. You must use Visual Studio 2022 Build Tools.

2. **Python** (for node-gyp):
   - Download from [python.org](https://www.python.org/downloads/)
   - During installation, check **"Add Python to PATH"**
   - Python 3.8 or higher is recommended

3. **Verify Visual Studio 2022 Installation:**
   - After installation completes, verify it was successful by running this command in a regular Command Prompt:
     ```cmd
     where devenv
     ```
   - If the command returns a path (e.g., `C:\Program Files\Microsoft Visual Studio\2022\BuildTools\Common7\IDE\devenv.exe`), the installation was successful.
   - If the command returns nothing, the installation may have failed or the tools are not in your PATH.

4. **⚠️ Important: Use Developer Command Prompt for VS 2022**
   - **All subsequent commands in this guide must be run in the "Developer Command Prompt for VS 2022"**
   - You can find it by searching for "Developer Command Prompt" in the Start menu
   - Look for **"Developer Command Prompt for VS 2022"** (not VS 2026 or newer)
   - This sets up all necessary environment variables (PATH, VCINSTALLDIR, etc.) that are required for building native Node.js modules
   - **Do not use regular Command Prompt or PowerShell** - the build will fail without these environment variables

### Node.js and npm

Ensure you have Node.js installed (version 16 or higher for nut.js, 10.15.3+ for libnut-core):

```cmd
node --version
npm --version
```

If not installed, download and install from [nodejs.org](https://nodejs.org/).

### Configure npm for User Installation (Avoid Permission Issues)

```cmd
REM Configure npm to use a directory in your home folder
mkdir "%APPDATA%\npm-global" 2>nul
npm config set prefix "%APPDATA%\npm-global"

REM Add to your PATH (you may need to add this manually to your system PATH)
setx PATH "%PATH%;%APPDATA%\npm-global"
```

**Note:** After running `setx`, you may need to close and reopen your command prompt for PATH changes to take effect.

### Install pnpm

nut.js uses pnpm as its package manager. Install it:

```cmd
npm install -g pnpm@8.15.2
```

### pnpm verification

```cmd
pnpm -v
```

### Windows 10 N Edition

If you're running Windows 10 N and want to use ImageFinder plugins, install the [Media Feature Pack](https://support.microsoft.com/en-us/topic/media-feature-pack-for-windows-10-n-may-2020-ebbdf559-b84c-0fc2-bd51-e23c9f6a4439).

## Installation Steps

**⚠️ Important:** From this point forward, **all commands must be run in the "Developer Command Prompt for VS 2022"**. Do not use regular Command Prompt or PowerShell.

**Option: Automated Installation Script**

If you prefer an automated installation, you can use the `install-windows.bat` script which automates all the steps below. The script:
- Checks prerequisites
- Clones repositories
- Builds libnut-core
- Automatically edits package.json files
- Installs dependencies and compiles

To use the script, open "Developer Command Prompt for VS 2022" and run:
```cmd
install-windows.bat
```

**Manual Installation (Step-by-Step)**

If you prefer to follow the steps manually or need more control, continue with the steps below.

### Step 1: Clone the Repositories

Open the **Developer Command Prompt for VS 2022** and run:

```cmd
REM Create a directory for the projects
mkdir nutjs-build
cd nutjs-build

REM Clone libnut-core (the native dependency)
git clone https://github.com/nut-tree/libnut-core.git
cd libnut-core
```

### Step 2: Build libnut-core

**Important:** Make sure you're in the **"Developer Command Prompt for VS 2022"** (not VS 2026). This ensures all necessary environment variables are set correctly.

```cmd
REM Install npm dependencies
npm install

REM Patch the package name for your platform (Windows)
set CI=true
npm run patch

REM Build the release version
npm run build:release
```

This will compile the native C/C++ code and create a `.node` module. The build output will be in `build\Release\`.

**Note**: The first build may take several minutes as it compiles all native dependencies.

### Step 3: Clone nut.js

```cmd
REM Go back to your build directory
cd ..

REM Clone nut.js
git clone https://github.com/nut-tree/nut.js.git
cd nut.js
```

### Step 4: Configure nut.js to Use Local libnut-core

Edit `nut.js\providers\libnut\package.json` and change the Windows dependency:

**Find this line:**
```json
"@nut-tree/libnut-win32": "2.7.1",
```

**Replace with:**
```json
"@nut-tree/libnut-win32": "file:../../../libnut-core",
```

**Also update the peer dependency** (change `^3` to `^4` to match workspace version):

**Find:**
```json
"peerDependencies": {
  "@nut-tree/nut-js": "^3"
}
```

**Replace with:**
```json
"peerDependencies": {
  "@nut-tree/nut-js": "^4"
}
```

**Make macOS/Linux packages optional** (move them to `optionalDependencies`):

**Find:**
```json
"dependencies": {
  "@nut-tree/libnut-darwin": "2.7.1",
  "@nut-tree/libnut-linux": "2.7.1",
  "@nut-tree/libnut-win32": "file:../../../libnut-core"
}
```

**Replace with:**
```json
"dependencies": {
  "@nut-tree/libnut-win32": "file:../../../libnut-core"
},
"optionalDependencies": {
  "@nut-tree/libnut-darwin": "2.7.1",
  "@nut-tree/libnut-linux": "2.7.1"
}
```

### Step 5: Handle Premium Package Dependencies

Edit `nut.js\examples\screen-test\package.json` to make premium packages optional:

**Find:**
```json
"dependencies": {
  "@nut-tree/nut-js": "workspace:*",
  "@nut-tree/nl-matcher": "2.2.0"
}
```

**Replace with:**
```json
"dependencies": {
  "@nut-tree/nut-js": "workspace:*"
},
"optionalDependencies": {
  "@nut-tree/nl-matcher": "2.2.0"
}
```

Update peer dependencies in `nut.js\providers\clipboardy\package.json`:

**Find:**
```json
"peerDependencies": {
  "@nut-tree/nut-js": "^3"
}
```

**Replace with:**
```json
"peerDependencies": {
  "@nut-tree/nut-js": "^4"
}
```

### Step 6: Install Dependencies and Build

```cmd
REM Remove old lock file to regenerate with workspace packages (in nutjs directory)
del pnpm-lock.yaml 2>nul

REM Install all dependencies
pnpm install

REM Compile all TypeScript packages
pnpm run compile
```

## Verification

To verify the installation worked:

```cmd
REM Check that the compiled packages exist
dir core\nut.js\dist
dir providers\libnut\dist
```

If both directories exist and contain files, the installation was successful.

## Using Your Built nut.js

### Step 1: Create a Global Link

From the nut.js package directory, create a global link (in Developer Command Prompt for VS 2022):

```cmd
cd nutjs-build\nut.js\core\nut.js
pnpm link --global
```

### Step 2: Link in Your Project

Navigate to your project directory and link the package (in Developer Command Prompt for VS 2022):

```cmd
cd C:\path\to\your\project
pnpm link --global @nut-tree/nut-js
```

### Step 3: Update Your Project's package.json

In your project's `package.json`:

```json
{
  "dependencies": {
    "@nut-tree/nut-js": "link:"
  }
}
```

Then run `pnpm install` or `npm install` in your project. You got yourself a free, self-built nutjs, go nuts!!!

## Troubleshooting

### Visual Studio Version Errors

**Error: "unknown version 'undefined' found" or "could not find a version of Visual Studio 2017 or newer to use"**

This error occurs when you have Visual Studio 2026 or newer installed. node-gyp/cmake-js does not yet recognize these newer versions.

**Solution:** 
- Install **Visual Studio 2022 Build Tools** (not 2026 or newer)
- Use the "Developer Command Prompt for VS 2022" (not VS 2026)
- If you have both versions installed, you can create a `.npmrc` file in the `libnut-core` directory with:
  ```
  msvs_version=2022
  ```

### Build Tool Errors

**Error: "MSBuild.exe not found"**
- Ensure Visual Studio 2022 Build Tools are installed
- **You must run commands from "Developer Command Prompt for VS 2022"** - regular Command Prompt will not work
- Verify installation by running in Developer Command Prompt: `where devenv`
- If `where devenv` returns a path, VS 2022 is installed correctly
- If it returns nothing, reinstall Visual Studio 2022 Build Tools

**Error: "Python not found"**
- Install Python from [python.org](https://www.python.org/downloads/)
- During installation, ensure "Add Python to PATH" is checked
- Verify installation by running: `python --version`

**Error: "node-gyp rebuild failed" or "cmake-js rebuild failed"**
- Ensure you have Visual Studio 2022 Build Tools installed (not 2026 or newer)
- Ensure "Desktop development with C++" workload is installed
- Ensure "Windows 10/11 SDK" is selected
- Run from "Developer Command Prompt for VS 2022"
- If using VS 2026, install VS 2022 Build Tools alongside it

### Path Issues

Windows uses backslashes in paths. If you encounter path issues:
- Use forward slashes in package.json file paths (npm/pnpm handle this)
- Or use double backslashes: `file:..\\..\\..\\libnut-core`

### Package Not Found Errors

If you see errors about premium packages (`@nut-tree/libnut-darwin`, `@nut-tree/libnut-linux`, `@nut-tree/nl-matcher`, etc.), ensure you've moved them to `optionalDependencies` as described in Step 4 and Step 5.

### Long Path Issues

If you encounter "path too long" errors:
1. Enable long paths in Windows (requires admin, run Command Prompt as Administrator):
   ```cmd
   reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v LongPathsEnabled /t REG_DWORD /d 1 /f
   ```
   Then restart your computer.
2. Or build in a shorter path (e.g., `C:\nutjs` instead of deep nested paths)

### Antivirus Interference

Some antivirus software may interfere with the build process:
- Temporarily disable real-time scanning during build
- Add your build directory to antivirus exclusions
