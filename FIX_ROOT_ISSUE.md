# 🔧 Fix: Tizen SDK Root User Issue

## Problem

The Tizen SDK installer refuses to run as root user:
```
Do not install as 'root' user or 'su' commands.
```

## Solution: Two Options

---

## Option 1: Use Workaround Script (Quick Fix)

**In your current container (as root), run:**

```bash
chmod +x /workspace/container-build-as-root.sh && /workspace/container-build-as-root.sh
```

This script:
1. Creates a non-root `builder` user inside the container
2. Switches to that user
3. Runs the entire build process
4. Returns control to root when done

**Time:** Same as before (60-90 minutes)

---

## Option 2: Rebuild Container (Proper Fix)

**Exit your current container first:**
```bash
exit
```

**On your Mac, rebuild the container:**
```bash
chmod +x rebuild-container.sh
./rebuild-container.sh
```

**Then start the new container:**
```bash
podman run --platform linux/amd64 -v $(pwd):/workspace:Z -it localhost/kodi-tizen-builder
```

**Inside the new container (now as 'builder' user):**
```bash
chmod +x /workspace/container-build.sh && /workspace/container-build.sh
```

---

## Recommended: Option 1 (Workaround)

Since your container is already running and has downloaded the SDK, use **Option 1** to continue without rebuilding.

---

## What Changed?

The fixed `Containerfile.tizen` now:
- Uses Ubuntu 20.04 (better Tizen SDK compatibility)
- Installs Python 3.8 (required by Tizen SDK)
- Creates a non-root `builder` user
- Runs as `builder` by default

---

## Copy-Paste Command (In Container)

```bash
chmod +x /workspace/container-build-as-root.sh && /workspace/container-build-as-root.sh
```

That's it! The script handles everything.
