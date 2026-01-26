# 🏗️ Local Build Guide - Fixed and Ready

## Issues Found and Fixed

### Problems Identified:
1. ❌ Container running as root (Tizen SDK won't work)
2. ❌ Wrong working directory (`/home/builder` instead of `/workspace`)
3. ❌ Permission issues with volume mounts
4. ❌ Python version mismatch (Ubuntu 22.04 has Python 3.10, need 3.8)
5. ❌ Build scripts not optimized for container environment

### Solutions Implemented:
1. ✅ Fixed Containerfile with non-root `builder` user (UID 1000)
2. ✅ Correct working directory (`/workspace`)
3. ✅ Proper volume mount with SELinux labels (`:Z`)
4. ✅ Ubuntu 20.04 with Python 3.8
5. ✅ Optimized build script that handles all steps
6. ✅ Persistent container that can be reused

---

## 🚀 Quick Start (One Command)

**On your Mac, run:**

```bash
./setup-local-build.sh
```

This will:
- Stop and remove old container
- Rebuild container image with fixes
- Start new container properly configured
- Set up build environment
- Give you instructions to start building

**Time:** 2-3 minutes for setup

---

## 📋 What the Setup Does

### 1. Builds Proper Container
- Ubuntu 20.04 (Python 3.8 compatible)
- Non-root `builder` user (UID 1000)
- All build dependencies installed
- Correct working directory

### 2. Starts Container Correctly
- Mounts your workspace to `/workspace`
- Runs as `builder` user (not root)
- Named `kodi-tizen-build` for easy access
- Keeps running in background

### 3. Prepares Build Script
- Installs Tizen SDK
- Builds dependencies
- Compiles Kodi
- Creates TPK package
- All in one automated script

---

## 🎯 After Setup - Start Building

### Step 1: Attach to Container
```bash
podman exec -it kodi-tizen-build bash
```

### Step 2: Run Build Script
```bash
~/build-kodi.sh
```

### Step 3: Wait
- 10 min: Tizen SDK install
- 30-60 min: Dependencies
- 30-60 min: Kodi build
- 5 min: TPK creation
- **Total: 60-90 minutes**

### Step 4: Get TPK
```bash
# Exit container
exit

# Find TPK on your Mac
ls -lh build/*.tpk
```

---

## 🔄 Reusing the Container

The container persists! You don't need to rebuild everything each time.

### To Stop Container:
```bash
podman stop kodi-tizen-build
```

### To Restart and Build Again:
```bash
podman start kodi-tizen-build
podman exec -it kodi-tizen-build bash
~/build-kodi.sh  # Skips already-built components
```

### To Rebuild from Scratch:
```bash
# Inside container
rm -rf ~/tizen-studio ~/kodi-tizen-deps
~/build-kodi.sh
```

---

## 📁 File Locations

### On Your Mac:
- Source code: `./` (current directory)
- Build output: `./build/`
- TPK files: `./build/*.tpk`

### Inside Container:
- Workspace: `/workspace` (same as your Mac directory)
- Tizen SDK: `/home/builder/tizen-studio`
- Dependencies: `/home/builder/kodi-tizen-deps`
- Build script: `/home/builder/build-kodi.sh`

---

## 🛠️ Troubleshooting

### Container Won't Start:
```bash
# Remove old containers
podman rm -f $(podman ps -aq)

# Rebuild
./setup-local-build.sh
```

### Build Fails:
```bash
# Inside container, check logs
less ~/kodi-tizen-deps/build.log
less /workspace/build/build.log

# Clean and retry
rm -rf ~/kodi-tizen-deps/.built
~/build-kodi.sh
```

### Permission Errors:
```bash
# On Mac, fix permissions
chmod -R u+w .

# Rebuild container
./setup-local-build.sh
```

---

## 📊 Comparison: Local vs GitHub Actions

| Feature | Local Build | GitHub Actions |
|---------|-------------|----------------|
| **Setup Time** | 2-3 min | 0 min (automatic) |
| **Build Time** | 60-90 min | 60-90 min |
| **Your Resources** | Uses your Mac | Uses GitHub servers |
| **Customization** | Full control | Limited |
| **Debugging** | Easy | Harder |
| **Cost** | Free | Free |
| **Reusability** | Container persists | Rebuilds each time |

**Recommendation:** Use local build for development and testing. Use GitHub Actions for final releases.

---

## ✅ Verification Checklist

After running `./setup-local-build.sh`, verify:

- [ ] Container is running: `podman ps | grep kodi-tizen-build`
- [ ] User is `builder`: `podman exec kodi-tizen-build whoami`
- [ ] Python 3.8: `podman exec kodi-tizen-build python3 --version`
- [ ] Workspace mounted: `podman exec kodi-tizen-build ls /workspace`
- [ ] Build script exists: `podman exec kodi-tizen-build ls ~/build-kodi.sh`

All should show success!

---

## 🎉 Ready to Build!

Run this now:

```bash
./setup-local-build.sh
```

Then follow the instructions it gives you!
