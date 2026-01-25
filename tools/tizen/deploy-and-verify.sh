#!/bin/bash
# Complete deployment and verification script for Kodi Tizen
# This script deploys TPK to device and verifies installation and launch

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Configuration
TPK_FILE=""
DEVICE_ID=""
UNINSTALL_FIRST="yes"
LAUNCH_APP="yes"
VERIFY_INSTALL="yes"
PACKAGE_ID="org.xbmc.kodi"
WAIT_AFTER_INSTALL=5

# Function to print status
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[i]${NC} $1"
}

print_section() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
}

# Display usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -t, --tpk <file>            TPK file to deploy (auto-detected if not specified)"
    echo "  -d, --device <id>           Device ID (required if multiple devices)"
    echo "  -n, --no-uninstall          Skip uninstalling existing version"
    echo "  -s, --skip-launch           Skip launching application after install"
    echo "  -v, --no-verify             Skip installation verification"
    echo "  -h, --help                  Display this help message"
    echo ""
    echo "Environment Variables:"
    echo "  TIZEN_SDK                   Path to Tizen Studio installation"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Deploy with auto-detected TPK"
    echo "  $0 -t build/org.xbmc.kodi-21.0.0.tpk # Deploy specific TPK"
    echo "  $0 -d 192.168.1.100:26101            # Deploy to specific device"
    echo "  $0 -n                                 # Skip uninstall step"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--tpk)
            TPK_FILE="$2"
            shift 2
            ;;
        -d|--device)
            DEVICE_ID="$2"
            shift 2
            ;;
        -n|--no-uninstall)
            UNINSTALL_FIRST="no"
            shift
            ;;
        -s|--skip-launch)
            LAUNCH_APP="no"
            shift
            ;;
        -v|--no-verify)
            VERIFY_INSTALL="no"
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            print_error "Unknown argument: $1"
            usage
            ;;
    esac
done

print_section "Kodi Tizen Deployment and Verification"

print_info "Configuration:"
echo "  TPK File: ${TPK_FILE:-<auto-detect>}"
echo "  Device ID: ${DEVICE_ID:-<auto-detect>}"
echo "  Uninstall First: $UNINSTALL_FIRST"
echo "  Launch App: $LAUNCH_APP"
echo "  Verify Install: $VERIFY_INSTALL"
echo ""

# Step 1: Verify environment
print_section "Step 1: Verifying Environment"

# Check for SDB
if ! command -v sdb >/dev/null 2>&1; then
    print_error "SDB (Smart Development Bridge) not found"
    
    if [ -n "$TIZEN_SDK" ] && [ -f "$TIZEN_SDK/tools/sdb" ]; then
        print_info "Found SDB in TIZEN_SDK, adding to PATH"
        export PATH="$TIZEN_SDK/tools:$PATH"
    else
        print_error "Please install Tizen Studio and add SDB to PATH"
        print_error "Typical location: ~/tizen-studio/tools/sdb"
        exit 1
    fi
fi
print_status "SDB found: $(which sdb)"

# Check SDB version
SDB_VERSION=$(sdb version 2>&1 | head -n 1 || echo "unknown")
print_info "SDB version: $SDB_VERSION"

# Step 2: Check device connection
print_section "Step 2: Checking Device Connection"

print_info "Listing connected devices..."
sdb devices

# Count connected devices
DEVICE_COUNT=$(sdb devices 2>/dev/null | grep -c "device" || echo "0")

if [ "$DEVICE_COUNT" -eq 0 ]; then
    print_error "No Tizen devices connected"
    echo ""
    echo "To connect a Samsung TV:"
    echo "  1. Enable Developer Mode on TV (see: $SCRIPT_DIR/DEVELOPER_MODE_GUIDE.md)"
    echo "  2. Get TV IP address from TV settings"
    echo "  3. Connect: sdb connect <TV_IP>:26101"
    echo ""
    echo "To start Tizen emulator:"
    echo "  1. Launch Tizen Studio"
    echo "  2. Start TV emulator from Emulator Manager"
    echo "  3. Wait for emulator to boot"
    exit 1
fi

print_status "Found $DEVICE_COUNT connected device(s)"

# Handle multiple devices
if [ "$DEVICE_COUNT" -gt 1 ] && [ -z "$DEVICE_ID" ]; then
    print_error "Multiple devices connected, please specify with -d option"
    echo ""
    echo "Available devices:"
    sdb devices | grep "device" | awk '{print "  - " $1}'
    exit 1
fi

