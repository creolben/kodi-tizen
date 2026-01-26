# 🎯 How to Get the Kodi TPK File

## Current Situation

✅ Container is running  
❌ Build hasn't been executed yet  
❌ No TPK file exists  

You have **two options** to get the TPK file:

---

## Option 1: Use GitHub Actions (Easiest - Recommended)

GitHub Actions is building Kodi automatically in the cloud.

### Check Build Status:

Go to: **https://github.com/creolben/kodi-tizen/actions**

### When Build Completes:

1. Click on the latest **successful** workflow run (green checkmark ✓)
2. Scroll down to **Artifacts** section
3. Download `kodi-tizen-*-arm.zip`
4. Unzip to get the TPK file
5. Install: `./install-kodi-now.sh`

**Time:** Build takes 60-90 minutes (runs automatically)

---

## Option 2: Build Locally in Container

Your container is ready but the build hasn't run yet.

### Step 1: Attach to Container

```bash
podman exec -it kodi-tizen-build bash
```

You should see:
```
builder@fbe0eaf11081:/workspace$
```

### Step 2: Run Build Script

```bash
~/build-kodi.sh
```

This will:
- Install Tizen SDK (~10 min)
- Build dependencies (~30-60 min)
- Build Kodi (~30-60 min)
- Create TPK (~5 min)

**Total time:** 60-90 minutes

### Step 3: Wait for Completion

You'll see progress messages. When complete:
```
==========================================
Build Complete! 🎉
==========================================

TPK files:
-rw-r--r-- 1 builder builder 150M ... kodi-tizen-21.0-arm.tpk
```

### Step 4: Exit and Find TPK

```bash
exit  # Leave container
ls -lh build/*.tpk  # Find TPK on your Mac
```

### Step 5: Install to TV

```bash
./install-kodi-now.sh
```

---

## Quick Commands

### Check Build Status Anytime:

```bash
./check-build-status.sh
```

### Start Local Build:

```bash
podman exec -it kodi-tizen-build bash
~/build-kodi.sh
```

### Check GitHub Actions:

```bash
open https://github.com/creolben/kodi-tizen/actions
```

---

## Why No TPK Yet?

The container was created but the build script inside it hasn't been run. The container is just an environment - you need to execute the build commands inside it.

Think of it like this:
- ✅ Kitchen is ready (container running)
- ❌ Haven't started cooking yet (build not executed)
- ❌ No meal ready (no TPK file)

---

## Recommendation

**Use GitHub Actions** (Option 1) - it's easier and doesn't use your Mac's resources.

Just wait for the build to complete, then download the TPK from the Artifacts section.

**Or start local build** (Option 2) if you want to build now:

```bash
podman exec -it kodi-tizen-build bash
~/build-kodi.sh
```

---

## Timeline

| Method | Time | Effort |
|--------|------|--------|
| **GitHub Actions** | 60-90 min | Just wait & download |
| **Local Build** | 60-90 min | Run command & wait |

Both take the same time, but GitHub Actions is hands-off!

---

## Next Steps

### If Using GitHub Actions:
1. Check: https://github.com/creolben/kodi-tizen/actions
2. Wait for green checkmark ✓
3. Download TPK from Artifacts
4. Run: `./install-kodi-now.sh`

### If Building Locally:
1. Run: `podman exec -it kodi-tizen-build bash`
2. Run: `~/build-kodi.sh`
3. Wait 60-90 minutes
4. Exit and run: `./install-kodi-now.sh`

---

## Check Status Anytime

```bash
./check-build-status.sh
```

This shows:
- Local TPK files (if any)
- Container status
- GitHub Actions status
- What to do next
