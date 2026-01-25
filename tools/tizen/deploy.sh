#!/bin/bash
# Kodi Tizen Deployment Script
# This script deploys Kodi TPK to a Tizen device via SDB

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
TPK_FILE=""
DEVICE_ID=""
UNINSTALL_FIRST=false
PACKAGE_ID="org.xbmc.kodi"

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if SDB is available
check_sdb() {
    if ! command -v sdb &> /dev/null; then
        print_error "SDB (Smart Development Bridge) not found in PATH"
        print_error "Please install Tizen Studio and add SDB to your PATH"
        print_error "Typical location: ~/tizen-studio/tools/sdb"
        exit 1
    fi
    print_info "SDB found: $(which sdb)"
}

# Function to list connected devices
list_devices() {
    print_info "Listing connected Tizen devices..."
    sdb devices
}

# Function to check device connection
check_device() {
    local device_count=$(sdb devices | grep -c "device" || true)
    
    if [ "$device_count" -eq 0 ]; then
        print_error "No Tizen devices connected"
        print_error "Please connect a device or start the Tizen emulator"
        print_error ""
        print_error "To connect a device:"
        print_error "  1. Enable Developer Mode on your Samsung TV"
        print_error "  2. Connect via: sdb connect <TV_IP_ADDRESS>"
        exit 1
    fi
    
    if [ "$device_count" -gt 1 ] && [ -z "$DEVICE_ID" ]; then
        print_warn "Multiple devices connected. Please specify device with -d option"
        list_devices
        exit 1
    fi
    
    print_info "Device connected successfully"
}

# Function to find TPK file
find_tpk() {
    if [ -n "$TPK_FILE" ]; then
        if [ ! -f "$TPK_FILE" ]; then
            print_error "TPK file not found: $TPK_FILE"
            exit 1
        fi
        return
    fi
    
    # Search for TPK in common locations
    local search_paths=(
        "${PROJECT_ROOT}/build/kodi-tizen.tpk"
        "${PROJECT_ROOT}/kodi-tizen.tpk"
        "${PROJECT_ROOT}/build/tizen/kodi-tizen.tpk"
    )
    
    for path in "${search_paths[@]}"; do
        if [ -f "$path" ]; then
            TPK_FILE="$path"
            print_info "Found TPK: $TPK_FILE"
            return
        fi
    done
    
    print_error "TPK file not found. Please specify with -t option or build first"
    exit 1
}

# Function to uninstall existing package
uninstall_package() {
    print_info "Checking if package is already installed..."
    
    local sdb_cmd="sdb"
    if [ -n "$DEVICE_ID" ]; then
        sdb_cmd="sdb -s $DEVICE_ID"
    fi
    
    if $sdb_cmd shell "app_launcher -l" | grep -q "$PACKAGE_ID"; then
        print_info "Package $PACKAGE_ID is installed. Uninstalling..."
        $sdb_cmd shell "pkgcmd -u -n $PACKAGE_ID" || true
        sleep 2
        print_info "Uninstall complete"
    else
        print_info "Package not currently installed"
    fi
}

# Function to check if TPK is signed
check_tpk_signature() {
    if command -v unzip &> /dev/null; then
        if unzip -l "$TPK_FILE" 2>/dev/null | grep -q "signature1.xml"; then
            return 0  # Signed
        else
            return 1  # Unsigned
        fi
    fi
    return 2  # Cannot determine
}

# Function to install TPK
install_tpk() {
    print_info "Installing TPK: $TPK_FILE"
    
    # Check if TPK is signed
    local is_signed=2
    check_tpk_signature
    is_signed=$?
    
    if [ $is_signed -eq 1 ]; then
        print_warn "TPK appears to be unsigned"
        print_warn "Unsigned TPKs require developer mode to be enabled on the device"
        print_warn "See tools/tizen/DEVELOPER_MODE_GUIDE.md for instructions"
    fi
    
    local sdb_cmd="sdb"
    if [ -n "$DEVICE_ID" ]; then
        sdb_cmd="sdb -s $DEVICE_ID"
    fi
    
    # Push TPK to device
    local remote_path="/tmp/kodi-tizen.tpk"
    print_info "Pushing TPK to device..."
    $sdb_cmd push "$TPK_FILE" "$remote_path"
    
    # Install package
    print_info "Installing package..."
    if $sdb_cmd shell "pkgcmd -i -t tpk -p $remote_path"; then
        print_info "Installation successful!"
    else
        print_error "Installation failed!"
        if [ $is_signed -eq 1 ]; then
            print_error ""
            print_error "Possible causes:"
            print_error "  1. Developer mode is not enabled on the device"
            print_error "  2. Device is not properly connected"
            print_error "  3. Insufficient storage space"
            print_error ""
            print_error "For unsigned TPKs, ensure developer mode is enabled:"
            print_error "  See: tools/tizen/DEVELOPER_MODE_GUIDE.md"
        fi
        exit 1
    fi
    
    # Clean up
    $sdb_cmd shell "rm -f $remote_path"
}

# Function to launch application
launch_app() {
    print_info "Launching Kodi..."
    
    local sdb_cmd="sdb"
    if [ -n "$DEVICE_ID" ]; then
        sdb_cmd="sdb -s $DEVICE_ID"
    fi
    
    $sdb_cmd shell "app_launcher -s $PACKAGE_ID"
    print_info "Kodi launched successfully"
}

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Deploy Kodi TPK to Tizen device via SDB

OPTIONS:
    -t <file>       Path to TPK file (auto-detected if not specified)
    -d <device>     Device ID (required if multiple devices connected)
    -u              Uninstall existing package before installing
    -l              Launch application after installation
    -h              Show this help message

EXAMPLES:
    # Deploy with auto-detected TPK
    $0

    # Deploy specific TPK file
    $0 -t build/kodi-tizen.tpk

    # Uninstall old version and install new one
    $0 -u

    # Install and launch
    $0 -u -l

    # Deploy to specific device
    $0 -d emulator-26101

EOF
}

# Parse command line arguments
LAUNCH_APP=false

while getopts "t:d:ulh" opt; do
    case $opt in
        t)
            TPK_FILE="$OPTARG"
            ;;
        d)
            DEVICE_ID="$OPTARG"
            ;;
        u)
            UNINSTALL_FIRST=true
            ;;
        l)
            LAUNCH_APP=true
            ;;
        h)
            show_usage
            exit 0
            ;;
        \?)
            print_error "Invalid option: -$OPTARG"
            show_usage
            exit 1
            ;;
    esac
done

# Main deployment flow
print_info "Kodi Tizen Deployment Script"
print_info "=============================="

check_sdb
check_device
find_tpk

if [ "$UNINSTALL_FIRST" = true ]; then
    uninstall_package
fi

install_tpk

if [ "$LAUNCH_APP" = true ]; then
    launch_app
fi

print_info ""
print_info "Deployment complete!"
print_info "To view logs, run: tools/tizen/logs.sh"
