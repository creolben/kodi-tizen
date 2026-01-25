# Tizen Emulator Guide for Kodi Development

This guide explains how to set up and use the Tizen emulator for Kodi development and testing.

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Emulator Installation](#emulator-installation)
4. [Emulator Configuration](#emulator-configuration)
5. [Running the Emulator](#running-the-emulator)
6. [Deploying Kodi](#deploying-kodi)
7. [Debugging](#debugging)
8. [Troubleshooting](#troubleshooting)

## Overview

The Tizen emulator allows you to test Kodi without a physical Samsung TV. It provides:

- Fast iteration during development
- Consistent testing environment
- Easy debugging and log access
- No need for physical hardware

### Emulator vs Physical Device

| Feature | Emulator | Physical TV |
|---------|----------|-------------|
| Setup time | Minutes | Requires TV setup |
| Performance | Depends on host PC | Native hardware |
| Graphics | Software/GPU passthrough | Hardware accelerated |
| Remote control | Keyboard/mouse | Physical remote |
| Network | Host network | TV network |
| HDR support | Limited/None | Full support |
| Real-world testing | No | Yes |

**Recommendation:** Use emulator for development, physical device for final testing.

## Prerequisites

### System Requirements

#### Minimum Requirements
- **CPU:** Intel Core i5 or equivalent (VT-x/AMD-V support required)
- **RAM:** 8 GB
- **Disk:** 20 GB free space
- **OS:** Ubuntu 18.04+, macOS 10.13+, Windows 10+

#### Recommended Requirements
- **CPU:** Intel Core i7 or equivalent with VT-x/AMD-V
- **RAM:** 16 GB or more
- **Disk:** 50 GB free space (SSD recommended)
- **GPU:** Dedicated GPU for better graphics performance

### Software Requirements

- **Tizen Studio** - Latest version
- **Emulator Manager** - Included with Tizen Studio
- **Emulator Images** - TV emulator images (download via Package Manager)
- **Virtualization** - Hardware virtualization enabled in BIOS

## Emulator Installation

### Step 1: Install Tizen Studio

If not already installed:

```bash
# Linux
wget http://download.tizen.org/sdk/Installer/tizen-studio_x.x/web-cli_Tizen_Studio_x.x_ubuntu-64.bin
chmod +x web-cli_Tizen_Studio_x.x_ubuntu-64.bin
./web-cli_Tizen_Studio_x.x_ubuntu-64.bin

# macOS
# Download DMG from https://developer.tizen.org/development/tizen-studio/download
# Mount and run installer
```

### Step 2: Enable Hardware Virtualization

#### Linux (KVM)

```bash
# Check if KVM is available
egrep -c '(vmx|svm)' /proc/cpuinfo
# Should return > 0

# Install KVM
sudo apt-get install qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils

# Add user to kvm group
sudo usermod -aG kvm $USER
sudo usermod -aG libvirt $USER

# Reboot or re-login
```

#### macOS (Hypervisor Framework)

Hypervisor framework is built into macOS. Ensure:

1. System Integrity Protection (SIP) is enabled
2. Virtualization is enabled in BIOS/UEFI

#### Windows (HAXM)

```powershell
# Check if Hyper-V is enabled
Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V

# If Hyper-V is enabled, disable it (conflicts with HAXM)
Disable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All

# Install HAXM via Tizen Studio Package Manager
```

### Step 3: Install Emulator via Package Manager

1. Launch Tizen Studio Package Manager:
   ```bash
   ~/tizen-studio/package-manager/package-manager
   ```

2. In the Package Manager:
   - Go to **Main SDK** tab
   - Check **Tizen SDK Tools** > **Emulator**
   - Go to **Extension SDK** tab
   - Check **TV Extensions-x.x** > **TV Emulator**
   - Click **Install**

3. Wait for installation to complete (may take 10-30 minutes)

### Step 4: Download Emulator Images

1. In Package Manager, go to **Extension SDK** tab
2. Expand **TV Extensions-x.x** > **Emulator Images**
3. Select desired TV emulator images:
   - **TV-samsung-6.0-x86** (recommended for development)
   - **TV-samsung-6.5-x86** (newer platform)
   - **TV-samsung-7.0-x86** (latest)
4. Click **Install**

**Note:** Download size can be 2-5 GB per image.

## Emulator Configuration

### Launch Emulator Manager

```bash
~/tizen-studio/tools/emulator/bin/emulator-manager
```

Or from Tizen Studio IDE: **Tools** > **Emulator Manager**

### Create a New Emulator Instance

1. Click **Create** button
2. Select **TV** platform
3. Choose emulator image (e.g., TV-samsung-6.0-x86)
4. Configure settings:

#### Basic Settings
- **Name:** kodi-dev-tv (or any name)
- **Resolution:** 1920x1080 (Full HD) or 3840x2160 (4K)
- **Display:** Single display

#### Advanced Settings
- **RAM:** 2048 MB (minimum), 4096 MB (recommended)
- **CPU Cores:** 2-4 cores
- **Heap:** 512 MB
- **Graphics:** OpenGL ES 3.0 or higher
- **Skin:** TV skin

#### Network Settings
- **Network Type:** NAT (default)
- **Port Forwarding:** Automatic (SDB port 26101)

5. Click **Confirm** to create the emulator

### Emulator Profiles

You can create multiple emulator profiles for different scenarios:

```
kodi-dev-fhd     - 1920x1080, 2GB RAM, for general development
kodi-dev-4k      - 3840x2160, 4GB RAM, for 4K testing
kodi-test-lowmem - 1920x1080, 1GB RAM, for low-memory testing
```

## Running the Emulator

### Start Emulator from Manager

1. Open Emulator Manager
2. Select your emulator profile
3. Click **Launch**
4. Wait for emulator to boot (30-60 seconds)

### Start Emulator from Command Line

```bash
# List available emulators
~/tizen-studio/tools/emulator/bin/em-cli list-vm

# Launch specific emulator
~/tizen-studio/tools/emulator/bin/em-cli launch --name kodi-dev-tv

# Launch with specific options
~/tizen-studio/tools/emulator/bin/em-cli launch \
  --name kodi-dev-tv \
  --resolution 1920x1080 \
  --ram 4096
```

### Verify Emulator Connection

```bash
# Check SDB connection
sdb devices

# Expected output:
# List of devices attached
# emulator-26101    device    emulator-26101
```

If not connected:

```bash
# Connect manually
sdb connect localhost:26101

# Or
sdb connect 127.0.0.1:26101
```

### Emulator Controls

#### Keyboard Shortcuts

| Key | Function |
|-----|----------|
| Arrow Keys | Navigation (Up/Down/Left/Right) |
| Enter | Select/OK |
| Escape | Back |
| Home | Home button |
| F1 | Menu |
| F2 | Volume Up |
| F3 | Volume Down |
| Ctrl+F11 | Rotate screen |
| Ctrl+F12 | Screenshot |

#### Mouse Controls

- Click to select
- Scroll wheel for volume
- Right-click for context menu

## Deploying Kodi

### Build for Emulator

Build Kodi for x86 architecture:

```bash
# Configure for x86
cd tools/tizen
./configure-tizen-x86.sh

# Build dependencies
cd ../depends
make -j$(nproc)

# Build Kodi
cd ../../build
cmake .. -DCMAKE_TOOLCHAIN_FILE=../cmake/platform/linux/tizen.cmake
make -j$(nproc)

# Package
cd ../tools/tizen/packaging
./package.sh
```

### Deploy to Emulator

```bash
# Using deployment script
./tools/tizen/deploy.sh -d emulator-26101 -u -l

# Or manually
sdb -s emulator-26101 install kodi-tizen.tpk
sdb -s emulator-26101 shell "app_launcher -s org.xbmc.kodi"
```

### Verify Installation

```bash
# List installed apps
sdb shell "app_launcher -l | grep kodi"

# Check if running
sdb shell "ps aux | grep kodi"
```

## Debugging

### View Logs

```bash
# Real-time logs
./tools/tizen/logs.sh -d emulator-26101 -f

# Or directly
sdb -s emulator-26101 dlog KODI:V
```

### Access File System

```bash
# Browse application files
sdb -s emulator-26101 shell "ls -la /opt/usr/apps/org.xbmc.kodi/"

# Pull configuration
sdb -s emulator-26101 pull /opt/usr/home/owner/apps_rw/org.xbmc.kodi/data/.kodi/ ./

# Push test files
sdb -s emulator-26101 push test-video.mp4 /tmp/
```

### Performance Monitoring

```bash
# CPU usage
sdb shell "top -n 1 | grep kodi"

# Memory usage
sdb shell "cat /proc/$(sdb shell pidof kodi-tizen)/status | grep VmRSS"

# FPS (if available)
sdb shell "cat /sys/class/graphics/fb0/fps"
```

### Debugging with GDB

```bash
# Enable root access
sdb root on

# Start gdbserver on emulator
sdb shell "gdbserver :5039 --attach $(pidof kodi-tizen)"

# On host, connect with gdb
arm-tizen-linux-gnueabi-gdb kodi-tizen
(gdb) target remote localhost:5039
(gdb) continue
```

## Troubleshooting

### Emulator Won't Start

**Problem:** Emulator fails to launch or crashes on startup.

**Solutions:**

1. **Check virtualization:**
   ```bash
   # Linux
   egrep -c '(vmx|svm)' /proc/cpuinfo
   
   # macOS
   sysctl kern.hv_support
   ```

2. **Verify KVM/HAXM installation:**
   ```bash
   # Linux
   lsmod | grep kvm
   
   # Windows
   sc query intelhaxm
   ```

3. **Increase RAM allocation:**
   - Edit emulator profile
   - Increase RAM to 4096 MB

4. **Update graphics drivers:**
   - Ensure latest GPU drivers installed
   - Try software rendering if GPU issues

5. **Check logs:**
   ```bash
   ~/tizen-studio/tools/emulator/logs/emulator.log
   ```

### Emulator is Slow

**Problem:** Emulator performance is poor.

**Solutions:**

1. **Enable hardware acceleration:**
   - Ensure KVM (Linux) or HAXM (Windows) is enabled
   - Check virtualization in BIOS

2. **Reduce resolution:**
   - Use 1920x1080 instead of 4K
   - Lower graphics quality

3. **Allocate more resources:**
   - Increase RAM to 4096 MB
   - Increase CPU cores to 4

4. **Close other applications:**
   - Free up system resources
   - Disable antivirus temporarily

5. **Use SSD:**
   - Install emulator on SSD
   - Move virtual disk to SSD

### SDB Connection Issues

**Problem:** Cannot connect to emulator via SDB.

**Solutions:**

1. **Check emulator is running:**
   ```bash
   ~/tizen-studio/tools/emulator/bin/em-cli list-vm
   ```

2. **Restart SDB:**
   ```bash
   sdb kill-server
   sdb start-server
   sdb devices
   ```

3. **Connect manually:**
   ```bash
   sdb connect localhost:26101
   ```

4. **Check port conflicts:**
   ```bash
   # Linux/macOS
   lsof -i :26101
   
   # Windows
   netstat -ano | findstr :26101
   ```

5. **Firewall settings:**
   - Allow port 26101 in firewall
   - Disable firewall temporarily for testing

### Installation Fails

**Problem:** TPK installation fails on emulator.

**Solutions:**

1. **Check storage space:**
   ```bash
   sdb shell "df -h"
   ```

2. **Uninstall old version:**
   ```bash
   sdb shell "pkgcmd -u -n org.xbmc.kodi"
   ```

3. **Verify TPK architecture:**
   - Ensure TPK is built for x86
   - Check manifest for correct architecture

4. **Check installation logs:**
   ```bash
   sdb dlog pkgmgr:V
   ```

### Graphics Issues

**Problem:** Graphics rendering issues or crashes.

**Solutions:**

1. **Update emulator image:**
   - Download latest TV emulator image
   - Recreate emulator profile

2. **Change graphics mode:**
   - Edit emulator profile
   - Try different OpenGL ES version

3. **Disable hardware acceleration:**
   - Use software rendering
   - May be slower but more stable

4. **Update host GPU drivers:**
   - Install latest drivers
   - Restart after update

### Audio Issues

**Problem:** No audio or audio playback issues.

**Solutions:**

1. **Check host audio:**
   - Ensure host system audio works
   - Check volume levels

2. **Emulator audio settings:**
   - Edit emulator profile
   - Enable audio output

3. **Check Kodi audio settings:**
   - Settings > System > Audio
   - Select correct audio device

## Performance Optimization

### Host System Optimization

```bash
# Linux: Increase file descriptor limit
ulimit -n 4096

# Linux: Disable CPU frequency scaling
sudo cpupower frequency-set -g performance

# Linux: Increase shared memory
sudo sysctl -w kernel.shmmax=2147483648
```

### Emulator Optimization

1. **Use x86 images** (faster than ARM emulation)
2. **Allocate sufficient RAM** (4GB recommended)
3. **Enable hardware acceleration** (KVM/HAXM)
4. **Use SSD** for virtual disk
5. **Close unnecessary applications**

### Kodi Optimization for Emulator

```xml
<!-- advancedsettings.xml -->
<advancedsettings>
  <video>
    <adjustrefreshrate>false</adjustrefreshrate>
    <useocclusionquery>false</useocclusionquery>
  </video>
  <cache>
    <memorysize>104857600</memorysize> <!-- 100 MB -->
  </cache>
</advancedsettings>
```

## Emulator Limitations

### Known Limitations

1. **Performance:** Slower than physical hardware
2. **HDR:** Limited or no HDR support
3. **Hardware codecs:** May not match TV capabilities
4. **Remote control:** Keyboard emulation only
5. **Network:** Different network stack than TV
6. **Sensors:** Limited sensor emulation
7. **DRM:** Some DRM content may not work

### Not Suitable For

- Final performance testing
- HDR content validation
- Real remote control testing
- Network streaming stress tests
- Long-running stability tests

### Recommended For

- UI development and testing
- Feature implementation
- Quick iteration
- Debugging
- Unit testing
- Integration testing

## Best Practices

### Development Workflow

1. **Develop on emulator** - Fast iteration
2. **Test on emulator** - Basic functionality
3. **Test on physical device** - Final validation
4. **Profile on physical device** - Performance tuning

### Emulator Management

1. **Create multiple profiles** for different scenarios
2. **Snapshot emulator state** for quick restore
3. **Keep emulator images updated**
4. **Clean up old emulators** to save disk space

### Debugging Strategy

1. **Use emulator for initial debugging**
2. **Reproduce issues on physical device**
3. **Use logs extensively** (dlog)
4. **Test edge cases on both** emulator and device

## Additional Resources

- [Tizen Emulator Documentation](https://developer.tizen.org/development/tizen-studio/native-tools/emulator)
- [Emulator Manager Guide](https://developer.tizen.org/development/tizen-studio/native-tools/emulator/emulator-manager)
- [Emulator Control Panel](https://developer.tizen.org/development/tizen-studio/native-tools/emulator/emulator-control-panel)
- [Tizen TV Development](https://developer.samsung.com/smarttv/develop/getting-started/setting-up-sdk.html)

## Quick Reference

### Common Commands

```bash
# Launch emulator
~/tizen-studio/tools/emulator/bin/em-cli launch --name kodi-dev-tv

# Connect SDB
sdb connect localhost:26101

# Deploy Kodi
./tools/tizen/deploy.sh -d emulator-26101 -u -l

# View logs
./tools/tizen/logs.sh -d emulator-26101 -f

# Stop emulator
~/tizen-studio/tools/emulator/bin/em-cli stop --name kodi-dev-tv
```

### Keyboard Shortcuts

- **Arrow Keys** - Navigate
- **Enter** - Select
- **Escape** - Back
- **Home** - Home button
- **F2/F3** - Volume
- **Ctrl+F12** - Screenshot
