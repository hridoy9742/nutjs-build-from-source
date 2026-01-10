#!/bin/bash
# nut.js Installation Script for macOS
# This script automates building nut.js from source on macOS

set -e  # Exit on error

echo "=========================================="
echo "nut.js Installation Script for macOS"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}Error: This script is for macOS only${NC}"
    exit 1
fi

# Check prerequisites
echo "Checking prerequisites..."

# Check for Xcode Command Line Tools
if ! xcode-select -p &> /dev/null; then
    echo -e "${RED}Error: Xcode Command Line Tools are not installed${NC}"
    echo "Please install them by running: xcode-select --install"
    echo "Then run this script again after installation completes."
    exit 1
fi
echo -e "${GREEN}✓ Xcode Command Line Tools found${NC}"

# Check for Node.js
if ! command -v node &> /dev/null; then
    echo -e "${RED}Error: Node.js is not installed${NC}"
    echo "Please install Node.js from https://nodejs.org/ or: brew install node"
    exit 1
fi
NODE_VERSION=$(node --version)
NODE_MAJOR=$(node --version | sed 's/v//' | cut -d'.' -f1)
NODE_MINOR=$(node --version | sed 's/v//' | cut -d'.' -f2)
echo -e "${GREEN}✓ Node.js found: $NODE_VERSION${NC}"

# Check Node.js version (need 10.15.3+ for libnut-core, 16+ recommended for nut.js)
if [ "$NODE_MAJOR" -lt 10 ] || ([ "$NODE_MAJOR" -eq 10 ] && [ "$NODE_MINOR" -lt 15 ]); then
    echo -e "${RED}Error: Node.js version 10.15.3 or higher is required${NC}"
    echo "Current version: $NODE_VERSION"
    echo "Please upgrade Node.js from https://nodejs.org/"
    exit 1
fi
if [ "$NODE_MAJOR" -lt 16 ]; then
    echo -e "${YELLOW}Warning: Node.js 16+ is recommended for nut.js (you have $NODE_VERSION)${NC}"
    echo "Continuing anyway, but you may encounter issues..."
fi

# Check for npm
if ! command -v npm &> /dev/null; then
    echo -e "${RED}Error: npm is not installed${NC}"
    exit 1
fi
NPM_VERSION=$(npm --version)
echo -e "${GREEN}✓ npm found: $NPM_VERSION${NC}"

# Check for git
if ! command -v git &> /dev/null; then
    echo -e "${RED}Error: git is not installed${NC}"
    echo "Install with: xcode-select --install (includes git)"
    exit 1
fi
GIT_VERSION=$(git --version)
echo -e "${GREEN}✓ git found: $GIT_VERSION${NC}"

# Check for Python3 (needed for JSON manipulation in script)
if ! command -v python3 &> /dev/null; then
    echo -e "${YELLOW}Warning: python3 not found${NC}"
    echo "Python3 is required for this script. Install with: brew install python3"
    exit 1
fi
PYTHON_VERSION=$(python3 --version 2>&1)
echo -e "${GREEN}✓ Python3 found: $PYTHON_VERSION${NC}"

# Check for pnpm (use npx if not available to avoid global install)
echo ""
echo "Checking for pnpm..."
if ! command -v pnpm &> /dev/null; then
    echo -e "${YELLOW}pnpm not found. Will use npx pnpm (no global installation needed)${NC}"
    USE_NPX=true
else
    PNPM_VERSION=$(pnpm --version)
    echo -e "${GREEN}✓ pnpm found: $PNPM_VERSION${NC}"
    USE_NPX=false
fi

# Set build directory (use current directory to keep everything self-contained)
BUILD_DIR="$(pwd)/nutjs-build"
echo ""
echo "Build directory: $BUILD_DIR"
echo -e "${YELLOW}Note: All files will be installed in this directory. You can delete it entirely if something goes wrong.${NC}"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Clone libnut-core
echo ""
echo "=========================================="
echo "Step 1: Cloning libnut-core"
echo "=========================================="
if [ -d "libnut-core" ]; then
    echo -e "${YELLOW}libnut-core directory exists. Pulling latest changes...${NC}"
    cd libnut-core
    git pull
    cd ..
else
    git clone https://github.com/nut-tree/libnut-core.git
    echo -e "${GREEN}✓ libnut-core cloned${NC}"
fi

# Build libnut-core
echo ""
echo "=========================================="
echo "Step 2: Building libnut-core"
echo "=========================================="
cd libnut-core

echo "Installing npm dependencies..."
npm install

echo "Patching package name for macOS..."
CI=true npm run patch

echo "Building release version (this may take a few minutes)..."
npm run build:release

if [ -f "build/Release/libnut.node" ] || [ -f "build/Release/libnut-darwin.node" ]; then
    echo -e "${GREEN}✓ libnut-core built successfully${NC}"
else
    echo -e "${RED}Error: Build output not found${NC}"
    exit 1
fi

cd ..

