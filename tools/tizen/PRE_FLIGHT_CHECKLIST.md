# Pre-Flight Checklist - Testing Kodi on Samsung TV

Before you start testing, make sure you have everything ready:

## ✅ Prerequisites Checklist

### Hardware
- [ ] Samsung Smart TV (2020 or newer model)
- [ ] TV is powered on
- [ ] TV and computer are on the same Wi-Fi network

### Software on Your Mac
- [x] Tizen Studio installed at `~/tizen-studio/`
- [x] SDB (Smart Development Bridge) available
- [ ] Kodi source code (you have this)
- [ ] Kodi built for Tizen (we'll check this)

### TV Setup
- [ ] Developer Mode enabled on TV
- [ ] TV has been rebooted after enabling Developer Mode
- [ ] You know your TV's IP address

### Optional (for building)
- [ ] Tizen SDK configured
- [ ] Build dependencies installed
- [ ] Certificate created for signing

## 🚀 Quick Start (3 Steps)

### Step 1: Find Your TV's IP Address

**On your Samsung TV:**
1. Press the **Home** button on your remote
2. Navigate to **Settings** → **General** → **Network** → **Network Status**
3. Write down the IP address (e.g., `192.168.1.100`)

**Your TV IP:** ________________

### Step 2: Enable Developer Mode

**If not already enabled:**
1. Press **Home** button
2. Go to **Apps**
3. Quickly press: **1 2 3 4 5** on the number pad
4. Toggle **Developer Mode** to **ON**
5. Enter your Mac's IP address when prompted
6. **Reboot your TV** (important!)

**Your Mac's IP:** You can find this in System Preferences → Network

### Step 3: Run the Connection Helper

```bash
# From the Kodi project root directory
./tools/tizen/quick-test.sh
```

This will:
- ✓ Check if SDB is available
- ✓ Connect to your TV
- ✓ Verify the connection
- ✓ Show you options to install/test Kodi

## 📋 What You'll Need to Provide

When you run the script, you'll be asked for:

1. **TV IP Address** - from Step 1 above
2. **Confirm Developer Mode is enabled** - from Step 2 above

## 🔧 If You Need to Build Kodi First

If you don't have a TPK package yet, you'll need to build Kodi:

```bash
# This takes 1-2 hours
cd tools/depends
./bootstrap
./configure --host=arm-tizen-linux-gnueabi --with-tizen-sdk=$HOME/tizen-studio
make -j$(sysctl -n hw.ncpu)

# Then build Kodi
cd ../..
mkdir -p build && cd build
cmake .. -DCMAKE_TOOLCHAIN_FILE=../cmake/platform/linux/tizen.cmake
make -j$(sysctl -n hw.ncpu)

# Create TPK package
cd ..
./tools/tizen/create-and-sign-tpk.sh
```

**Note:** For quick testing, you might want to use the Tizen emulator first (see `tools/tizen/EMULATOR_GUIDE.md`)

## 🎯 Testing Checklist

Once Kodi is installed on your TV, test these:

### Basic Tests
- [ ] App launches successfully
- [ ] UI is visible and properly rendered
- [ ] Remote control navigation works (up/down/left/right)
- [ ] Select button works
- [ ] Back button works

### Media Tests
- [ ] Can browse to video files
- [ ] Video playback starts
- [ ] Can pause/resume video
- [ ] Can seek forward/backward
- [ ] Audio is working
- [ ] Volume controls work

### Settings Tests
- [ ] Can access settings menu
- [ ] Can change a setting
- [ ] Settings persist after app restart

### Network Tests (if applicable)
- [ ] Can access network shares
- [ ] Can stream from network
- [ ] Network status is detected

## 📊 Monitoring and Logs

While testing, keep logs running in a separate terminal:

```bash
# Add SDB to PATH
export PATH=$PATH:$HOME/tizen-studio/tools

# Connect to TV
sdb connect <YOUR_TV_IP>

# View live logs
sdb dlog KODI:V

# Or save logs to file
sdb dlog KODI:V > kodi-test-logs.txt
```

## 🆘 Common Issues

| Problem | Solution |
|---------|----------|
| Can't find TV IP | Check TV: Settings → Network → Network Status |
| Can't connect via SDB | Enable Developer Mode, reboot TV |
| SDB command not found | Run: `export PATH=$PATH:$HOME/tizen-studio/tools` |
| App won't install | Check certificate, verify TPK is signed |
| Black screen on launch | Check logs: `sdb dlog KODI:E` |
| Remote not working | Check logs for input events |

## 📚 Additional Resources

- **Full Connection Guide:** `tools/tizen/TV_CONNECTION_GUIDE.md`
- **Developer Mode Setup:** `tools/tizen/DEVELOPER_MODE_GUIDE.md`
- **Build Instructions:** `docs/README.Tizen.md`
- **Troubleshooting:** `docs/TIZEN_PLATFORM_NOTES.md`

## ✨ Ready to Start?

Run this command to begin:

```bash
./tools/tizen/quick-test.sh
```

The script will guide you through the rest!
