# Tizen Developer Mode Guide

This guide explains how to enable developer mode on Samsung TVs and use it for Kodi development and testing.

## Table of Contents

1. [What is Developer Mode](#what-is-developer-mode)
2. [Enabling Developer Mode](#enabling-developer-mode)
3. [Unsigned TPK Installation](#unsigned-tpk-installation)
4. [Developer Mode Features](#developer-mode-features)
5. [Troubleshooting](#troubleshooting)

## What is Developer Mode

Developer Mode is a special mode on Samsung Tizen TVs that enables:

- Installation of unsigned TPK packages (for development)
- SDB (Smart Development Bridge) connectivity
- Remote debugging capabilities
- Access to developer tools and logs
- Relaxed security restrictions for testing

**Important:** Developer Mode is intended for development and testing only. It should not be used on production devices or for distributing applications to end users.

## Enabling Developer Mode

### Prerequisites

- Samsung Smart TV (2020 or later model recommended)
- TV connected to the same network as your development PC
- Samsung TV remote control

### Step-by-Step Instructions

#### Step 1: Access the Apps Panel

1. Press the **Home** button on your Samsung TV remote
2. Navigate to the **Apps** panel
3. Ensure you're on the main Apps screen (not in a specific app)

#### Step 2: Enter Developer Mode Code

1. Using the number keys on your remote, enter: **12345**
2. A "Developer Mode" dialog will appear

**Note:** If the dialog doesn't appear:
- Make sure you're on the Apps panel (not in Settings)
- Try entering the code again
- Ensure your TV firmware is up to date

#### Step 3: Configure Developer Mode

In the Developer Mode dialog:

1. Toggle **Developer mode** to **ON**
2. Enter your development PC's IP address in the "Host PC IP" field
   - Find your PC's IP with: `ifconfig` (Linux/macOS) or `ipconfig` (Windows)
   - Example: `192.168.1.50`
3. Click **OK**

#### Step 4: Restart the TV

1. The TV will prompt you to restart
2. Click **OK** to restart now, or restart manually later
3. Wait for the TV to fully restart (this may take 1-2 minutes)

#### Step 5: Verify Developer Mode

After restart:

1. Go back to the Apps panel
2. You should see a "Developer Mode" indicator or icon
3. The TV is now ready for SDB connection

### Visual Guide

```
Samsung TV Remote
┌─────────────────┐
│     [POWER]     │
│                 │
│  [1] [2] [3]    │  ← Enter: 1-2-3-4-5
│  [4] [5] [6]    │
│  [7] [8] [9]    │
│      [0]        │
│                 │
│     [HOME]      │  ← Press first to go to Apps
└─────────────────┘
```

## Unsigned TPK Installation

Developer Mode allows installation of unsigned TPK packages, which is essential for development and testing.

### Why Unsigned TPKs?

During development, you may want to:
- Test builds without going through the signing process
- Iterate quickly without certificate management
- Share test builds with team members
- Debug issues before final release

### Installing Unsigned TPKs

#### Method 1: Using Deployment Script (Recommended)

The deployment script automatically handles unsigned TPK installation when developer mode is enabled:

```bash
./tools/tizen/deploy.sh -t kodi-tizen-unsigned.tpk
```

#### Method 2: Manual Installation via SDB

```bash
# 1. Connect to TV
sdb connect <TV_IP>:26101

# 2. Push unsigned TPK
sdb push kodi-tizen-unsigned.tpk /tmp/kodi.tpk

# 3. Install (developer mode allows unsigned)
sdb shell "pkgcmd -i -t tpk -p /tmp/kodi.tpk"

# 4. Launch
sdb shell "app_launcher -s org.xbmc.kodi"
```

#### Method 3: Using Tizen Studio

1. Open Tizen Studio
2. Go to **Tools** > **Device Manager**
3. Select your TV from the device list
4. Right-click and select **Install Application**
5. Browse to your unsigned TPK file
6. Click **Install**

### Unsigned vs Signed TPKs

| Feature | Unsigned TPK | Signed TPK |
|---------|--------------|------------|
| Installation | Developer mode only | Any device |
| Distribution | Development only | Public distribution |
| Security | Reduced | Full |
| Certificate required | No | Yes |
| App store submission | No | Yes |
| Use case | Development/testing | Production |

### Creating Unsigned TPKs

To create an unsigned TPK for development:

```bash
# Package without signing
./tools/tizen/packaging/package.sh --no-sign

# Or skip the signing step
./tools/tizen/packaging/package.sh
# Then skip running sign.sh
```

The resulting TPK can be installed on devices with developer mode enabled.

## Developer Mode Features

### 1. SDB Connectivity

Developer mode enables SDB connections for:

- Remote command execution
- File transfer
- Log access
- Application management

```bash
# Connect to TV
sdb connect <TV_IP>:26101

# Execute commands
sdb shell "ls -la /opt/usr/apps/"

# Transfer files
sdb push local_file /tmp/remote_file
sdb pull /tmp/remote_file local_file
```

### 2. Remote Debugging

Access detailed logs and debugging information:

```bash
# View application logs
sdb dlog KODI:V

# Monitor system logs
sdb dlog *:W

# Access crash dumps
sdb shell "ls /opt/usr/share/crash/"
```

### 3. Application Management

Install, uninstall, and manage applications:

```bash
# List installed apps
sdb shell "app_launcher -l"

# Install app
sdb shell "pkgcmd -i -t tpk -p /tmp/app.tpk"

# Uninstall app
sdb shell "pkgcmd -u -n org.xbmc.kodi"

# Launch app
sdb shell "app_launcher -s org.xbmc.kodi"

# Kill app
sdb shell "app_launcher -k org.xbmc.kodi"
```

### 4. File System Access

Browse and modify application files:

```bash
# Application directory
sdb shell "ls -la /opt/usr/apps/org.xbmc.kodi/"

# User data directory
sdb shell "ls -la /opt/usr/home/owner/apps_rw/org.xbmc.kodi/"

# System directories (may require root)
sdb shell "ls -la /etc/"
```

### 5. Performance Monitoring

Monitor application performance:

```bash
# CPU usage
sdb shell "top -n 1 | grep kodi"

# Memory usage
sdb shell "cat /proc/$(pidof kodi-tizen)/status | grep VmRSS"

# Disk usage
sdb shell "df -h"
```

## Troubleshooting

### Developer Mode Won't Enable

**Problem:** The developer mode dialog doesn't appear when entering 12345.

**Solutions:**

1. Ensure you're on the Apps panel (not in Settings or another app)
2. Update TV firmware to the latest version:
   - Settings > Support > Software Update
3. Try a different remote (if available)
4. Factory reset the TV (last resort)

### Can't Connect via SDB

**Problem:** `sdb connect` fails or times out.

**Solutions:**

1. Verify developer mode is enabled (check Apps panel for indicator)
2. Ensure TV and PC are on the same network:
   ```bash
   ping <TV_IP>
   ```
3. Check firewall settings (allow port 26101)
4. Restart developer mode:
   - Disable developer mode
   - Restart TV
   - Re-enable developer mode
5. Verify PC IP address is correct in TV settings
6. Try connecting with explicit port:
   ```bash
   sdb connect <TV_IP>:26101
   ```

### Unsigned TPK Installation Fails

**Problem:** Installation fails with "signature verification failed" or similar error.

**Solutions:**

1. Verify developer mode is enabled
2. Check that the TPK is actually unsigned (not a signed TPK)
3. Ensure sufficient storage space:
   ```bash
   sdb shell "df -h"
   ```
4. Try uninstalling existing version first:
   ```bash
   sdb shell "pkgcmd -u -n org.xbmc.kodi"
   ```
5. Check installation logs:
   ```bash
   sdb dlog pkgmgr:V
   ```

### Developer Mode Disables After Restart

**Problem:** Developer mode turns off after TV restart.

**Solutions:**

1. This is normal behavior on some TV models
2. Re-enable developer mode after each restart
3. Keep the TV powered on during development
4. Some newer models maintain developer mode across restarts

### SDB Connection Drops Frequently

**Problem:** SDB connection is unstable or drops frequently.

**Solutions:**

1. Use wired Ethernet instead of Wi-Fi
2. Ensure TV is not in power-saving mode
3. Disable TV's automatic updates during development
4. Keep the TV screen on (prevent sleep mode)
5. Use a static IP for the TV

### Can't Access Certain Directories

**Problem:** Permission denied when accessing system directories.

**Solutions:**

1. Try enabling root access:
   ```bash
   sdb root on
   ```
2. Note: Root access may not be available on all TV models
3. Some directories are restricted even in developer mode
4. Use application-specific directories instead

## Security Considerations

### Important Warnings

⚠️ **Developer mode reduces security:**
- Allows unsigned code execution
- Enables remote access to the device
- May expose sensitive information
- Should not be used on production devices

⚠️ **Network security:**
- Developer mode opens port 26101
- Ensure your network is secure
- Don't enable developer mode on public networks
- Consider using a separate development network

⚠️ **Data privacy:**
- Developer mode may expose user data
- Don't enable on TVs with sensitive content
- Clear user data before enabling for testing

### Best Practices

1. **Only enable on development devices**
   - Use dedicated test TVs
   - Don't enable on personal/production TVs

2. **Disable when not needed**
   - Turn off developer mode after testing
   - Reduces security risks

3. **Secure your network**
   - Use WPA2/WPA3 encryption
   - Strong Wi-Fi passwords
   - Consider VLANs for development devices

4. **Monitor access**
   - Check SDB connections regularly
   - Review installed applications
   - Monitor system logs

5. **Update regularly**
   - Keep TV firmware updated
   - Update Tizen Studio and SDB
   - Apply security patches

## Disabling Developer Mode

When you're done with development:

### Method 1: Via TV Settings

1. Go to Apps panel
2. Enter **12345** again
3. Toggle **Developer mode** to **OFF**
4. Restart the TV

### Method 2: Factory Reset

For complete cleanup:

1. Settings > General > Reset
2. Enter PIN (default: 0000)
3. Confirm reset

**Warning:** This will erase all data and settings.

## Additional Resources

- [Samsung Smart TV Developer Documentation](https://developer.samsung.com/smarttv/develop/getting-started/setting-up-sdk.html)
- [Tizen Developer Guide](https://developer.tizen.org/development/getting-started)
- [SDB Command Reference](https://developer.tizen.org/development/tizen-studio/native-tools/smart-development-bridge)
- [Kodi Development Guide](https://kodi.wiki/view/Development)

## Quick Reference

### Enable Developer Mode
1. Apps panel → Enter **12345**
2. Toggle ON → Enter PC IP → OK
3. Restart TV

### Connect via SDB
```bash
sdb connect <TV_IP>:26101
sdb devices
```

### Install Unsigned TPK
```bash
./tools/tizen/deploy.sh -t unsigned.tpk
```

### View Logs
```bash
./tools/tizen/logs.sh -f
```

### Disable Developer Mode
1. Apps panel → Enter **12345**
2. Toggle OFF → OK
3. Restart TV
