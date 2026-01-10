# Building nut.js from Source on Linux

This guide will walk you through building nut.js from source on Linux, including building the native dependencies.

## Prerequisites

### System Dependencies

Install the required build tools and libraries:

```bash
sudo apt-get update
sudo apt-get install -y cmake libx11-dev zlib1g-dev libpng-dev libxtst-dev build-essential
```

**Note**: If you're on a different Linux distribution, use your package manager:
- **Fedora/RHEL**: `sudo dnf install cmake libX11-devel zlib-devel libpng-devel libXtst-devel gcc gcc-c++`
- **Arch**: `sudo pacman -S cmake libx11 zlib libpng libxtst base-devel`

### Node.js and npm

Ensure you have Node.js installed (version 16 or higher for nut.js, 10.15.3+ for libnut-core):

```bash
node --version
npm --version
```

If not installed, install Node.js from [nodejs.org](https://nodejs.org/) or using your package manager.

### Configure npm for User Installation (Avoid Permission Issues)

```bash
# Configure npm to use a directory in your home folder
mkdir -p ~/.npm-global
npm config set prefix '~/.npm-global'

# Add to your PATH (add this to ~/.bashrc or ~/.zshrc)
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

### Install pnpm

nut.js uses pnpm as its package manager. Install it:

```bash
npm install -g pnpm@8.15.2
```

Or if you have Node.js 16.13+ with corepack:

```bash
corepack enable
corepack prepare pnpm@8.15.2 --activate
```

## Installation Steps

### Step 1: Clone the Repositories

```bash
# Create a directory for the projects
mkdir -p ~/nutjs-build
cd ~/nutjs-build

# Clone libnut-core (the native dependency)
git clone https://github.com/nut-tree/libnut-core.git
cd libnut-core
```

### Step 2: Build libnut-core

```bash
# Install npm dependencies
npm install

# Patch the package name for your platform (Linux)
CI=true npm run patch

# Build the release version
npm run build:release
```

This will compile the native C/C++ code and create a `.node` module. The build output will be in `build/Release/`.

### Step 3: Clone nut.js

```bash
# Go back to your build directory
cd ~/nutjs-build

# Clone nut.js
git clone https://github.com/nut-tree/nut.js.git
cd nut.js
```

### Step 4: Configure nut.js to Use Local libnut-core

Edit `nut.js/providers/libnut/package.json` and change the Linux dependency:

**Find this line:**
```json
"@nut-tree/libnut-linux": "2.7.1",
```

**Replace with:**
```json
"@nut-tree/libnut-linux": "file:../../../libnut-core",
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

**Make Windows/macOS packages optional** (move them to `optionalDependencies`):

**Find:**
```json
"dependencies": {
  "@nut-tree/libnut-darwin": "2.7.1",
  "@nut-tree/libnut-linux": "file:../../../libnut-core",
  "@nut-tree/libnut-win32": "2.7.1"
}
```

**Replace with:**
```json
"dependencies": {
  "@nut-tree/libnut-linux": "file:../../../libnut-core"
},
"optionalDependencies": {
  "@nut-tree/libnut-darwin": "2.7.1",
  "@nut-tree/libnut-win32": "2.7.1"
}
```

### Step 5: Handle Premium Package Dependencies

Edit `nut.js/examples/screen-test/package.json` to make premium packages optional:

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

Update peer dependencies in `nut.js/providers/clipboardy/package.json`:

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

```bash
# Remove old lock file to regenerate with workspace packages
rm -f pnpm-lock.yaml

# Install all dependencies
pnpm install

# Compile all TypeScript packages
pnpm run compile
```

## Verification

To verify the installation worked:

```bash
# Check that the compiled packages exist
ls -la core/nut.js/dist/
ls -la providers/libnut/dist/
```

## Using Your Built nut.js

### Option 1: Link to Your Project

```bash
cd ~/nutjs-build/nut.js/core/nut.js
pnpm link

# In your project directory
cd /path/to/your/project
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

### Permission Errors

If you get permission errors with npm, ensure you've configured the npm prefix:
```bash
npm config set prefix '~/.npm-global'
export PATH=~/.npm-global/bin:$PATH
```

### Build Errors

- **CMake not found**: Install cmake: `sudo apt-get install cmake`
- **Compiler errors**: Ensure build-essential is installed: `sudo apt-get install build-essential`
- **Missing libraries**: Install libxtst-dev: `sudo apt-get install libxtst-dev libpng-dev`

### Wayland Issues

nut.js only supports X11, not Wayland. If you're on Wayland:
- Switch to X11 session on login screen
- Or use XWayland (may have limitations)

### Package Not Found Errors

If you see errors about premium packages (`@nut-tree/libnut-win32`, `@nut-tree/nl-matcher`, etc.), ensure you've moved them to `optionalDependencies` as described in Step 4 and Step 5.

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
~/nutjs-build/
├── libnut-core/          # Native C/C++ module
│   ├── build/           # Build output
│   └── ...
└── nut.js/              # TypeScript monorepo
    ├── core/
    │   ├── nut.js/      # Main package
    │   ├── shared/      # Shared utilities
    │   └── provider-interfaces/
    ├── providers/
    │   ├── libnut/      # libnut provider
    │   └── clipboardy/  # Clipboard provider
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
