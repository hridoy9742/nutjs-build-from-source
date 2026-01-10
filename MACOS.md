# Building nut.js from Source on macOS

This guide will walk you through building nut.js from source on macOS, including building the native dependencies.

## Prerequisites

### System Dependencies

Install Xcode Command Line Tools:

```bash
xcode-select --install
```

This will install the necessary compilers and build tools.

### Node.js and npm

Ensure you have Node.js installed (version 16 or higher for nut.js, 10.15.3+ for libnut-core):

```bash
node --version
npm --version
```

If not installed, install Node.js from [nodejs.org](https://nodejs.org/) or using Homebrew:

```bash
brew install node
```

### Configure npm for User Installation (Optional, Avoid Permission Issues)

```bash
# Configure npm to use a directory in your home folder
mkdir -p ~/.npm-global
npm config set prefix '~/.npm-global'

# Add to your PATH (add this to ~/.zshrc or ~/.bash_profile)
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.zshrc
source ~/.zshrc
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

### macOS Permissions

nut.js requires Accessibility and Screen Recording permissions. The library will prompt you automatically, but you can grant them manually:

1. Open **System Settings** (or **System Preferences** on older macOS)
2. Go to **Privacy & Security**
3. Enable **Accessibility** for your terminal/IDE
4. Enable **Screen Recording** for your terminal/IDE

**Note**: You'll need to grant permissions to:
- Terminal.app (if using Terminal)
- iTerm.app (if using iTerm2)
- Your IDE (VSCode, IntelliJ, etc.) if running scripts from there

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

# Patch the package name for your platform (macOS)
CI=true npm run patch

# Build the release version
npm run build:release
```

This will compile the native C/C++/Objective-C code and create a `.node` module. The build output will be in `build/Release/`.

**Note**: The build supports both Intel (x86_64) and Apple Silicon (arm64) architectures.

### Step 3: Clone nut.js

```bash
# Go back to your build directory
cd ~/nutjs-build

# Clone nut.js
git clone https://github.com/nut-tree/nut.js.git
cd nut.js
```

### Step 4: Configure nut.js to Use Local libnut-core

Edit `nut.js/providers/libnut/package.json` and change the macOS dependency:

**Find this line:**
```json
"@nut-tree/libnut-darwin": "2.7.1",
```

**Replace with:**
```json
"@nut-tree/libnut-darwin": "file:../../../libnut-core",
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

**Make Windows/Linux packages optional** (move them to `optionalDependencies`):

**Find:**
```json
"dependencies": {
  "@nut-tree/libnut-darwin": "file:../../../libnut-core",
  "@nut-tree/libnut-linux": "2.7.1",
  "@nut-tree/libnut-win32": "2.7.1"
}
```

**Replace with:**
```json
"dependencies": {
  "@nut-tree/libnut-darwin": "file:../../../libnut-core"
},
"optionalDependencies": {
  "@nut-tree/libnut-linux": "2.7.1",
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

- **Xcode Command Line Tools not found**: Run `xcode-select --install`
- **Compiler errors**: Ensure Xcode Command Line Tools are properly installed
- **Architecture issues**: The build automatically supports both Intel and Apple Silicon

### Permission Warnings

If you see warnings about Accessibility or Screen Recording:
1. Go to **System Settings** > **Privacy & Security**
2. Add your terminal/IDE to **Accessibility**
3. Add your terminal/IDE to **Screen Recording**

### Package Not Found Errors

If you see errors about premium packages (`@nut-tree/libnut-linux`, `@nut-tree/libnut-win32`, `@nut-tree/nl-matcher`, etc.), ensure you've moved them to `optionalDependencies` as described in Step 4 and Step 5.

### Apple Silicon (M1/M2/M3) Issues

The build should work automatically on Apple Silicon. If you encounter issues:
- Ensure you're using a Node.js version compiled for arm64
- Check that Xcode Command Line Tools are installed for your architecture

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
├── libnut-core/          # Native C/C++/Objective-C module
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
