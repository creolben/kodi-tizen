#!/bin/bash
# UTM Setup Script for Kodi Tizen Build on Apple Silicon M4
# This script helps you set up a complete build environment

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo ""
echo -e "${CYAN}=========================================="
echo "UTM Setup for Kodi Tizen Build"
echo "Apple Silicon M4 Mac"
echo -e "==========================================${NC}"
echo ""

# Check if UTM is installed
if ! command -v utmctl &> /dev/null; then
    echo -e "${YELLOW}UTM not found. Installing via Homebrew...${NC}"
    brew install --cask utm
    echo -e "${GREEN}✓ UTM installed${NC}"
else
    echo -e "${GREEN}✓ UTM is already installed${NC}"
fi

# Check for Ubuntu ISO
UBUNTU_ISO="$HOME/Downloads/ubuntu-22.04.5-live-server-arm64.iso"
UBUNTU_URL="https://cdimage.ubuntu.com/releases/22.04/release/ubuntu-22.04.5-live-server-arm64.iso"

echo ""
echo -e "${BLUE}Step 1: Download Ubuntu ARM64 ISO${NC}"
echo ""

if [ -f "$UBUNTU_ISO" ]; then
    echo -e "${GREEN}✓ Ubuntu ISO already exists at: $UBUNTU_ISO${NC}"
else
    echo "Ubuntu ARM64 ISO not found."
    echo ""
    echo "Downloading Ubuntu 22.04 LTS ARM64 (~1.5 GB)..."
    echo "This may take a few minutes depending on your internet speed."
    echo ""
    
    # Download with progress
    curl -L -o "$UBUNTU_ISO" --progress-bar "$UBUNTU_URL"
    
    if [ -f "$UBUNTU_ISO" ]; then
        echo -e "${GREEN}✓ Ubuntu ISO downloaded successfully${NC}"
    else
        echo -e "${RED}✗ Failed to download Ubuntu ISO${NC}"
        echo "Please download manually from:"
        echo "  $UBUNTU_URL"
        echo "Save to: $UBUNTU_ISO"
        exit 1
    fi
fi

# Verify ISO
echo ""
echo "Verifying ISO file..."
ISO_SIZE=$(stat -f%z "$UBUNTU_ISO" 2>/dev/null || stat -c%s "$UBUNTU_ISO" 2>/dev/null)
if [ "$ISO_SIZE" -gt 1000000000 ]; then
    echo -e "${GREEN}✓ ISO file size looks correct ($(echo "scale=2; $ISO_SIZE/1073741824" | bc) GB)${NC}"
else
    echo -e "${RED}✗ ISO file seems too small. Please re-download.${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}Step 2: Create UTM Virtual Machine${NC}"
echo ""
echo "Now you need to create the VM in UTM manually."
echo ""
echo -e "${YELLOW}=== IMPORTANT: Follow these steps exactly ===${NC}"
echo ""
echo "1. Open UTM application"
echo "   ${CYAN}Press Enter to open UTM...${NC}"
read -p ""

# Open UTM
open -a UTM

echo ""
echo "2. In UTM, click 'Create a New Virtual Machine'"
echo ""
echo "3. Select 'Virtualize' (NOT Emulate!)"
echo "   ${YELLOW}⚠️  This is critical for performance!${NC}"
echo ""
echo "4. Select 'Linux'"
echo ""
echo "5. Configure the VM with these settings:"
echo ""
echo "   ${CYAN}Boot ISO Image:${NC}"
echo "   Browse to: $UBUNTU_ISO"
echo ""
echo "   ${CYAN}Hardware:${NC}"
echo "   - Memory: 8192 MB (8 GB)"
echo "   - CPU Cores: 6"
echo ""
echo "   ${CYAN}Storage:${NC}"
echo "   - Size: 100 GB"
echo ""
echo "   ${CYAN}Shared Directory:${NC}"
echo "   - Enable: Yes"
echo "   - Path: $(pwd)"
echo ""
echo "   ${CYAN}Name:${NC}"
echo "   - kodi-tizen-builder"
echo ""
echo "6. Click 'Save' to create the VM"
echo ""
echo "7. Start the VM and install Ubuntu Server"
echo ""
echo -e "${YELLOW}=== Ubuntu Installation Tips ===${NC}"
echo ""
echo "- Choose 'Ubuntu Server' (no GUI needed)"
echo "- Use default disk partitioning"
echo "- Create a user account (remember the password!)"
echo "- Enable OpenSSH server when prompted"
echo "- Wait for installation to complete (~10-15 minutes)"
echo "- Reboot when prompted"
echo ""
read -p "Press Enter when Ubuntu installation is complete..."

