#!/bin/bash
# Build Kodi for Tizen using Podman on Apple Silicon Mac

set -e

echo "=== Kodi Tizen Build Script for Apple Silicon Mac (Podman) ==="
echo ""
echo "This script builds Kodi for Tizen using Podman with x86_64 emulation."
echo ""

# Check if Podman is installed
if ! command -v podman &> /dev/null; then
    echo "Error: Podman is not installed."
    echo ""
    echo "Install Podman on macOS:"
    echo "  brew install podman"
    echo ""
    echo "Then initialize the Podman machine:"
    echo "  podman machine init"
    echo "  podman machine start"
    exit 1
fi

# Check if Podman machine is running
if ! podman machine list | grep -q "Currently running"; then
    echo "Error: Podman machine is not running."
    echo ""
    echo "Start the Podman machine:"
    echo "  podman machine start"
    echo ""
    echo "Or initialize if not created:"
    echo "  podman machine init"
    echo "  podman machine start"
    exit 1
fi

echo "✓ Podman is installed and running"
echo ""

# Create Containerfile (Podman's Dockerfile)
cat > Containerfile.tizen <<'EOF'
FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies including Python 3.8 (required by Tizen SDK)
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    curl \
    git \
    python3.8 \
    python3.8-dev \
    python3-pip \
    libpython3.8 \
    autoconf \
    automake \
    libtool \
    pkg-config \
    gawk \
    gperf \
    zip \
    unzip \
    wget \
    default-jre \
    nasm \
    yasm \
    libssl-dev \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Ensure python3 points to python3.8
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.8 1

# Create a non-root user
RUN useradd -m -s /bin/bash builder && \
    echo "builder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER builder
WORKDIR /home/builder

# Default command
CMD ["/bin/bash"]
EOF

echo "✓ Created Containerfile.tizen"
echo ""

# Build Podman image
echo "Building Podman image (this may take a few minutes)..."
podman build --platform linux/amd64 -t kodi-tizen-builder -f Containerfile.tizen .

echo ""
echo "✓ Podman image built successfully"
echo ""
echo "=== Next Steps ==="
echo ""
echo "1. Run the Podman container:"
echo "   podman run --platform linux/amd64 -v \$(pwd):/workspace:Z -it kodi-tizen-builder"
echo ""
echo "   Note: The ':Z' flag is important for SELinux labeling on some systems"
echo ""
echo "2. Inside the container, you'll need to:"
echo "   a) Download and install Tizen SDK"
echo "   b) Configure and build dependencies"
echo "   c) Build Kodi"
echo ""
echo "However, note that the Tizen SDK download requires manual steps."
echo "See the detailed instructions below."
echo ""
echo "=== Detailed Build Instructions ==="
echo ""
echo "Option A: Interactive Build (Recommended)"
echo "----------------------------------------"
echo "1. Start the container:"
echo "   podman run --platform linux/amd64 -v \$(pwd):/workspace:Z -it kodi-tizen-builder"
echo ""
echo "2. Inside container, download Tizen SDK:"
echo "   wget http://download.tizen.org/sdk/Installer/tizen-studio_5.0/web-cli_Tizen_Studio_5.0_ubuntu-64.bin"
echo "   chmod +x web-cli_Tizen_Studio_5.0_ubuntu-64.bin"
echo "   ./web-cli_Tizen_Studio_5.0_ubuntu-64.bin --accept-license $HOME/tizen-studio"
echo ""
echo "3. Install required packages:"
echo "   $HOME/tizen-studio/package-manager/package-manager-cli.bin install \\"
echo "     NativeToolchain-Gcc-9.2 \\"
echo "     PLATFORM-6.0-NativeAppDevelopment-CLI"
echo ""
echo "4. Build dependencies:"
echo "   cd /workspace/tools/depends"
echo "   ./bootstrap"
echo "   ./configure \\"
echo "     --host=arm-tizen-linux-gnueabi \\"
echo "     --with-toolchain=\$HOME/tizen-studio/tools/arm-linux-gnueabi-gcc-9.2 \\"
echo "     --with-platform=tizen \\"
echo "     --with-rendersystem=gles \\"
echo "     --enable-debug=no"
echo "   make -j\$(nproc)"
echo ""
echo "5. Build Kodi:"
echo "   cd /workspace"
echo "   make -C tools/depends/target/cmakebuildsys"
echo "   cd build"
echo "   make -j\$(nproc)"
echo ""
echo "6. Create TPK:"
echo "   make tpk"
echo ""
echo "Option B: Automated Script (Advanced)"
echo "------------------------------------"
echo "Create a build script inside the container to automate the process."
echo ""
echo "=== Alternative: Use Pre-built Container ==="
echo ""
echo "If someone creates a pre-built container with Tizen SDK included,"
echo "you can use it directly:"
echo ""
echo "  podman pull <registry>/kodi-tizen-builder:latest"
echo "  podman run --platform linux/amd64 -v \$(pwd):/workspace:Z -it <registry>/kodi-tizen-builder"
echo ""
echo "=== Podman Tips ==="
echo ""
echo "- List images: podman images"
echo "- List containers: podman ps -a"
echo "- Remove image: podman rmi kodi-tizen-builder"
echo "- Stop machine: podman machine stop"
echo "- SSH into machine: podman machine ssh"
echo ""
