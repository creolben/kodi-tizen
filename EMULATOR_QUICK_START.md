# Emulator Quick Start Guide

## 🎉 Good News!

You already have everything you need to test Kodi on the emulator:

✅ Tizen Studio installed
✅ Emulator installed  
✅ Emulator instances created:
   - T-9.0-x86_64
   - T-9.0-x86
   - T-samsung-9.0-x86

## 🚀 Quick Start (One Command)

```bash
./tools/tizen/setup-emulator.sh
```

This script will:
1. Check your emulator installation
2. Show you available emulators
3. Launch the emulator you select
4. Connect via SDB
5. Give you options to build/install/test Kodi

## 📋 What the Script Will Do

### Step 1: Select Emulator
You'll see your 3 emulators and can choose which one to use.

**Recommendation:** Use `T-samsung-9.0-x86` (it's the Samsung TV emulator)

### Step 2: Launch Emulator
The script will launch the emulator and wait for it to boot (30-60 seconds).

### Step 3: Choose Action
You'll get these options:
1. **Build Kodi for emulator** - Takes 1-2 hours, builds x86 version
2. **Install Kodi TPK** - If you already have a TPK file
3. **Launch Kodi** - If Kodi is already installed
4. **View logs** - See what's happening
5. **Open emulator window** - See the emulator GUI
6. **Exit** - Leave emulator running

## 🎯 Recommended Workflow

### First Time Setup

1. **Launch the emulator:**
   ```bash
   ./tools/tizen/setup-emulator.sh
   ```

2. **Select:** `T-samsung-9.0-x86` (option 3)

3. **Wait** for emulator to boot (you'll see dots: ........)

4. **Choose option 1** to build Kodi for emulator

5. **Wait** 1-2 hours for build to complete

6. **Run script again** and choose option 2 to install

7. **Choose option 3** to launch Kodi

### Testing Workflow

Once Kodi is installed:

```bash
# Terminal 1: Launch emulator and Kodi
./tools/tizen/setup-emulator.sh
# Select emulator
# Choose option 3 (Launch Kodi)

# Terminal 2: Watch logs
export PATH=$PATH:$HOME/tizen-studio/tools
sdb devices  # Get emulator ID
sdb -s emulator-26101 dlog KODI:V
```

## 🎮 Using the Emulator

### Keyboard Controls

| Key | Function |
|-----|----------|
| **Arrow Keys** | Navigate (Up/Down/Left/Right) |
| **Enter** | Select/OK |
| **Escape** | Back |
| **Home** | Home button |
| **F2** | Volume Up |
| **F3** | Volume Down |

### Mouse Controls

- Click to select items
- Scroll wheel for volume

## 🔧 Manual Commands (If You Prefer)

### Launch Emulator Manually

```bash
# Add to PATH
export PATH=$PATH:$HOME/tizen-studio/tools/emulator/bin

# List emulators
em-cli list-vm

# Launch specific emulator
em-cli launch --name T-samsung-9.0-x86

# Wait for boot, then connect
export PATH=$PATH:$HOME/tizen-studio/tools
sdb connect localhost:26101
sdb devices
```

### Install Kodi Manually

```bash
# If you have a TPK file
sdb -s emulator-26101 install kodi-tizen-21.0.0.tpk

# Launch Kodi
sdb -s emulator-26101 shell app_launcher -s org.xbmc.kodi

# View logs
sdb -s emulator-26101 dlog KODI:V
```

## 📊 Monitoring

### Check if Emulator is Running

```bash
export PATH=$PATH:$HOME/tizen-studio/tools
sdb devices

# Should show something like:
# List of devices attached
# emulator-26101    device    emulator-26101
```

### Check if Kodi is Installed

```bash
sdb -s emulator-26101 shell pkginfo --listpkg | grep kodi
```

### Check if Kodi is Running

```bash
sdb -s emulator-26101 shell ps | grep kodi
```

### View Logs

```bash
# All Kodi logs
sdb -s emulator-26101 dlog KODI:V

# Only errors
sdb -s emulator-26101 dlog KODI:E

# Save to file
sdb -s emulator-26101 dlog KODI:V > emulator-logs.txt
```

## 🐛 Troubleshooting

### Emulator Won't Start

```bash
# Check if virtualization is enabled
sysctl kern.hv_support

# Should return: kern.hv_support: 1
```

If it returns 0, you need to enable virtualization in your Mac's BIOS/firmware.

### Can't Connect via SDB

```bash
# Restart SDB
export PATH=$PATH:$HOME/tizen-studio/tools
sdb kill-server
sdb start-server

# Connect manually
sdb connect localhost:26101

# Check connection
sdb devices
```

### Emulator is Slow

1. Close other applications
2. Allocate more RAM to emulator (edit in Emulator Manager)
3. Use lower resolution (1920x1080 instead of 4K)

### Build Fails

Check the build guide for detailed instructions:
```bash
cat docs/README.Tizen.md
```

## 📚 More Information

- **Full Emulator Guide:** `tools/tizen/EMULATOR_GUIDE.md`
- **Build Instructions:** `docs/README.Tizen.md`
- **Platform Notes:** `docs/TIZEN_PLATFORM_NOTES.md`

## ✨ Ready to Start?

Run this command:

```bash
./tools/tizen/setup-emulator.sh
```

The script will guide you through everything!

## 💡 Pro Tips

1. **Use T-samsung-9.0-x86** - It's the Samsung TV emulator
2. **Keep logs running** in a separate terminal while testing
3. **Test simple videos first** - Use MP4 with H.264 codec
4. **Save your work** - The emulator state persists between launches
5. **Build takes time** - First build is 1-2 hours, be patient!

## 🎬 Next Steps After Installation

Once Kodi is running in the emulator:

1. **Test UI Navigation** - Use arrow keys and Enter
2. **Test Video Playback** - Copy a test video and play it
3. **Test Settings** - Change settings and verify they persist
4. **Check Logs** - Look for any errors or warnings
5. **Test Remote Control** - Verify all keyboard shortcuts work

Good luck! 🚀
