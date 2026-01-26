#!/bin/bash
set -e

echo "=========================================="
echo "Kodi Tizen Build Script (Container)"
echo "=========================================="
echo ""
echo "This script will:"
echo "  1. Install Tizen SDK (~10 min)"
echo "  2. Build dependencies (~30-60 min)"
echo "  3. Build Kodi (~30-60 min)"
echo "  4. Create TPK package (~5 min)"
echo ""
echo "Total estimated time: 60-90 minutes"
echo "Press Ctrl+C to cancel, or wait 5 seconds to continue..."
sleep 5

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
TIZEN_SDK_DIR="$HOME/tizen-studio"
KODI_DEPS_DIR="$HOME/kodi-tizen-deps"
WORKSPACE_DIR="/workspace"

# Function to print step headers
print_step() {
    echo ""
    echo -e "${BLUE}=========================================="
    echo -e "$1"
    echo -e "==========================================${NC}"
    echo ""
}

# Function to check command success
check_success() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $1${NC}"
    else
        echo -e "${RED}✗ $1 failed${NC}"
        exit 1
    fi
}

# Step 1: Install Tizen SDK
print_step "Step 1/4: Installing Tizen SDK"

if [ -d "$TIZEN_SDK_DIR" ]; then
    echo "Tizen SDK already installed at $TIZEN_SDK_DIR"
else
    echo "Downloading Tizen SDK installer..."
    cd /tmp
    wget --progress=bar:force http://download.tizen.org/sdk/Installer/tizen-studio_5.0/web-cli_Tizen_Studio_5.0_ubuntu-64.bin
    check_success "Download Tizen SDK"
    
    echo "Installing Tizen SDK (this may take 5-10 minutes)..."
    chmod +x web-cli_Tizen_Studio_5.0_ubuntu-64.bin
    ./web-cli_Tizen_Studio_5.0_ubuntu-64.bin --accept-license "$TIZEN_SDK_DIR"
    check_success "Install Tizen SDK"
    
    echo "Installing Tizen toolchain packages..."
    "$TIZEN_SDK_DIR/package-manager/package-manager-cli.bin" install \
        NativeToolchain-Gcc-9.2 \
        PLATFORM-6.0-NativeAppDevelopment-CLI 2>&1 | grep -v "^Downloading" || true
    
    # Verify installation
    if [ -d "$TIZEN_SDK_DIR/tools/arm-linux-gnueabi-gcc-9.2" ]; then
        echo -e "${GREEN}✓ Tizen SDK installed successfully${NC}"
        ls -la "$TIZEN_SDK_DIR/tools/arm-linux-gnueabi-gcc-9.2/bin/" | head -5
    else
        echo -e "${RED}✗ Tizen SDK installation failed - toolchain not found${NC}"
        exit 1
    fi
fi

# Set environment variables
export PATH="$PATH:$TIZEN_SDK_DIR/tools"
export TIZEN_SDK="$TIZEN_SDK_DIR"

# Step 2: Build Dependencies
print_step "Step 2/4: Building Kodi Dependencies"

cd "$WORKSPACE_DIR/tools/depends"

if [ ! -f "configure" ]; then
    echo "Running bootstrap..."
    ./bootstrap
    check_success "Bootstrap"
fi

if [ -d "$KODI_DEPS_DIR" ] && [ -f "$KODI_DEPS_DIR/.built" ]; then
    echo "Dependencies already built, skipping..."
else
    echo "Configuring dependencies..."
    ./configure \
        --prefix="$KODI_DEPS_DIR" \
        --host=arm-tizen-linux-gnueabi \
        --with-toolchain="$TIZEN_SDK_DIR/tools/arm-linux-gnueabi-gcc-9.2" \
        --with-platform=tizen \
        --with-rendersystem=gles \
        --enable-debug=no
    check_success "Configure dependencies"
    
    echo "Building dependencies (this will take 30-60 minutes)..."
    echo "Progress will be logged to: $WORKSPACE_DIR/tools/depends/build.log"
    make -j$(nproc) 2>&1 | tee build.log
    check_success "Build dependencies"
    
    # Mark as built
    touch "$KODI_DEPS_DIR/.built"
fi

# Step 3: Build Kodi
print_step "Step 3/4: Building Kodi"

cd "$WORKSPACE_DIR"

echo "Configuring Kodi build with CMake..."
make -C tools/depends/target/cmakebuildsys
check_success "Configure Kodi"

if [ ! -d "build" ]; then
    echo -e "${RED}✗ Build directory not created${NC}"
    exit 1
fi

cd build
echo "Compiling Kodi (this will take 30-60 minutes)..."
echo "Progress will be logged to: $WORKSPACE_DIR/build/build.log"
make -j$(nproc) 2>&1 | tee build.log
check_success "Build Kodi"

# Step 4: Create TPK Package
print_step "Step 4/4: Creating TPK Package"

# Check if make tpk target exists
if make -n tpk &>/dev/null; then
    echo "Creating TPK using make target..."
    make tpk
    check_success "Create TPK"
else
    echo -e "${YELLOW}Warning: 'make tpk' target not found${NC}"
    echo "Attempting manual TPK creation..."
    
    if [ -f "$WORKSPACE_DIR/tools/tizen/packaging/package.sh" ]; then
        cd "$WORKSPACE_DIR"
        bash tools/tizen/packaging/package.sh
        check_success "Create TPK manually"
    else
        echo -e "${RED}✗ TPK packaging script not found${NC}"
        echo "Available packaging files:"
        find "$WORKSPACE_DIR/tools/tizen" -name "*.sh" -ls
        exit 1
    fi
fi

# Find and display TPK files
print_step "Build Complete! 🎉"

TPK_FILES=$(find "$WORKSPACE_DIR" -name "*.tpk" 2>/dev/null || true)
if [ -n "$TPK_FILES" ]; then
    echo -e "${GREEN}TPK files created:${NC}"
    ls -lh $TPK_FILES
    echo ""
    echo -e "${GREEN}Location on host machine:${NC}"
    for tpk in $TPK_FILES; do
        HOST_PATH=$(echo "$tpk" | sed "s|$WORKSPACE_DIR|$(pwd)|")
        echo "  $HOST_PATH"
    done
else
    echo -e "${YELLOW}Warning: No TPK files found${NC}"
    echo "Searching entire workspace..."
    find "$WORKSPACE_DIR" -type f -name "*.tpk" -o -name "*tizen*" | head -20
fi

echo ""
echo -e "${BLUE}=========================================="
echo "Next Steps:"
echo "==========================================${NC}"
echo "1. Exit the container: type 'exit'"
echo "2. Find the TPK file in your local directory"
echo "3. Install on Samsung TV:"
echo "   ${GREEN}sdb connect <TV_IP>:26101${NC}"
echo "   ${GREEN}sdb install kodi-tizen-*.tpk${NC}"
echo "   ${GREEN}sdb shell app_launcher -s org.xbmc.kodi${NC}"
echo ""
echo "For more information, see:"
echo "  - docs/README.Tizen.md"
echo "  - tools/tizen/DEVELOPER_MODE_GUIDE.md"
echo "  - tools/tizen/TV_CONNECTION_GUIDE.md"
echo ""
