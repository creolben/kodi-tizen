#!/bin/bash
# Quick Emulator Setup and Launch Script for Kodi Testing

set +e

# Add Tizen Studio to PATH
export PATH=$PATH:$HOME/tizen-studio/tools
export PATH=$PATH:$HOME/tizen-studio/tools/emulator/bin

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Kodi Tizen - Emulator Quick Setup${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if emulator is installed
echo -e "${BLUE}[1/5]${NC} Checking emulator installation..."
if [ -f "$HOME/tizen-studio/tools/emulator/bin/em-cli" ]; then
    echo -e "${GREEN}✓${NC} Emulator found"
else
    echo -e "${RED}✗${NC} Emulator not found!"
    echo ""
    echo "Please install the emulator via Tizen Studio Package Manager:"
    echo "  1. Run: ~/tizen-studio/package-manager/package-manager"
    echo "  2. Install: Main SDK > Emulator"
    echo "  3. Install: Extension SDK > TV Extensions > TV Emulator"
    exit 1
fi

# List available emulators
echo ""
echo -e "${BLUE}[2/5]${NC} Checking for existing emulator instances..."
EMULATORS=$(em-cli list-vm 2>/dev/null)

if [ -z "$EMULATORS" ]; then
    echo -e "${YELLOW}⚠${NC} No emulator instances found"
    echo ""
    echo "You need to create an emulator instance first."
    echo ""
    read -p "Would you like to open Emulator Manager to create one? (y/n): " OPEN_MANAGER
    
    if [ "$OPEN_MANAGER" = "y" ]; then
        echo ""
        echo "Opening Emulator Manager..."
        echo ""
        echo -e "${YELLOW}In Emulator Manager:${NC}"
        echo "  1. Click 'Create' button"
        echo "  2. Select 'TV' platform"
        echo "  3. Choose a TV image (e.g., TV-samsung-6.0-x86)"
        echo "  4. Set name: kodi-dev-tv"
        echo "  5. Set resolution: 1920x1080"
        echo "  6. Set RAM: 2048 MB (or more)"
        echo "  7. Click 'Confirm'"
        echo ""
        echo "After creating the emulator, run this script again."
        echo ""
        
        emulator-manager &
        exit 0
    else
        echo ""
        echo "Please create an emulator manually:"
        echo "  ~/tizen-studio/tools/emulator/bin/emulator-manager"
        exit 1
    fi
else
    echo -e "${GREEN}✓${NC} Found emulator instances:"
    echo "$EMULATORS"
fi

# Select emulator
echo ""
echo -e "${BLUE}[3/5]${NC} Select emulator to launch"
echo ""

# Parse emulator names
EMULATOR_NAMES=$(echo "$EMULATORS" | grep -v "^vm_name" | awk '{print $1}')
EMULATOR_ARRAY=($EMULATOR_NAMES)

if [ ${#EMULATOR_ARRAY[@]} -eq 0 ]; then
    echo -e "${RED}✗${NC} No emulators available"
    exit 1
elif [ ${#EMULATOR_ARRAY[@]} -eq 1 ]; then
    SELECTED_EMULATOR="${EMULATOR_ARRAY[0]}"
    echo "Using emulator: $SELECTED_EMULATOR"
else
    echo "Available emulators:"
    for i in "${!EMULATOR_ARRAY[@]}"; do
        echo "  $((i+1)). ${EMULATOR_ARRAY[$i]}"
    done
    echo ""
    read -p "Select emulator (1-${#EMULATOR_ARRAY[@]}): " SELECTION
    
    if [ -z "$SELECTION" ] || [ "$SELECTION" -lt 1 ] || [ "$SELECTION" -gt ${#EMULATOR_ARRAY[@]} ]; then
        echo -e "${RED}✗${NC} Invalid selection"
        exit 1
    fi
    
    SELECTED_EMULATOR="${EMULATOR_ARRAY[$((SELECTION-1))]}"
fi

echo ""
echo -e "${GREEN}Selected:${NC} $SELECTED_EMULATOR"

# Check if emulator is already running
echo ""
echo -e "${BLUE}[4/5]${NC} Checking emulator status..."

if sdb devices 2>/dev/null | grep -q "emulator"; then
    echo -e "${GREEN}✓${NC} Emulator is already running"
    EMULATOR_RUNNING=true
else
    echo -e "${YELLOW}⚠${NC} Emulator is not running"
    EMULATOR_RUNNING=false
fi

# Launch emulator if not running
if [ "$EMULATOR_RUNNING" = false ]; then
    echo ""
    echo -e "${BLUE}[5/5]${NC} Launching emulator..."
    echo "This may take 30-60 seconds..."
    echo ""
    
    # Launch emulator in background
    em-cli launch --name "$SELECTED_EMULATOR" > /dev/null 2>&1 &
    LAUNCH_PID=$!
    
    # Wait for emulator to start
    echo -n "Waiting for emulator to boot"
    for i in {1..60}; do
        sleep 1
        echo -n "."
        
        # Check if emulator is ready
        if sdb devices 2>/dev/null | grep -q "emulator"; then
            echo ""
            echo -e "${GREEN}✓${NC} Emulator is ready!"
            break
        fi
        
        # Check if launch failed
        if ! kill -0 $LAUNCH_PID 2>/dev/null; then
            echo ""
            echo -e "${RED}✗${NC} Emulator launch failed"
            echo ""
            echo "Troubleshooting:"
            echo "  1. Check if virtualization is enabled in BIOS"
            echo "  2. Ensure you have enough RAM (4GB+ recommended)"
            echo "  3. Try launching manually: emulator-manager"
            exit 1
        fi
    done
    
    # Final check
    if ! sdb devices 2>/dev/null | grep -q "emulator"; then
        echo ""
        echo -e "${YELLOW}⚠${NC} Emulator is taking longer than expected"
        echo "You can check the status manually with: sdb devices"
    fi
else
    echo ""
    echo -e "${BLUE}[5/5]${NC} Emulator already running, skipping launch"
fi

# Get emulator device ID
echo ""
echo "Getting emulator device ID..."
EMULATOR_ID=$(sdb devices 2>/dev/null | grep "emulator" | awk '{print $1}')

if [ -z "$EMULATOR_ID" ]; then
    echo -e "${YELLOW}⚠${NC} Could not detect emulator device ID"
    echo "Trying to connect manually..."
    
    sdb connect localhost:26101 > /dev/null 2>&1
    sleep 2
    
    EMULATOR_ID=$(sdb devices 2>/dev/null | grep "emulator" | awk '{print $1}')
    
    if [ -z "$EMULATOR_ID" ]; then
        echo -e "${RED}✗${NC} Failed to connect to emulator"
        echo ""
        echo "Please check:"
        echo "  1. Emulator is running (check Emulator Manager)"
        echo "  2. SDB is working: sdb devices"
        echo "  3. Try connecting manually: sdb connect localhost:26101"
        exit 1
    fi
fi

echo -e "${GREEN}✓${NC} Emulator device ID: $EMULATOR_ID"

# Success!
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Emulator is ready!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Show emulator info
echo "Emulator Information:"
echo "  Name: $SELECTED_EMULATOR"
echo "  Device ID: $EMULATOR_ID"
echo ""

# Check if Kodi is installed
if sdb -s "$EMULATOR_ID" shell pkginfo --listpkg 2>/dev/null | grep -q "org.xbmc.kodi"; then
    echo -e "  Kodi Status: ${YELLOW}Already installed${NC}"
    KODI_INSTALLED=true
else
    echo -e "  Kodi Status: ${GREEN}Not installed${NC}"
    KODI_INSTALLED=false
fi

# Next steps
echo ""
echo "What would you like to do next?"
echo ""
echo "  1. Build Kodi for emulator (x86)"
echo "  2. Install Kodi TPK (if you have one)"
echo "  3. Launch Kodi (if already installed)"
echo "  4. View emulator logs"
echo "  5. Open emulator window"
echo "  6. Exit"
echo ""
read -p "Choose an option (1-6): " OPTION

case $OPTION in
    1)
        echo ""
        echo "Building Kodi for emulator (x86 architecture)..."
        echo ""
        echo "This will take 1-2 hours. The build process will:"
        echo "  1. Configure for x86 Tizen"
        echo "  2. Build dependencies"
        echo "  3. Build Kodi"
        echo "  4. Create TPK package"
        echo ""
        read -p "Continue? (y/n): " BUILD
        
        if [ "$BUILD" = "y" ]; then
            echo ""
            echo "Starting build process..."
            echo "See: docs/README.Tizen.md for detailed build instructions"
            echo ""
            echo "Quick build commands:"
            echo "  cd tools/depends"
            echo "  ./bootstrap"
            echo "  ./configure --host=x86-tizen-linux-gnu --with-tizen-sdk=\$HOME/tizen-studio"
            echo "  make -j\$(sysctl -n hw.ncpu)"
            echo ""
            echo "Then build Kodi:"
            echo "  cd ../.."
            echo "  mkdir -p build && cd build"
            echo "  cmake .. -DCMAKE_TOOLCHAIN_FILE=../cmake/platform/linux/tizen.cmake"
            echo "  make -j\$(sysctl -n hw.ncpu)"
            echo ""
            echo "Finally create TPK:"
            echo "  cd .."
            echo "  ./tools/tizen/create-and-sign-tpk.sh"
        fi
        ;;
    2)
        echo ""
        if [ -f "kodi-tizen-21.0.0.tpk" ]; then
            echo -e "${GREEN}✓${NC} Found: kodi-tizen-21.0.0.tpk"
            read -p "Install this package? (y/n): " INSTALL
            
            if [ "$INSTALL" = "y" ]; then
                echo ""
                echo "Installing Kodi on emulator..."
                
                if [ "$KODI_INSTALLED" = true ]; then
                    echo "Uninstalling old version..."
                    sdb -s "$EMULATOR_ID" uninstall org.xbmc.kodi
                fi
                
                sdb -s "$EMULATOR_ID" install kodi-tizen-21.0.0.tpk
                echo ""
                echo -e "${GREEN}✓${NC} Installation complete!"
                echo ""
                read -p "Launch Kodi now? (y/n): " LAUNCH
                
                if [ "$LAUNCH" = "y" ]; then
                    sdb -s "$EMULATOR_ID" shell app_launcher -s org.xbmc.kodi
                    echo ""
                    echo "Kodi should now be launching in the emulator!"
                    echo "To view logs: sdb -s $EMULATOR_ID dlog KODI:V"
                fi
            fi
        else
            echo -e "${YELLOW}⚠${NC} No TPK package found"
            echo ""
            echo "Please build Kodi first (option 1) or place a TPK file in the current directory"
        fi
        ;;
    3)
        if [ "$KODI_INSTALLED" = true ]; then
            echo ""
            echo "Launching Kodi on emulator..."
            sdb -s "$EMULATOR_ID" shell app_launcher -s org.xbmc.kodi
            echo ""
            echo -e "${GREEN}✓${NC} Kodi should now be launching!"
            echo ""
            echo "To view logs: sdb -s $EMULATOR_ID dlog KODI:V"
        else
            echo ""
            echo -e "${RED}✗${NC} Kodi is not installed on the emulator"
            echo "Please install it first (option 2)"
        fi
        ;;
    4)
        echo ""
        echo "Viewing emulator logs (press Ctrl+C to stop)..."
        echo ""
        sdb -s "$EMULATOR_ID" dlog
        ;;
    5)
        echo ""
        echo "Opening emulator window..."
        emulator-manager &
        ;;
    6)
        echo ""
        echo "Emulator is still running."
        echo ""
        echo "Useful commands:"
        echo "  View logs: sdb -s $EMULATOR_ID dlog KODI:V"
        echo "  Stop emulator: em-cli stop --name $SELECTED_EMULATOR"
        echo "  List devices: sdb devices"
        echo ""
        echo "Goodbye!"
        ;;
    *)
        echo ""
        echo "Invalid option"
        ;;
esac

echo ""
echo "For more help, see: tools/tizen/EMULATOR_GUIDE.md"
echo ""
