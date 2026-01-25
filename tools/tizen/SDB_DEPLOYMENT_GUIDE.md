# Kodi Tizen SDB Deployment Guide

This guide explains how to deploy and debug Kodi on Tizen devices using SDB (Smart Development Bridge).

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [SDB Setup](#sdb-setup)
3. [Device Connection](#device-connection)
4. [Deployment](#deployment)
5. [Log Access](#log-access)
6. [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Software

- **Tizen Studio** - Download from [developer.tizen.org](https://developer.tizen.org/development/tizen-studio/download)
- **SDB (Smart Development Bridge)** - Included with Tizen Studio
- **Kodi TPK Package** - Built using the packaging scripts

### System Requirements

- Linux, macOS, or Windows development machine
- Samsung TV (2020+ model) or Tizen emulator
- Network connection (for physical device deployment)

### Developer Mode

For unsigned TPK installation (development builds), you must enable developer mode on your Samsung TV.

**See the [Developer Mode Guide](DEVELOPER_MODE_GUIDE.md) for detailed instructions.**

Quick steps:
1. Go to Apps panel on TV
2. Enter code: **12345**
3. Toggle Developer Mode **ON**
4. Enter your PC's IP address
5. Restart TV

## SDB Setup

### 1. Install Tizen Studio

Download and install Tizen Studio from the official website:

```bash
# Linux/macOS
wget http://download.tizen.org/sdk/Installer/tizen-studio_x.x/web-cli_Tizen_Studio_x.x_ubuntu-64.bin
chmod +x web-cli_Tizen_Studio_x.x_ubuntu-64.bin
./web-cli_Tizen_Studio_x.x_ubuntu-64.bin
```

### 2. Add SDB to PATH

Add SDB to your system PATH:

```bash
# Add to ~/.bashrc or ~/.zshrc
export PATH=$PATH:~/tizen-studio/tools

# Reload shell configuration
source ~/.bashrc  # or source ~/.zshrc
```

### 3. Verify SDB Installation

```bash
sdb version
```

Expected output:
```
Smart Development Bridge version 4.x.x
```

## Device Connection

### Connecting to Samsung TV

#### Step 1: Enable Developer Mode on TV

1. Open the **Apps** panel on your Samsung TV
2. Using the remote, enter the code: **12345**
3. A "Developer Mode" dialog will appear
4. Toggle **Developer mode** to **ON**
5. Enter your development PC's IP address
6. Click **OK** and restart the TV

#### Step 2: Find TV IP Address

1. Go to **Settings** > **General** > **Network** > **Network Status**
2. Note the IP address (e.g., 192.168.1.100)

#### Step 3: Connect via SDB

Use the connection script:

```bash
./tools/tizen/connect.sh -c <TV_IP_ADDRESS>
```

Or manually:

```bash
sdb connect <TV_IP_ADDRESS>:26101
```

#### Step 4: Verify Connection

```bash
./tools/tizen/connect.sh -l
```

Or:

```bash
sdb devices
```

Expected output:
```
List of devices attached
192.168.1.100:26101    device    UE65xxxxx
```

### Connecting to Tizen Emulator

#### Step 1: Launch Emulator

1. Open **Emulator Manager** from Tizen Studio
2. Select a TV emulator profile
3. Click **Launch**

#### Step 2: Verify Auto-Connection

The emulator should automatically connect. Verify with:

```bash
sdb devices
```

Expected output:
```
List of devices attached
emulator-26101    device    emulator-26101
```

### Connection Scripts

The project includes helper scripts for device management:

```bash
# Show connection guide
./tools/tizen/connect.sh -g

# List connected devices
./tools/tizen/connect.sh -l

# Connect to device
./tools/tizen/connect.sh -c 192.168.1.100

# Show device information
./tools/tizen/connect.sh -i

# Enable root access (if supported)
./tools/tizen/connect.sh -r

# Disconnect from device
./tools/tizen/connect.sh -x 192.168.1.100
```

## Deployment

### Quick Deployment

The simplest way to deploy Kodi:

```bash
./tools/tizen/deploy.sh
```

This will:
- Auto-detect the TPK file
- Connect to the device
- Install the package

### Deployment Options

```bash
# Deploy specific TPK file
./tools/tizen/deploy.sh -t build/kodi-tizen.tpk

# Uninstall old version first (recommended)
./tools/tizen/deploy.sh -u

# Install and launch automatically
./tools/tizen/deploy.sh -u -l

# Deploy to specific device (if multiple connected)
./tools/tizen/deploy.sh -d emulator-26101

# Full deployment with all options
./tools/tizen/deploy.sh -t build/kodi-tizen.tpk -u -l
```

### Manual Deployment

If you prefer manual deployment:

```bash
# 1. Push TPK to device
sdb push kodi-tizen.tpk /tmp/kodi-tizen.tpk

# 2. Install package
sdb shell "pkgcmd -i -t tpk -p /tmp/kodi-tizen.tpk"

# 3. Launch application
sdb shell "app_launcher -s org.xbmc.kodi"

# 4. Clean up
sdb shell "rm /tmp/kodi-tizen.tpk"
```

### Uninstalling Kodi

```bash
# Using SDB
sdb shell "pkgcmd -u -n org.xbmc.kodi"

# Or during deployment
./tools/tizen/deploy.sh -u
```

## Log Access

### Real-Time Log Viewing

View Kodi logs in real-time:

```bash
./tools/tizen/logs.sh -f
```

### Log Filtering

```bash
# View only errors
./tools/tizen/logs.sh -l E

# View specific component logs
./tools/tizen/logs.sh -g "video"

# View logs from specific tag
./tools/tizen/logs.sh -t KODI

# Clear logs and follow new ones
./tools/tizen/logs.sh -c -f
```

### Saving Logs

Save logs to a file for analysis:

```bash
./tools/tizen/logs.sh -s kodi-logs.txt
```

### Crash Logs

View crash logs and core dumps:

```bash
./tools/tizen/logs.sh -C
```

For detailed information on crash logging, see the [Crash Logging Guide](CRASH_LOGGING_GUIDE.md).

### Manual Log Access

```bash
# View all Kodi logs
sdb dlog KODI:V

# View only errors
sdb dlog KODI:E

# Follow logs in real-time
sdb dlog KODI:V | grep --color=auto "ERROR"

# Clear log buffer
sdb dlog -c
```

### Log Levels

- **V** - Verbose (all messages)
- **D** - Debug and above
- **I** - Info and above
- **W** - Warning and above
- **E** - Error and above
- **F** - Fatal only

### Accessing Crash Dumps

```bash
# List crash dumps
sdb shell "ls -lh /opt/usr/share/crash/"

# Pull crash dump to local machine
sdb pull /opt/usr/share/crash/kodi_crash_YYYYMMDD.log ./
```

## Troubleshooting

### Connection Issues

#### Problem: "No devices connected"

**Solutions:**

1. Verify TV developer mode is enabled
2. Check that TV and PC are on the same network
3. Verify firewall allows port 26101
4. Try restarting TV developer mode
5. Restart the TV

```bash
# Test network connectivity
ping <TV_IP_ADDRESS>

# Check if port is open
nc -zv <TV_IP_ADDRESS> 26101
```

#### Problem: "Connection refused"

**Solutions:**

1. Restart developer mode on TV
2. Re-enter PC IP address in TV developer settings
3. Restart the TV
4. Check firewall settings

#### Problem: "Multiple devices connected"

**Solution:** Specify device ID:

```bash
./tools/tizen/deploy.sh -d <DEVICE_ID>
./tools/tizen/logs.sh -d <DEVICE_ID>
```

### Installation Issues

#### Problem: "Installation failed"

**Solutions:**

1. Uninstall existing version first:
   ```bash
   ./tools/tizen/deploy.sh -u
   ```

2. Verify TPK is signed correctly:
   ```bash
   unzip -l kodi-tizen.tpk | grep signature
   ```

3. Check device storage space:
   ```bash
   sdb shell "df -h"
   ```

#### Problem: "Package signature verification failed"

**Solutions:**

1. Ensure TPK is signed with valid certificate
2. Re-sign the package:
   ```bash
   ./tools/tizen/packaging/sign.sh kodi-tizen.tpk
   ```

3. For development, enable unsigned package installation (developer mode)

### Runtime Issues

#### Problem: "Application crashes on launch"

**Solutions:**

1. Check crash logs:
   ```bash
   ./tools/tizen/logs.sh -C
   ```

2. View detailed error logs:
   ```bash
   ./tools/tizen/logs.sh -l E -f
   ```

3. Verify all dependencies are included in TPK

#### Problem: "No logs appearing"

**Solutions:**

1. Verify application is running:
   ```bash
   sdb shell "app_launcher -l | grep kodi"
   ```

2. Check dlog is working:
   ```bash
   sdb dlog *:V
   ```

3. Ensure logging is initialized in code

### Performance Issues

#### Problem: "Slow deployment"

**Solutions:**

1. Use wired connection instead of Wi-Fi
2. Reduce TPK size by removing debug symbols
3. Use incremental deployment for development

#### Problem: "Slow log retrieval"

**Solutions:**

1. Filter logs by level:
   ```bash
   ./tools/tizen/logs.sh -l W  # Warnings and above only
   ```

2. Use grep to filter specific messages:
   ```bash
   ./tools/tizen/logs.sh -g "playback"
   ```

## Advanced Usage

### Root Access

Some debugging operations require root access:

```bash
# Enable root (may not work on all devices)
./tools/tizen/connect.sh -r

# Or manually
sdb root on
```

### File System Access

```bash
# Browse application directory
sdb shell "ls -la /opt/usr/apps/org.xbmc.kodi/"

# View user data
sdb shell "ls -la /opt/usr/home/owner/apps_rw/org.xbmc.kodi/data/"

# Pull configuration files
sdb pull /opt/usr/home/owner/apps_rw/org.xbmc.kodi/data/.kodi/ ./kodi-config/

# Push configuration files
sdb push ./kodi-config/ /opt/usr/home/owner/apps_rw/org.xbmc.kodi/data/.kodi/
```

### Remote Shell

```bash
# Open interactive shell
sdb shell

# Execute single command
sdb shell "command"

# Execute command with root
sdb root on
sdb shell "command"
```

### Performance Profiling

```bash
# Monitor CPU usage
sdb shell "top -n 1 | grep kodi"

# Monitor memory usage
sdb shell "cat /proc/$(pidof kodi-tizen)/status | grep VmRSS"

# Monitor GPU usage (if available)
sdb shell "cat /sys/class/graphics/fb0/fps"
```

## Quick Reference

### Common Commands

```bash
# Connection
sdb connect <IP>:26101
sdb devices
sdb disconnect <IP>:26101

# Deployment
sdb push <local> <remote>
sdb shell "pkgcmd -i -t tpk -p <path>"
sdb shell "pkgcmd -u -n org.xbmc.kodi"
sdb shell "app_launcher -s org.xbmc.kodi"

# Logging
sdb dlog KODI:V
sdb dlog -c

# File Operations
sdb pull <remote> <local>
sdb push <local> <remote>
sdb shell "ls -la <path>"

# Process Management
sdb shell "app_launcher -l"
sdb shell "app_launcher -k org.xbmc.kodi"
```

### Script Reference

```bash
# Connection
./tools/tizen/connect.sh -c <IP>    # Connect
./tools/tizen/connect.sh -l         # List devices
./tools/tizen/connect.sh -i         # Device info
./tools/tizen/connect.sh -g         # Show guide

# Deployment
./tools/tizen/deploy.sh             # Deploy
./tools/tizen/deploy.sh -u          # Uninstall first
./tools/tizen/deploy.sh -l          # Launch after install

# Logging
./tools/tizen/logs.sh -f            # Follow logs
./tools/tizen/logs.sh -l E          # Errors only
./tools/tizen/logs.sh -C            # Crash logs
./tools/tizen/logs.sh -s file.txt   # Save to file
```

## Additional Resources

- [Tizen Developer Documentation](https://developer.tizen.org/)
- [SDB Command Reference](https://developer.tizen.org/development/tizen-studio/native-tools/smart-development-bridge)
- [Tizen TV Development Guide](https://developer.samsung.com/smarttv/develop/getting-started/setting-up-sdk/installing-tv-sdk.html)
- [Kodi Development Documentation](https://kodi.wiki/view/Development)

## Support

For issues and questions:

- Kodi Forum: https://forum.kodi.tv/
- Tizen Developer Forum: https://developer.tizen.org/forums
- GitHub Issues: [Project Repository]