# Clone nut.js
echo ""
echo "=========================================="
echo "Step 3: Cloning nut.js"
echo "=========================================="
if [ -d "nut.js" ]; then
    echo -e "${YELLOW}nut.js directory exists. Pulling latest changes...${NC}"
    cd nut.js
    git pull
    cd ..
else
    git clone https://github.com/nut-tree/nut.js.git
    echo -e "${GREEN}✓ nut.js cloned${NC}"
fi

# Configure nut.js
echo ""
echo "=========================================="
echo "Step 4: Configuring nut.js"
echo "=========================================="
cd nut.js

# Update providers/libnut/package.json using Python
LIBNUT_PKG="providers/libnut/package.json"
echo "Updating $LIBNUT_PKG..."

python3 << 'PYTHON_SCRIPT'
import json

with open('providers/libnut/package.json', 'r') as f:
    data = json.load(f)

# Move darwin to dependencies with file path, others to optional
deps = data.get('dependencies', {})
darwin_val = 'file:../../../libnut-core'
linux_val = deps.get('@nut-tree/libnut-linux', '2.7.1')
win32_val = deps.get('@nut-tree/libnut-win32', '2.7.1')

data['dependencies'] = {'@nut-tree/libnut-darwin': darwin_val}
if 'optionalDependencies' not in data:
    data['optionalDependencies'] = {}
data['optionalDependencies']['@nut-tree/libnut-linux'] = linux_val
data['optionalDependencies']['@nut-tree/libnut-win32'] = win32_val

# Update peer dependency
if 'peerDependencies' in data:
    data['peerDependencies']['@nut-tree/nut-js'] = '^4'

with open('providers/libnut/package.json', 'w') as f:
    json.dump(data, f, indent=2)
PYTHON_SCRIPT

echo -e "${GREEN}✓ Updated $LIBNUT_PKG${NC}"

# Update providers/clipboardy/package.json
CLIPBOARDY_PKG="providers/clipboardy/package.json"
echo "Updating $CLIPBOARDY_PKG..."
python3 << 'PYTHON_SCRIPT'
import json

with open('providers/clipboardy/package.json', 'r') as f:
    data = json.load(f)

if 'peerDependencies' in data:
    data['peerDependencies']['@nut-tree/nut-js'] = '^4'

with open('providers/clipboardy/package.json', 'w') as f:
    json.dump(data, f, indent=2)
PYTHON_SCRIPT
echo -e "${GREEN}✓ Updated $CLIPBOARDY_PKG${NC}"

# Update examples/screen-test/package.json
SCREEN_TEST_PKG="examples/screen-test/package.json"
echo "Updating $SCREEN_TEST_PKG..."
python3 << 'PYTHON_SCRIPT'
import json

with open('examples/screen-test/package.json', 'r') as f:
    data = json.load(f)

deps = data.get('dependencies', {})
if '@nut-tree/nl-matcher' in deps:
    nl_matcher_val = deps.pop('@nut-tree/nl-matcher')
    if 'optionalDependencies' not in data:
        data['optionalDependencies'] = {}
    data['optionalDependencies']['@nut-tree/nl-matcher'] = nl_matcher_val
    data['dependencies'] = deps

with open('examples/screen-test/package.json', 'w') as f:
    json.dump(data, f, indent=2)
PYTHON_SCRIPT
echo -e "${GREEN}✓ Updated $SCREEN_TEST_PKG${NC}"

# Install and build
echo ""
echo "=========================================="
echo "Step 5: Installing dependencies and building"
echo "=========================================="

echo "Removing old lock file..."
rm -f pnpm-lock.yaml

echo "Installing dependencies (this may take a few minutes)..."
if [ "$USE_NPX" = true ]; then
    npx pnpm@8.15.2 install
else
    pnpm install
fi

echo ""
echo "Compiling TypeScript packages..."
if [ "$USE_NPX" = true ]; then
    npx pnpm@8.15.2 run compile
else
    pnpm run compile
fi

echo ""
echo "=========================================="
echo -e "${GREEN}Installation Complete!${NC}"
echo "=========================================="
echo ""
echo "nut.js has been successfully built from source!"
echo ""
echo "Build location: $BUILD_DIR/nut.js"
echo ""
echo -e "${YELLOW}All files are contained in: $BUILD_DIR${NC}"
echo -e "${YELLOW}You can delete this entire directory if you need to start over.${NC}"
echo ""
echo "⚠️  IMPORTANT: macOS Permissions Required"
echo "nut.js needs Accessibility and Screen Recording permissions:"
echo "  1. Open System Settings > Privacy & Security"
echo "  2. Enable Accessibility for your terminal/IDE"
echo "  3. Enable Screen Recording for your terminal/IDE"
echo ""
echo "To use in your project:"
echo "  cd $BUILD_DIR/nut.js/core/nut.js"
if [ "$USE_NPX" = true ]; then
    echo "  npx pnpm@8.15.2 link"
    echo ""
    echo "Then in your project:"
    echo "  npx pnpm@8.15.2 link @nut-tree/nut-js"
else
    echo "  pnpm link"
    echo ""
    echo "Then in your project:"
    echo "  pnpm link @nut-tree/nut-js"
fi
echo ""
