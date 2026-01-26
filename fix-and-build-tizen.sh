#!/bin/bash
set -e

echo "=========================================="
echo "Kodi Tizen Build Fix Script"
echo "=========================================="
echo ""
echo "This script will:"
echo "  1. Fix C++20 -> C++17 compatibility"
echo "  2. Fix file permissions"
echo "  3. Build Kodi for Tizen"
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

# Step 1: Fix permissions
print_step "Step 1: Fixing File Permissions"
chmod -R u+rw tools/depends/configure.ac cmake/scripts/common/CompilerSettings.cmake 2>/dev/null || true
echo "Permissions fixed"

# Step 2: Patch C++ standard
print_step "Step 2: Patching C++ Standard (C++20 -> C++17)"

# Patch configure.ac
if grep -q "AX_CXX_COMPILE_STDCXX(\[20\]" tools/depends/configure.ac 2>/dev/null; then
    echo "Patching tools/depends/configure.ac..."
    sed -i.bak 's/AX_CXX_COMPILE_STDCXX(\[20\]/AX_CXX_COMPILE_STDCXX([17]/' tools/depends/configure.ac
    echo -e "${GREEN}✓ configure.ac patched${NC}"
else
    echo "configure.ac already patched or not found"
fi

# Patch CompilerSettings.cmake
if grep -q "CMAKE_CXX_STANDARD 20" cmake/scripts/common/CompilerSettings.cmake 2>/dev/null; then
    echo "Patching cmake/scripts/common/CompilerSettings.cmake..."
    sed -i.bak 's/CMAKE_CXX_STANDARD 20/CMAKE_CXX_STANDARD 17/' cmake/scripts/common/CompilerSettings.cmake
    echo -e "${GREEN}✓ CompilerSettings.cmake patched${NC}"
else
    echo "CompilerSettings.cmake already patched or not found"
fi

# Step 3: Build using native compiler for dependencies
print_step "Step 3: Building Dependencies (Native)"

cd tools/depends

# Clean previous attempts
rm -rf Makefile.include config.site* Toolchain*.cmake 2>/dev/null || true

# Bootstrap
if [ ! -f "configure" ]; then
    echo "Running bootstrap..."
    ./bootstrap
fi

# Configure with native compiler (not cross-compiling)
echo "Configuring dependencies with native compiler..."
./configure \
    --prefix=$HOME/kodi-tizen-deps \
    --with-platform=tizen \
    --with-rendersystem=gles \
    --enable-debug=no

echo "Building dependencies..."
make -j$(nproc) 2>&1 | tee build.log

cd ../..

# Step 4: Build Kodi
print_step "Step 4: Building Kodi"

echo "Configuring Kodi..."
make -C tools/depends/target/cmakebuildsys

if [ ! -d "build" ]; then
    echo -e "${RED}✗ Build directory not created${NC}"
    exit 1
fi

cd build
echo "Compiling Kodi..."
make -j$(nproc) 2>&1 | tee build.log

# Step 5: Create TPK
print_step "Step 5: Creating TPK Package"

if make -n tpk &>/dev/null; then
    make tpk
else
    echo "Using manual TPK creation..."
    cd ..
    bash tools/tizen/packaging/package.sh || echo "TPK creation may need manual intervention"
fi

print_step "Build Complete!"

TPK_FILES=$(find . -name "*.tpk" 2>/dev/null || true)
if [ -n "$TPK_FILES" ]; then
    echo -e "${GREEN}TPK files created:${NC}"
    ls -lh $TPK_FILES
else
    echo -e "${YELLOW}No TPK files found. Check build logs.${NC}"
fi

echo ""
echo "Next steps:"
echo "1. Install on TV: sdb connect <TV_IP>:26101"
echo "2. Install TPK: sdb install <tpk-file>"
echo "3. Launch: sdb shell app_launcher -s org.xbmc.kodi"
