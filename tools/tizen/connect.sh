#!/bin/bash
# Kodi Tizen Device Connection Script
# This script helps connect to Tizen devices via SDB

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Function to check if SDB is available
check_sdb() {
    if ! command -v sdb &> /dev/null; then
        print_error "SDB (Smart Development Bridge) not found in PATH"
        print_error ""
        print_error "Please install Tizen Studio and add SDB to your PATH:"
        print_error "  export PATH=\$PATH:~/tizen-studio/tools"
        print_error ""
        print_error "Download Tizen Studio from:"
        print_error "  https://developer.tizen.org/development/tizen-studio/download"
        exit 1
    fi
    print_info "SDB found: $(which sdb)"
    print_info "SDB version: $(sdb version 2>&1 | head -n1)"
}

# Function to list connected devices
list_devices() {
    print_info "Connected devices:"
    print_info "=================="
    sdb devices
    echo ""
}

# Function to connect to device
connect_device() {
    local ip_address="$1"
    local port="${2:-26101}"  # Default Tizen SDB port
    
    print_info "Connecting to $ip_address:$port..."
    
    if sdb connect "$ip_address:$port"; then
        print_info "Successfully connected to $ip_address:$port"
        sleep 1
        list_devices
        return 0
    else
        print_error "Failed to connect to $ip_address:$port"
        return 1
    fi
}

# Function to disconnect device
disconnect_device() {
    local ip_address="$1"
    local port="${2:-26101}"
    
    print_info "Disconnecting from $ip_address:$port..."
    
    if sdb disconnect "$ip_address:$port"; then
        print_info "Successfully disconnected"
        return 0
    else
        print_error "Failed to disconnect"
        return 1
    fi
}

# Function to show device info
show_device_info() {
    local device_id="$1"
    
    print_info "Device Information"
    print_info "=================="
    
    local sdb_cmd="sdb"
    if [ -n "$device_id" ]; then
        sdb_cmd="sdb -s $device_id"
    fi
    
    echo ""
    print_info "Model:"
    $sdb_cmd shell "cat /etc/config/model-config.xml 2>/dev/null | grep -oP '(?<=<ModelName>)[^<]+' || echo 'Unknown'"
    
    echo ""
    print_info "Tizen Version:"
    $sdb_cmd shell "cat /etc/tizen-release 2>/dev/null || echo 'Unknown'"
    
    echo ""
    print_info "Platform:"
    $sdb_cmd capability
    
    echo ""
    print_info "Installed Packages:"
    $sdb_cmd shell "pkginfo --listpkg | grep kodi || echo 'Kodi not installed'"
}

# Function to enable root access
enable_root() {
    print_warn "Attempting to enable root access..."
    print_warn "This may not work on all devices"
    
    sdb root on
    
    if [ $? -eq 0 ]; then
        print_info "Root access enabled"
    else
        print_warn "Failed to enable root access"
        print_warn "Some debugging features may be limited"
    fi
}

# Function to show connection guide
show_connection_guide() {
    cat << EOF

${GREEN}Tizen Device Connection Guide${NC}
================================

${BLUE}For Samsung TV:${NC}

1. Enable Developer Mode on your TV:
   - Go to Apps
   - Enter "12345" using the remote
   - Toggle "Developer mode" ON
   - Enter your PC's IP address
   - Restart the TV

2. Find your TV's IP address:
   - Go to Settings > General > Network > Network Status
   - Note the IP address

3. Connect using this script:
   ${GREEN}$0 -c <TV_IP_ADDRESS>${NC}

${BLUE}For Tizen Emulator:${NC}

1. Start the emulator from Tizen Studio:
   - Open Emulator Manager
   - Select a TV emulator
   - Click "Launch"

2. The emulator should auto-connect
   - Check with: ${GREEN}$0 -l${NC}

${BLUE}Troubleshooting:${NC}

- Ensure TV and PC are on the same network
- Check firewall settings (port 26101)
- Try restarting the TV's developer mode
- Verify SDB is in your PATH

${BLUE}Useful Commands:${NC}

  List devices:        ${GREEN}$0 -l${NC}
  Connect to TV:       ${GREEN}$0 -c <IP>${NC}
  Disconnect:          ${GREEN}$0 -x <IP>${NC}
  Device info:         ${GREEN}$0 -i${NC}
  Enable root:         ${GREEN}$0 -r${NC}

EOF
}

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Manage SDB connections to Tizen devices

OPTIONS:
    -c <ip>         Connect to device at IP address
    -p <port>       Port number (default: 26101)
    -x <ip>         Disconnect from device
    -l              List connected devices
    -i [device]     Show device information
    -r              Enable root access
    -g              Show connection guide
    -h              Show this help message

EXAMPLES:
    # Show connection guide
    $0 -g

    # List connected devices
    $0 -l

    # Connect to Samsung TV
    $0 -c 192.168.1.100

    # Connect to device on custom port
    $0 -c 192.168.1.100 -p 26102

    # Disconnect from device
    $0 -x 192.168.1.100

    # Show device information
    $0 -i

    # Enable root access
    $0 -r

EOF
}

# Parse command line arguments
CONNECT_IP=""
DISCONNECT_IP=""
PORT="26101"
LIST_DEVICES=false
SHOW_INFO=false
ENABLE_ROOT=false
SHOW_GUIDE=false
DEVICE_ID=""

while getopts "c:p:x:li:rgh" opt; do
    case $opt in
        c)
            CONNECT_IP="$OPTARG"
            ;;
        p)
            PORT="$OPTARG"
            ;;
        x)
            DISCONNECT_IP="$OPTARG"
            ;;
        l)
            LIST_DEVICES=true
            ;;
        i)
            SHOW_INFO=true
            DEVICE_ID="$OPTARG"
            ;;
        r)
            ENABLE_ROOT=true
            ;;
        g)
            SHOW_GUIDE=true
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

# Main flow
print_info "Kodi Tizen Device Connection Manager"
print_info "====================================="
echo ""

check_sdb

if [ "$SHOW_GUIDE" = true ]; then
    show_connection_guide
    exit 0
fi

if [ -n "$CONNECT_IP" ]; then
    connect_device "$CONNECT_IP" "$PORT"
    exit 0
fi

if [ -n "$DISCONNECT_IP" ]; then
    disconnect_device "$DISCONNECT_IP" "$PORT"
    exit 0
fi

if [ "$LIST_DEVICES" = true ]; then
    list_devices
    exit 0
fi

if [ "$SHOW_INFO" = true ]; then
    show_device_info "$DEVICE_ID"
    exit 0
fi

if [ "$ENABLE_ROOT" = true ]; then
    enable_root
    exit 0
fi

# If no options specified, show usage
show_usage
