#!/bin/bash
# Step 1: Download and install Tizen SDK only

set -e

echo "=== Step 1: Installing Tizen SDK ==="
echo ""

if [ -d "$HOME/tizen-studio" ]; then
    echo "✓ Tizen SDK already installed at $HOME/tizen-studio"
    ls -la $HOME/tizen-studio
    exit 0
fi

echo "Downloading Tizen Studio (this may take a few minutes)..."
cd /tmp

# Download with progress
wget --progress=bar:force http://download.tizen.org/sdk/Installer/tizen-studio_5.0/web-cli_Tizen_Studio_5.0_ubuntu-64.bin

echo ""
echo "Installing Tizen Studio..."
chmod +x web-cli_Tizen_Studio_5.0_ubuntu-64.bin

# Install to home directory
./web-cli_Tizen_Studio_5.0_ubuntu-64.bin --accept-license $HOME/tizen-studio

echo ""
echo "Installing required packages..."
$HOME/tizen-studio/package-manager/package-manager-cli.bin install \
    NativeToolchain-Gcc-9.2 \
    PLATFORM-6.0-NativeAppDevelopment-CLI

echo ""
echo "✓ Tizen SDK installed successfully!"
echo ""
echo "SDK location: $HOME/tizen-studio"
ls -la $HOME/tizen-studio/tools/
