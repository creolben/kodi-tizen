#!/bin/bash
# Complete TPK creation and signing script for Kodi Tizen
# This script orchestrates the full packaging and signing process

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
BUILD_DIR="${BUILD_DIR:-$PROJECT_ROOT/build}"
SECURITY_PROFILE="${TIZEN_SECURITY_PROFILE}"
SKIP_SIGNING="${SKIP_SIGNING:-no}"
VERIFY_PACKAGE="${VERIFY_PACKAGE:-yes}"

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
    echo "  -b, --build-dir <path>      Build directory (default: $PROJECT_ROOT/build)"
    echo "  -p, --profile <name>        Security profile for signing (default: from TIZEN_SECURITY_PROFILE)"
    echo "  -s, --skip-signing          Skip signing step (create unsigned TPK only)"
    echo "  -n, --no-verify             Skip package verification"
    echo "  -h, --help                  Display this help message"
    echo ""
    echo "Environment Variables:"
    echo "  TIZEN_SDK                   Path to Tizen Studio installation (required)"
    echo "  TIZEN_SECURITY_PROFILE      Default security profile name"
    echo "  BUILD_DIR                   Build directory path"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Create and sign TPK with default profile"
    echo "  $0 -s                                 # Create unsigned TPK only"
    echo "  $0 -p my-profile                      # Use specific security profile"
    echo "  $0 -b /path/to/build                  # Use custom build directory"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -b|--build-dir)
            BUILD_DIR="$2"
            shift 2
            ;;
        -p|--profile)
            SECURITY_PROFILE="$2"
            shift 2
            ;;
        -s|--skip-signing)
            SKIP_SIGNING="yes"
            shift
            ;;
        -n|--no-verify)
            VERIFY_PACKAGE="no"
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

print_section "Kodi Tizen TPK Creation and Signing"

print_info "Configuration:"
echo "  Build Directory: $BUILD_DIR"
echo "  Security Profile: ${SECURITY_PROFILE:-<not set>}"
echo "  Skip Signing: $SKIP_SIGNING"
echo "  Verify Package: $VERIFY_PACKAGE"
echo ""

# Step 1: Verify environment
print_section "Step 1: Verifying Environment"

if [ -z "$TIZEN_SDK" ]; then
    print_error "TIZEN_SDK environment variable not set"
    echo "Please set TIZEN_SDK to your Tizen Studio installation path"
    exit 1
fi
print_status "TIZEN_SDK: $TIZEN_SDK"

if [ ! -d "$TIZEN_SDK" ]; then
    print_error "TIZEN_SDK directory does not exist: $TIZEN_SDK"
    exit 1
fi
print_status "Tizen SDK directory exists"

# Check for tizen CLI tool
TIZEN_CLI="$TIZEN_SDK/tools/ide/bin/tizen"
if [ ! -f "$TIZEN_CLI" ]; then
    print_error "Tizen CLI tool not found at: $TIZEN_CLI"
    exit 1
fi
print_status "Tizen CLI tool found"

# Check build directory
if [ ! -d "$BUILD_DIR" ]; then
    print_error "Build directory not found: $BUILD_DIR"
    echo "Please build Kodi first using: ./tools/tizen/build-complete.sh"
    exit 1
fi
print_status "Build directory exists"

# Check for Kodi binary
if [ ! -f "$BUILD_DIR/kodi.bin" ]; then
    print_error "Kodi binary not found in build directory"
    echo "Please build Kodi first using: ./tools/tizen/build-complete.sh"
    exit 1
fi
print_status "Kodi binary found"

# Step 2: Create TPK package
print_section "Step 2: Creating TPK Package"

print_info "Running packaging script..."
cd "$PROJECT_ROOT"

# Set environment for packaging script
export BUILD_DIR
export PACKAGE_DIR="$BUILD_DIR/package"
export OUTPUT_DIR="$BUILD_DIR"

# Run packaging script
"$SCRIPT_DIR/packaging/package.sh"

if [ $? -ne 0 ]; then
    print_error "Packaging failed"
    exit 1
fi

# Find the created TPK
TPK_FILE=$(find "$BUILD_DIR" -maxdepth 1 -name "org.xbmc.kodi-*.tpk" -type f | head -n 1)

if [ -z "$TPK_FILE" ] || [ ! -f "$TPK_FILE" ]; then
    print_error "TPK file not found after packaging"
    exit 1
fi

print_status "TPK package created: $TPK_FILE"

# Get TPK size
TPK_SIZE=$(du -h "$TPK_FILE" | cut -f1)
print_info "TPK size: $TPK_SIZE"

