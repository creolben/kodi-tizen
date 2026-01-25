#!/bin/bash
# This script runs INSIDE the Podman container to build Kodi for Tizen

set -e

echo "=== Kodi Tizen Build Script (Inside Container) ==="
echo ""

# Check if we're in the container
if [ ! -f /home/builder/workspace/CMakeLists.txt ]; then
    echo "Error: Not in the correct workspace directory"
    echo "This script should be run inside the Podman container"
    echo "Current directory: $(pwd)"
    echo "Looking for: /home/builder/workspace/CMakeLists.txt"
    ls -la /home/builder/ || true
    exit 1
fi

# Step 1: Download and install Tizen SDK
echo "Step 1: Installing Tizen SDK..."
echo ""

if [ ! -d "$HOME/tizen-studio" ]; then
    echo "Downloading Tizen Studio..."
    cd /tmp
    wget -q --show-progress http://download.tizen.org/sdk/Installer/tizen-studio_5.0/web-cli_Tizen_Studio_5.0_ubuntu-64.bin
    
    echo "Installing Tizen Studio..."
    chmod +x web-cli_Tizen_Studio_5.0_ubuntu-64.bin
    ./web-cli_Tizen_Studio_5.0_ubuntu-64.bin --accept-license $HOME/tizen-studio
    
    echo "Installing required packages..."
    $HOME/tizen-studio/package-manager/package-manager-cli.bin install \
        NativeToolchain-Gcc-9.2 \
        PLATFORM-6.0-NativeAppDevelopment-CLI
else
    echo "✓ Tizen SDK already installed"
fi

# Set environment variables
export PATH=$PATH:$HOME/tizen-studio/tools
export TIZEN_SDK=$HOME/tizen-studio

echo ""
echo "✓ Tizen SDK installed"
echo ""

# Step 2: Build dependencies
echo "Step 2: Building dependencies..."
echo ""

cd /home/builder/workspace/tools/depends

if [ ! -f "Makefile" ]; then
    echo "Bootstrapping..."
    ./bootstrap
    
    echo "Configuring..."
    ./configure \
        --prefix=$HOME/kodi-tizen-deps \
        --host=arm-tizen-linux-gnueabi \
        --with-toolchain=$HOME/tizen-studio/tools/arm-linux-gnueabi-gcc-9.2 \
        --with-platform=tizen \
        --with-rendersystem=gles \
        --enable-debug=no
fi

echo "Building dependencies (this will take a while)..."
make -j$(nproc)

echo ""
echo "✓ Dependencies built"
echo ""

# Step 3: Build Kodi
echo "Step 3: Building Kodi..."
echo ""

cd /home/builder/workspace

echo "Generating build files..."
make -C tools/depends/target/cmakebuildsys

echo "Building Kodi..."
cd build
make -j$(nproc)

echo ""
echo "✓ Kodi built"
echo ""

# Step 4: Create TPK
echo "Step 4: Creating TPK package..."
echo ""

make tpk

echo ""
echo "=== Build Complete! ==="
echo ""
echo "TPK file created:"
ls -lh /home/builder/workspace/build/*.tpk
echo ""
echo "Copy the TPK file to your Mac and install on your Samsung TV:"
echo "  sdb connect <TV_IP>:26101"
echo "  sdb install <tpk-file>"
echo ""
