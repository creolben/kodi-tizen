#!/bin/bash
# Kodi Tizen Migration - Final Verification Script
# This script performs comprehensive verification of the Tizen migration

# Don't exit on error - we want to collect all failures
set +e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNINGS=0

# Log functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((PASSED_CHECKS++))
    ((TOTAL_CHECKS++))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((FAILED_CHECKS++))
    ((TOTAL_CHECKS++))
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    ((WARNINGS++))
}

log_section() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

# Check if file exists
check_file() {
    local file=$1
    local description=$2
    
    if [ -f "$file" ]; then
        log_success "$description exists: $file"
        return 0
    else
        log_fail "$description missing: $file"
        return 1
    fi
}

# Check if directory exists
check_dir() {
    local dir=$1
    local description=$2
    
    if [ -d "$dir" ]; then
        log_success "$description exists: $dir"
        return 0
    else
        log_fail "$description missing: $dir"
        return 1
    fi
}

# Check if string exists in file
check_in_file() {
    local file=$1
    local pattern=$2
    local description=$3
    
    if [ ! -f "$file" ]; then
        log_fail "$description - file not found: $file"
        return 1
    fi
    
    if grep -q "$pattern" "$file"; then
        log_success "$description found in $file"
        return 0
    else
        log_fail "$description not found in $file"
        return 1
    fi
}

# Main verification
log_section "Kodi Tizen Migration - Final Verification"
log_info "Starting comprehensive migration verification..."

# 1. Build System Verification
log_section "1. Build System Configuration"

check_file "cmake/platform/linux/tizen.cmake" "Tizen CMake configuration"
check_in_file "cmake/platform/linux/tizen.cmake" "TARGET_TIZEN" "TARGET_TIZEN macro definition"
check_in_file "cmake/platform/linux/tizen.cmake" "dlog" "dlog dependency"
check_in_file "cmake/platform/linux/tizen.cmake" "capi-appfw-application" "Application framework dependency"
check_in_file "cmake/platform/linux/tizen.cmake" "capi-media-player" "Media player dependency"

# 2. Platform Abstraction Layer
log_section "2. Platform Abstraction Layer"

check_file "xbmc/platform/linux/PlatformTizen.h" "Platform header"
check_file "xbmc/platform/linux/PlatformTizen.cpp" "Platform implementation"
check_in_file "xbmc/platform/linux/PlatformTizen.h" "class CPlatformTizen" "CPlatformTizen class"
check_in_file "xbmc/platform/linux/PlatformTizen.cpp" "app_event_set_cb" "Lifecycle callbacks"
check_in_file "xbmc/platform/linux/PlatformTizen.cpp" "app_get_data_path" "Data path handling"

# 3. Logging Integration
log_section "3. Logging Integration"

check_file "xbmc/platform/linux/utils/DlogSink.h" "Dlog sink header"
check_file "xbmc/platform/linux/utils/DlogSink.cpp" "Dlog sink implementation"
check_in_file "xbmc/platform/linux/utils/DlogSink.cpp" "dlog_print" "dlog_print usage"

# 4. Windowing System
log_section "4. Windowing System"

check_file "xbmc/windowing/wayland/WinSystemWaylandTizen.h" "Windowing system header"
check_file "xbmc/windowing/wayland/WinSystemWaylandTizen.cpp" "Windowing system implementation"
check_in_file "xbmc/windowing/wayland/WinSystemWaylandTizen.h" "class CWinSystemWaylandTizen" "CWinSystemWaylandTizen class"
check_file "xbmc/windowing/wayland/OSScreenSaverTizen.h" "Screen saver header"
check_file "xbmc/windowing/wayland/OSScreenSaverTizen.cpp" "Screen saver implementation"

# 5. Input Handling
log_section "5. Input Handling"

check_file "xbmc/windowing/wayland/SeatTizen.h" "Seat Tizen header"
check_file "xbmc/windowing/wayland/SeatTizen.cpp" "Seat Tizen implementation"
check_in_file "xbmc/windowing/wayland/SeatTizen.cpp" "MapTizenKeyToKodiEvent" "Key mapping function"

# 6. Media Pipeline
log_section "6. Media Pipeline"

check_file "xbmc/cores/VideoPlayer/VideoPlayerTizen.h" "Video player header"
check_file "xbmc/cores/VideoPlayer/VideoPlayerTizen.cpp" "Video player implementation"
check_in_file "xbmc/cores/VideoPlayer/VideoPlayerTizen.cpp" "player_create" "AVPlay integration"

# 7. Network Support
log_section "7. Network Support"

check_file "xbmc/platform/linux/network/NetworkTizen.h" "Network header"
check_file "xbmc/platform/linux/network/NetworkTizen.cpp" "Network implementation"
check_in_file "xbmc/platform/linux/network/NetworkTizen.cpp" "connection_create" "Network monitoring"

# 8. Storage Management
log_section "8. Storage Management"

