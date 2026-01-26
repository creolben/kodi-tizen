#!/bin/bash
set -e

echo "=========================================="
echo "Kodi Tizen Local Build Setup"
echo "=========================================="
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

check_success() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $1${NC}"
    else
        echo -e "${RED}✗ $1 failed${NC}"
        exit 1
    fi
}

# Step 1: Stop existing container
print_step "Step 1: Cleaning up existing container"

EXISTING_CONTAINER=$(podman ps -aq --filter ancestor=localhost/kodi-tizen-builder)
if [ -n "$EXISTING_CONTAINER" ]; then
    echo "Stopping and removing existing container..."
    podman stop $EXISTING_CONTAINER 2>/dev/null || true
    podman rm $EXISTING_CONTAINER 2>/dev/null || true
    check_success "Remove old container"
else
    echo "No existing container found"
fi

# Step 2: Rebuild container image
print_step "Step 2: Building container image"

echo "Building with proper non-root user and Python 3.8..."
podman build --platform linux/amd64 -t kodi-tizen-builder -f Containerfile.tizen .
check_success "Build container image"

# Step 3: Start new container
print_step "Step 3: Starting new container"

echo "Starting container with workspace mounted..."
CONTAINER_ID=$(podman run -d --platform linux/amd64 \
    -v "$(pwd):/workspace:Z" \
    --name kodi-tizen-build \
    localhost/kodi-tizen-builder \
    sleep infinity)

check_success "Start container"
echo "Container ID: $CONTAINER_ID"

# Step 4: Verify setup
print_step "Step 4: Verifying setup"

echo "Checking container status..."
podman exec kodi-tizen-build whoami
podman exec kodi-tizen-build pwd
podman exec kodi-tizen-build python3 --version
podman exec kodi-tizen-build ls -la /workspace | head -10

check_success "Verify container"

# Step 5: Create build script inside container
print_step "Step 5: Setting up build environment"

cat > /tmp/container-build-fixed.sh << 'BUILDSCRIPT'
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
    check_success "Download SDK"
    
    echo "Installing Tizen SDK..."
    chmod +x web-cli_Tizen_Studio_5.0_ubuntu-64.bin
    ./web-cli_Tizen_Studio_5.0_ubuntu-64.bin --accept-license "$TIZEN_SDK_DIR"
    check_success "Install SDK"
    
    echo "Installing toolchain..."
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
echo "TPK files are in /workspace/build/ (visible on your Mac)"
echo ""
BUILDSCRIPT

# Copy script to container
podman cp /tmp/container-build-fixed.sh kodi-tizen-build:/home/builder/build-kodi.sh
podman exec kodi-tizen-build chmod +x /home/builder/build-kodi.sh

check_success "Setup build script"

# Final instructions
print_step "Setup Complete! 🎉"

echo -e "${GREEN}Your local build environment is ready!${NC}"
echo ""
echo "To start building:"
echo ""
echo "  1. Attach to container:"
echo "     ${YELLOW}podman exec -it kodi-tizen-build bash${NC}"
echo ""
echo "  2. Inside container, run:"
echo "     ${YELLOW}~/build-kodi.sh${NC}"
echo ""
echo "  3. Wait 60-90 minutes for build to complete"
echo ""
echo "  4. Find TPK in your local build/ directory"
echo ""
echo "Container name: ${GREEN}kodi-tizen-build${NC}"
echo "Container ID: ${GREEN}$CONTAINER_ID${NC}"
echo ""
echo "To stop container later:"
echo "  podman stop kodi-tizen-build"
echo ""
echo "To restart container:"
echo "  podman start kodi-tizen-build"
echo "  podman exec -it kodi-tizen-build bash"
echo ""
