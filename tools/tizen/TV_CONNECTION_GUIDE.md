# Samsung TV Connection and Testing Guide

## Quick Start Checklist

Before connecting to your TV, ensure you have:

- [ ] Samsung TV (2020+ model with Tizen 5.5+)
- [ ] TV and computer on the same network
- [ ] TV's IP address
- [ ] Tizen Studio installed
- [ ] Developer mode enabled on TV
- [ ] SDB (Smart Development Bridge) installed

## Step 1: Enable Developer Mode on TV

### Method 1: Using Remote Control
1. Press **Home** button on your Samsung TV remote
2. Navigate to **Apps**
3. Press **1 2 3 4 5** quickly on the number pad
4. A popup will appear asking to enable Developer Mode
5. Toggle **Developer Mode** to **ON**
6. Enter your computer's IP address when prompted
7. Restart your TV

### Method 2: Using Smart Hub
1. Open **Smart Hub** on your TV
2. Go to **Apps**
3. Enter the secret code: **12345**
4. Enable Developer Mode
5. Enter your PC's IP address
6. Reboot TV

**Note:** See `tools/tizen/DEVELOPER_MODE_GUIDE.md` for detailed instructions.

## Step 2: Find Your TV's IP Address

### On the TV:
1. Press **Home** button
2. Go to **Settings** → **General** → **Network**
3. Select **Network Status**
4. Note the IP address (e.g., 192.168.1.100)

### Alternative - Use Network Scanner:
```bash
# On macOS
arp -a | grep -i samsung

# Or use nmap (if installed)
nmap -sn 192.168.1.0/24 | grep -B 2 "Samsung"
```

## Step 3: Connect via SDB

### Check SDB Installation
```bash
# Check if SDB is installed
which sdb

# If not found, it should be in Tizen Studio
export PATH=$PATH:$HOME/tizen-studio/tools
```

### Connect to TV
```bash
# Replace with your TV's IP address
sdb connect 192.168.1.100

# Verify connection
sdb devices

# You should see output like:
# List of devices attached
# 192.168.1.100:26101    device    UE65TU7000
```

### Troubleshooting Connection Issues

**If connection fails:**

1. **Check network connectivity:**
   ```bash
   ping 192.168.1.100
   ```

2. **Verify developer mode is enabled:**
   - Check TV settings
   - Ensure TV was rebooted after enabling

3. **Check firewall:**
   ```bash
   # On macOS, temporarily disable firewall or allow SDB
   # System Preferences → Security & Privacy → Firewall
   ```

4. **Try different port:**
   ```bash
   sdb connect 192.168.1.100:26101
   ```

5. **Restart SDB server:**
   ```bash
   sdb kill-server
   sdb start-server
   sdb connect 192.168.1.100
   ```

## Step 4: Verify Connection

### Check Device Info
```bash
# Get device information
sdb -s 192.168.1.100:26101 capability

# Check Tizen version
sdb -s 192.168.1.100:26101 shell cat /etc/tizen-release

# Check available space
sdb -s 192.168.1.100:26101 shell df -h
```

### Test Shell Access
```bash
# Open shell on TV
sdb -s 192.168.1.100:26101 shell

# Once in shell, try:
ls /opt/usr/apps
exit
```

## Step 5: Build Kodi (If Not Already Built)

### Quick Build
```bash
# Navigate to project root
cd /path/to/kodi

# Configure build
cd tools/depends
./bootstrap
./configure --host=arm-tizen-linux-gnueabi --with-tizen-sdk=$TIZEN_SDK

# Build dependencies
make -j$(sysctl -n hw.ncpu)

# Build Kodi
cd ../..
mkdir -p build && cd build
cmake .. -DCMAKE_TOOLCHAIN_FILE=../cmake/platform/linux/tizen.cmake
make -j$(sysctl -n hw.ncpu)
```

**Note:** This can take 1-2 hours depending on your machine.

## Step 6: Create TPK Package

```bash
# From project root
./tools/tizen/create-and-sign-tpk.sh

# This will:
# 1. Collect all binaries and resources
# 2. Generate tizen-manifest.xml
# 3. Create TPK package
# 4. Sign with your certificate

# Output will be: kodi-tizen-21.0.0.tpk
```

### If You Don't Have a Certificate

```bash
# Create a certificate using Tizen Studio Certificate Manager
tizen certificate -a MyKodi -p 1234 -c US -s Seoul -ct Seoul -o Samsung -n "Your Name" -e your@email.com

# Create security profile
tizen security-profiles add -n MyProfile -a /path/to/author.p12 -p 1234

# Set as active profile
tizen cli-config "default.profiles.path=/path/to/profiles.xml"
```

## Step 7: Install Kodi on TV

### Using Deployment Script
```bash
# Replace with your TV's IP
./tools/tizen/deploy-and-verify.sh 192.168.1.100

# This will:
# 1. Check connection
# 2. Uninstall old version (if exists)
# 3. Install new TPK
# 4. Launch Kodi
# 5. Show logs
```

### Manual Installation
```bash
# Install TPK
sdb -s 192.168.1.100:26101 install kodi-tizen-21.0.0.tpk

# Launch Kodi
sdb -s 192.168.1.100:26101 shell app_launcher -s org.xbmc.kodi

# View logs
sdb -s 192.168.1.100:26101 dlog KODI:V
```

## Step 8: Test the Application

### Basic Functionality Tests

1. **Launch Test:**
   - Kodi should appear on TV screen
   - UI should be visible and responsive

2. **Navigation Test:**
   - Use TV remote to navigate menus
   - Test: Up, Down, Left, Right, Select, Back

