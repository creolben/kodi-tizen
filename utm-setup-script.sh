#!/bin/bash
# UTM Ubuntu VM Setup Script for Kodi Tizen Build
# Run this inside your Ubuntu ARM64 VM after installation

set -e

echo "=========================================="
echo "Kodi Tizen Build Environment Setup"
echo "For Ubuntu ARM64 on UTM (Apple Silicon)"
echo "=========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_step() {
    echo ""
    echo -e "${BLUE}=========================================="
    echo -e "$1"
    echo -e "==========================================${NC}"
    echo ""
}

check_success() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $1${NC}"
    else
        echo -e "${RED}✗ $1 failed${NC}"
        exit 1
    fi
}

# Step 1: Update system
print_step "Step 1/6: Updating System"
sudo apt update
sudo apt upgrade -y
check_success "System update"

# Step 2: Install build dependencies
print_step "Step 2/6: Installing Build Dependencies"
sudo apt install -y \
    build-essential \
    cmake \
    curl \
    git \
    python3 \
    python3-pip \
    autoconf \
    automake \
    libtool \
    pkg-config \
    gawk \
    gperf \
    zip \
    unzip \
    wget \
    default-jre \
    nasm \
    yasm \
    libssl-dev \
    vim \
    htop
check_success "Build dependencies installation"

# Step 3: Download and install Tizen SDK
print_step "Step 3/6: Installing Tizen SDK"

TIZEN_SDK_DIR="$HOME/tizen-studio"

if [ -d "$TIZEN_SDK_DIR" ]; then
    echo "Tizen SDK already installed at $TIZEN_SDK_DIR"
else
    cd /tmp
    echo "Downloading Tizen SDK 6.1..."
    # Try Tizen Studio 6.1 first, fallback to 5.0 if not available
    if wget --progress=bar:force http://download.tizen.org/sdk/Installer/tizen-studio_6.1/web-cli_Tizen_Studio_6.1_ubuntu-64.bin 2>/dev/null; then
        echo "Downloaded Tizen Studio 6.1"
        INSTALLER="web-cli_Tizen_Studio_6.1_ubuntu-64.bin"
    else
        echo "Tizen Studio 6.1 not available, falling back to 5.0..."
        wget --progress=bar:force http://download.tizen.org/sdk/Installer/tizen-studio_5.0/web-cli_Tizen_Studio_5.0_ubuntu-64.bin
        INSTALLER="web-cli_Tizen_Studio_5.0_ubuntu-64.bin"
    fi
    check_success "Tizen SDK download"
    
    echo "Installing Tizen SDK (this may take 5-10 minutes)..."
    chmod +x "$INSTALLER"
    ./"$INSTALLER" --accept-license "$TIZEN_SDK_DIR"
    check_success "Tizen SDK installation"
    
    echo "Installing Tizen toolchain packages..."
    "$TIZEN_SDK_DIR/package-manager/package-manager-cli.bin" install \
        NativeToolchain-Gcc-9.2 \
        PLATFORM-6.0-NativeAppDevelopment-CLI 2>&1 | grep -v "^Downloading" || true
    
    # Verify installation
    if [ -d "$TIZEN_SDK_DIR/tools/arm-linux-gnueabi-gcc-9.2" ]; then
        echo -e "${GREEN}✓ Tizen SDK installed successfully${NC}"
    else
        echo -e "${RED}✗ Tizen SDK installation failed - toolchain not found${NC}"
        exit 1
    fi
fi

# Step 4: Set up environment variables
print_step "Step 4/6: Configuring Environment"

if ! grep -q "TIZEN_SDK" ~/.bashrc; then
    echo "" >> ~/.bashrc
    echo "# Tizen SDK" >> ~/.bashrc
    echo "export TIZEN_SDK=\$HOME/tizen-studio" >> ~/.bashrc
    echo "export PATH=\$PATH:\$TIZEN_SDK/tools" >> ~/.bashrc
    echo -e "${GREEN}✓ Environment variables added to ~/.bashrc${NC}"
else
    echo "Environment variables already configured"
fi

# Source the environment
export TIZEN_SDK="$HOME/tizen-studio"
export PATH="$PATH:$TIZEN_SDK/tools"

# Step 5: Clone Kodi repository
print_step "Step 5/6: Cloning Kodi Repository"

if [ -d "$HOME/kodi-tizen" ]; then
    echo "Kodi repository already exists at $HOME/kodi-tizen"
    read -p "Do you want to pull latest changes? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cd "$HOME/kodi-tizen"
        git pull
        check_success "Git pull"
    fi
