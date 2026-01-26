#!/bin/bash
# Fix Tizen Toolchain Installation
# Run this in the Ubuntu VM if toolchain installation failed

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=========================================="
echo "Fixing Tizen Toolchain Installation"
echo -e "==========================================${NC}"
echo ""

TIZEN_SDK_DIR="$HOME/tizen-studio"

if [ ! -d "$TIZEN_SDK_DIR" ]; then
    echo -e "${RED}✗ Tizen SDK not found at $TIZEN_SDK_DIR${NC}"
    echo "Please run the main setup script first."
    exit 1
fi

echo -e "${GREEN}✓ Tizen SDK found${NC}"
echo ""

# Check what's installed
echo "Checking installed packages..."
"$TIZEN_SDK_DIR/package-manager/package-manager-cli.bin" show-pkgs 2>/dev/null | grep -i "native\|gcc\|toolchain" || echo "No toolchain packages found"
echo ""

# Try installing toolchain with different package names
echo "Installing Tizen toolchain packages..."
echo "This may take 5-10 minutes..."
echo ""

# Method 1: Try exact package names
echo "Attempting Method 1: Exact package names..."
"$TIZEN_SDK_DIR/package-manager/package-manager-cli.bin" install \
    NativeToolchain-Gcc-9.2 \
    PLATFORM-6.0-NativeAppDevelopment-CLI 2>&1 | tee /tmp/tizen-install.log || true

# Check if it worked
if [ -d "$TIZEN_SDK_DIR/tools/arm-linux-gnueabi-gcc-9.2" ]; then
    echo -e "${GREEN}✓ Toolchain installed successfully!${NC}"
    ls -la "$TIZEN_SDK_DIR/tools/arm-linux-gnueabi-gcc-9.2/bin/" | head -10
    exit 0
fi

# Method 2: Try with different version
echo ""
echo "Attempting Method 2: Alternative package names..."
"$TIZEN_SDK_DIR/package-manager/package-manager-cli.bin" install \
    NativeToolchain-Gcc-9.2-arm \
    NativeToolchain-Gcc-9.2-x86 2>&1 | tee -a /tmp/tizen-install.log || true

if [ -d "$TIZEN_SDK_DIR/tools/arm-linux-gnueabi-gcc-9.2" ]; then
    echo -e "${GREEN}✓ Toolchain installed successfully!${NC}"
    ls -la "$TIZEN_SDK_DIR/tools/arm-linux-gnueabi-gcc-9.2/bin/" | head -10
    exit 0
fi

# Method 3: List available packages and try to find toolchain
echo ""
echo "Attempting Method 3: Searching for available toolchain packages..."
echo "Available packages:"
"$TIZEN_SDK_DIR/package-manager/package-manager-cli.bin" show-pkgs 2>/dev/null | grep -i "toolchain\|gcc" || echo "No toolchain packages found in repository"

# Method 4: Try installing all native development packages
echo ""
echo "Attempting Method 4: Installing all native development packages..."
"$TIZEN_SDK_DIR/package-manager/package-manager-cli.bin" install \
    NativeToolchain \
    NativeAppDevelopment 2>&1 | tee -a /tmp/tizen-install.log || true

if [ -d "$TIZEN_SDK_DIR/tools/arm-linux-gnueabi-gcc-9.2" ]; then
    echo -e "${GREEN}✓ Toolchain installed successfully!${NC}"
    ls -la "$TIZEN_SDK_DIR/tools/arm-linux-gnueabi-gcc-9.2/bin/" | head -10
    exit 0
fi

# Check what we have in tools directory
echo ""
echo "Checking what's in tools directory:"
ls -la "$TIZEN_SDK_DIR/tools/" 2>/dev/null || echo "Tools directory is empty"

# Final check - maybe it's in a different location
echo ""
echo "Searching for GCC in Tizen SDK..."
find "$TIZEN_SDK_DIR" -name "*gcc*" -type f 2>/dev/null | head -20 || echo "No GCC found"

echo ""
echo -e "${YELLOW}=========================================="
echo "Toolchain Installation Status"
echo -e "==========================================${NC}"

if [ -d "$TIZEN_SDK_DIR/tools/arm-linux-gnueabi-gcc-9.2" ]; then
    echo -e "${GREEN}✓ SUCCESS: Toolchain is installed${NC}"
    echo "Location: $TIZEN_SDK_DIR/tools/arm-linux-gnueabi-gcc-9.2"
else
    echo -e "${RED}✗ FAILED: Toolchain not found${NC}"
    echo ""
    echo "This might be because:"
    echo "  1. Tizen SDK repository is down or changed"
    echo "  2. Package names have changed"
    echo "  3. Network connectivity issues"
    echo ""
    echo "Installation log saved to: /tmp/tizen-install.log"
    echo ""
    echo "Alternative: Use GitHub Actions to build instead"
    echo "  - GitHub Actions has native Linux ARM64 runners"
    echo "  - No local setup needed"
    echo "  - See: ACTION_PLAN_NOW.md"
    exit 1
fi
