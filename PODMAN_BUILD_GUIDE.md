# Building Kodi for Tizen with Podman on macOS

This guide shows how to build Kodi for Tizen using Podman on Apple Silicon Mac.

## Why Podman?

- ✅ Open source and free
- ✅ Daemonless (more secure)
- ✅ Compatible with Docker commands
- ✅ Works well on macOS
- ✅ No Docker Desktop license required

## Prerequisites

### 1. Install Podman

```bash
# Install via Homebrew
brew install podman

# Initialize Podman machine
podman machine init

# Start Podman machine
podman machine start

# Verify installation
podman --version
podman machine list
```

### 2. Verify Podman is Running

```bash
podman machine list
# Should show "Currently running"

podman info
# Should show system information
```

## Quick Start

### Option 1: Use the Build Script

```bash
# Make script executable
chmod +x build-tizen-podman.sh

# Run the script
./build-tizen-podman.sh
```

This will:
1. Check Podman installation
2. Create a Containerfile
3. Build the container image
4. Show next steps

### Option 2: Manual Steps

#### Step 1: Create the Container Image

```bash
# Create Containerfile
cat > Containerfile.tizen <<'EOF'
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    curl \
    git \
    python3 \
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
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
CMD ["/bin/bash"]
EOF

# Build the image
podman build --platform linux/amd64 -t kodi-tizen-builder -f Containerfile.tizen .
```

#### Step 2: Run the Container

```bash
# Run interactively with current directory mounted
podman run --platform linux/amd64 \
  -v $(pwd):/workspace:Z \
  -it kodi-tizen-builder
```

**Note:** The `:Z` flag is important for SELinux labeling.

#### Step 3: Inside Container - Install Tizen SDK

```bash
# Download Tizen Studio
wget http://download.tizen.org/sdk/Installer/tizen-studio_5.0/web-cli_Tizen_Studio_5.0_ubuntu-64.bin

# Make executable
chmod +x web-cli_Tizen_Studio_5.0_ubuntu-64.bin

# Install (accept license)
./web-cli_Tizen_Studio_5.0_ubuntu-64.bin --accept-license $HOME/tizen-studio

# Install required packages
$HOME/tizen-studio/package-manager/package-manager-cli.bin install \
  NativeToolchain-Gcc-9.2 \
  PLATFORM-6.0-NativeAppDevelopment-CLI

# Add to PATH
export PATH=$PATH:$HOME/tizen-studio/tools
export TIZEN_SDK=$HOME/tizen-studio
```

#### Step 4: Build Dependencies

```bash
cd /workspace/tools/depends

# Bootstrap
./bootstrap

# Configure for ARM Tizen
./configure \
  --prefix=$HOME/kodi-tizen-deps \
  --host=arm-tizen-linux-gnueabi \
  --with-toolchain=$HOME/tizen-studio/tools/arm-linux-gnueabi-gcc-9.2 \
  --with-platform=tizen \
  --with-rendersystem=gles \
  --enable-debug=no

# Build (this takes a while)
make -j$(nproc)
```

#### Step 5: Build Kodi

```bash
cd /workspace

# Generate build files
make -C tools/depends/target/cmakebuildsys

# Build Kodi
cd build
make -j$(nproc)

# Create TPK package
make tpk
```

#### Step 6: Exit and Copy TPK

```bash
# Exit container
exit

# TPK file will be in build/ directory on your Mac
ls -lh build/*.tpk
```

## Advanced Usage

### Save Container State

If you want to save your container with Tizen SDK installed:

```bash
# Inside container, after installing Tizen SDK
# Exit the container

# Find container ID
podman ps -a

# Commit the container to a new image
podman commit <container-id> kodi-tizen-builder-with-sdk

# Use the new image
podman run --platform linux/amd64 \
  -v $(pwd):/workspace:Z \
  -it kodi-tizen-builder-with-sdk
```

### Create a Build Script

Create `build-in-container.sh`:

```bash
#!/bin/bash
set -e

export PATH=$PATH:$HOME/tizen-studio/tools
export TIZEN_SDK=$HOME/tizen-studio

cd /workspace/tools/depends

if [ ! -f "Makefile" ]; then
    ./bootstrap
    ./configure \
      --prefix=$HOME/kodi-tizen-deps \
      --host=arm-tizen-linux-gnueabi \
      --with-toolchain=$HOME/tizen-studio/tools/arm-linux-gnueabi-gcc-9.2 \
      --with-platform=tizen \
      --with-rendersystem=gles \
      --enable-debug=no
fi

make -j$(nproc)

cd /workspace
make -C tools/depends/target/cmakebuildsys

cd build
make -j$(nproc)
make tpk

echo "Build complete! TPK file:"
ls -lh *.tpk
```

