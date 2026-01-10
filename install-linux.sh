#!/bin/bash
# nut.js Installation Script for Linux
# This script automates building nut.js from source on Linux

set -e  # Exit on error

echo "=========================================="
echo "nut.js Installation Script for Linux"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root (we don't want that for npm)
if [ "$EUID" -eq 0 ]; then 
   echo -e "${RED}Error: Please do not run this script as root${NC}"
   exit 1
fi

# Detect platform
PLATFORM="linux"
echo -e "${GREEN}Detected platform: Linux${NC}"

# Check prerequisites
echo ""
echo "Checking prerequisites..."

# Check for Node.js
if ! command -v node &> /dev/null; then
    echo -e "${RED}Error: Node.js is not installed${NC}"
    echo "Please install Node.js from https://nodejs.org/"
    exit 1
fi
NODE_VERSION=$(node --version)
NODE_MAJOR=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
NODE_MINOR=$(node --version | cut -d'v' -f2 | cut -d'.' -f2)
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
    echo "Install with: sudo apt-get install git"
    exit 1
fi
GIT_VERSION=$(git --version)
echo -e "${GREEN}✓ git found: $GIT_VERSION${NC}"

# Check for Python3 (needed for JSON manipulation in script)
if ! command -v python3 &> /dev/null; then
    echo -e "${YELLOW}Warning: python3 not found. Installing system dependencies...${NC}"
    echo "Please enter your password to install build dependencies:"
    sudo apt-get update
    sudo apt-get install -y python3 python3-json
fi
PYTHON_VERSION=$(python3 --version 2>&1)
echo -e "${GREEN}✓ Python3 found: $PYTHON_VERSION${NC}"

# Check for cmake and other build tools
MISSING_TOOLS=()
if ! command -v cmake &> /dev/null; then
    MISSING_TOOLS+=("cmake")
fi
if ! command -v g++ &> /dev/null && ! command -v gcc &> /dev/null; then
    MISSING_TOOLS+=("build-essential")
fi
if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
    echo -e "${YELLOW}Warning: Some build tools are missing. Installing system dependencies...${NC}"
    echo "Missing: ${MISSING_TOOLS[*]}"
    echo "Please enter your password to install build dependencies:"
    sudo apt-get update
    sudo apt-get install -y cmake libx11-dev zlib1g-dev libpng-dev libxtst-dev build-essential python3
fi

# Verify build tools are now available
if ! command -v cmake &> /dev/null; then
    echo -e "${RED}Error: cmake installation failed${NC}"
    exit 1
fi
CMAKE_VERSION=$(cmake --version | head -n1)
echo -e "${GREEN}✓ Build tools found: $CMAKE_VERSION${NC}"

# Configure npm to avoid permission issues
echo ""
echo "Configuring npm for user installation..."
mkdir -p ~/.npm-global
npm config set prefix '~/.npm-global' 2>/dev/null || true

# Add to PATH if not already there
if [[ ":$PATH:" != *":$HOME/.npm-global/bin:"* ]]; then
    echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
    export PATH=~/.npm-global/bin:$PATH
    echo -e "${GREEN}✓ npm configured${NC}"
else
    echo -e "${GREEN}✓ npm already configured${NC}"
fi

# Install pnpm
echo ""
echo "Installing pnpm..."
if ! command -v pnpm &> /dev/null; then
    npm install -g pnpm@8.15.2
    echo -e "${GREEN}✓ pnpm installed${NC}"
else
    PNPM_VERSION=$(pnpm --version)
    echo -e "${GREEN}✓ pnpm found: $PNPM_VERSION${NC}"
fi

# Set build directory
BUILD_DIR="$HOME/nutjs-build"
echo ""
echo "Build directory: $BUILD_DIR"
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

echo "Patching package name for Linux..."
CI=true npm run patch

echo "Building release version (this may take a few minutes)..."
npm run build:release

if [ -f "build/Release/libnut.node" ] || [ -f "build/Release/libnut-linux.node" ]; then
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

# Update providers/libnut/package.json
LIBNUT_PKG="providers/libnut/package.json"
echo "Updating $LIBNUT_PKG..."

# Create backup
cp "$LIBNUT_PKG" "$LIBNUT_PKG.bak"

# Update dependencies - replace the dependencies section
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i.tmp 's|"@nut-tree/libnut-darwin": "2.7.1"|"@nut-tree/libnut-darwin": "file:../../../libnut-core"|g' "$LIBNUT_PKG"
    sed -i.tmp 's|"@nut-tree/libnut-linux": "2.7.1"|"@nut-tree/libnut-linux": "2.7.1"|g' "$LIBNUT_PKG"
    # Move linux and win32 to optionalDependencies
    python3 << 'PYTHON_SCRIPT'
import json
import sys

with open('providers/libnut/package.json', 'r') as f:
    data = json.load(f)

# Move darwin to dependencies with file path, others to optional
deps = data.get('dependencies', {})
darwin_val = deps.get('@nut-tree/libnut-darwin', 'file:../../../libnut-core')
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
else
    # Linux
    python3 << 'PYTHON_SCRIPT'
import json
import sys

with open('providers/libnut/package.json', 'r') as f:
    data = json.load(f)

# Move linux to dependencies with file path, others to optional
deps = data.get('dependencies', {})
darwin_val = deps.get('@nut-tree/libnut-darwin', '2.7.1')
linux_val = 'file:../../../libnut-core'
win32_val = deps.get('@nut-tree/libnut-win32', '2.7.1')

data['dependencies'] = {'@nut-tree/libnut-linux': linux_val}
if 'optionalDependencies' not in data:
    data['optionalDependencies'] = {}
data['optionalDependencies']['@nut-tree/libnut-darwin'] = darwin_val
data['optionalDependencies']['@nut-tree/libnut-win32'] = win32_val

# Update peer dependency
if 'peerDependencies' in data:
    data['peerDependencies']['@nut-tree/nut-js'] = '^4'

with open('providers/libnut/package.json', 'w') as f:
    json.dump(data, f, indent=2)
PYTHON_SCRIPT
fi

rm -f "$LIBNUT_PKG.tmp"
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
pnpm install

echo ""
echo "Compiling TypeScript packages..."
pnpm run compile

echo ""
echo "=========================================="
echo -e "${GREEN}Installation Complete!${NC}"
echo "=========================================="
echo ""
echo "nut.js has been successfully built from source!"
echo ""
echo "Build location: $BUILD_DIR/nut.js"
echo ""
echo "To use in your project:"
echo "  cd $BUILD_DIR/nut.js/core/nut.js"
echo "  pnpm link"
echo ""
echo "Then in your project:"
echo "  pnpm link @nut-tree/nut-js"
echo ""
