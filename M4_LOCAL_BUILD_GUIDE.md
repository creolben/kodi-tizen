# Building Kodi TPK Locally on Apple Silicon M4

## Executive Summary

Building Kodi TPK files locally on Apple Silicon (M4/M3/M2/M1) is **possible but complex**. Here are your best options ranked by practicality:

1. **✅ RECOMMENDED: GitHub Actions** (easiest, most reliable)
2. **✅ VIABLE: UTM VM with Ubuntu ARM64** (native ARM performance)
3. **⚠️ COMPLEX: Docker/Podman with QEMU** (slower, emulation overhead)
4. **❌ NOT VIABLE: Native macOS build** (missing ARM sysroot)

## Option 1: GitHub Actions (Recommended) ⭐

**Why this is best:**
- ✅ Native Linux ARM64 runners available
- ✅ No local resources needed
- ✅ Free for public repos (2,000 minutes/month)
- ✅ Already configured in your workflow
- ✅ Reliable and reproducible

**Setup:** See `ACTION_PLAN_NOW.md`

**Time:** 5 minutes setup + 60-90 minutes build (automated)

---

## Option 2: UTM Virtual Machine (Best Local Option) ⭐

UTM is a free, open-source virtualization app for macOS that runs ARM64 Linux at near-native speeds on Apple Silicon.

### Why UTM is Better Than Docker/Podman:

| Feature | UTM | Docker/Podman |
|---------|-----|---------------|
| **Performance** | Near-native (ARM64) | Slow (x86 emulation) |
| **Complexity** | Medium | High |
| **Stability** | Excellent | Issues with QEMU |
| **Setup Time** | 30 minutes | 1-2 hours |
| **Build Speed** | Fast | Very slow |

### Step-by-Step UTM Setup

#### 1. Install UTM (5 minutes)

```bash
# Option A: Homebrew (recommended)
brew install --cask utm

# Option B: Download from website
# https://mac.getutm.app/
```

#### 2. Download Ubuntu ARM64 (10 minutes)

Download Ubuntu Server 22.04 LTS ARM64:
```
https://cdimage.ubuntu.com/releases/22.04/release/ubuntu-22.04.5-live-server-arm64.iso
```

**Why Ubuntu 22.04?**
- ✅ Native ARM64 support
- ✅ Compatible with Tizen SDK 6.1 and 5.0
- ✅ Long-term support (LTS)
- ✅ Well-tested for development

#### 3. Create Ubuntu VM in UTM (15 minutes)

1. **Open UTM** and click "Create a New Virtual Machine"

2. **Select "Virtualize"** (not Emulate - this is key for performance!)

3. **Choose Linux**

4. **Configure VM:**
   - **Boot ISO**: Select the Ubuntu ARM64 ISO you downloaded
   - **Memory**: 8 GB (minimum 4 GB)
   - **CPU Cores**: 4-6 cores
   - **Storage**: 100 GB (minimum 60 GB)
   - **Shared Directory**: Enable (for easy file transfer)

5. **Start VM** and install Ubuntu:
   - Follow Ubuntu installation wizard
   - Choose "Ubuntu Server" (no GUI needed)
   - Create user account
   - Enable OpenSSH server (important!)

6. **After installation:**
   ```bash
   # Update system
   sudo apt update && sudo apt upgrade -y
   
   # Install essential tools
   sudo apt install -y build-essential git curl wget
   ```

#### 4. Set Up Shared Folder (Optional but Recommended)

In UTM:
1. Go to VM Settings → Sharing
2. Enable "Share Directory"
3. Select your Kodi source folder on macOS

In Ubuntu VM:
```bash
# Mount shared folder
sudo mkdir -p /mnt/shared
sudo mount -t 9p -o trans=virtio share /mnt/shared

# Make it permanent
echo "share /mnt/shared 9p trans=virtio,version=9p2000.L,rw 0 0" | sudo tee -a /etc/fstab
```

#### 5. Install Tizen SDK in VM (20 minutes)

```bash
# Download Tizen SDK (tries 6.1, falls back to 5.0)
cd /tmp

# Try Tizen Studio 6.1 first
if wget http://download.tizen.org/sdk/Installer/tizen-studio_6.1/web-cli_Tizen_Studio_6.1_ubuntu-64.bin 2>/dev/null; then
    INSTALLER="web-cli_Tizen_Studio_6.1_ubuntu-64.bin"
    echo "Using Tizen Studio 6.1"
else
    # Fallback to 5.0
    wget http://download.tizen.org/sdk/Installer/tizen-studio_5.0/web-cli_Tizen_Studio_5.0_ubuntu-64.bin
    INSTALLER="web-cli_Tizen_Studio_5.0_ubuntu-64.bin"
    echo "Using Tizen Studio 5.0"
fi

# Install
chmod +x "$INSTALLER"
./"$INSTALLER" --accept-license $HOME/tizen-studio

# Install toolchain
$HOME/tizen-studio/package-manager/package-manager-cli.bin install \
    NativeToolchain-Gcc-9.2 \
    PLATFORM-6.0-NativeAppDevelopment-CLI

# Set environment variables
echo 'export TIZEN_SDK=$HOME/tizen-studio' >> ~/.bashrc
echo 'export PATH=$PATH:$TIZEN_SDK/tools' >> ~/.bashrc
source ~/.bashrc
```

