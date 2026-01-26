# 📺 Install Kodi to Samsung TV - Complete Guide

## Prerequisites

Before you start, you need:
- ✅ Samsung TV (2020+ model with Tizen 5.5+)
- ✅ TV and Mac on the same Wi-Fi network
- ✅ Kodi TPK file (from build or GitHub Actions)
- ✅ Tizen Studio installed (for SDB tool)

---

## 🚀 Quick Install (3 Steps)

### Step 1: Enable Developer Mode on TV
1. Press **Home** on your TV remote
2. Go to **Apps**
3. Press **12345** quickly on the number pad
4. Toggle **Developer Mode** to **ON**
5. Enter your Mac's IP address
6. **Restart your TV**

### Step 2: Connect to TV
```bash
# Find your TV's IP (check TV Settings → Network → Network Status)
# Then connect:
sdb connect <YOUR_TV_IP>

# Example:
sdb connect 192.168.1.100
```

### Step 3: Install Kodi
```bash
# Install the TPK file
sdb install build/kodi-tizen-*.tpk

# Launch Kodi
sdb shell app_launcher -s org.xbmc.kodi
```

Done! Kodi should now be running on your TV.

---

## 📋 Detailed Step-by-Step Guide

### Part 1: Prepare Your TV

#### 1.1 Find Your Mac's IP Address
```bash
# On your Mac
ifconfig | grep "inet " | grep -v 127.0.0.1
```

Note the IP address (e.g., `192.168.1.50`)

#### 1.2 Enable Developer Mode on TV

**Method A: Using Remote (Recommended)**
1. Press **Home** button on Samsung remote
2. Navigate to **Apps**
3. Quickly press: **1 → 2 → 3 → 4 → 5**
4. A popup appears: "Developer Mode"
5. Toggle **ON**
6. Enter your **Mac's IP address** (from step 1.1)
7. Click **OK**
8. **Restart your TV** (important!)

**Method B: Using Smart Hub**
1. Open **Smart Hub**
2. Go to **Apps**
3. Enter code: **12345**
4. Enable Developer Mode
5. Enter your Mac's IP
6. Reboot TV

#### 1.3 Find Your TV's IP Address

**On the TV:**
1. Press **Home**
2. **Settings** → **General** → **Network**
3. **Network Status**
4. Note the IP address (e.g., `192.168.1.100`)

**Or scan from Mac:**
```bash
# Find Samsung devices on network
arp -a | grep -i samsung
```

---

### Part 2: Install Tizen Studio (If Not Already Installed)

#### 2.1 Check if SDB is Installed
```bash
which sdb
```

If found, skip to Part 3. Otherwise, continue:

#### 2.2 Install Tizen Studio

**Option A: Use Existing Installation**
If you have Tizen Studio in `~/tizen-studio`:
```bash
export PATH=$PATH:$HOME/tizen-studio/tools
echo 'export PATH=$PATH:$HOME/tizen-studio/tools' >> ~/.zshrc
```

**Option B: Download and Install**
```bash
cd ~/Downloads
wget http://download.tizen.org/sdk/Installer/tizen-studio_5.0/web-cli_Tizen_Studio_5.0_macos-64.bin
chmod +x web-cli_Tizen_Studio_5.0_macos-64.bin
./web-cli_Tizen_Studio_5.0_macos-64.bin --accept-license $HOME/tizen-studio
```

#### 2.3 Verify SDB Installation
```bash
sdb version
# Should show: Smart Development Bridge version 4.x.x
```

---

### Part 3: Connect to Your TV

#### 3.1 Start SDB Server
```bash
sdb start-server
```

#### 3.2 Connect to TV
```bash
# Replace with your TV's IP address
sdb connect 192.168.1.100

# You should see:
# connecting to 192.168.1.100:26101 ...
# connected to 192.168.1.100:26101
```

#### 3.3 Verify Connection
```bash
sdb devices

# You should see:
# List of devices attached
# 192.168.1.100:26101    device    UE65TU7000
```

---

### Part 4: Get the TPK File

You need the Kodi TPK file. You have two options:

#### Option A: From Local Build
```bash
# If you built locally
ls -lh build/*.tpk
```

#### Option B: From GitHub Actions
1. Go to: https://github.com/creolben/kodi-tizen/actions
2. Click on the latest successful workflow run
3. Scroll down to **Artifacts**
4. Download `kodi-tizen-*-arm.zip`
5. Unzip to get the TPK file

---

### Part 5: Install Kodi on TV

#### 5.1 Install the TPK
```bash
# Navigate to where your TPK file is
cd /path/to/tpk/file

# Install (replace with actual filename)
sdb install kodi-tizen-21.0-arm.tpk

# You should see:
# pushed kodi-tizen-21.0-arm.tpk 100%
# 1 file(s) pushed. 0 file(s) skipped.
# path is /home/owner/share/tmp/sdk_tools/tmp/...
# __return_cb req_id[1] pkg_type[tpk] pkgid[org.xbmc.kodi] key[install_percent] val[100]
# __return_cb req_id[1] pkg_type[tpk] pkgid[org.xbmc.kodi] key[end] val[ok]
# spend time for pkgcmd is [xxxxx]ms
```

#### 5.2 Launch Kodi
```bash
sdb shell app_launcher -s org.xbmc.kodi
```

Kodi should now appear on your TV screen!

---

### Part 6: Verify Installation

#### 6.1 Check if Kodi is Running
```bash
# Check installed apps
sdb shell pkginfo --listpkg | grep kodi

# Should show: org.xbmc.kodi

# Check if running
sdb shell ps | grep kodi
```