check_file "xbmc/platform/linux/storage/StorageTizen.h" "Storage header"
check_file "xbmc/platform/linux/storage/StorageTizen.cpp" "Storage implementation"
check_in_file "xbmc/platform/linux/storage/StorageTizen.cpp" "storage_get_internal_memory_size" "Storage queries"

# 9. Packaging System
log_section "9. Packaging System"

check_file "tools/tizen/packaging/tizen-manifest.xml.in" "Manifest template"
check_file "tools/tizen/packaging/package.sh" "Packaging script"
check_file "tools/tizen/packaging/sign.sh" "Signing script"
check_in_file "tools/tizen/packaging/tizen-manifest.xml.in" "org.xbmc.kodi" "Package ID"
check_dir "tools/tizen/packaging/icons" "Icon directory"

# 10. Documentation
log_section "10. Documentation"

check_file "docs/README.Tizen.md" "Tizen build guide"
check_file "docs/TIZEN_PLATFORM_NOTES.md" "Platform notes"
check_file "tools/tizen/DEVELOPER_MODE_GUIDE.md" "Developer mode guide"
check_file "tools/tizen/EMULATOR_GUIDE.md" "Emulator guide"
check_file "tools/tizen/CRASH_LOGGING_GUIDE.md" "Crash logging guide"

# 11. Test Files
log_section "11. Test Coverage"

check_file "xbmc/platform/linux/test/TestPlatformTizen.cpp" "Platform tests"
check_file "xbmc/windowing/wayland/test/TestWinSystemWaylandTizen.cpp" "Windowing tests"
check_file "xbmc/platform/linux/test/TestTizenSkinCompatibility.cpp" "Skin compatibility tests"
check_file "xbmc/platform/linux/test/TestTizenFontRendering.cpp" "Font rendering tests"

# 12. Deployment Scripts
log_section "12. Deployment Scripts"

check_file "tools/tizen/create-and-sign-tpk.sh" "TPK creation script"
check_file "tools/tizen/deploy-and-verify.sh" "Deployment script"

if [ -f "tools/tizen/create-and-sign-tpk.sh" ]; then
    if [ -x "tools/tizen/create-and-sign-tpk.sh" ]; then
        log_success "TPK creation script is executable"
    else
        log_warning "TPK creation script is not executable"
    fi
fi

if [ -f "tools/tizen/deploy-and-verify.sh" ]; then
    if [ -x "tools/tizen/deploy-and-verify.sh" ]; then
        log_success "Deployment script is executable"
    else
        log_warning "Deployment script is not executable"
    fi
fi

# 13. Data Management Documentation
log_section "13. Data Management"

check_file "xbmc/platform/linux/TIZEN_DATA_MANAGEMENT.md" "Data management documentation"

# 14. Crash Handling
log_section "14. Crash Handling"

check_file "xbmc/platform/linux/TizenCrashHandler.h" "Crash handler header"
check_file "xbmc/platform/linux/TizenCrashHandler.cpp" "Crash handler implementation"

# 15. Asset Preservation
log_section "15. Asset Preservation"

check_dir "addons/skin.estuary" "Default skin"
check_dir "media/Fonts" "Font directory"
check_dir "media" "Media assets"

# 16. Check for required Tizen API usage
log_section "16. Tizen API Integration"

log_info "Checking for Tizen API usage in codebase..."

# Check for key Tizen APIs
if grep -r "app_event_set_cb" xbmc/platform/linux/*.cpp > /dev/null 2>&1; then
    log_success "Application lifecycle API usage found"
else
    log_fail "Application lifecycle API usage not found"
fi

if grep -r "player_create" xbmc/cores/VideoPlayer/*.cpp > /dev/null 2>&1; then
    log_success "Media player API usage found"
else
    log_fail "Media player API usage not found"
fi

if grep -r "dlog_print" xbmc/platform/linux/utils/*.cpp > /dev/null 2>&1; then
    log_success "Logging API usage found"
else
    log_fail "Logging API usage not found"
fi

# 17. Summary
log_section "Verification Summary"

echo ""
echo "Total Checks: $TOTAL_CHECKS"
echo -e "${GREEN}Passed: $PASSED_CHECKS${NC}"
echo -e "${RED}Failed: $FAILED_CHECKS${NC}"
echo -e "${YELLOW}Warnings: $WARNINGS${NC}"
echo ""

if [ $FAILED_CHECKS -eq 0 ]; then
    echo -e "${GREEN}✓ All critical checks passed!${NC}"
    echo ""
    echo "The Kodi Tizen migration appears to be complete."
    echo ""
    echo "Next steps:"
    echo "1. Build the project: cd tools/depends && ./bootstrap && ./configure --host=arm-tizen-linux-gnueabi"
    echo "2. Run tests: make test"
    echo "3. Create TPK: ./tools/tizen/create-and-sign-tpk.sh"
    echo "4. Deploy to device: ./tools/tizen/deploy-and-verify.sh"
    echo ""
    exit 0
else
    echo -e "${RED}✗ Some checks failed. Please review the failures above.${NC}"
    echo ""
    exit 1
fi
