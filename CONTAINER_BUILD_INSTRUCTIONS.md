# Container Build Instructions

## Quick Start (Inside Container)

You are now inside the Podman container. Run this single command to build everything:

```bash
chmod +x /workspace/container-build.sh && /workspace/container-build.sh
```

This will automatically:
1. Install Tizen SDK (~10 minutes)
2. Build dependencies (~30-60 minutes)
3. Build Kodi (~30-60 minutes)
4. Create TPK package (~5 minutes)

**Total time: 60-90 minutes**

---

## Manual Step-by-Step (Alternative)

If you prefer to run each step manually:

### Step 1: Install Tizen SDK (~10 minutes)

```bash
cd /tmp
wget http://download.tizen.org/sdk/Installer/tizen-studio_5.0/web-cli_Tizen_Studio_5.0_ubuntu-64.bin
chmod +x web-cli_Tizen_Studio_5.0_ubuntu-64.bin
./web-cli_Tizen_Studio_5.0_ubuntu-64.bin --accept-license $HOME/tizen-studio

# Install toolchain
$HOME/tizen-studio/package-manager/package-manager-cli.bin install \
    NativeToolchain-Gcc-9.2 \
    PLATFORM-6.0-NativeAppDevelopment-CLI

# Verify
ls -la $HOME/tizen-studio/tools/arm-linux-gnueabi-gcc-9.2/bin/
```

### Step 2: Build Dependencies (~30-60 minutes)

```bash
export PATH=$PATH:$HOME/tizen-studio/tools
export TIZEN_SDK=$HOME/tizen-studio

cd /workspace/tools/depends
./bootstrap
./configure \
    --prefix=$HOME/kodi-tizen-deps \
    --host=arm-tizen-linux-gnueabi \
    --with-toolchain=$HOME/tizen-studio/tools/arm-linux-gnueabi-gcc-9.2 \
    --with-platform=tizen \
    --with-rendersystem=gles \
    --enable-debug=no

make -j$(nproc)
```

### Step 3: Build Kodi (~30-60 minutes)

```bash
cd /workspace
make -C tools/depends/target/cmakebuildsys
cd build
make -j$(nproc)
```

### Step 4: Create TPK Package (~5 minutes)

```bash
cd /workspace/build
make tpk

# List created files
ls -lh *.tpk
```

---

## Monitoring Progress

Open another terminal and attach to the container to monitor logs:

```bash
# On your Mac (in another terminal)
podman exec -it <container_id> bash

# Inside container, monitor build progress
tail -f /workspace/tools/depends/build.log
# or
tail -f /workspace/build/build.log
```

---

## Troubleshooting

### If Tizen SDK download fails:
```bash
# Try alternative mirror
cd /tmp
wget http://download.tizen.org/sdk/Installer/tizen-studio_5.0/web-cli_Tizen_Studio_5.0_ubuntu-64.bin
```

### If dependencies fail to build:
```bash
# Check the log
less /workspace/tools/depends/build.log

# Clean and retry
cd /workspace/tools/depends
make clean
make -j$(nproc)
```

### If Kodi build fails:
```bash
# Check the log
less /workspace/build/build.log

# Clean and retry
cd /workspace/build
make clean
make -j$(nproc)
```

### If TPK creation fails:
```bash
# Try manual packaging
cd /workspace
bash tools/tizen/packaging/package.sh
```

---

## After Build Completes

1. **Exit the container:**
   ```bash
   exit
   ```

2. **Find the TPK on your Mac:**
   ```bash
   ls -lh build/*.tpk
   ```

3. **Install on Samsung TV:**
   ```bash
   sdb connect <TV_IP>:26101
   sdb install build/kodi-tizen-*.tpk
   sdb shell app_launcher -s org.xbmc.kodi
   ```

---

## Expected Output

When complete, you should see:
```
TPK files created:
-rw-r--r-- 1 builder builder 150M Jan 25 12:34 kodi-tizen-21.0-arm.tpk
```

The TPK file will be available on your host machine in the `build/` directory.

---

## Need Help?

- See `docs/README.Tizen.md` for detailed build documentation
- See `tools/tizen/DEVELOPER_MODE_GUIDE.md` for TV setup
- See `tools/tizen/TV_CONNECTION_GUIDE.md` for connection help
- See `TESTING_GUIDE.md` for testing procedures
