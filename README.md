# nut.js Installation Guides

This repo offers guides to install nutjs from source as the prebuilt versions cannot be accessed unless you have a paid subscription.

## Quick Start.

The automated scripts are designed to warn about missing prerequisites instead of auto-installing them, so you can install them manually and control any system-wide changes at your own risk. It only installs packages within the build directory, which you can safely delete and build again if you encounter any trouble.

### Linux

```bash
wget https://raw.githubusercontent.com/buiilding/nutjs-build-from-source/main/install-linux.sh
chmod +x install-linux.sh
./install-linux.sh
```

### macOS

```bash
wget https://raw.githubusercontent.com/buiilding/nutjs-build-from-source/main/install-macos.sh
chmod +x install-macos.sh
./install-macos.sh
```

### Windows

**⚠️ Important:** The Windows installation script **MUST** be run in the "Developer Command Prompt for VS 2022". Do not use regular Command Prompt or PowerShell.

1. **First, install Visual Studio 2022 Build Tools:**
   - Go to [Visual Studio Downloads](https://visualstudio.microsoft.com/downloads/)
   - Download "Build Tools for Visual Studio 2022"
   - Install with "Desktop development with C++" workload
   - Verify installation: Open regular Command Prompt and run `where devenv`

2. **Open "Developer Command Prompt for VS 2022"** (search in Start menu)

3. **Download and run the script:**
```cmd
REM Download the script (or download manually from GitHub)
curl -o install-windows.bat https://raw.githubusercontent.com/buiilding/nutjs-build-from-source/main/install-windows.bat

REM Run the script
install-windows.bat
```

**Note:** If you prefer step-by-step manual installation, see the [Windows Installation Guide](./WINDOWS.md).

## Manual Guides

If you prefer to install from source step-by-step, go to each corresponding os guide:

- **[Linux Installation Guide](./LINUX.md)**
- **[macOS Installation Guide](./MACOS.md)**
- **[Windows Installation Guide](./WINDOWS.md)**
- **[File Changes Reference](./FILE_CHANGES.md)** - Reference for required file modifications

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

## Contributing

If you find issues with these guides or have improvements, please:
1. Open an issue in the repository
2. Submit a pull request with your improvements

## License

nut.js and libnut-core are licensed under Apache-2.0. These guides are provided as-is to help the community build from source.
