#!/bin/bash
set -e

echo "=========================================="
echo "Kodi Tizen Build Script (Root Workaround)"
echo "=========================================="
echo ""
echo "WARNING: Running as root with workaround"
echo "The Tizen SDK normally refuses to run as root."
echo "This script creates a non-root user to run the SDK."
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BUILDER_USER="builder"
BUILDER_HOME="/home/$BUILDER_USER"
TIZEN_SDK_DIR="$BUILDER_HOME/tizen-studio"
KODI_DEPS_DIR="$BUILDER_HOME/kodi-tizen-deps"
WORKSPACE_DIR="/workspace"

# Function to print step headers
print_step() {
    echo ""
    echo -e "${BLUE}=========================================="
    echo -e "$1"
    echo -e "==========================================${NC}"
    echo ""
}

# Create non-root user if doesn't exist
print_step "Setting up non-root user"

if ! id "$BUILDER_USER" &>/dev/null; then
    echo "Creating user '$BUILDER_USER'..."
    useradd -m -s /bin/bash "$BUILDER_USER"
    echo "$BUILDER_USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
    echo -e "${GREEN}✓ User created${NC}"
else
    echo "User '$BUILDER_USER' already exists"
fi

# Give builder user access to workspace (skip .git to avoid permission issues)
echo "Setting permissions on workspace (this may show some permission warnings for .git - that's okay)..."
chown -R "$BUILDER_USER:$BUILDER_USER" "$WORKSPACE_DIR" 2>/dev/null || true
# Ensure builder can at least read the workspace
chmod -R a+rX "$WORKSPACE_DIR" 2>/dev/null || true

# Create build script for builder user
cat > /tmp/build-as-builder.sh << 'BUILDER_SCRIPT'
#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

TIZEN_SDK_DIR="$HOME/tizen-studio"
KODI_DEPS_DIR="$HOME/kodi-tizen-deps"
WORKSPACE_DIR="/workspace"

print_step() {
    echo ""
    echo -e "${BLUE}=========================================="
    echo -e "$1"
    echo -e "==========================================${NC}"
    echo ""
}

check_success() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $1${NC}"
    else
        echo -e "${RED}✗ $1 failed${NC}"
        exit 1
    fi
}

# Step 1: Install Tizen SDK
print_step "Step 1/4: Installing Tizen SDK"

if [ -d "$TIZEN_SDK_DIR" ]; then
    echo "Tizen SDK already installed"
else
    echo "Downloading Tizen SDK..."
    cd /tmp
    wget --progress=bar:force http://download.tizen.org/sdk/Installer/tizen-studio_5.0/web-cli_Tizen_Studio_5.0_ubuntu-64.bin
    check_success "Download Tizen SDK"
    
    echo "Installing Tizen SDK..."
    chmod +x web-cli_Tizen_Studio_5.0_ubuntu-64.bin
    ./web-cli_Tizen_Studio_5.0_ubuntu-64.bin --accept-license "$TIZEN_SDK_DIR"
    check_success "Install Tizen SDK"
    
    echo "Installing toolchain packages..."
    "$TIZEN_SDK_DIR/package-manager/package-manager-cli.bin" install \
        NativeToolchain-Gcc-9.2 \
        PLATFORM-6.0-NativeAppDevelopment-CLI 2>&1 | grep -v "^Downloading" || true
    
    if [ -d "$TIZEN_SDK_DIR/tools/arm-linux-gnueabi-gcc-9.2" ]; then
        echo -e "${GREEN}✓ Tizen SDK installed${NC}"
    else
        echo -e "${RED}✗ Toolchain not found${NC}"
        exit 1
    fi
fi

export PATH="$PATH:$TIZEN_SDK_DIR/tools"
export TIZEN_SDK="$TIZEN_SDK_DIR"

# Step 2: Build Dependencies
print_step "Step 2/4: Building Dependencies"

cd "$WORKSPACE_DIR/tools/depends"

if [ ! -f "configure" ]; then
    ./bootstrap
    check_success "Bootstrap"
fi

if [ -f "$KODI_DEPS_DIR/.built" ]; then
    echo "Dependencies already built"
else
    echo "Configuring dependencies..."
    ./configure \
        --prefix="$KODI_DEPS_DIR" \
        --host=arm-tizen-linux-gnueabi \
        --with-toolchain="$TIZEN_SDK_DIR/tools/arm-linux-gnueabi-gcc-9.2" \
        --with-platform=tizen \
        --with-rendersystem=gles \
        --enable-debug=no
    check_success "Configure"
    
    echo "Building dependencies (30-60 minutes)..."
    make -j$(nproc) 2>&1 | tee build.log
    check_success "Build dependencies"
    
    touch "$KODI_DEPS_DIR/.built"
fi

# Step 3: Build Kodi
print_step "Step 3/4: Building Kodi"

cd "$WORKSPACE_DIR"
make -C tools/depends/target/cmakebuildsys
check_success "Configure Kodi"

cd build
echo "Building Kodi (30-60 minutes)..."
make -j$(nproc) 2>&1 | tee build.log
check_success "Build Kodi"

# Step 4: Create TPK
print_step "Step 4/4: Creating TPK"

if make -n tpk &>/dev/null; then
    make tpk
    check_success "Create TPK"
else
    echo "Trying manual packaging..."
    cd "$WORKSPACE_DIR"
    bash tools/tizen/packaging/package.sh
    check_success "Create TPK manually"
fi

print_step "Build Complete! 🎉"

TPK_FILES=$(find "$WORKSPACE_DIR" -name "*.tpk" 2>/dev/null || true)
if [ -n "$TPK_FILES" ]; then
    echo -e "${GREEN}TPK files:${NC}"
    ls -lh $TPK_FILES
else
    echo -e "${YELLOW}No TPK files found${NC}"
fi

echo ""
echo "Exit container and find TPK in build/ directory"
echo ""
BUILDER_SCRIPT

chmod +x /tmp/build-as-builder.sh

# Run as builder user
print_step "Running build as non-root user"
echo "Switching to user '$BUILDER_USER' to run build..."
echo ""

su - "$BUILDER_USER" -c "/tmp/build-as-builder.sh"

echo ""
echo -e "${GREEN}Build complete!${NC}"
echo "TPK files should be in /workspace/build/"