# Step 3: Verify package structure (if enabled)
if [ "$VERIFY_PACKAGE" = "yes" ]; then
    print_section "Step 3: Verifying Package Structure"
    
    print_info "Checking TPK contents..."
    
    # Check if unzip is available
    if command -v unzip >/dev/null 2>&1; then
        # List TPK contents
        MANIFEST_CHECK=$(unzip -l "$TPK_FILE" 2>/dev/null | grep -c "tizen-manifest.xml" || echo "0")
        BINARY_CHECK=$(unzip -l "$TPK_FILE" 2>/dev/null | grep -c "bin/kodi-tizen" || echo "0")
        ICON_CHECK=$(unzip -l "$TPK_FILE" 2>/dev/null | grep -c "shared/res/kodi.png" || echo "0")
        
        if [ "$MANIFEST_CHECK" -eq 0 ]; then
            print_error "tizen-manifest.xml not found in TPK"
            exit 1
        fi
        print_status "Manifest file present"
        
        if [ "$BINARY_CHECK" -eq 0 ]; then
            print_error "Kodi binary not found in TPK"
            exit 1
        fi
        print_status "Kodi binary present"
        
        if [ "$ICON_CHECK" -eq 0 ]; then
            print_warning "Application icon not found in TPK"
        else
            print_status "Application icon present"
        fi
        
        # Check for critical resources
        MEDIA_CHECK=$(unzip -l "$TPK_FILE" 2>/dev/null | grep -c "res/media" || echo "0")
        ADDONS_CHECK=$(unzip -l "$TPK_FILE" 2>/dev/null | grep -c "res/addons" || echo "0")
        SYSTEM_CHECK=$(unzip -l "$TPK_FILE" 2>/dev/null | grep -c "res/system" || echo "0")
        
        if [ "$MEDIA_CHECK" -gt 0 ]; then
            print_status "Media assets present"
        else
            print_warning "Media assets not found"
        fi
        
        if [ "$ADDONS_CHECK" -gt 0 ]; then
            print_status "Addons present"
        else
            print_warning "Addons not found"
        fi
        
        if [ "$SYSTEM_CHECK" -gt 0 ]; then
            print_status "System files present"
        else
            print_warning "System files not found"
        fi
        
        # Display file count
        FILE_COUNT=$(unzip -l "$TPK_FILE" 2>/dev/null | tail -n 1 | awk '{print $2}')
        print_info "Total files in TPK: $FILE_COUNT"
        
    else
        print_warning "unzip not available, skipping detailed verification"
    fi
else
    print_info "Skipping package verification (use --no-verify to disable)"
fi

# Step 4: Sign TPK (if not skipped)
if [ "$SKIP_SIGNING" = "yes" ]; then
    print_section "Step 4: Signing Skipped"
    print_warning "TPK is unsigned and can only be installed in developer mode"
    print_info "To sign later, run: $SCRIPT_DIR/packaging/sign.sh $TPK_FILE"
else
    print_section "Step 4: Signing TPK"
    
    # Check if security profile is set
    if [ -z "$SECURITY_PROFILE" ]; then
        print_warning "Security profile not specified"
        print_warning "Set TIZEN_SECURITY_PROFILE environment variable or use -p option"
        print_warning "Creating unsigned TPK only"
        print_info "To sign later, run: $SCRIPT_DIR/packaging/sign.sh $TPK_FILE"
    else
        print_info "Signing with profile: $SECURITY_PROFILE"
        
        # Run signing script
        "$SCRIPT_DIR/packaging/sign.sh" -p "$SECURITY_PROFILE" "$TPK_FILE"
        
        if [ $? -ne 0 ]; then
            print_error "Signing failed"
            print_warning "TPK is unsigned and can only be installed in developer mode"
        else
            print_status "TPK signed successfully"
        fi
    fi
fi

# Step 5: Final summary
print_section "Summary"

print_status "TPK creation completed successfully"
echo ""
print_info "Package Details:"
echo "  File: $TPK_FILE"
echo "  Size: $TPK_SIZE"

if [ "$SKIP_SIGNING" = "yes" ] || [ -z "$SECURITY_PROFILE" ]; then
    echo "  Status: Unsigned (developer mode only)"
else
    echo "  Status: Signed with profile '$SECURITY_PROFILE'"
fi

echo ""
print_info "Next Steps:"
echo ""
echo "1. Deploy to Samsung TV:"
echo "   $SCRIPT_DIR/deploy.sh -u -l"
echo ""
echo "2. Or install manually via SDB:"
echo "   sdb install $TPK_FILE"
echo ""
echo "3. View logs after installation:"
echo "   $SCRIPT_DIR/logs.sh -f"
echo ""

if [ "$SKIP_SIGNING" = "yes" ] || [ -z "$SECURITY_PROFILE" ]; then
    print_warning "Note: Unsigned TPK requires developer mode enabled on TV"
    print_info "See: $SCRIPT_DIR/DEVELOPER_MODE_GUIDE.md"
    echo ""
fi

print_status "TPK creation and signing complete!"
