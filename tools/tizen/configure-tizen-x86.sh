#!/bin/bash
# Example configure script for building Kodi dependencies for Tizen x86 (emulator)
# This script demonstrates how to configure the unified depends system for Tizen

set -e

# Check if TIZEN_SDK is set
if [ -z "$TIZEN_SDK" ]; then
    echo "ERROR: TIZEN_SDK environment variable is not set"
    echo "Please set it to your Tizen Studio installation path:"
    echo "  export TIZEN_SDK=/path/to/tizen-studio"
    exit 1
fi

# Default values (can be overridden by environment variables)
TIZEN_VERSION=${TIZEN_VERSION:-6.0}
TIZEN_ROOTSTRAP=${TIZEN_ROOTSTRAP:-tv-samsung-6.0-emulator.core}
PREFIX=${PREFIX:-$HOME/kodi-tizen-deps}
TARBALLS=${TARBALLS:-$PREFIX/xbmc-tarballs}

# Detect toolchain path
TOOLCHAIN_CANDIDATES=(
    "$TIZEN_SDK/tools/i686-linux-gnueabi-gcc-9.2"
    "$TIZEN_SDK/tools/i686-linux-gnueabi-gcc-6.2"
    "$TIZEN_SDK/tools/smart-build-interface/plugins/org.tizen.nativeplatform/platforms/mobile-6.0/rootstraps/$TIZEN_ROOTSTRAP"
)

TOOLCHAIN=""
for candidate in "${TOOLCHAIN_CANDIDATES[@]}"; do
    if [ -d "$candidate" ]; then
        TOOLCHAIN="$candidate"
        break
    fi
done

if [ -z "$TOOLCHAIN" ]; then
    echo "ERROR: Could not find Tizen toolchain"
    echo "Searched in:"
    for candidate in "${TOOLCHAIN_CANDIDATES[@]}"; do
        echo "  - $candidate"
    done
    echo ""
    echo "Please specify toolchain path manually:"
    echo "  TOOLCHAIN=/path/to/toolchain $0"
    exit 1
fi

echo "=========================================="
echo "Kodi Tizen Dependencies Configuration"
echo "=========================================="
echo "Target: x86 (Tizen Emulator)"
echo "Tizen SDK: $TIZEN_SDK"
echo "Tizen Version: $TIZEN_VERSION"
echo "Rootstrap: $TIZEN_ROOTSTRAP"
echo "Toolchain: $TOOLCHAIN"
echo "Prefix: $PREFIX"
echo "Tarballs: $TARBALLS"
echo "=========================================="
echo ""

# Navigate to depends directory
cd "$(dirname "$0")/../depends"

# Bootstrap if needed
if [ ! -f "configure" ]; then
    echo "Running bootstrap..."
    ./bootstrap
fi

# Configure
echo "Configuring dependencies for Tizen x86..."
./configure \
    --prefix="$PREFIX" \
    --host=i686-tizen-linux-gnu \
    --with-toolchain="$TOOLCHAIN" \
    --with-platform=tizen \
    --with-rendersystem=gles \
    --with-tarballs="$TARBALLS" \
    --enable-debug=no \
    "$@"

echo ""
echo "=========================================="
echo "Configuration complete!"
echo "=========================================="
echo "To build dependencies, run:"
echo "  cd $(pwd)"
echo "  make -j\$(nproc)"
echo ""
echo "After building dependencies, configure Kodi:"
echo "  cd ../.."
echo "  mkdir build && cd build"
echo "  cmake .. -DCMAKE_TOOLCHAIN_FILE=$PREFIX/i686-tizen-linux-gnu-release/share/Toolchain.cmake"
echo "=========================================="
