#!/bin/bash
# Build Kodi for Tizen using Docker on Apple Silicon Mac

set -e

echo "=== Kodi Tizen Build Script for Apple Silicon Mac ==="
echo ""
echo "This script builds Kodi for Tizen using Docker with x86_64 emulation."
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed."
    echo "Please install Docker Desktop from: https://www.docker.com/products/docker-desktop"
    exit 1
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo "Error: Docker is not running."
    echo "Please start Docker Desktop and try again."
    exit 1
fi

echo "✓ Docker is installed and running"
echo ""

# Create Dockerfile
cat > Dockerfile.tizen <<'EOF'
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    curl \
    git \
    python3 \
    python3-pip \
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
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /workspace

# Default command
CMD ["/bin/bash"]
EOF

echo "✓ Created Dockerfile.tizen"
echo ""

# Build Docker image
echo "Building Docker image (this may take a few minutes)..."
docker build --platform linux/amd64 -t kodi-tizen-builder -f Dockerfile.tizen .

echo ""
echo "✓ Docker image built successfully"
echo ""
echo "=== Next Steps ==="
echo ""
echo "1. Run the Docker container:"
echo "   docker run --platform linux/amd64 -v \$(pwd):/workspace -it kodi-tizen-builder"
echo ""
echo "2. Inside the container, configure and build:"
echo "   cd /workspace/tools/depends"
echo "   ./bootstrap"
echo "   ./configure --host=arm-tizen-linux-gnueabi --with-platform=tizen --with-rendersystem=gles"
echo "   make -j\$(nproc)"
echo ""
echo "3. Build Kodi:"
echo "   cd /workspace"
echo "   make -C tools/depends/target/cmakebuildsys"
echo "   cd build"
echo "   make -j\$(nproc)"
echo ""
echo "Note: The Tizen toolchain is not included in this container."
echo "You'll need to download it separately or use a pre-built Kodi binary."
echo ""
