# ✅ SDB Setup Complete!

## What Was Done

SDB (Smart Development Bridge) has been configured on your Mac!

- ✅ Found Tizen Studio at: `~/tizen-studio`
- ✅ Found SDB at: `~/tizen-studio/tools/sdb`
- ✅ Added to PATH in `~/.zshrc`
- ✅ SDB version: 4.2.36

---

## 🚀 Quick Start

### For Current Terminal Session:

Run this command to use SDB immediately:

```bash
export PATH="$PATH:$HOME/tizen-studio/tools"
```

### For All Future Terminal Sessions:

The PATH has been added to your `~/.zshrc` file. Either:

**Option A: Restart your terminal**

**Option B: Reload the config:**
```bash
source ~/.zshrc
```

---

## ✅ Verify SDB Works

```bash
sdb version
```

You should see:
```
Smart Development Bridge version 4.2.36
```

---

## 📺 Now Install Kodi to TV

### Method 1: Automated (Recommended)

```bash
# First, make SDB available in current session
export PATH="$PATH:$HOME/tizen-studio/tools"

# Then run the installer
./install-to-tv.sh
```

### Method 2: Manual

```bash
# Make SDB available
export PATH="$PATH:$HOME/tizen-studio/tools"

# Connect to TV (replace with your TV's IP)
sdb connect 192.168.1.100

# Verify connection
sdb devices

# Install Kodi
sdb install build/kodi-tizen-*.tpk

# Launch Kodi
sdb shell app_launcher -s org.xbmc.kodi
```

---

## 📝 Common SDB Commands

```bash
# Check version
sdb version

# Connect to TV
sdb connect <TV_IP>

# List connected devices
sdb devices

# Install app
sdb install app.tpk

# Launch app
sdb shell app_launcher -s org.xbmc.kodi

# View logs
sdb dlog KODI:V

# Uninstall app
sdb uninstall org.xbmc.kodi

# Disconnect
sdb disconnect <TV_IP>

# Kill SDB server (if having issues)
sdb kill-server
sdb start-server
```

---

## 🔧 Troubleshooting

### "sdb: command not found" in New Terminal

**Solution:** Restart your terminal or run:
```bash
source ~/.zshrc
```

### "sdb: command not found" After Restart

**Solution:** Manually add to PATH:
```bash
export PATH="$PATH:$HOME/tizen-studio/tools"
```

Then check your `~/.zshrc` file has this line:
```bash
export PATH="$PATH:$HOME/tizen-studio/tools"
```

### Can't Connect to TV

See `INSTALL_TO_TV.md` for TV connection troubleshooting.

---

## 📚 Next Steps

1. **Enable Developer Mode on your TV** (see `INSTALL_TO_TV.md`)
2. **Run the installer:**
   ```bash
   export PATH="$PATH:$HOME/tizen-studio/tools"
   ./install-to-tv.sh
   ```
3. **Or follow manual steps** in `INSTALL_TO_TV.md`

---

## 🎉 You're Ready!

SDB is now configured. You can install Kodi to your Samsung TV!

**Quick command to get started:**

```bash
export PATH="$PATH:$HOME/tizen-studio/tools" && ./install-to-tv.sh
```
