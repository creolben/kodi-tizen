# Tizen Build Fix for Apple Silicon Mac

## Problem

You're trying to build Kodi for Tizen on an Apple Silicon Mac (M4). There are **two major issues**:

1. **Toolchain Architecture Mismatch**: The Tizen toolchain is x86_64 (Intel), requiring Rosetta 2 and x86_64 libraries
2. **Missing Sysroot**: The macOS Tizen SDK lacks the ARM sysroot (C libraries, headers) needed for cross-compilation

**Errors:**
- `Library not loaded: /usr/local/opt/isl/lib/libisl.19.dylib` (architecture mismatch)
- `cannot find crt1.o: No such file or directory` (missing sysroot)

**Bottom Line:** The macOS Tizen SDK is designed for packaging and deployment, not for building Kodi from source.

## Solution Options

## Solution Options

### ✅ Option 1: Test on Real Samsung TV (RECOMMENDED)

Since you can't build locally on macOS, test directly on your Samsung TV:

**Advantages:**
- No build required on your Mac
- Real hardware testing
- Faster iteration
- More accurate results

**Steps:**
1. Get a pre-built Kodi TPK (from CI, another developer, or Linux build)
2. Connect to your Samsung TV via SDB
3. Install and test

See `APPLE_SILICON_SOLUTION.md` for complete TV testing guide.

### ✅ Option 2: Use GitHub Actions (RECOMMENDED for Development)

Build automatically on Linux in the cloud:

```yaml
# .github/workflows/build-tizen.yml
name: Build Tizen
on: [push, pull_request]
jobs:
  build:
    runs-on: ubuntu-22.04
    steps:
      - uses: actions/checkout@v3
      
      - name: Install Tizen SDK
        run: |
          wget http://download.tizen.org/sdk/Installer/tizen-studio_5.0/web-cli_Tizen_Studio_5.0_ubuntu-64.bin
          chmod +x web-cli_Tizen_Studio_5.0_ubuntu-64.bin
          ./web-cli_Tizen_Studio_5.0_ubuntu-64.bin --accept-license
      
      - name: Build Dependencies
        run: |
          cd tools/depends
          ./bootstrap
          ./configure --host=arm-tizen-linux-gnueabi \
            --with-toolchain=$HOME/tizen-studio/tools/arm-linux-gnueabi-gcc-9.2 \
            --with-platform=tizen \
            --with-rendersystem=gles
          make -j$(nproc)
      
      - name: Build Kodi
        run: |
          make -C tools/depends/target/cmakebuildsys
          cd build
          make -j$(nproc)
      
      - name: Create TPK
        run: |
          cd build
          make tpk
      
      - name: Upload TPK
        uses: actions/upload-artifact@v3
        with:
          name: kodi-tizen-tpk
          path: build/*.tpk
```

### Option 3: Use Linux VM or Cloud Instance

Build on a Linux machine with proper Tizen SDK:

**AWS EC2:**
```bash
# Launch Ubuntu 22.04 instance
# Install Tizen SDK
# Build Kodi
# Download TPK to your Mac
```

**Local VM (UTM, Parallels, VMware):**
```bash
# Create Ubuntu 22.04 VM
# Install Tizen SDK
# Share folder with macOS
# Build in VM, test on TV
```

### Option 4: Docker or Podman (Advanced)

Use Docker/Podman with full Tizen SDK:

**Using Podman (Recommended):**
```bash
# Install Podman
brew install podman
podman machine init
podman machine start

# Use the build script
chmod +x build-tizen-podman.sh
./build-tizen-podman.sh

# See PODMAN_BUILD_GUIDE.md for complete instructions
```

**Using Docker:**
```bash
# Use the build script
chmod +x build-tizen-docker.sh
./build-tizen-docker.sh
```

**Note:** Both require downloading the Tizen SDK inside the container. See `PODMAN_BUILD_GUIDE.md` for detailed instructions.

## Current Status

Your environment:
- ✅ Tizen SDK installed at `~/tizen-studio`
- ✅ ARM toolchain available (`arm-linux-gnueabi-gcc-9.2`)
- ✅ Symlinks created for `arm-tizen-linux-gnueabi-*` tools
- ❌ ISL library is arm64, needs x86_64
- ❌ Toolchain binaries are x86_64, need Rosetta 2

## Recommended Next Steps

**IMPORTANT:** The macOS Tizen SDK does not include the ARM sysroot (C libraries, headers) needed for cross-compilation. Even with x86_64 ISL installed, you cannot build Kodi for Tizen on macOS.

### Recommended Solutions (in order of practicality):

1. **Use GitHub Actions / CI** (Easiest) - Build on Linux in the cloud
2. **Use a Linux VM or Cloud Instance** - Full build environment
3. **Test on Real Samsung TV** - Skip local building entirely
4. **Use Docker with full Tizen SDK** - Complex setup required

## Quick Commands

### Check Architecture

```bash
# Check ISL architecture
file /usr/local/opt/isl/lib/libisl.23.dylib

# Check toolchain architecture
file ~/tizen-studio/tools/arm-linux-gnueabi-gcc-9.2/bin/arm-tizen-linux-gnueabi-gcc

# Check if Rosetta is installed
pgrep oahd
```

### Test Compiler

```bash
# Test under Rosetta
echo 'int main() { return 0; }' > /tmp/test.c
arch -x86_64 ~/tizen-studio/tools/arm-linux-gnueabi-gcc-9.2/bin/arm-tizen-linux-gnueabi-gcc /tmp/test.c -o /tmp/test
```

## Additional Resources

- `APPLE_SILICON_SOLUTION.md` - Testing on real Samsung TV
- `docs/README.Tizen.md` - Complete Tizen build guide
- `tools/tizen/TV_CONNECTION_GUIDE.md` - Connect to Samsung TV
- `QUICK_SETUP.md` - Environment setup

## Summary

The Tizen toolchain for macOS is x86_64 only. On Apple Silicon Macs, you need to either:
1. Run the toolchain under Rosetta 2 with x86_64 libraries
2. Use Docker with x86_64 emulation
3. Build on a different platform (Linux, Intel Mac, CI)
4. Skip local building and test directly on Samsung TV

For most developers, **Option 1 (Rosetta) or Option 3 (TV testing)** is recommended.