Then run:

```bash
podman run --platform linux/amd64 \
  -v $(pwd):/workspace:Z \
  -it kodi-tizen-builder-with-sdk \
  bash /workspace/build-in-container.sh
```

### Incremental Builds

For faster rebuilds after code changes:

```bash
# Start container
podman run --platform linux/amd64 \
  -v $(pwd):/workspace:Z \
  -it kodi-tizen-builder-with-sdk

# Inside container - only rebuild changed files
cd /workspace/build
make -j$(nproc)
make tpk
```

## Podman vs Docker Differences

Podman commands are mostly compatible with Docker:

| Docker | Podman |
|--------|--------|
| `docker build` | `podman build` |
| `docker run` | `podman run` |
| `docker ps` | `podman ps` |
| `docker images` | `podman images` |
| `docker pull` | `podman pull` |
| `docker push` | `podman push` |

Key differences:
- Podman is daemonless (no background service)
- Podman runs rootless by default (more secure)
- Podman uses `machine` on macOS (like Docker Desktop)

## Troubleshooting

### Podman Machine Not Starting

```bash
# Stop and remove existing machine
podman machine stop
podman machine rm

# Recreate
podman machine init
podman machine start
```

### Platform Emulation Issues

If you get errors about platform emulation:

```bash
# Check if qemu is installed
podman machine ssh
which qemu-x86_64-static

# If missing, reinstall Podman machine
podman machine rm
podman machine init --now
```

### Volume Mount Issues

If files aren't visible in container:

```bash
# Use absolute path
podman run --platform linux/amd64 \
  -v /Users/yourusername/path/to/kodi:/workspace:Z \
  -it kodi-tizen-builder

# Or use $PWD
podman run --platform linux/amd64 \
  -v $PWD:/workspace:Z \
  -it kodi-tizen-builder
```

### SELinux Labeling

The `:Z` flag is important:

```bash
# Without :Z - may have permission issues
-v $(pwd):/workspace

# With :Z - proper SELinux labeling
-v $(pwd):/workspace:Z
```

### Slow Build Performance

Podman on macOS uses a VM, which can be slower than native:

```bash
# Increase machine resources
podman machine stop
podman machine set --cpus 4 --memory 8192
podman machine start

# Check current settings
podman machine info
```

## Performance Tips

1. **Allocate More Resources**:
   ```bash
   podman machine set --cpus 8 --memory 16384
   ```

2. **Use Parallel Builds**:
   ```bash
   make -j$(nproc)  # Uses all available cores
   ```

3. **Cache Dependencies**:
   Save the container after building dependencies once

4. **Incremental Builds**:
   Keep container running for multiple builds

## Comparison with Other Options

| Method | Pros | Cons |
|--------|------|------|
| **Podman** | Free, secure, Docker-compatible | Requires VM on macOS, slower than native |
| **Docker** | Well-documented, widely used | Requires license for business use |
| **Linux VM** | Full control, native performance | More setup, resource intensive |
| **GitHub Actions** | No local resources, automated | Requires GitHub, slower feedback |
| **Real TV** | Real hardware, accurate testing | Can't build, only test |

## Next Steps

After building:

1. **Copy TPK to your Mac**:
   ```bash
   # TPK is already in build/ directory
   ls -lh build/*.tpk
   ```

2. **Install on Samsung TV**:
   ```bash
   export PATH=$PATH:$HOME/tizen-studio/tools
   sdb connect <TV_IP>:26101
   sdb install build/org.xbmc.kodi_*.tpk
   ```

3. **Test on TV**:
   ```bash
   sdb shell app_launcher -s org.xbmc.kodi
   sdb dlog KODI:V
   ```

## Additional Resources

- **Podman Documentation**: https://docs.podman.io/
- **Podman on macOS**: https://podman.io/getting-started/installation#macos
- **Tizen SDK**: https://developer.tizen.org/development/tizen-studio
- **Kodi Tizen Guide**: `docs/README.Tizen.md`

## Summary

Podman is a great alternative to Docker for building Kodi on macOS:

✅ Free and open source
✅ No licensing concerns
✅ Docker-compatible commands
✅ Secure (rootless, daemonless)
✅ Works on Apple Silicon

The build process is the same as Docker, just replace `docker` with `podman` in commands.
