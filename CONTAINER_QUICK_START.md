# 🚀 Container Quick Start Guide

## You Are Here: Inside the Podman Container

Your container is running and ready to build Kodi for Tizen!

---

## ⚡ Quick Start (Recommended)

Copy and paste this single command:

```bash
chmod +x /workspace/container-build.sh && /workspace/container-build.sh
```

That's it! The script will:
- ✅ Install Tizen SDK
- ✅ Build all dependencies  
- ✅ Compile Kodi
- ✅ Create TPK package

**Time:** 60-90 minutes  
**Output:** `kodi-tizen-*.tpk` file

---

## 📊 What's Happening?

The build process has 4 stages:

| Stage | Task | Time | Status |
|-------|------|------|--------|
| 1 | Install Tizen SDK | ~10 min | Downloading & installing |
| 2 | Build Dependencies | ~30-60 min | Compiling libraries |
| 3 | Build Kodi | ~30-60 min | Compiling Kodi |
| 4 | Create TPK | ~5 min | Packaging |

---

## 👀 Monitor Progress

The script shows progress in real-time. You'll see:

```
==========================================
Step 1/4: Installing Tizen SDK
==========================================

Downloading Tizen SDK installer...
✓ Download Tizen SDK
Installing Tizen SDK (this may take 5-10 minutes)...
✓ Install Tizen SDK
✓ Tizen SDK installed successfully
```

---

## 🔍 Check Logs (Optional)

Open another terminal on your Mac and run:

```bash
# Find your container ID
podman ps

# Attach to container
podman exec -it <container_id> bash

# Watch build logs
tail -f /workspace/tools/depends/build.log
# or
tail -f /workspace/build/build.log
```

---

## ✅ When Complete

You'll see:

```
==========================================
Build Complete! 🎉
==========================================

TPK files created:
-rw-r--r-- 1 builder builder 150M Jan 25 12:34 /workspace/build/kodi-tizen-21.0-arm.tpk

Location on host machine:
  /path/to/your/kodi/build/kodi-tizen-21.0-arm.tpk
```

---

## 📦 Next Steps

1. **Exit the container:**
   ```bash
   exit
   ```

2. **Find TPK on your Mac:**
   ```bash
   ls -lh build/*.tpk
   ```

3. **Install on Samsung TV:**
   ```bash
   # Enable Developer Mode on TV first (see DEVELOPER_MODE_GUIDE.md)
   sdb connect <YOUR_TV_IP>:26101
   sdb install build/kodi-tizen-*.tpk
   sdb shell app_launcher -s org.xbmc.kodi
   ```

---

## ❓ Troubleshooting

### Build fails?
- Check logs: `less /workspace/tools/depends/build.log`
- Clean and retry: `cd /workspace/tools/depends && make clean && make`

### No TPK file created?
- Check: `find /workspace -name "*.tpk"`
- Try manual: `cd /workspace && bash tools/tizen/packaging/package.sh`

### Need to restart?
- The build caches progress, so you can re-run the script
- Already-built components will be skipped

---

## 📚 Documentation

- `CONTAINER_BUILD_INSTRUCTIONS.md` - Detailed build steps
- `docs/README.Tizen.md` - Complete Tizen build guide
- `tools/tizen/DEVELOPER_MODE_GUIDE.md` - Enable dev mode on TV
- `tools/tizen/TV_CONNECTION_GUIDE.md` - Connect to your TV
- `TESTING_GUIDE.md` - Test your build

---

## 🎯 Ready?

Run this now:

```bash
chmod +x /workspace/container-build.sh && /workspace/container-build.sh
```

Then grab a coffee ☕ - this will take about an hour!
