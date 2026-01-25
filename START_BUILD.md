# Start Kodi Tizen Build

Your Podman environment is ready! Here's how to build Kodi for Tizen.

## Quick Start (Automated)

Run the full automated build (takes 1-2 hours):

```bash
podman run --platform linux/amd64 \
  -v $(pwd):/workspace:Z \
  kodi-tizen-builder \
  bash /workspace/container-build.sh 2>&1 | tee build.log
```

This will:
1. Download and install Tizen SDK (~10 min)
2. Build dependencies (~60-90 min)
3. Build Kodi (~20-30 min)
4. Create TPK package (~5 min)

**Total time: 1.5-2 hours**

## Step-by-Step (Recommended for First Time)

### Step 1: Start Interactive Container

```bash
podman run --platform linux/amd64 \
  -v $(pwd):/workspace:Z \
  -it kodi-tizen-builder
```

You're now inside the container!

### Step 2: Download Tizen SDK

```bash
cd /tmp
wget http://download.tizen.org/sdk/Installer/tizen-studio_5.0/web-cli_Tizen_Studio_5.0_ubuntu-64.bin
chmod +x web-cli_Tizen_Studio_5.0_ubuntu-64.bin
./web-cli_Tizen_Studio_5.0_ubuntu-64.bin --accept-license $HOME/tizen-studio
```

### Step 3: Install Tizen Packages

```bash
$HOME/tizen-studio/package-manager/package-manager-cli.bin install \
  NativeToolchain-Gcc-9.2 \
  PLATFORM-6.0-NativeAppDevelopment-CLI
```

### Step 4: Set Environment

```bash
export PATH=$PATH:$HOME/tizen-studio/tools
export TIZEN_SDK=$HOME/tizen-studio
```

### Step 5: Build Dependencies

```bash
cd /workspace/tools/depends
./bootstrap
./configure \
  --prefix=$HOME/kodi-tizen-deps \
  --host=arm-tizen-linux-gnueabi \
  --with-toolchain=$HOME/tizen-studio/tools/arm-linux-gnueabi-gcc-9.2 \
  --with-platform=tizen \
  --with-rendersystem=gles \
  --enable-debug=no

# This takes 60-90 minutes
make -j$(nproc)
```

### Step 6: Build Kodi

```bash
cd /workspace
make -C tools/depends/target/cmakebuildsys

cd build
make -j$(nproc)
```

### Step 7: Create TPK

```bash
make tpk
```

### Step 8: Exit and Find TPK

```bash
exit
```

Back on your Mac:
```bash
ls -lh build/*.tpk
```

## Monitor Build Progress

If running automated build:

```bash
# In another terminal, watch the log
tail -f build.log

# Or check container status
podman ps
```

## Troubleshooting

### Build Fails

Check the log:
```bash
tail -100 build.log
```

### Out of Disk Space

Check Podman machine disk:
```bash
podman machine ssh
df -h
```

Increase if needed:
```bash
podman machine stop
podman machine set --disk-size 100
podman machine start
```

### Out of Memory

Increase memory:
```bash
podman machine stop
podman machine set --memory 8192
podman machine start
```

### Slow Build

Increase CPUs:
```bash
podman machine stop
podman machine set --cpus 8
podman machine start
```

## After Build Completes

### Install on Samsung TV

```bash
# Connect to TV
export PATH=$PATH:$HOME/tizen-studio/tools
sdb connect <TV_IP>:26101

# Install TPK
sdb install build/org.xbmc.kodi_*.tpk

# Launch
sdb shell app_launcher -s org.xbmc.kodi

# View logs
sdb dlog KODI:V
```

## Alternative: Use Pre-built TPK

If you don't want to wait for the build:

1. Ask if anyone has a pre-built TPK
2. Download from Kodi releases (if available)
3. Use GitHub Actions to build (see `TIZEN_BUILD_FIX.md`)

## Estimated Times

| Step | Time |
|------|------|
| Download Tizen SDK | 5-10 min |
| Install Tizen packages | 5 min |
| Build dependencies | 60-90 min |
| Build Kodi | 20-30 min |
| Create TPK | 5 min |
| **Total** | **1.5-2 hours** |

## Save Container State

To avoid reinstalling Tizen SDK next time:

```bash
# After installing Tizen SDK, exit container
exit

# Find container ID
podman ps -a

# Save container as new image
podman commit <container-id> kodi-tizen-builder-with-sdk

# Use saved image next time
podman run --platform linux/amd64 \
  -v $(pwd):/workspace:Z \
  -it kodi-tizen-builder-with-sdk
```

## Next Build (Incremental)

After first build, subsequent builds are much faster (5-15 min):

```bash
podman run --platform linux/amd64 \
  -v $(pwd):/workspace:Z \
  -it kodi-tizen-builder-with-sdk

# Inside container
cd /workspace/build
make -j$(nproc)
make tpk
exit
```

## Summary

**First build:** 1.5-2 hours
**Incremental builds:** 5-15 minutes
**Result:** TPK file in `build/` directory ready to install on Samsung TV

Ready to start? Run:

```bash
podman run --platform linux/amd64 -v $(pwd):/workspace:Z -it kodi-tizen-builder
```

Then follow the step-by-step instructions above!
