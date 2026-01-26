# 🚀 Quick Start: Build Kodi TPK Now

## Current Status
- ✅ Container is running (ID: fbe0eaf11081)
- ❌ Build hasn't been executed yet
- ⏳ GitHub Actions is queued (not started)

## Start Local Build (Recommended)

### Step 1: Attach to Container
```bash
podman exec -it fbe0eaf11081 bash
```

You'll see:
```
builder@fbe0eaf11081:/workspace$
```

### Step 2: Start the Build
```bash
~/build-kodi.sh
```

This will:
1. Install Tizen SDK (~10 min)
2. Build dependencies (~30-60 min)
3. Build Kodi (~30-60 min)
4. Create TPK (~5 min)

**Total time: 60-90 minutes**

### Step 3: Monitor Progress

The script will show progress. You can also monitor in another terminal:
```bash
# In a new terminal on your Mac
podman exec fbe0eaf11081 tail -f /home/builder/kodi-tizen-deps/build.log
```

### Step 4: When Complete

You'll see:
```
==========================================
Build Complete! 🎉
==========================================

TPK files:
-rw-r--r-- 1 builder builder 150M ... kodi-tizen-21.0-arm.tpk
```

Exit the container:
```bash
exit
```

### Step 5: Find Your TPK

```bash
ls -lh build/*.tpk
```

### Step 6: Install to TV

```bash
./install-kodi-now.sh
```

## Alternative: Wait for GitHub Actions

If you prefer to wait for GitHub Actions:

1. Check status: https://github.com/creolben/kodi-tizen/actions
2. Wait for green checkmark ✓ (60-90 min)
3. Download TPK from Artifacts section
4. Run: `./install-kodi-now.sh`

## Quick Commands

**Start build:**
```bash
podman exec -it fbe0eaf11081 bash
~/build-kodi.sh
```

**Check status anytime:**
```bash
./check-build-status.sh
```

**Monitor build log:**
```bash
podman exec fbe0eaf11081 tail -f /home/builder/kodi-tizen-deps/build.log
```

---

**Recommendation:** Start the local build now since GitHub Actions is still queued!
