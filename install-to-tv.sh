#!/bin/bash
set -e

echo "=========================================="
echo "Install Kodi to Samsung TV"
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

# Check if SDB is installed
print_step "Step 1: Checking SDB Installation"

if ! command -v sdb &> /dev/null; then
    echo -e "${RED}SDB not found!${NC}"
    echo ""
    echo "Please install Tizen Studio or add SDB to PATH:"
    echo "  export PATH=\$PATH:\$HOME/tizen-studio/tools"
    echo ""
    exit 1
fi

echo "SDB version:"
sdb version
check_success "SDB found"

# Get TV IP
print_step "Step 2: TV Connection"

echo "Enter your Samsung TV's IP address:"
echo "(Find it in: TV Settings → Network → Network Status)"
read -p "TV IP: " TV_IP

if [ -z "$TV_IP" ]; then
    echo -e "${RED}No IP address provided${NC}"
    exit 1
fi

echo ""
echo "Connecting to TV at $TV_IP..."
sdb connect "$TV_IP"
check_success "Connect to TV"

echo ""
echo "Verifying connection..."
sdb devices
check_success "Verify connection"

# Find TPK file
print_step "Step 3: Finding TPK File"

TPK_FILE=$(find . -name "kodi-tizen-*.tpk" -o -name "kodi-*.tpk" | head -1)

if [ -z "$TPK_FILE" ]; then
    echo -e "${YELLOW}No TPK file found automatically${NC}"
    echo ""
    echo "Please enter the path to your Kodi TPK file:"
    read -p "TPK file path: " TPK_FILE
    
    if [ ! -f "$TPK_FILE" ]; then
        echo -e "${RED}TPK file not found: $TPK_FILE${NC}"
        exit 1
    fi
fi

echo "Found TPK: $TPK_FILE"
ls -lh "$TPK_FILE"

# Ask about uninstalling old version
print_step "Step 4: Checking for Existing Installation"

if sdb shell pkginfo --listpkg | grep -q "org.xbmc.kodi"; then
    echo -e "${YELLOW}Kodi is already installed on the TV${NC}"
    echo ""
    read -p "Uninstall old version first? (y/n): " UNINSTALL
    
    if [ "$UNINSTALL" = "y" ] || [ "$UNINSTALL" = "Y" ]; then
        echo "Uninstalling old version..."
        sdb uninstall org.xbmc.kodi
        check_success "Uninstall old version"
    fi
else
    echo "No existing Kodi installation found"
fi

# Install TPK
print_step "Step 5: Installing Kodi"

echo "Installing $TPK_FILE to TV..."
echo "This may take a few minutes..."
echo ""

sdb install "$TPK_FILE"
check_success "Install Kodi"

# Verify installation
print_step "Step 6: Verifying Installation"

echo "Checking if Kodi is installed..."
if sdb shell pkginfo --listpkg | grep -q "org.xbmc.kodi"; then
    echo -e "${GREEN}✓ Kodi is installed!${NC}"
    
    echo ""
    echo "Package info:"
    sdb shell pkginfo --pkg-info org.xbmc.kodi
else
    echo -e "${RED}✗ Kodi installation verification failed${NC}"
    exit 1
fi

# Launch Kodi
print_step "Step 7: Launching Kodi"

read -p "Launch Kodi now? (y/n): " LAUNCH

if [ "$LAUNCH" = "y" ] || [ "$LAUNCH" = "Y" ]; then
    echo "Launching Kodi..."
    sdb shell app_launcher -s org.xbmc.kodi
    check_success "Launch Kodi"
    
    echo ""
    echo -e "${GREEN}Kodi should now be running on your TV!${NC}"
    echo ""
    echo "To view logs:"
    echo "  sdb dlog KODI:V"
    echo ""
    echo "To stop Kodi:"
    echo "  sdb shell app_launcher -t org.xbmc.kodi"
fi

# Final summary
print_step "Installation Complete! 🎉"

echo -e "${GREEN}Kodi has been successfully installed on your Samsung TV!${NC}"
echo ""
echo "Quick commands:"
echo "  Launch Kodi:    sdb shell app_launcher -s org.xbmc.kodi"
echo "  View logs:      sdb dlog KODI:V"
echo "  Uninstall:      sdb uninstall org.xbmc.kodi"
echo "  Disconnect:     sdb disconnect $TV_IP"
echo ""
echo "For more information, see: INSTALL_TO_TV.md"
echo ""