#### 6. Clone Kodi and Build (60-90 minutes)

```bash
# Clone your Kodi fork
cd ~
git clone https://github.com/creolben/kodi-tizen.git
cd kodi-tizen

# Apply C++17 patches
sed -i 's/AX_CXX_COMPILE_STDCXX(\[20\]/AX_CXX_COMPILE_STDCXX([17]/' tools/depends/configure.ac
sed -i 's/CMAKE_CXX_STANDARD 20/CMAKE_CXX_STANDARD 17/' cmake/scripts/common/CompilerSettings.cmake

# Build dependencies
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

# Build Kodi
cd ~/kodi-tizen
make -C tools/depends/target/cmakebuildsys
cd build
make -j$(nproc)

# Create TPK
make tpk
```

#### 7. Transfer TPK to macOS

```bash
# If using shared folder:
cp *.tpk /mnt/shared/

# Or use SCP from macOS:
scp username@vm-ip:~/kodi-tizen/build/*.tpk ~/Downloads/
```

### UTM Performance Tips

1. **Enable Rosetta** (if needed for x86 tools):
   - VM Settings → System → Enable Rosetta

2. **Allocate more resources**:
   - More CPU cores = faster build
   - More RAM = better performance
   - SSD storage = faster I/O

3. **Use SSH** instead of console:
   ```bash
   # From macOS terminal
   ssh username@vm-ip
   ```

4. **Snapshot before building**:
   - Create VM snapshot after Tizen SDK installation
   - Restore if build fails

### UTM Advantages

