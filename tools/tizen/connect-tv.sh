#!/bin/bash
# Interactive TV Connection Helper for Kodi Tizen Testing

set +e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Kodi Tizen - TV Connection Helper${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check for SDB
echo -e "${BLUE}[1/7]${NC} Checking for SDB (Smart Development Bridge)..."
if command_exists sdb; then
    echo -e "${GREEN}✓${NC} SDB found: $(which sdb)"
else
    echo -e "${RED}✗${NC} SDB not found!"
    echo ""
    echo "Please install Tizen Studio and add SDB to your PATH:"
    echo "  export PATH=\$PATH:\$HOME/tizen-studio/tools"
    echo ""
    echo "Or install Tizen Studio from:"
    echo "  https://developer.tizen.org/development/tizen-studio/download"
    exit 1
fi

# Get TV IP address
echo ""
echo -e "${BLUE}[2/7]${NC} Enter your Samsung TV's IP address"
echo "  (You can find this in: TV Settings → Network → Network Status)"
read -p "TV IP Address: " TV_IP

if [ -z "$TV_IP" ]; then
    echo -e "${RED}✗${NC} No IP address provided"
    exit 1
fi

# Validate IP format (basic check)
if ! [[ $TV_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo -e "${YELLOW}⚠${NC} Warning: IP address format looks unusual: $TV_IP"
    read -p "Continue anyway? (y/n): " CONTINUE
    if [ "$CONTINUE" != "y" ]; then
        exit 1
    fi
fi

# Test network connectivity
echo ""
echo -e "${BLUE}[3/7]${NC} Testing network connectivity to TV..."
if ping -c 2 -W 2 "$TV_IP" > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} TV is reachable on the network"
else
    echo -e "${RED}✗${NC} Cannot reach TV at $TV_IP"
    echo ""
    echo "Troubleshooting:"
    echo "  1. Verify the IP address is correct"
    echo "  2. Ensure TV and computer are on the same network"
    echo "  3. Check if TV's firewall is blocking connections"
    exit 1
fi

# Check developer mode
echo ""
echo -e "${BLUE}[4/7]${NC} Checking developer mode status..."
echo ""
echo "Is Developer Mode enabled on your TV?"
echo "  (If not, see: tools/tizen/DEVELOPER_MODE_GUIDE.md)"
echo ""
read -p "Developer Mode enabled? (y/n): " DEV_MODE

if [ "$DEV_MODE" != "y" ]; then
    echo ""
    echo -e "${YELLOW}Please enable Developer Mode on your TV:${NC}"
    echo "  1. Press Home button on remote"
    echo "  2. Go to Apps"
    echo "  3. Press 1-2-3-4-5 quickly"
    echo "  4. Enable Developer Mode"
    echo "  5. Enter your computer's IP address"
    echo "  6. Reboot TV"
    echo ""
    echo "Then run this script again."
    exit 1
fi

# Connect to TV
echo ""
echo -e "${BLUE}[5/7]${NC} Connecting to TV via SDB..."

# Kill any existing connections
sdb disconnect > /dev/null 2>&1

# Try to connect
if sdb connect "$TV_IP" > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Connected to TV"
else
    echo -e "${YELLOW}⚠${NC} Initial connection failed, trying with port..."
    if sdb connect "$TV_IP:26101" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Connected to TV on port 26101"
    else
        echo -e "${RED}✗${NC} Failed to connect to TV"
        echo ""
        echo "Troubleshooting:"
        echo "  1. Verify Developer Mode is enabled"
        echo "  2. Ensure TV was rebooted after enabling Developer Mode"
        echo "  3. Try restarting SDB: sdb kill-server && sdb start-server"
        echo "  4. Check firewall settings on your computer"
        exit 1
    fi
fi

# Verify connection
echo ""
echo -e "${BLUE}[6/7]${NC} Verifying connection..."
DEVICES=$(sdb devices 2>&1)

if echo "$DEVICES" | grep -q "device"; then
    echo -e "${GREEN}✓${NC} Connection verified"
    echo ""
    echo "Connected devices:"
    echo "$DEVICES"
else
    echo -e "${RED}✗${NC} Connection verification failed"
    echo ""
    echo "SDB output:"
    echo "$DEVICES"
    exit 1
fi

# Get TV info
echo ""
echo -e "${BLUE}[7/7]${NC} Getting TV information..."
echo ""

# Get Tizen version
TIZEN_VERSION=$(sdb shell cat /etc/tizen-release 2>/dev/null | head -1)
if [ -n "$TIZEN_VERSION" ]; then
    echo -e "  Tizen Version: ${GREEN}$TIZEN_VERSION${NC}"
else
    echo -e "  Tizen Version: ${YELLOW}Unknown${NC}"
fi

# Get available space
SPACE=$(sdb shell df -h /opt/usr 2>/dev/null | tail -1 | awk '{print $4}')
if [ -n "$SPACE" ]; then
    echo -e "  Available Space: ${GREEN}$SPACE${NC}"
else
    echo -e "  Available Space: ${YELLOW}Unknown${NC}"
fi

# Check if Kodi is already installed
if sdb shell pkginfo --listpkg 2>/dev/null | grep -q "org.xbmc.kodi"; then
    echo -e "  Kodi Status: ${YELLOW}Already installed${NC}"
    KODI_INSTALLED=true
else
    echo -e "  Kodi Status: ${GREEN}Not installed${NC}"
    KODI_INSTALLED=false
fi

# Success!
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Successfully connected to TV!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Next steps
echo "What would you like to do next?"
echo ""
echo "  1. Install/Update Kodi on TV"
echo "  2. Launch Kodi (if already installed)"
echo "  3. View Kodi logs"
echo "  4. Uninstall Kodi"
echo "  5. Exit"
echo ""
read -p "Choose an option (1-5): " OPTION

case $OPTION in
    1)
        echo ""
        echo "To install Kodi, you need a TPK package."
        echo ""
        if [ -f "kodi-tizen-21.0.0.tpk" ]; then
            echo -e "${GREEN}✓${NC} Found: kodi-tizen-21.0.0.tpk"
            read -p "Install this package? (y/n): " INSTALL
            if [ "$INSTALL" = "y" ]; then
                echo ""
                echo "Installing Kodi..."
                if [ "$KODI_INSTALLED" = true ]; then
                    echo "Uninstalling old version..."
                    sdb uninstall org.xbmc.kodi
                fi
                sdb install kodi-tizen-21.0.0.tpk
                echo ""
                echo -e "${GREEN}✓${NC} Installation complete!"
                echo ""
                read -p "Launch Kodi now? (y/n): " LAUNCH
                if [ "$LAUNCH" = "y" ]; then
                    sdb shell app_launcher -s org.xbmc.kodi
                    echo ""
                    echo "Kodi should now be launching on your TV!"
                    echo "To view logs: sdb dlog KODI:V"
                fi
            fi
        else
            echo -e "${YELLOW}⚠${NC} No TPK package found in current directory"
            echo ""
            echo "To create a TPK package, run:"
            echo "  ./tools/tizen/create-and-sign-tpk.sh"
        fi
        ;;
    2)
        if [ "$KODI_INSTALLED" = true ]; then
            echo ""
            echo "Launching Kodi..."
            sdb shell app_launcher -s org.xbmc.kodi
            echo ""
            echo -e "${GREEN}✓${NC} Kodi should now be launching on your TV!"
            echo ""
            echo "To view logs: sdb dlog KODI:V"
        else
            echo ""
            echo -e "${RED}✗${NC} Kodi is not installed on the TV"
            echo "Please install it first (option 1)"
        fi
        ;;
    3)
        echo ""
        echo "Viewing Kodi logs (press Ctrl+C to stop)..."
        echo ""
        sdb dlog KODI:V
        ;;
    4)
        if [ "$KODI_INSTALLED" = true ]; then
            echo ""
            read -p "Are you sure you want to uninstall Kodi? (y/n): " UNINSTALL
            if [ "$UNINSTALL" = "y" ]; then
                echo "Uninstalling Kodi..."
                sdb uninstall org.xbmc.kodi
                echo ""
                echo -e "${GREEN}✓${NC} Kodi uninstalled"
            fi
        else
            echo ""
            echo "Kodi is not installed on the TV"
        fi
        ;;
    5)
        echo ""
        echo "Connection to TV is still active."
        echo "To disconnect: sdb disconnect $TV_IP"
        echo ""
        echo "Goodbye!"
        ;;
    *)
        echo ""
        echo "Invalid option"
        ;;
esac

echo ""
echo "For more help, see: tools/tizen/TV_CONNECTION_GUIDE.md"
echo ""
