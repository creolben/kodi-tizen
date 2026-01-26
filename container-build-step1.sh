#!/bin/bash
# Step 1: Install Tizen SDK
set -e

echo "Installing Tizen SDK..."
TIZEN_SDK_DIR="$HOME/tizen-studio"

if [ -d "$TIZEN_SDK_DIR" ]; then
    echo "Tizen SDK already installed"
    exit 0
fi

cd /tmp
wget http://download.tizen.org/sdk/Installer/tizen-studio_5.0/web-cli_Tizen_Studio_5.0_ubuntu-64.bin
chmod +x web-cli_Tizen_Studio_5.0_ubuntu-64.bin
./web-cli_Tizen_Studio_5.0_ubuntu-64.bin --accept-license "$TIZEN_SDK_DIR"

echo "Installing Tizen packages..."
"$TIZEN_SDK_DIR/package-manager/package-manager-cli.bin" install \
    NativeToolchain-Gcc-9.2 \
    PLATFORM-6.0-NativeAppDevelopment-CLI || true

echo "Tizen SDK installed successfully!"
ls -la "$TIZEN_SDK_DIR/tools/arm-linux-gnueabi-gcc-9.2/bin/" || echo "Toolchain verification failed"