# Get device ID if not specified
if [ -z "$DEVICE_ID" ]; then
    DEVICE_ID=$(sdb devices 2>/dev/null | grep "device" | head -n 1 | awk '{print $1}')
    print_info "Using device: $DEVICE_ID"
else
    print_info "Target device: $DEVICE_ID"
fi

# Verify device is accessible
SDB_CMD="sdb -s $DEVICE_ID"
if ! $SDB_CMD shell "echo test" >/dev/null 2>&1; then
    print_error "Cannot communicate with device: $DEVICE_ID"
    exit 1
fi
print_status "Device is accessible"

# Get device information
print_info "Device information:"
DEVICE_MODEL=$($SDB_CMD shell "cat /etc/config/model-config.xml 2>/dev/null | grep -oP '(?<=<model>)[^<]+' || echo 'Unknown'")
TIZEN_VERSION=$($SDB_CMD shell "cat /etc/tizen-release 2>/dev/null | grep -oP '(?<=TIZEN_VERSION=)[^ ]+' || echo 'Unknown'")
echo "  Model: $DEVICE_MODEL"
echo "  Tizen Version: $TIZEN_VERSION"

# Step 3: Find TPK file
print_section "Step 3: Locating TPK File"

if [ -z "$TPK_FILE" ]; then
    print_info "Auto-detecting TPK file..."
    
    # Search for TPK in build directory
    TPK_FILE=$(find "$PROJECT_ROOT/build" -maxdepth 1 -name "org.xbmc.kodi-*.tpk" -type f 2>/dev/null | head -n 1)
    
    if [ -z "$TPK_FILE" ]; then
        print_error "TPK file not found in build directory"
        echo ""
        echo "Please build and package Kodi first:"
        echo "  1. Build: ./tools/tizen/build-complete.sh"
        echo "  2. Package: ./tools/tizen/create-and-sign-tpk.sh"
        echo ""
        echo "Or specify TPK file with -t option"
        exit 1
    fi
    
    print_status "Found TPK: $TPK_FILE"
else
    if [ ! -f "$TPK_FILE" ]; then
        print_error "TPK file not found: $TPK_FILE"
        exit 1
    fi
    print_status "Using TPK: $TPK_FILE"
fi

# Get TPK size
TPK_SIZE=$(du -h "$TPK_FILE" | cut -f1)
print_info "TPK size: $TPK_SIZE"

# Check if TPK is signed
print_info "Checking TPK signature..."
if command -v unzip >/dev/null 2>&1; then
    if unzip -l "$TPK_FILE" 2>/dev/null | grep -q "signature1.xml"; then
        print_status "TPK is signed"
    else
        print_warning "TPK is unsigned (requires developer mode)"
    fi
else
    print_warning "Cannot verify signature (unzip not available)"
fi

# Step 4: Uninstall existing version (if requested)
if [ "$UNINSTALL_FIRST" = "yes" ]; then
    print_section "Step 4: Uninstalling Existing Version"
    
    print_info "Checking if Kodi is installed..."
    
    if $SDB_CMD shell "pkgcmd -l" 2>/dev/null | grep -q "$PACKAGE_ID"; then
        print_info "Kodi is installed, uninstalling..."
        
        # Kill app if running
        $SDB_CMD shell "app_launcher -k $PACKAGE_ID" 2>/dev/null || true
        sleep 1
        
        # Uninstall
        if $SDB_CMD shell "pkgcmd -u -n $PACKAGE_ID" 2>/dev/null; then
            print_status "Uninstall successful"
            sleep 2
        else
            print_warning "Uninstall failed (may not be installed)"
        fi
    else
        print_info "Kodi is not currently installed"
    fi
else
    print_info "Skipping uninstall step"
fi

# Step 5: Install TPK
print_section "Step 5: Installing TPK"

print_info "Pushing TPK to device..."
REMOTE_TPK="/tmp/kodi-tizen.tpk"
$SDB_CMD push "$TPK_FILE" "$REMOTE_TPK"

if [ $? -ne 0 ]; then
    print_error "Failed to push TPK to device"
    exit 1
fi
print_status "TPK pushed to device"

print_info "Installing package..."
if $SDB_CMD shell "pkgcmd -i -t tpk -p $REMOTE_TPK" 2>&1 | tee /tmp/install.log; then
    print_status "Installation successful"
else
    print_error "Installation failed"
    echo ""
    echo "Installation log:"
    cat /tmp/install.log
    echo ""
    print_error "Possible causes:"
    echo "  1. Unsigned TPK without developer mode enabled"
    echo "  2. Insufficient storage space on device"
    echo "  3. Incompatible Tizen version"
    echo "  4. Certificate/signature issues"
    exit 1