else
    cd "$HOME"
    echo "Enter your Kodi repository URL (or press Enter for default):"
    read -p "URL [https://github.com/creolben/kodi-tizen.git]: " REPO_URL
    REPO_URL=${REPO_URL:-https://github.com/creolben/kodi-tizen.git}
    
    git clone "$REPO_URL" kodi-tizen
    check_success "Repository clone"
fi

# Step 6: Apply C++17 patches
print_step "Step 6/6: Applying C++17 Compatibility Patches"

cd "$HOME/kodi-tizen"

# Patch configure.ac
if grep -q "AX_CXX_COMPILE_STDCXX(\[20\]" tools/depends/configure.ac; then
    echo "Patching tools/depends/configure.ac..."
    sed -i 's/AX_CXX_COMPILE_STDCXX(\[20\]/AX_CXX_COMPILE_STDCXX([17]/' tools/depends/configure.ac
    check_success "configure.ac patch"
else
    echo "configure.ac already patched"
fi

# Patch CompilerSettings.cmake
if grep -q "CMAKE_CXX_STANDARD 20" cmake/scripts/common/CompilerSettings.cmake; then
    echo "Patching cmake/scripts/common/CompilerSettings.cmake..."
    sed -i 's/CMAKE_CXX_STANDARD 20/CMAKE_CXX_STANDARD 17/' cmake/scripts/common/CompilerSettings.cmake
    check_success "CompilerSettings.cmake patch"
else
    echo "CompilerSettings.cmake already patched"
fi

# Final summary
print_step "Setup Complete! 🎉"

echo -e "${GREEN}Your build environment is ready!${NC}"
echo ""
echo "Next steps:"
echo ""
echo "1. Build dependencies:"
echo "   ${BLUE}cd ~/kodi-tizen/tools/depends${NC}"
echo "   ${BLUE}./bootstrap${NC}"
echo "   ${BLUE}./configure --prefix=\$HOME/kodi-tizen-deps --host=arm-tizen-linux-gnueabi --with-toolchain=\$HOME/tizen-studio/tools/arm-linux-gnueabi-gcc-9.2 --with-platform=tizen --with-rendersystem=gles --enable-debug=no${NC}"
echo "   ${BLUE}make -j\$(nproc)${NC}"
echo ""
echo "2. Build Kodi:"
echo "   ${BLUE}cd ~/kodi-tizen${NC}"
echo "   ${BLUE}make -C tools/depends/target/cmakebuildsys${NC}"
echo "   ${BLUE}cd build${NC}"
echo "   ${BLUE}make -j\$(nproc)${NC}"
echo ""
echo "3. Create TPK:"
echo "   ${BLUE}make tpk${NC}"
echo ""
echo "Or run the automated build script:"
echo "   ${BLUE}cd ~/kodi-tizen${NC}"
echo "   ${BLUE}bash fix-and-build-tizen.sh${NC}"
echo ""
echo "Estimated build time: 60-90 minutes"
echo ""
echo "To transfer TPK to macOS:"
echo "   - Use shared folder: ${BLUE}cp build/*.tpk /mnt/shared/${NC}"
echo "   - Or use SCP from macOS: ${BLUE}scp username@vm-ip:~/kodi-tizen/build/*.tpk ~/Downloads/${NC}"
echo ""

# Save build command to a script
cat > "$HOME/build-kodi.sh" << 'EOF'
#!/bin/bash
set -e

echo "Building Kodi for Tizen..."
echo ""

# Set environment
export TIZEN_SDK=$HOME/tizen-studio
export PATH=$PATH:$TIZEN_SDK/tools

cd ~/kodi-tizen

# Build dependencies if not already built
if [ ! -d "$HOME/kodi-tizen-deps" ]; then
    echo "Building dependencies..."
    cd tools/depends
    ./bootstrap
    ./configure \
        --prefix=$HOME/kodi-tizen-deps \
        --host=arm-tizen-linux-gnueabi \
        --with-toolchain=$HOME/tizen-studio/tools/arm-linux-gnueabi-gcc-9.2 \
        --with-platform=tizen \
        --with-rendersystem=gles \
        --enable-debug=no
    make -j$(nproc)
    cd ../..
fi

# Build Kodi
echo "Building Kodi..."
make -C tools/depends/target/cmakebuildsys
cd build
make -j$(nproc)

# Create TPK
echo "Creating TPK..."
make tpk

echo ""
echo "Build complete!"
ls -lh *.tpk
EOF

chmod +x "$HOME/build-kodi.sh"

echo -e "${GREEN}Quick build script created: ~/build-kodi.sh${NC}"
echo ""