echo ""
echo -e "${BLUE}Step 3: Configure Ubuntu VM${NC}"
echo ""
echo "After Ubuntu boots, log in with your credentials."
echo ""
echo "Then run these commands in the Ubuntu VM:"
echo ""
echo -e "${CYAN}# Update system${NC}"
echo "sudo apt update && sudo apt upgrade -y"
echo ""
echo -e "${CYAN}# Install build dependencies${NC}"
echo "sudo apt install -y build-essential cmake curl git python3 python3-pip autoconf automake libtool pkg-config gawk gperf zip unzip wget default-jre nasm yasm libssl-dev"
echo ""
echo -e "${CYAN}# Download and run setup script${NC}"
echo "wget https://raw.githubusercontent.com/creolben/kodi-tizen/main/utm-setup-script.sh"
echo "bash utm-setup-script.sh"
echo ""
echo "Or copy-paste this one-liner:"
echo ""
echo -e "${GREEN}curl -sSL https://raw.githubusercontent.com/creolben/kodi-tizen/main/utm-setup-script.sh | bash${NC}"
echo ""

# Create a helper script for inside the VM
cat > /tmp/utm-vm-commands.txt << 'VMCMDS'
# ============================================
# Run these commands inside your Ubuntu VM
# ============================================

# 1. Update system
sudo apt update && sudo apt upgrade -y

# 2. Install build dependencies
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
    libssl-dev

# 3. Install Tizen SDK
cd /tmp
wget http://download.tizen.org/sdk/Installer/tizen-studio_5.0/web-cli_Tizen_Studio_5.0_ubuntu-64.bin
chmod +x web-cli_Tizen_Studio_5.0_ubuntu-64.bin
./web-cli_Tizen_Studio_5.0_ubuntu-64.bin --accept-license $HOME/tizen-studio

# 4. Install Tizen toolchain
$HOME/tizen-studio/package-manager/package-manager-cli.bin install \
    NativeToolchain-Gcc-9.2 \
    PLATFORM-6.0-NativeAppDevelopment-CLI

# 5. Set environment variables
echo 'export TIZEN_SDK=$HOME/tizen-studio' >> ~/.bashrc
echo 'export PATH=$PATH:$TIZEN_SDK/tools' >> ~/.bashrc
source ~/.bashrc

# 6. Clone Kodi repository
cd ~
git clone https://github.com/creolben/kodi-tizen.git
cd kodi-tizen

# 7. Apply C++17 patches
sed -i 's/AX_CXX_COMPILE_STDCXX(\[20\]/AX_CXX_COMPILE_STDCXX([17]/' tools/depends/configure.ac
sed -i 's/CMAKE_CXX_STANDARD 20/CMAKE_CXX_STANDARD 17/' cmake/scripts/common/CompilerSettings.cmake

# 8. Build dependencies
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

# 9. Build Kodi
cd ~/kodi-tizen
make -C tools/depends/target/cmakebuildsys
cd build
make -j$(nproc)

# 10. Create TPK
make tpk

# 11. Find your TPK
ls -lh *.tpk

# ============================================
# Done! Your TPK is ready.
# ============================================
VMCMDS

echo "Commands saved to: /tmp/utm-vm-commands.txt"
echo ""
echo "You can also view them with: cat /tmp/utm-vm-commands.txt"
echo ""

echo -e "${BLUE}Step 4: Transfer TPK to macOS${NC}"
echo ""
echo "After building, transfer the TPK file to macOS:"
echo ""
echo "Option A - Using shared folder (if configured):"
echo "  ${CYAN}cp ~/kodi-tizen/build/*.tpk /mnt/shared/${NC}"
echo ""
echo "Option B - Using SCP from macOS terminal:"
echo "  ${CYAN}scp username@vm-ip:~/kodi-tizen/build/*.tpk ~/Downloads/${NC}"
echo ""
echo "To find VM IP address, run in Ubuntu:"
echo "  ${CYAN}ip addr show | grep inet${NC}"
echo ""

echo -e "${BLUE}Step 5: Install TPK on Samsung TV${NC}"
echo ""
echo "Once you have the TPK on macOS:"
echo ""
echo "  ${CYAN}sdb connect <TV_IP>:26101${NC}"
echo "  ${CYAN}sdb install kodi-tizen-*.tpk${NC}"
echo "  ${CYAN}sdb shell app_launcher -s org.xbmc.kodi${NC}"
echo ""

echo -e "${GREEN}=========================================="
echo "Setup Guide Complete!"
echo -e "==========================================${NC}"
echo ""
echo "Summary:"
echo "1. UTM is installed ✓"
echo "2. Ubuntu ISO is ready ✓"
echo "3. Follow the VM creation steps above"
echo "4. Run the build commands in Ubuntu"
echo "5. Transfer TPK and install on TV"
echo ""
echo "Estimated time:"
echo "- VM setup: 30 minutes"
echo "- Build: 60-90 minutes"
echo "- Total: ~2 hours (first time)"
echo ""
echo "For detailed instructions, see:"
echo "  - M4_LOCAL_BUILD_GUIDE.md"
echo "  - M4_QUICK_START.md"
echo ""
