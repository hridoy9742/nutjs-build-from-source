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
```powershell
# Download the script
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/buiilding/nutjs-build-from-source/main/install-windows.ps1" -OutFile "install-windows.ps1"

# Run the script (may need to allow script execution)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\install-windows.ps1
```

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
3. Share your experience in the Discord community

## License

nut.js and libnut-core are licensed under Apache-2.0. These guides are provided as-is to help the community build from source.