#### 6.2 View Logs
```bash
# Watch Kodi logs in real-time
sdb dlog KODI:V

# Or save to file
sdb dlog KODI:V > kodi-logs.txt
```

---

## 🎮 Using Kodi on TV

### Navigation with TV Remote:
- **Arrow keys**: Navigate menus
- **OK/Select**: Confirm selection
- **Back**: Go back
- **Home**: Return to main menu
- **Play/Pause**: Control playback
- **Volume**: Adjust volume

### First Time Setup:
1. Select your language
2. Configure network settings (if needed)
3. Add media sources
4. Enjoy!

---

## 🔧 Troubleshooting

### Can't Connect to TV

**Problem:** `sdb connect` fails

**Solutions:**
1. **Check TV is on same network as Mac**
   ```bash
   ping <TV_IP>
   ```

2. **Verify Developer Mode is enabled**
   - Check TV settings
   - Ensure TV was rebooted after enabling

3. **Restart SDB**
   ```bash
   sdb kill-server
   sdb start-server
   sdb connect <TV_IP>
   ```

4. **Check firewall**
   - System Preferences → Security & Privacy → Firewall
   - Allow SDB or temporarily disable

5. **Try with port**
   ```bash
   sdb connect <TV_IP>:26101
   ```

---

### Installation Fails

**Problem:** TPK won't install

**Solutions:**
1. **Check TPK file exists**
   ```bash
   ls -lh *.tpk
   ```

2. **Verify connection**
   ```bash
   sdb devices
   ```

3. **Check TV storage space**
   ```bash
   sdb shell df -h
   ```

4. **Uninstall old version first**
   ```bash
   sdb uninstall org.xbmc.kodi
   sdb install kodi-tizen-*.tpk
   ```

5. **Check certificate (if needed)**
   - TPK must be signed with valid certificate
   - For development, unsigned TPKs work in Developer Mode

---

### Kodi Won't Launch

**Problem:** App installs but won't start

**Solutions:**
1. **Check logs for errors**
   ```bash
   sdb dlog KODI:E
   ```

2. **Verify app is installed**
   ```bash
   sdb shell pkginfo --pkg-info org.xbmc.kodi
   ```

3. **Try launching manually**
   ```bash
   sdb shell app_launcher -s org.xbmc.kodi
   ```

4. **Check for crashes**
   ```bash
   sdb shell ls /opt/usr/apps/org.xbmc.kodi/data/crash_logs/
   ```

5. **Reinstall**
   ```bash
   sdb uninstall org.xbmc.kodi
   sdb install kodi-tizen-*.tpk
   sdb shell app_launcher -s org.xbmc.kodi
   ```

---

### Black Screen or Crash

**Problem:** Kodi launches but shows black screen or crashes

**Solutions:**
1. **Check Wayland/EGL logs**
   ```bash
   sdb dlog | grep -i "wayland\|egl\|gles"
   ```

2. **Verify graphics support**
   ```bash
   sdb shell cat /etc/tizen-release
   ```

3. **Check memory**
   ```bash
   sdb shell free -h
   ```

4. **View detailed logs**
   ```bash
   sdb dlog KODI:V > detailed-logs.txt
   ```

---

### Remote Control Not Working

**Problem:** Can't navigate with TV remote

**Solutions:**
1. **Check input events**
   ```bash
   sdb dlog | grep -i "input\|key"
   ```

2. **Verify Wayland seat**
   ```bash
   sdb dlog | grep -i "seat"
   ```

3. **Try different remote buttons**
   - Some buttons may not be mapped yet

---

## 🗑️ Uninstall Kodi

If you need to remove Kodi:

```bash
# Uninstall
sdb uninstall org.xbmc.kodi

# Verify removal
sdb shell pkginfo --listpkg | grep kodi
# Should return nothing
```

---

## 📝 Quick Reference

### Essential Commands

```bash
# Connect to TV
sdb connect <TV_IP>

# List connected devices
sdb devices

# Install Kodi
sdb install kodi-tizen-*.tpk

# Launch Kodi
sdb shell app_launcher -s org.xbmc.kodi

# View logs
sdb dlog KODI:V

# Uninstall Kodi
sdb uninstall org.xbmc.kodi

# Disconnect
sdb disconnect <TV_IP>
```

### Useful Checks

```bash
# Check if Kodi is installed
sdb shell pkginfo --listpkg | grep kodi

# Check if Kodi is running
sdb shell ps | grep kodi

# Check TV storage
sdb shell df -h

# Check Tizen version
sdb shell cat /etc/tizen-release

# Get TV info
sdb capability
```

---

## 📚 Additional Resources

- **Developer Mode Guide**: `tools/tizen/DEVELOPER_MODE_GUIDE.md`
- **TV Connection Guide**: `tools/tizen/TV_CONNECTION_GUIDE.md`
- **Crash Logging**: `tools/tizen/CRASH_LOGGING_GUIDE.md`
- **Testing Guide**: `TESTING_GUIDE.md`
- **Build Guide**: `docs/README.Tizen.md`

---

## 🎉 Success!

If Kodi is running on your TV, congratulations! You've successfully installed Kodi on Samsung Tizen.

### Next Steps:
1. Configure your media sources
2. Install add-ons
3. Customize the interface
4. Enjoy your media!

### Need Help?
- Check logs: `sdb dlog KODI:V`
- Review troubleshooting section above
- Consult documentation files

---

## 💡 Tips

- **Keep Developer Mode enabled** for easy updates
- **Save your TV's IP** for quick reconnection
- **Monitor logs** when testing new features
- **Backup settings** before major updates
- **Test with sample media** before adding full library

Happy streaming! 🍿
