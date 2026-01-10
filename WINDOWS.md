# Building nut.js from Source on Windows

This guide will walk you through building nut.js from source on Windows, including building the native dependencies.

## Prerequisites

### System Dependencies

#### Option 1: Install windows-build-tools (Recommended)

From an **elevated PowerShell or CMD.exe** (Run as Administrator):

```powershell
npm install --global --production windows-build-tools
```

This installs:
- Visual C++ Build Tools
- Python (required for node-gyp)
- Other necessary build tools

#### Option 2: Manual Installation

If you prefer to install manually:

1. **Visual Studio Build Tools** or **Visual Studio Community**:
   - Download from [Visual Studio Downloads](https://visualstudio.microsoft.com/downloads/)
   - Install "Desktop development with C++" workload
   - Ensure "Windows 10/11 SDK" is selected

2. **Python** (for node-gyp):
   - Download from [python.org](https://www.python.org/downloads/)
   - During installation, check "Add Python to PATH"

### Node.js and npm

Ensure you have Node.js installed (version 16 or higher for nut.js, 10.15.3+ for libnut-core):

```powershell
node --version
npm --version
```

If not installed, download and install from [nodejs.org](https://nodejs.org/).

### Install pnpm

nut.js uses pnpm as its package manager. Install it:

```powershell
npm install -g pnpm@8.15.2
```

Or if you have Node.js 16.13+ with corepack:

```powershell
corepack enable
corepack prepare pnpm@8.15.2 --activate
```

### Windows 10 N Edition

If you're running Windows 10 N and want to use ImageFinder plugins, install the [Media Feature Pack](https://support.microsoft.com/en-us/topic/media-feature-pack-for-windows-10-n-may-2020-ebbdf559-b84c-0fc2-bd51-e23c9f6a4439).

## Installation Steps

### Step 1: Clone the Repositories

Open PowerShell or Git Bash:

```powershell
# Create a directory for the projects
New-Item -ItemType Directory -Force -Path "$HOME\nutjs-build"
cd "$HOME\nutjs-build"

# Clone libnut-core (the native dependency)
git clone https://github.com/nut-tree/libnut-core.git
cd libnut-core
```

Or using Git Bash:

```bash
mkdir -p ~/nutjs-build
cd ~/nutjs-build
git clone https://github.com/nut-tree/libnut-core.git
cd libnut-core
```

### Step 2: Build libnut-core

```powershell
# Install npm dependencies
npm install

# Patch the package name for your platform (Windows)
$env:CI = "true"
npm run patch

# Build the release version
npm run build:release
```

This will compile the native C/C++ code and create a `.node` module. The build output will be in `build\Release\`.

**Note**: The first build may take several minutes as it compiles all native dependencies.

### Step 3: Clone nut.js

```powershell
# Go back to your build directory
cd ..

# Clone nut.js
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

```powershell
# Remove old lock file to regenerate with workspace packages
Remove-Item -Force pnpm-lock.yaml -ErrorAction SilentlyContinue

# Install all dependencies
pnpm install

# Compile all TypeScript packages
pnpm run compile
```

## Verification

To verify the installation worked:

```powershell
# Check that the compiled packages exist
Test-Path core\nut.js\dist\
Test-Path providers\libnut\dist\
```

Or list the directories:

```powershell
Get-ChildItem core\nut.js\dist\
Get-ChildItem providers\libnut\dist\
```

## Using Your Built nut.js

### Option 1: Link to Your Project

```powershell
cd nut.js\core\nut.js
pnpm link

# In your project directory
cd C:\path\to\your\project
pnpm link @nut-tree/nut-js
```

### Option 2: Use File Path in Your Project

In your project's `package.json`:

```json
{
  "dependencies": {
    "@nut-tree/nut-js": "file:../nutjs-build/nut.js/core/nut.js"
  }
}
```

Then run `pnpm install` or `npm install` in your project.

## Troubleshooting

### Build Tool Errors

**Error: "MSBuild.exe not found"**
- Ensure Visual Studio Build Tools or Visual Studio is installed
- Run from "Developer Command Prompt for VS" or ensure MSBuild is in PATH

**Error: "Python not found"**
- Install Python and ensure it's added to PATH
- Or use windows-build-tools which includes Python

**Error: "node-gyp rebuild failed"**
- Ensure you have the Windows SDK installed
- Try running: `npm install --global windows-build-tools`

### Permission Errors

If you get permission errors, try:
1. Run PowerShell/CMD as Administrator
2. Or configure npm to use a user directory:
   ```powershell
   npm config set prefix "$env:APPDATA\npm-global"
   $env:PATH += ";$env:APPDATA\npm-global"
   ```

### Path Issues

Windows uses backslashes in paths. If you encounter path issues:
- Use forward slashes in package.json file paths (npm/pnpm handle this)
- Or use double backslashes: `file:..\\..\\..\\libnut-core`

### Package Not Found Errors

If you see errors about premium packages (`@nut-tree/libnut-darwin`, `@nut-tree/libnut-linux`, `@nut-tree/nl-matcher`, etc.), ensure you've moved them to `optionalDependencies` as described in Step 4 and Step 5.

### Long Path Issues

If you encounter "path too long" errors:
1. Enable long paths in Windows (requires admin):
   ```powershell
   New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled" -Value 1 -PropertyType DWORD -Force
   ```
2. Or build in a shorter path (e.g., `C:\nutjs` instead of deep nested paths)

### Antivirus Interference

Some antivirus software may interfere with the build process:
- Temporarily disable real-time scanning during build
- Add your build directory to antivirus exclusions

## What Features Are Available?

With the open-source build, you have access to:

✅ **Core Features:**
- Keyboard input (typing, key presses)
- Mouse control (movement, clicks, scrolling, dragging)
- Screen capture (screenshots, color detection, highlighting)
- Window management (list windows, get active window, focus, resize, reposition)
- Clipboard operations (copy/paste text)

❌ **Premium Features (Not Available):**
- OCR/text recognition on screen
- Advanced image matching
- GUI element inspection
- Window minimize/restore (some platforms)
- Advanced screen hooks

## Directory Structure

After installation, your directory structure should look like:

```
%USERPROFILE%\nutjs-build\
├── libnut-core\          # Native C/C++ module
│   ├── build\           # Build output
│   └── ...
└── nut.js\              # TypeScript monorepo
    ├── core\
    │   ├── nut.js\      # Main package
    │   ├── shared\      # Shared utilities
    │   └── provider-interfaces\
    ├── providers\
    │   ├── libnut\      # libnut provider
    │   └── clipboardy\  # Clipboard provider
    └── ...
```

## Next Steps

- Read the [nut.js documentation](https://nutjs.dev)
- Check out the [examples](https://github.com/nut-tree/nut.js/tree/master/examples)
- Join the [Discord community](https://discord.gg/U5csuM4Esp)

## Support

If you encounter issues:
1. Check the [nut.js issues](https://github.com/nut-tree/nut.js/issues)
2. Check the [libnut-core issues](https://github.com/nut-tree/libnut-core/issues)
3. Join the Discord community for help
