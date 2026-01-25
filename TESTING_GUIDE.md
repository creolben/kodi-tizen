# Kodi Tizen - TV Testing Guide

## 🎯 Quick Start

You're ready to test Kodi on your Samsung TV! Here's what to do:

### Option 1: Quick Test (Recommended for First Time)

```bash
# Run the interactive helper script
./tools/tizen/quick-test.sh
```

This script will:
1. Check if SDB is available (✓ you have it)
2. Ask for your TV's IP address
3. Connect to your TV
4. Guide you through installation and testing

### Option 2: Manual Steps

If you prefer to do it manually:

```bash
# 1. Add SDB to your PATH
export PATH=$PATH:$HOME/tizen-studio/tools

# 2. Connect to your TV (replace with your TV's IP)
sdb connect 192.168.1.XXX

# 3. Verify connection
sdb devices

# 4. Install Kodi (once you have a TPK)
sdb install kodi-tizen-21.0.0.tpk

# 5. Launch Kodi
sdb shell app_launcher -s org.xbmc.kodi

# 6. View logs
sdb dlog KODI:V
```

## 📋 Before You Start

### You Need:

1. **Your TV's IP Address**
   - Find it: TV Settings → Network → Network Status
   - Example: `192.168.1.100`

2. **Developer Mode Enabled on TV**
   - Press Home → Apps → Press `12345` quickly
   - Enable Developer Mode
   - Enter your Mac's IP address
   - **Reboot TV** (important!)

3. **A TPK Package** (Kodi installation file)
   - You don't have one yet
   - See "Building Kodi" section below

### You Have:

- ✅ Tizen Studio installed
- ✅ SDB available at `~/tizen-studio/tools/sdb`
- ✅ Kodi source code
- ✅ macOS system

## 🔨 Building Kodi (If You Need a TPK)

Since you don't have a TPK package yet, you have two options:

### Option A: Use Tizen Emulator (Faster for Testing)

Test on an emulator first before building for real hardware:

```bash
# See the emulator guide
cat tools/tizen/EMULATOR_GUIDE.md
```

### Option B: Build for Real TV (Takes 1-2 Hours)

```bash
# 1. Configure dependencies
cd tools/depends
./bootstrap
./configure --host=arm-tizen-linux-gnueabi --with-tizen-sdk=$HOME/tizen-studio

# 2. Build dependencies (this takes a while)
make -j$(sysctl -n hw.ncpu)

# 3. Build Kodi
cd ../..
mkdir -p build && cd build
cmake .. -DCMAKE_TOOLCHAIN_FILE=../cmake/platform/linux/tizen.cmake
make -j$(sysctl -n hw.ncpu)

# 4. Create TPK package
cd ..
./tools/tizen/create-and-sign-tpk.sh
```

**Note:** You'll need a certificate to sign the TPK. The script will guide you through creating one if needed.

## 🚀 Testing Workflow

### 1. Connect to TV

```bash
./tools/tizen/quick-test.sh
```

Or manually:

```bash
export PATH=$PATH:$HOME/tizen-studio/tools
sdb connect <YOUR_TV_IP>
sdb devices  # Should show your TV
```

### 2. Install Kodi

```bash
# If you have a TPK file
sdb install kodi-tizen-21.0.0.tpk

# Or use the deployment script
./tools/tizen/deploy-and-verify.sh <YOUR_TV_IP>
```

### 3. Launch and Monitor

```bash
# Launch Kodi
sdb shell app_launcher -s org.xbmc.kodi

# In another terminal, watch logs
sdb dlog KODI:V
```

### 4. Test on TV

Use your Samsung TV remote to:
- Navigate menus (arrow keys)
- Select items (OK button)
- Go back (Back button)
- Play videos
- Adjust volume
- Change settings

## 📊 What to Test

### Critical Tests
- [ ] App launches without crashing
- [ ] UI is visible and readable
- [ ] Remote control works
- [ ] Can navigate all menus
- [ ] Video playback works
- [ ] Audio works

### Additional Tests
- [ ] Settings persist after restart
- [ ] Network connectivity works
- [ ] Can browse files
- [ ] Seeking in videos works
- [ ] Volume controls work

## 🐛 Troubleshooting

### Can't Connect to TV

```bash
# Check if TV is reachable
ping <YOUR_TV_IP>

# Restart SDB
sdb kill-server
sdb start-server
sdb connect <YOUR_TV_IP>
```

### App Won't Launch

```bash
# Check if installed
sdb shell pkginfo --listpkg | grep kodi

# Check logs for errors
sdb dlog KODI:E

# Try launching again
sdb shell app_launcher -s org.xbmc.kodi
```

### Black Screen

```bash
# Check for Wayland/EGL errors
sdb dlog | grep -i "wayland\|egl\|error"

# Check if process is running
sdb shell ps | grep kodi
```

## 📚 Documentation

All the guides you need:

- **Pre-Flight Checklist:** `tools/tizen/PRE_FLIGHT_CHECKLIST.md`
- **Full Connection Guide:** `tools/tizen/TV_CONNECTION_GUIDE.md`
- **Developer Mode:** `tools/tizen/DEVELOPER_MODE_GUIDE.md`
- **Build Instructions:** `docs/README.Tizen.md`
- **Platform Notes:** `docs/TIZEN_PLATFORM_NOTES.md`
- **Crash Logging:** `tools/tizen/CRASH_LOGGING_GUIDE.md`

## 🎬 Next Steps

1. **Read the Pre-Flight Checklist:**
   ```bash
   cat tools/tizen/PRE_FLIGHT_CHECKLIST.md
   ```

2. **Get your TV's IP address** from TV settings

3. **Enable Developer Mode** on your TV

4. **Run the quick test script:**
   ```bash
   ./tools/tizen/quick-test.sh
   ```

5. **Follow the interactive prompts**

## 💡 Tips

- Keep logs running in a separate terminal while testing
- Test with simple video files first (MP4, H.264)
- If something doesn't work, check the logs immediately
- Save logs to a file for later analysis: `sdb dlog KODI:V > logs.txt`
- The emulator is great for quick testing before deploying to real hardware

## ❓ Need Help?

If you run into issues:

1. Check the logs: `sdb dlog KODI:V`
2. Look for errors: `sdb dlog KODI:E`
3. Review the troubleshooting section in `tools/tizen/TV_CONNECTION_GUIDE.md`
4. Check if the app is running: `sdb shell ps | grep kodi`

## 🎉 Ready?

Start here:

```bash
./tools/tizen/quick-test.sh
```

Good luck! 🚀
