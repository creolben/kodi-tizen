# UTM Setup: Step-by-Step Guide for Kodi Tizen Build

## Current Status

✅ UTM is installed
✅ Ubuntu ARM64 ISO downloading to `~/Downloads/ubuntu-22.04.5-live-server-arm64.iso`

## Step 1: Wait for ISO Download

Check download progress:
```bash
ls -lh ~/Downloads/ubuntu*.iso
```

Expected size: ~1.5 GB

## Step 2: Open UTM and Create VM

1. **Open UTM**:
   ```bash
   open -a UTM
   ```

2. **Click "Create a New Virtual Machine"**

3. **Select "Virtualize"** (NOT Emulate!)
   - ⚠️ This is critical for performance!
   - Virtualize = Native ARM64 speed
   - Emulate = Very slow x86 emulation

4. **Select "Linux"**

5. **Configure Boot:**
   - Click "Browse" for Boot ISO Image
   - Navigate to: `~/Downloads/ubuntu-22.04.5-live-server-arm64.iso`
   - Select the ISO file

6. **Configure Hardware:**
   - Memory: **8192 MB** (8 GB)
   - CPU Cores: **6** (or more if available)

7. **Configure Storage:**
   - Size: **100 GB**

8. **Configure Shared Directory:**
   - Enable: **Yes**
   - Path: Browse to your Kodi source folder

9. **Name the VM:**
   - Name: **kodi-tizen-builder**

10. **Click "Save"**

## Step 3: Install Ubuntu

1. **Start the VM** (click Play button)

2. **Ubuntu Installer will boot**

3. **Follow installation:**
   - Language: English
   - Keyboard: Your preference
   - Installation type: Ubuntu Server
   - Network: Use defaults (DHCP)
   - Storage: Use entire disk (default)
   - Profile setup:
     - Your name: `builder`
     - Server name: `kodi-builder`
     - Username: `builder`
     - Password: (choose something you'll remember)
   - SSH: **Enable OpenSSH server** ✓
   - Featured snaps: Skip (press Tab, Enter)

4. **Wait for installation** (~10-15 minutes)

5. **Reboot when prompted**

6. **Remove ISO:**
   - After reboot, shut down VM
   - Go to VM settings → CD/DVD
   - Clear the ISO path
   - Start VM again

## Step 4: Configure Ubuntu

After Ubuntu boots and you log in, run these commands:

### Update System
```bash
sudo apt update && sudo apt upgrade -y
```

### Install Build Dependencies
```bash
sudo apt install -y \
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
    nasm \
    yasm \
    libssl-dev \
    vim \
    htop
```

### Install Tizen SDK
```bash
cd /tmp

# Try Tizen Studio 6.1 first, fallback to 5.0
if wget http://download.tizen.org/sdk/Installer/tizen-studio_6.1/web-cli_Tizen_Studio_6.1_ubuntu-64.bin 2>/dev/null; then
    INSTALLER="web-cli_Tizen_Studio_6.1_ubuntu-64.bin"
    echo "Using Tizen Studio 6.1"
else
    wget http://download.tizen.org/sdk/Installer/tizen-studio_5.0/web-cli_Tizen_Studio_5.0_ubuntu-64.bin
    INSTALLER="web-cli_Tizen_Studio_5.0_ubuntu-64.bin"
    echo "Using Tizen Studio 5.0"
fi

chmod +x "$INSTALLER"
./"$INSTALLER" --accept-license $HOME/tizen-studio
```

### Install Tizen Toolchain
```bash
$HOME/tizen-studio/package-manager/package-manager-cli.bin install \
    NativeToolchain-Gcc-9.2 \
    PLATFORM-6.0-NativeAppDevelopment-CLI
```

### Set Environment Variables
```bash
echo 'export TIZEN_SDK=$HOME/tizen-studio' >> ~/.bashrc
echo 'export PATH=$PATH:$TIZEN_SDK/tools' >> ~/.bashrc
source ~/.bashrc
```

### Verify Tizen SDK
```bash
ls $TIZEN_SDK/tools/arm-linux-gnueabi-gcc-9.2/bin/
```

## Step 5: Clone and Build Kodi

### Clone Repository
```bash
cd ~
git clone https://github.com/creolben/kodi-tizen.git
cd kodi-tizen
```

### Apply C++17 Patches
```bash
sed -i 's/AX_CXX_COMPILE_STDCXX(\[20\]/AX_CXX_COMPILE_STDCXX([17]/' tools/depends/configure.ac
sed -i 's/CMAKE_CXX_STANDARD 20/CMAKE_CXX_STANDARD 17/' cmake/scripts/common/CompilerSettings.cmake
```

### Build Dependencies (~30-60 minutes)
```bash
cd tools/depends
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

### Build Kodi (~30-60 minutes)
```bash
cd ~/kodi-tizen
make -C tools/depends/target/cmakebuildsys
cd build
make -j$(nproc)
```

### Create TPK
```bash
make tpk
```

### Find Your TPK
```bash
ls -lh *.tpk
```

## Step 6: Transfer TPK to macOS

### Option A: Using SCP (Recommended)

First, get VM IP address (in Ubuntu):
```bash
ip addr show | grep "inet " | grep -v 127.0.0.1
```

Then from macOS terminal:
```bash
scp builder@<VM_IP>:~/kodi-tizen/build/*.tpk ~/Downloads/
```

### Option B: Using Shared Folder

If you configured shared folder:
```bash
# In Ubuntu VM
sudo mkdir -p /mnt/shared
sudo mount -t 9p -o trans=virtio share /mnt/shared
cp ~/kodi-tizen/build/*.tpk /mnt/shared/
```

## Step 7: Install on Samsung TV

From macOS:
```bash
sdb connect <TV_IP>:26101
sdb install ~/Downloads/kodi-tizen-*.tpk
sdb shell app_launcher -s org.xbmc.kodi
```

## Quick Reference Commands

### Start VM from Terminal
```bash
utmctl start kodi-tizen-builder
```

### SSH into VM
```bash
ssh builder@<VM_IP>
```

### Build Kodi (after initial setup)
```bash
cd ~/kodi-tizen
git pull
cd build
make -j$(nproc)
make tpk
```

## Troubleshooting

### VM is slow
- Ensure "Virtualize" was selected (not "Emulate")
- Allocate more CPU cores
- Allocate more RAM

### Can't connect via SSH
- Check VM IP: `ip addr show`
- Ensure SSH is installed: `sudo apt install openssh-server`
- Check SSH status: `sudo systemctl status ssh`

### Build fails
- Check disk space: `df -h`
- Check memory: `free -h`
- Review error messages in build output

### Tizen SDK issues
- Verify toolchain: `ls $TIZEN_SDK/tools/arm-linux-gnueabi-gcc-9.2/bin/`
- Reinstall if needed

## Time Estimates

| Step | Time |
|------|------|
| ISO Download | 5-10 min |
| VM Creation | 5 min |
| Ubuntu Install | 15 min |
| System Update | 5 min |
| Tizen SDK Install | 10 min |
| Clone Repository | 2 min |
| Build Dependencies | 30-60 min |
| Build Kodi | 30-60 min |
| Create TPK | 5 min |
| **Total (First Time)** | **~2 hours** |
| **Subsequent Builds** | **~60-90 min** |

## Next Steps

After you have the TPK:
1. Install on Samsung TV
2. Test Kodi functionality
3. Report any issues

For more details, see:
- `M4_LOCAL_BUILD_GUIDE.md`
- `docs/README.Tizen.md`