fi

# Clean up remote TPK
$SDB_CMD shell "rm -f $REMOTE_TPK" 2>/dev/null || true

# Wait for installation to complete
print_info "Waiting for installation to settle..."
sleep $WAIT_AFTER_INSTALL

# Step 6: Verify installation
if [ "$VERIFY_INSTALL" = "yes" ]; then
    print_section "Step 6: Verifying Installation"
    
    print_info "Checking if package is installed..."
    if $SDB_CMD shell "pkgcmd -l" 2>/dev/null | grep -q "$PACKAGE_ID"; then
        print_status "Package is installed"
    else
        print_error "Package not found after installation"
        exit 1
    fi
    
    print_info "Checking package information..."
    PKG_INFO=$($SDB_CMD shell "pkginfo --pkg $PACKAGE_ID" 2>/dev/null || echo "")
    
    if [ -n "$PKG_INFO" ]; then
        print_status "Package information retrieved"
        echo "$PKG_INFO" | grep -E "(package|version|type)" | sed 's/^/  /'
    else
        print_warning "Could not retrieve package information"
    fi
    
    print_info "Checking installed files..."
    APP_DIR="/opt/usr/apps/$PACKAGE_ID"
    
    # Check binary
    if $SDB_CMD shell "test -f $APP_DIR/bin/kodi-tizen" 2>/dev/null; then
        print_status "Kodi binary installed"
    else
        print_error "Kodi binary not found"
        exit 1
    fi
    
    # Check manifest
    if $SDB_CMD shell "test -f $APP_DIR/tizen-manifest.xml" 2>/dev/null; then
        print_status "Manifest file installed"
    else
        print_warning "Manifest file not found"
    fi
    
    # Check resources
    if $SDB_CMD shell "test -d $APP_DIR/res" 2>/dev/null; then
        print_status "Resources directory installed"
    else
        print_warning "Resources directory not found"
    fi
    
    # Check storage space
    print_info "Checking device storage..."
    STORAGE_INFO=$($SDB_CMD shell "df -h /opt" 2>/dev/null | tail -n 1)
    STORAGE_AVAIL=$(echo "$STORAGE_INFO" | awk '{print $4}')
    print_info "Available storage: $STORAGE_AVAIL"
else
    print_info "Skipping installation verification"
fi

# Step 7: Launch application
if [ "$LAUNCH_APP" = "yes" ]; then
    print_section "Step 7: Launching Application"
    
    print_info "Starting Kodi..."
    if $SDB_CMD shell "app_launcher -s $PACKAGE_ID" 2>/dev/null; then
        print_status "Kodi launched successfully"
        
        # Wait a moment for app to start
        sleep 3
        
        # Check if app is running
        print_info "Verifying application is running..."
        if $SDB_CMD shell "app_launcher -r" 2>/dev/null | grep -q "$PACKAGE_ID"; then
            print_status "Kodi is running"
        else
            print_warning "Could not verify if Kodi is running"
        fi
    else
        print_error "Failed to launch Kodi"
        echo ""
        echo "Try launching manually from TV home screen"
        exit 1
    fi
else
    print_info "Skipping application launch"
fi

# Step 8: Summary
print_section "Summary"

print_status "Deployment completed successfully"
echo ""
print_info "Deployment Details:"
echo "  TPK File: $TPK_FILE"
echo "  TPK Size: $TPK_SIZE"
echo "  Device: $DEVICE_ID"
echo "  Device Model: $DEVICE_MODEL"
echo "  Tizen Version: $TIZEN_VERSION"
echo "  Package ID: $PACKAGE_ID"

if [ "$LAUNCH_APP" = "yes" ]; then
    echo "  Status: Installed and running"
else
    echo "  Status: Installed (not launched)"
fi

echo ""
print_info "Next Steps:"
echo ""
echo "1. View application logs:"
echo "   $SCRIPT_DIR/logs.sh -f"
echo ""
echo "2. View crash logs (if any):"
echo "   $SCRIPT_DIR/logs.sh -C"
echo ""
echo "3. Stop application:"
echo "   sdb -s $DEVICE_ID shell 'app_launcher -k $PACKAGE_ID'"
echo ""
echo "4. Uninstall application:"
echo "   sdb -s $DEVICE_ID shell 'pkgcmd -u -n $PACKAGE_ID'"
echo ""

print_status "Deployment and verification complete!"
