# 🎯 Simple Instructions - Where to Run Commands

## ❌ You Just Tried This (WRONG):

You ran the command on your **Mac terminal** (outside the container):
```
benjerome@Mac Kodi % chmod +x /workspace/container-build-as-root.sh
```

This doesn't work because `/workspace` only exists **inside** the container!

---

## ✅ What You Need to Do (CORRECT):

### Option 1: Go Back to Your Container Terminal

Look for the terminal window that shows:
```
root@78b72566c034:/workspace#
```

That's your **container terminal**. In that window, run:
```bash
chmod +x /workspace/container-build-as-root.sh && /workspace/container-build-as-root.sh
```

---

### Option 2: Attach to Container from Mac

If you lost the container terminal, **on your Mac** run:

```bash
./attach-to-container.sh
```

This will connect you to the container. Then run the build command.

---

### Option 3: Manual Attach

**On your Mac:**
```bash
podman exec -it 78b72566c034 bash
```

**Then inside the container:**
```bash
chmod +x /workspace/container-build-as-root.sh && /workspace/container-build-as-root.sh
```

---

## 📍 How to Tell Where You Are

### On Your Mac:
```
benjerome@Mac Kodi %
```
- You see your username and "Mac"
- You're in `/Users/benjerome/...`

### Inside Container:
```
root@78b72566c034:/workspace#
```
- You see "root@" and a long ID
- You're in `/workspace`

---

## 🚀 Quick Start

**Right now, on your Mac, run:**
```bash
./attach-to-container.sh
```

**Then inside the container, run:**
```bash
chmod +x /workspace/container-build-as-root.sh && /workspace/container-build-as-root.sh
```

That's it!

---

## 🔄 Alternative: Start Fresh

If you want to rebuild the container properly:

**1. On Mac - Exit container:**
```bash
# In container terminal, type:
exit
```

**2. On Mac - Rebuild:**
```bash
./rebuild-container.sh
```

**3. On Mac - Start new container:**
```bash
podman run --platform linux/amd64 -v $(pwd):/workspace:Z -it localhost/kodi-tizen-builder
```

**4. Inside new container:**
```bash
chmod +x /workspace/container-build.sh && /workspace/container-build.sh
```

---

## 📝 Summary

- **Mac terminal** = Run `./attach-to-container.sh`
- **Container terminal** = Run the build script
- Files are shared between Mac and container via `/workspace`
