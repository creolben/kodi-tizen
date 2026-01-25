#!/bin/bash
# Kodi Tizen Log Viewer Script
# This script retrieves and displays logs from Tizen device via SDB

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
DEVICE_ID=""
LOG_TAG="KODI"
FOLLOW=false
CLEAR_LOGS=false
LOG_LEVEL="V"  # V=Verbose, D=Debug, I=Info, W=Warning, E=Error, F=Fatal
FILTER=""

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
        exit 1
    fi
}

# Function to check device connection
check_device() {
    local device_count=$(sdb devices | grep -c "device" || true)
    
    if [ "$device_count" -eq 0 ]; then
        print_error "No Tizen devices connected"
        exit 1
    fi
    
    if [ "$device_count" -gt 1 ] && [ -z "$DEVICE_ID" ]; then
        print_warn "Multiple devices connected. Please specify device with -d option"
        sdb devices
        exit 1
    fi
}

# Function to clear logs
clear_logs() {
    print_info "Clearing dlog buffer..."
    
    local sdb_cmd="sdb"
    if [ -n "$DEVICE_ID" ]; then
        sdb_cmd="sdb -s $DEVICE_ID"
    fi
    
    $sdb_cmd dlog -c
    print_info "Logs cleared"
}

# Function to view logs
view_logs() {
    local sdb_cmd="sdb"
    if [ -n "$DEVICE_ID" ]; then
        sdb_cmd="sdb -s $DEVICE_ID"
    fi
    
    # Build dlog command
    local dlog_cmd="dlog"
    
    # Add tag filter
    if [ -n "$LOG_TAG" ]; then
        dlog_cmd="$dlog_cmd $LOG_TAG:$LOG_LEVEL"
    else
        dlog_cmd="$dlog_cmd *:$LOG_LEVEL"
    fi
    
    # Add follow mode
    if [ "$FOLLOW" = true ]; then
        print_info "Following logs (Ctrl+C to stop)..."
        print_info "Log level: $LOG_LEVEL, Tag: $LOG_TAG"
        print_info "----------------------------------------"
        
        if [ -n "$FILTER" ]; then
            $sdb_cmd $dlog_cmd | grep --color=auto "$FILTER"
        else
            $sdb_cmd $dlog_cmd
        fi
    else
        print_info "Retrieving logs..."
        print_info "Log level: $LOG_LEVEL, Tag: $LOG_TAG"
        print_info "----------------------------------------"
        
        if [ -n "$FILTER" ]; then
            $sdb_cmd $dlog_cmd | grep --color=auto "$FILTER"
        else
            $sdb_cmd $dlog_cmd
        fi
    fi
}

# Function to save logs to file
save_logs() {
    local output_file="$1"
    
    print_info "Saving logs to: $output_file"
    
    local sdb_cmd="sdb"
    if [ -n "$DEVICE_ID" ]; then
        sdb_cmd="sdb -s $DEVICE_ID"
    fi
    
    local dlog_cmd="dlog"
    if [ -n "$LOG_TAG" ]; then
        dlog_cmd="$dlog_cmd $LOG_TAG:$LOG_LEVEL"
    else
        dlog_cmd="$dlog_cmd *:$LOG_LEVEL"
    fi
    
    $sdb_cmd $dlog_cmd > "$output_file"
    print_info "Logs saved successfully"
}

# Function to show crash logs
show_crash_logs() {
    print_info "Retrieving crash logs..."
    
    local sdb_cmd="sdb"
    if [ -n "$DEVICE_ID" ]; then
        sdb_cmd="sdb -s $DEVICE_ID"
    fi
    
    # Show recent fatal errors from dlog
    print_info ""
    print_info "Recent fatal errors from dlog:"
    print_info "----------------------------------------"
    $sdb_cmd dlog KODI:F *:S
    
    # Check for crash log files
    print_info ""
    print_info "Crash log files:"
    print_info "----------------------------------------"
    
    # Get app data path
    local data_path="/opt/usr/home/owner/apps_rw/org.xbmc.kodi/data"
    
    # List crash log files
    $sdb_cmd shell "ls -lh $data_path/crash_*.log 2>/dev/null" || {
        print_info "No crash log files found"
        return
    }
    
    # Ask if user wants to pull crash logs
    print_info ""
    print_info "To download crash logs, run:"
    print_info "  $sdb_cmd pull $data_path/crash_*.log ./"
}

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

View and manage Kodi logs on Tizen device via SDB

OPTIONS:
    -d <device>     Device ID (required if multiple devices connected)
    -t <tag>        Log tag to filter (default: KODI)
    -l <level>      Log level: V(erbose), D(ebug), I(nfo), W(arning), E(rror), F(atal)
                    (default: V)
    -f              Follow logs in real-time (like tail -f)
    -c              Clear log buffer before viewing
    -s <file>       Save logs to file
    -g <pattern>    Grep filter for log messages
    -C              Show crash logs only
    -h              Show this help message

LOG LEVELS:
    V - Verbose (all messages)
    D - Debug and above
    I - Info and above
    W - Warning and above
    E - Error and above
    F - Fatal only

EXAMPLES:
    # View all Kodi logs
    $0

    # Follow logs in real-time
    $0 -f

    # View only errors and fatal messages
    $0 -l E

    # Clear logs and follow new ones
    $0 -c -f

    # Save logs to file
    $0 -s kodi-logs.txt

    # Filter logs containing "video"
    $0 -g "video"

    # View crash logs
    $0 -C

    # View logs from specific device
    $0 -d emulator-26101 -f

EOF
}

# Parse command line arguments
SAVE_FILE=""
CRASH_ONLY=false

while getopts "d:t:l:fcs:g:Ch" opt; do
    case $opt in
        d)
            DEVICE_ID="$OPTARG"
            ;;
        t)
            LOG_TAG="$OPTARG"
            ;;
        l)
            LOG_LEVEL="$OPTARG"
            ;;
        f)
            FOLLOW=true
            ;;
        c)
            CLEAR_LOGS=true
            ;;
        s)
            SAVE_FILE="$OPTARG"
            ;;
        g)
            FILTER="$OPTARG"
            ;;
        C)
            CRASH_ONLY=true
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
print_info "Kodi Tizen Log Viewer"
print_info "====================="

check_sdb
check_device

if [ "$CLEAR_LOGS" = true ]; then
    clear_logs
fi

if [ "$CRASH_ONLY" = true ]; then
    show_crash_logs
elif [ -n "$SAVE_FILE" ]; then
    save_logs "$SAVE_FILE"
else
    view_logs
fi
