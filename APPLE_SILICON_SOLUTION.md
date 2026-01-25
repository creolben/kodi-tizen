# Testing Kodi on Apple Silicon Mac (M4)

## 🚨 Important Discovery

You have an **Apple M4 Mac** (Apple Silicon). The Tizen emulator requires Intel HAXM, which **does not work on Apple Silicon Macs**.

```
Your Mac: Apple M4 (ARM architecture)
Tizen Emulator: Requires Intel HAXM (x86 only)
Result: Emulator cannot run on your Mac
```

## ✅ Solution: Test on Real Samsung TV

Since the emulator won't work on your M4 Mac, you'll need to test on a real Samsung TV. This is actually better for final testing anyway!

### Why This is Good News

- ✅ Real hardware testing is more accurate
- ✅ True performance measurements
- ✅ Actual remote control experience
- ✅ Real HDR and audio capabilities
- ✅ No emulator limitations

## 🚀 Quick Start: Connect to Your TV

### Step 1: Get Your TV Ready

1. **Find TV's IP Address:**
   - Press **Home** on remote
   - Go to **Settings** → **General** → **Network** → **Network Status**
   - Write down the IP (e.g., `192.168.1.100`)

2. **Enable Developer Mode:**
   - Press **Home** on remote
   - Go to **Apps**
   - Quickly press: **1 2 3 4 5**
   - Toggle **Developer Mode** to **ON**
   - Enter your Mac's IP address
   - **Reboot your TV** (important!)

### Step 2: Connect to TV

```bash
# Run the connection helper
./tools/tizen/quick-test.sh
```

This will:
- Check if SDB is available
- Connect to your TV
- Guide you through installation
- Help you test Kodi

### Step 3: What You'll Need

Since you can't use the emulator, you have two options:

#### Option A: Build for ARM (Real TV)

Build Kodi for ARM architecture (what Samsung TVs use):

```bash
cd tools/depends
./bootstrap
./configure --host=arm-tizen-linux-gnueabi --with-tizen-sdk=$HOME/tizen-studio
make -j$(sysctl -n hw.ncpu)

cd ../..
mkdir -p build && cd build
cmake .. -DCMAKE_TOOLCHAIN_FILE=../cmake/platform/linux/tizen.cmake
make -j$(sysctl -n hw.ncpu)

cd ..
./tools/tizen/create-and-sign-tpk.sh
```

**Time:** 1-2 hours for first build

#### Option B: Use Pre-built TPK (If Available)

If someone has already built Kodi for Tizen, you can use that TPK file directly.

## 📋 Testing Workflow

### 1. Connect to TV

```bash
# Add SDB to PATH
export PATH=$PATH:$HOME/tizen-studio/tools

# Connect to TV (replace with your TV's IP)
sdb connect 192.168.1.100

# Verify connection
sdb devices
```

### 2. Install Kodi

```bash
# Install TPK
sdb install kodi-tizen-21.0.0.tpk

# Launch Kodi
sdb shell app_launcher -s org.xbmc.kodi
```

### 3. Monitor Logs

```bash
# In a separate terminal
sdb dlog KODI:V
```

### 4. Test on TV

Use your Samsung TV remote to:
- Navigate menus
- Play videos
- Change settings
- Test all features

## 🎯 Advantages of Testing on Real TV

### What You Get

1. **Real Performance** - Actual hardware acceleration
2. **True HDR** - Real HDR10/Dolby Vision support
3. **Actual Remote** - Real remote control experience
4. **Real Audio** - True audio output and routing
5. **Network Testing** - Real network stack
6. **Accurate Results** - No emulator limitations

### What You Can Test

- ✅ Video playback (all codecs)
- ✅ Audio output
- ✅ HDR content
- ✅ 4K/8K resolution
- ✅ Remote control responsiveness
- ✅ Network streaming
- ✅ UI performance
- ✅ Long-running stability
- ✅ Real-world user experience

## 🔧 Alternative: Use Intel Mac or Cloud VM

If you really need an emulator for development:

### Option 1: Use Another Mac

If you have access to an Intel Mac:
- The emulator will work there
- Follow the emulator guide
- Use for quick development iterations

### Option 2: Cloud VM with Intel

Use a cloud service with Intel processors:

**AWS EC2:**
```bash
# Launch an Ubuntu instance with Intel processor
# Install Tizen Studio
# Run emulator in cloud
# Connect via VNC or X11 forwarding
```

**Google Cloud:**
```bash
# Create Compute Engine instance
# Choose Intel processor
# Install Tizen Studio
# Use remote desktop
```

### Option 3: Docker/VM (Limited)

You could try running an Intel VM, but:
- Performance will be poor (nested virtualization)
- May not work at all
- Not recommended

## 📚 Documentation for TV Testing

All the guides you need:

- **TV Connection:** `tools/tizen/TV_CONNECTION_GUIDE.md`
- **Quick Test:** `tools/tizen/quick-test.sh`
- **Developer Mode:** `tools/tizen/DEVELOPER_MODE_GUIDE.md`
- **Build Guide:** `docs/README.Tizen.md`
- **Deployment:** `tools/tizen/deploy-and-verify.sh`

## 🎬 Recommended Workflow

### For Development

1. **Write code** on your M4 Mac
2. **Build for ARM** (Samsung TV architecture)
3. **Deploy to TV** via SDB
4. **Test on TV** with real hardware
5. **View logs** via SDB
6. **Iterate** and repeat

### For Quick Testing

1. **Make changes** to code
2. **Rebuild** (incremental builds are faster)
3. **Create TPK** (quick)
4. **Install on TV** (via SDB)
5. **Test immediately** on TV

## 💡 Pro Tips

### Speed Up Development

1. **Keep TV connected** - Leave SDB connection open
2. **Use incremental builds** - Only changed files rebuild
3. **Test frequently** - Deploy often, catch issues early
4. **Save logs** - Keep logs for debugging
5. **Use test videos** - Have sample content ready

### Debugging on TV

```bash
# Real-time logs
sdb dlog KODI:V

# Filter errors
sdb dlog KODI:E

# Save logs
sdb dlog KODI:V > tv-test-logs.txt

# Check if running
sdb shell ps | grep kodi

# Check memory usage
sdb shell top -n 1 | grep kodi
```

## ✨ Next Steps

1. **Read the TV connection guide:**
   ```bash
   cat tools/tizen/TV_CONNECTION_GUIDE.md
   ```

2. **Get your TV's IP address**

3. **Enable Developer Mode on TV**

4. **Run the connection script:**
   ```bash
   ./tools/tizen/quick-test.sh
   ```

5. **Build Kodi for ARM** (if you haven't already)

6. **Deploy and test on TV**

## 🎉 Summary

**Your Situation:**
- ✅ Apple M4 Mac (Apple Silicon)
- ❌ Emulator won't work (needs Intel)
- ✅ Real TV testing is the solution

**What to Do:**
1. Connect to your Samsung TV
2. Build Kodi for ARM architecture
3. Deploy to TV via SDB
4. Test on real hardware

**Benefits:**
- More accurate testing
- Real performance data
- Actual user experience
- No emulator limitations

**Start Here:**
```bash
./tools/tizen/quick-test.sh
```

This is actually the better approach for final testing anyway! 🚀
