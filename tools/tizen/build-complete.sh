#!/bin/bash
# Complete Kodi build script for Tizen
# This script performs a full build with all components and verifies the build

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
KODI_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILD_DIR="${BUILD_DIR:-$KODI_ROOT/build}"
DEPS_PREFIX="${DEPS_PREFIX:-$HOME/kodi-tizen-deps}"
ARCH="${ARCH:-arm}"  # arm or x86

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Kodi Tizen Complete Build${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Configuration:"
echo "  KODI_ROOT: $KODI_ROOT"
echo "  BUILD_DIR: $BUILD_DIR"
echo "  DEPS_PREFIX: $DEPS_PREFIX"
echo "  ARCH: $ARCH"
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

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

# Step 1: Verify environment
echo -e "${GREEN}Step 1: Verifying environment...${NC}"

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

# Check for toolchain
if [ "$ARCH" = "arm" ]; then
    TOOLCHAIN_DIR="$TIZEN_SDK/tools/arm-linux-gnueabi-gcc-9.2"
else
    TOOLCHAIN_DIR="$TIZEN_SDK/tools/i686-linux-gnueabi-gcc-9.2"
fi

if [ ! -d "$TOOLCHAIN_DIR" ]; then
    print_warning "Toolchain not found at $TOOLCHAIN_DIR"
    print_warning "Trying alternative toolchain paths..."
    
    # Try to find any gcc toolchain
    TOOLCHAIN_DIR=$(find "$TIZEN_SDK/tools" -maxdepth 1 -type d -name "*gcc*" | head -n 1)
    
    if [ -z "$TOOLCHAIN_DIR" ]; then
        print_error "No toolchain found in $TIZEN_SDK/tools"
        exit 1
    fi
    print_status "Found toolchain: $TOOLCHAIN_DIR"
else
    print_status "Toolchain found: $TOOLCHAIN_DIR"
fi

# Check for required tools
for tool in make cmake git; do
    if ! command_exists "$tool"; then
        print_error "Required tool not found: $tool"
        exit 1
    fi
    print_status "Tool available: $tool"
done

echo ""

# Step 2: Check dependencies
echo -e "${GREEN}Step 2: Checking dependencies...${NC}"

if [ ! -d "$DEPS_PREFIX" ]; then
    print_error "Dependencies not found at $DEPS_PREFIX"
    echo "Please build dependencies first:"
    echo "  cd $KODI_ROOT/tools/depends"
    echo "  ./bootstrap"
    echo "  ./configure --prefix=$DEPS_PREFIX --host=arm-tizen-linux-gnueabi --with-platform=tizen"
    echo "  make -j\$(getconf _NPROCESSORS_ONLN)"
    exit 1
fi
print_status "Dependencies directory exists: $DEPS_PREFIX"

# Check for key dependency files
DEPS_CHECK=(
    "$DEPS_PREFIX/lib/libfreetype.a"
    "$DEPS_PREFIX/lib/libfmt.a"
    "$DEPS_PREFIX/lib/libspdlog.a"
)

for dep in "${DEPS_CHECK[@]}"; do
    if [ ! -f "$dep" ]; then
        print_warning "Dependency file not found: $dep"
    else
        print_status "Found: $(basename $dep)"
    fi
done

echo ""

# Step 3: Generate build files
echo -e "${GREEN}Step 3: Generating build files with CMake...${NC}"

cd "$KODI_ROOT"

if [ ! -f "$KODI_ROOT/tools/depends/Makefile.include" ]; then
    print_error "Dependencies not configured. Run configure in tools/depends first."
    exit 1
fi

# Generate CMake build files
print_status "Running CMake generation..."
make -C tools/depends/target/cmakebuildsys BUILD_DIR="$BUILD_DIR"

if [ $? -ne 0 ]; then
    print_error "CMake generation failed"
    exit 1
fi
print_status "CMake generation completed"

echo ""

# Step 4: Build Kodi
echo -e "${GREEN}Step 4: Building Kodi...${NC}"

cd "$BUILD_DIR"

# Get number of processors
NPROC=$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)
print_status "Building with $NPROC parallel jobs"

# Build
make -j$NPROC

if [ $? -ne 0 ]; then
    print_error "Build failed"
    echo ""
    echo "To retry with verbose output:"
    echo "  cd $BUILD_DIR"
    echo "  make VERBOSE=1"
    exit 1
fi

print_status "Build completed successfully"

echo ""

# Step 5: Verify build artifacts
echo -e "${GREEN}Step 5: Verifying build artifacts...${NC}"

# Check for main binary
KODI_BINARY="$BUILD_DIR/kodi.bin"
if [ ! -f "$KODI_BINARY" ]; then
    print_error "Kodi binary not found: $KODI_BINARY"
    exit 1
fi
print_status "Kodi binary exists: $KODI_BINARY"

# Check binary size (should be > 1MB)
BINARY_SIZE=$(stat -f%z "$KODI_BINARY" 2>/dev/null || stat -c%s "$KODI_BINARY" 2>/dev/null)
if [ "$BINARY_SIZE" -lt 1048576 ]; then
    print_warning "Kodi binary seems small: $BINARY_SIZE bytes"
else
    print_status "Kodi binary size: $((BINARY_SIZE / 1024 / 1024)) MB"
fi

# Check for required libraries
REQUIRED_LIBS=(
    "libkodiplatform.so"
    "libkodi-wayland.so"
)

for lib in "${REQUIRED_LIBS[@]}"; do
    if [ -f "$BUILD_DIR/lib/$lib" ] || [ -f "$BUILD_DIR/$lib" ]; then
        print_status "Found library: $lib"
    else
        print_warning "Library not found: $lib (may be statically linked)"
    fi
done

# Check for addons directory
if [ -d "$BUILD_DIR/addons" ]; then
    ADDON_COUNT=$(find "$BUILD_DIR/addons" -name "addon.xml" | wc -l)
    print_status "Found $ADDON_COUNT addons"
else
    print_warning "Addons directory not found (optional)"
fi

# Check for media assets
if [ -d "$BUILD_DIR/media" ]; then
    print_status "Media assets directory exists"
else
    print_warning "Media assets directory not found"
fi

echo ""

# Step 6: Verify dependencies are satisfied
echo -e "${GREEN}Step 6: Verifying dependencies are satisfied...${NC}"

# Check if ldd is available (may not be on macOS)
if command_exists ldd; then
    print_status "Checking shared library dependencies..."
    
    # Run ldd and check for missing libraries
    LDD_OUTPUT=$(ldd "$KODI_BINARY" 2>&1 || true)
    
    if echo "$LDD_OUTPUT" | grep -q "not found"; then
        print_error "Missing shared library dependencies:"
        echo "$LDD_OUTPUT" | grep "not found"
        exit 1
    else
        print_status "All shared library dependencies satisfied"
    fi
else
    print_warning "ldd not available, skipping dependency check"
fi

echo ""

# Step 7: Summary
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Build Summary${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
print_status "Build completed successfully"
print_status "Build directory: $BUILD_DIR"
print_status "Kodi binary: $KODI_BINARY"
echo ""
echo "Next steps:"
echo "  1. Create TPK package: cd $BUILD_DIR && make tpk"
echo "  2. Sign TPK: ./tools/tizen/packaging/sign.sh <tpk-file>"
echo "  3. Deploy to device: ./tools/tizen/deploy.sh -u -l"
echo ""
echo -e "${GREEN}Build verification complete!${NC}"
