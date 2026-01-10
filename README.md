# nut.js Installation Guides

Complete guides for building nut.js from source on Linux, macOS, and Windows.

## Overview

nut.js is a cross-platform native UI automation library. While pre-built packages are available through subscription plans, you can build the entire library from source for free. These guides walk you through the complete process.

## Quick Start (Automated Installation)

**Prefer a one-command installation?** We provide automated scripts that handle everything:

### Linux
```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/docs/nutjs-installation-guides/install-linux.sh | bash
```

Or download and run:
```bash
wget https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/docs/nutjs-installation-guides/install-linux.sh
chmod +x install-linux.sh
./install-linux.sh
```

### macOS
```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/docs/nutjs-installation-guides/install-macos.sh | bash
```

Or download and run:
```bash
wget https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/docs/nutjs-installation-guides/install-macos.sh
chmod +x install-macos.sh
./install-macos.sh
```

### Windows
Download and run in PowerShell:
```powershell
# Download the script
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/docs/nutjs-installation-guides/install-windows.ps1" -OutFile "install-windows.ps1"

# Run the script (may need to allow script execution)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\install-windows.ps1
```

**Note**: Replace `YOUR_USERNAME/YOUR_REPO` with your actual GitHub repository path.

## Manual Installation Guides

If you prefer step-by-step instructions or need to troubleshoot:

- **[Linux Installation Guide](./LINUX.md)** - For Ubuntu, Debian, Fedora, Arch, and other Linux distributions
- **[macOS Installation Guide](./MACOS.md)** - For macOS (Intel and Apple Silicon)
- **[Windows Installation Guide](./WINDOWS.md)** - For Windows 10/11
- **[File Changes Reference](./FILE_CHANGES.md)** - Quick reference for required file modifications

## What You'll Build

1. **libnut-core** - The native C/C++ module that provides low-level system automation
2. **nut.js** - The TypeScript/JavaScript library that provides the high-level API

## Prerequisites Summary

### All Platforms
- Node.js (16+ for nut.js, 10.15.3+ for libnut-core)
- npm or pnpm
- Git

### Platform-Specific
- **Linux**: cmake, build-essential, libxtst-dev, libpng-dev
- **macOS**: Xcode Command Line Tools
- **Windows**: Visual Studio Build Tools or windows-build-tools

## Installation Process Overview

1. Install prerequisites
2. Clone `libnut-core` repository
3. Build `libnut-core` native module
4. Clone `nut.js` repository
5. Configure `nut.js` to use local `libnut-core`
6. Install dependencies and compile

## Available Features

With the open-source build, you get:

✅ **Core Features:**
- Keyboard automation (typing, key presses)
- Mouse control (movement, clicks, scrolling, dragging)
- Screen capture (screenshots, color detection, highlighting)
- Window management (list, focus, resize, reposition)
- Clipboard operations

❌ **Premium Features (Not Available):**
- OCR/text recognition
- Advanced image matching
- GUI element inspection
- Advanced screen hooks

## Getting Help

- [nut.js GitHub Issues](https://github.com/nut-tree/nut.js/issues)
- [libnut-core GitHub Issues](https://github.com/nut-tree/libnut-core/issues)
- [nut.js Discord Community](https://discord.gg/U5csuM4Esp)
- [nut.js Documentation](https://nutjs.dev)

## Contributing

If you find issues with these guides or have improvements, please:
1. Open an issue in the repository
2. Submit a pull request with your improvements
3. Share your experience in the Discord community

## License

nut.js and libnut-core are licensed under Apache-2.0. These guides are provided as-is to help the community build from source.