3. **Video Playback Test:**
   ```bash
   # Copy a test video to TV
   sdb -s 192.168.1.100:26101 push test_video.mp4 /opt/usr/media/Videos/
   
   # In Kodi UI:
   # - Navigate to Videos
   # - Select test video
   # - Verify playback starts
   # - Test pause/play/seek
   ```

4. **Audio Test:**
   - Play audio file
   - Test volume controls
   - Verify audio output

5. **Settings Test:**
   - Change a setting
   - Exit Kodi
   - Relaunch Kodi
   - Verify setting persisted

### Monitor Logs During Testing

```bash
# In a separate terminal, monitor logs
sdb -s 192.168.1.100:26101 dlog KODI:V

# Filter for errors
sdb -s 192.168.1.100:26101 dlog KODI:E

# Save logs to file
sdb -s 192.168.1.100:26101 dlog KODI:V > kodi-test-logs.txt
```

### Check for Crashes

```bash
# Check if app is running
sdb -s 192.168.1.100:26101 shell ps | grep kodi

# Check crash logs
sdb -s 192.168.1.100:26101 shell ls -la /opt/usr/apps/org.xbmc.kodi/data/crash_logs/

# Pull crash logs if any
sdb -s 192.168.1.100:26101 pull /opt/usr/apps/org.xbmc.kodi/data/crash_logs/ ./crash_logs/
```

## Step 9: Debugging Issues

### App Won't Launch

```bash
# Check if app is installed
sdb -s 192.168.1.100:26101 shell pkginfo --listpkg | grep kodi

# Check app info
sdb -s 192.168.1.100:26101 shell pkginfo --pkg-info org.xbmc.kodi

# Try launching with verbose output
sdb -s 192.168.1.100:26101 shell app_launcher -s org.xbmc.kodi
```

### App Crashes on Launch

```bash
# Check dlog for errors
sdb -s 192.168.1.100:26101 dlog KODI:E

# Check system logs
sdb -s 192.168.1.100:26101 dlog | grep -i "kodi\|crash\|error"

# Check library dependencies
sdb -s 192.168.1.100:26101 shell ldd /opt/usr/apps/org.xbmc.kodi/bin/kodi-tizen
```

### Video Won't Play

```bash
# Check codec support
sdb -s 192.168.1.100:26101 shell gst-inspect-1.0 | grep -i "h264\|h265\|vp9"

# Check media player capabilities
sdb -s 192.168.1.100:26101 dlog | grep -i "player\|codec\|avplay"

# Verify video file format
file test_video.mp4
```

### Remote Control Not Working

```bash
# Check input events
sdb -s 192.168.1.100:26101 dlog | grep -i "input\|key\|seat"

# Verify Wayland connection
sdb -s 192.168.1.100:26101 dlog | grep -i "wayland"
```

## Step 10: Uninstall (If Needed)

```bash
# Uninstall Kodi
sdb -s 192.168.1.100:26101 uninstall org.xbmc.kodi

# Verify uninstallation
sdb -s 192.168.1.100:26101 shell pkginfo --listpkg | grep kodi
```

## Quick Reference Commands

```bash
# Connect to TV
sdb connect <TV_IP>

# List devices
sdb devices

# Install app
sdb install kodi-tizen-21.0.0.tpk

# Launch app
sdb shell app_launcher -s org.xbmc.kodi

# View logs
sdb dlog KODI:V

# Uninstall app
sdb uninstall org.xbmc.kodi

# Disconnect
sdb disconnect <TV_IP>
```

## Common Issues and Solutions

| Issue | Solution |
|-------|----------|
| Can't connect to TV | Enable developer mode, check network, restart TV |
| SDB not found | Add Tizen Studio tools to PATH |
| Certificate error | Create certificate using Tizen Certificate Manager |
| App won't install | Check TPK signature, verify TV has space |
| Black screen | Check logs for Wayland/EGL errors |
| No audio | Verify audio routing in logs |
| Remote not working | Check input event logs |

## Performance Testing

### Memory Usage
```bash
# Check memory usage
sdb shell top -n 1 | grep kodi

# Detailed memory info
sdb shell cat /proc/$(sdb shell pidof kodi-tizen)/status | grep -i mem
```

### CPU Usage
```bash
# Monitor CPU usage
sdb shell top -d 1 | grep kodi
```

### Network Performance
```bash
# Test network streaming
# Play a network stream in Kodi and monitor:
sdb dlog | grep -i "network\|stream\|buffer"
```

## Next Steps After Successful Testing

1. **Report Results:**
   - Document what works
   - Note any issues or crashes
   - Collect logs for analysis

2. **Test Different Content:**
   - Various video codecs (H.264, H.265, VP9)
   - Different resolutions (1080p, 4K)
   - HDR content (if TV supports)
   - Network streams (HTTP, RTSP, HLS)

3. **Long-Running Test:**
   - Leave Kodi running for extended period
   - Monitor for memory leaks
   - Check stability

4. **User Experience:**
   - Test all menu navigation
   - Verify settings work
   - Test library scanning
   - Test add-on installation

## Support Resources

- Developer Mode Guide: `tools/tizen/DEVELOPER_MODE_GUIDE.md`
- Crash Logging Guide: `tools/tizen/CRASH_LOGGING_GUIDE.md`
- Emulator Guide: `tools/tizen/EMULATOR_GUIDE.md`
- Platform Notes: `docs/TIZEN_PLATFORM_NOTES.md`
- Build Guide: `docs/README.Tizen.md`

## Getting Help

If you encounter issues:

1. Check logs: `sdb dlog KODI:V`
2. Review crash logs in `/opt/usr/apps/org.xbmc.kodi/data/crash_logs/`
3. Check this guide's troubleshooting section
4. Consult the documentation files listed above