✅ **Near-native ARM64 performance** (no emulation)
✅ **Full Linux environment** (all tools work)
✅ **Persistent** (VM stays configured)
✅ **Isolated** (doesn't affect macOS)
✅ **Free and open-source**
✅ **Easy file sharing** with macOS
✅ **Snapshot support** (save states)

### UTM Disadvantages

⚠️ **Requires disk space** (100 GB VM)
⚠️ **Initial setup time** (30-60 minutes)
⚠️ **Uses RAM** (8 GB allocated)
⚠️ **Manual management** (start/stop VM)

---

## Option 3: Docker/Podman with QEMU (Complex)

This approach uses Docker or Podman with QEMU to emulate x86_64 Linux on ARM64 macOS.

### Why This is Less Ideal:

❌ **Very slow** (x86 emulation on ARM)
❌ **Unstable** (QEMU issues, zombie processes)
❌ **Complex setup** (multiple layers)
❌ **Resource intensive** (emulation overhead)

### If You Still Want to Try:

#### Using Docker Desktop (Easier)

```bash
# Install Docker Desktop for Mac
brew install --cask docker

# Enable experimental features
# Docker Desktop → Settings → Experimental Features → Enable

# Build with platform specification
docker buildx build --platform linux/amd64 -t kodi-tizen-builder .

# Run container
docker run --platform linux/amd64 -it kodi-tizen-builder bash
```

#### Using Podman (More Control)

```bash
# Install Podman
brew install podman

# Initialize Podman machine with QEMU
podman machine init --cpus 4 --memory 8192 --disk-size 100

# Start machine
podman machine start

# Build with emulation
podman build --platform linux/amd64 -t kodi-tizen-builder .

# Run container
podman run --platform linux/amd64 -it kodi-tizen-builder bash
```

### Docker/Podman Issues on Apple Silicon:

1. **Slow builds** (5-10x slower than native)
2. **Zombie processes** (QEMU bugs)
3. **Memory issues** (emulation overhead)
4. **Compatibility problems** (not all tools work)
5. **Complex debugging** (multiple layers)

**Verdict:** Only use if you're already familiar with Docker/Podman and need containerization.

---

## Option 4: Native macOS Build (Not Viable)

### Why This Doesn't Work:

❌ **No ARM sysroot** in Tizen SDK for macOS
❌ **Missing cross-compilation tools**
❌ **Tizen SDK designed for packaging only**
❌ **Can't build from source natively**

The macOS Tizen SDK is designed for:
- ✅ Packaging pre-built binaries
- ✅ Deploying to devices
- ✅ Debugging applications
- ❌ **NOT for building from source**

---

## Comparison Matrix

| Method | Setup Time | Build Time | Complexity | Reliability | Cost |
|--------|-----------|------------|------------|-------------|------|
| **GitHub Actions** | 5 min | 60-90 min | Low | ⭐⭐⭐⭐⭐ | Free |
| **UTM VM** | 30-60 min | 60-90 min | Medium | ⭐⭐⭐⭐ | Free |
| **Docker/Podman** | 1-2 hours | 3-6 hours | High | ⭐⭐ | Free |
| **Native macOS** | N/A | N/A | N/A | ❌ | N/A |

---

## Recommended Workflow

### For Most Users:

1. **Use GitHub Actions** for automated builds
2. **Use UTM VM** for local development/testing
3. **Use macOS** for:
   - Code editing
   - Git operations
   - SDB deployment to TV
   - Testing TPK files

### For Advanced Users:

1. **Primary**: GitHub Actions (CI/CD)
2. **Secondary**: UTM VM (local testing)
3. **Tertiary**: Docker/Podman (if needed for containers)

---

## Quick Start: UTM Method

```bash
# 1. Install UTM
brew install --cask utm

# 2. Download Ubuntu ARM64 ISO
# https://cdimage.ubuntu.com/releases/22.04/release/ubuntu-22.04.5-live-server-arm64.iso

# 3. Create VM in UTM
# - Virtualize (not Emulate!)
# - 8 GB RAM, 4-6 CPU cores, 100 GB disk
# - Install Ubuntu Server

# 4. In Ubuntu VM:
sudo apt update && sudo apt upgrade -y
sudo apt install -y build-essential git curl wget

# 5. Install Tizen SDK (see step 5 above)

# 6. Clone and build Kodi (see step 6 above)

# 7. Transfer TPK to macOS
```

**Total time:** ~2-3 hours (first time), ~60-90 minutes (subsequent builds)

---

## Troubleshooting

### UTM Issues:

**Problem**: VM is slow
**Solution**: 
- Ensure "Virtualize" is selected (not "Emulate")
- Allocate more CPU cores and RAM
- Use SSD storage

**Problem**: Can't access shared folder
**Solution**:
```bash
sudo mount -t 9p -o trans=virtio share /mnt/shared
```

**Problem**: Network not working
**Solution**: 
- VM Settings → Network → Shared Network
- Restart VM

### Docker/Podman Issues:

**Problem**: Build is extremely slow
**Solution**: This is expected with x86 emulation. Use UTM instead.

**Problem**: Zombie processes
**Solution**: 
```bash
podman machine stop
podman machine rm
podman machine init --cpus 4 --memory 8192
```

### Tizen SDK Issues:

**Problem**: Toolchain not found
**Solution**:
```bash
ls $HOME/tizen-studio/tools/arm-linux-gnueabi-gcc-9.2/bin/
# If missing, reinstall toolchain
```

---

## Cost Analysis

### GitHub Actions (Recommended):
- **Cost**: Free (2,000 minutes/month)
- **Your time**: 5 minutes
- **Build time**: 60-90 minutes (automated)
- **Total**: ~$0

### UTM VM:
- **Cost**: Free (open-source)
- **Your time**: 30-60 minutes (setup) + 10 minutes (per build)
- **Build time**: 60-90 minutes
- **Disk space**: 100 GB
- **Total**: ~$0

### Docker/Podman:
- **Cost**: Free
- **Your time**: 1-2 hours (setup) + 30 minutes (per build)
- **Build time**: 3-6 hours (emulation)
- **Total**: ~$0 (but high time cost)

---

## Final Recommendation

### For Your M4 Mac:

1. **Primary method**: **GitHub Actions**
   - Set up once, use forever
   - No local resources needed
   - Most reliable

2. **Secondary method**: **UTM VM**
   - For local development
   - Fast ARM64 performance
   - Full Linux environment

3. **Avoid**: Docker/Podman with emulation
   - Too slow on Apple Silicon
   - Stability issues
   - Not worth the complexity

### Next Steps:

1. **Immediate**: Follow `ACTION_PLAN_NOW.md` for GitHub Actions
2. **Optional**: Set up UTM VM for local development
3. **Use macOS for**: Code editing, deployment, testing

---

## Resources

- **UTM**: https://mac.getutm.app/
- **Ubuntu ARM64**: https://cdimage.ubuntu.com/releases/22.04/release/
- **Tizen SDK**: https://developer.tizen.org/
- **GitHub Actions**: https://github.com/features/actions
- **Docker Desktop**: https://www.docker.com/products/docker-desktop/
- **Podman**: https://podman.io/

---

## Summary

**Can you build TPK locally on M4?** Yes, using UTM VM.

**Should you?** Only if you need local development environment.

**Best approach?** Use GitHub Actions for builds, macOS for development.

**Time investment:**
- GitHub Actions: 5 minutes
- UTM VM: 30-60 minutes setup
- Docker/Podman: Not recommended

**Performance:**
- GitHub Actions: Native Linux (fast)
- UTM VM: Near-native ARM64 (fast)
- Docker/Podman: x86 emulation (very slow)

Choose GitHub Actions for simplicity, UTM for local control. 🚀
