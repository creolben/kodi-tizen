# Quick Setup - Fix TIZEN_SDK Error

## The Error You're Seeing

```
[✗] TIZEN_SDK environment variable not set
Please set TIZEN_SDK to your Tizen Studio installation path
```

## Quick Fix (Run These Commands)

```bash
# Set the environment variable
export TIZEN_SDK=$HOME/tizen-studio

# Add tools to PATH
export PATH=$PATH:$TIZEN_SDK/tools

# Verify it's set
echo $TIZEN_SDK
```

You should see: `/Users/benjerome/tizen-studio`

## Now Try Again

```bash
./tools/tizen/quick-test.sh
```

## Make It Permanent (Optional)

To avoid setting this every time, add it to your shell profile:

### For zsh (default on macOS):

```bash
echo 'export TIZEN_SDK=$HOME/tizen-studio' >> ~/.zshrc
echo 'export PATH=$PATH:$TIZEN_SDK/tools' >> ~/.zshrc
source ~/.zshrc
```

### For bash:

```bash
echo 'export TIZEN_SDK=$HOME/tizen-studio' >> ~/.bash_profile
echo 'export PATH=$PATH:$TIZEN_SDK/tools' >> ~/.bash_profile
source ~/.bash_profile
```

## Alternative: Use the Setup Script

I created a setup script for you:

```bash
# Run this (note the 'source' command):
source setup-env.sh
```

The `source` command is important - it sets the variables in your current shell.

## Verify Setup

After setting the variables, verify they're correct:

```bash
# Check TIZEN_SDK
echo $TIZEN_SDK
# Should show: /Users/benjerome/tizen-studio

# Check if SDB is available
which sdb
# Should show: /Users/benjerome/tizen-studio/tools/sdb

# Test SDB
sdb version
```

## What These Variables Do

- **TIZEN_SDK**: Points to your Tizen Studio installation
  - Used by build scripts to find SDK tools
  - Required for cross-compilation

- **PATH**: Adds Tizen tools to your command path
  - Lets you run `sdb` from anywhere
  - Lets you run emulator commands

## Next Steps

Once the environment is set:

1. **For TV testing:**
   ```bash
   ./tools/tizen/quick-test.sh
   ```

2. **For building:**
   ```bash
   cd tools/depends
   ./configure --host=arm-tizen-linux-gnueabi --with-tizen-sdk=$TIZEN_SDK
   ```

## Troubleshooting

### "TIZEN_SDK still not set"

Make sure you used `export`:
```bash
export TIZEN_SDK=$HOME/tizen-studio
```

Not just:
```bash
TIZEN_SDK=$HOME/tizen-studio  # Wrong - missing 'export'
```

### "sdb: command not found"

Add tools to PATH:
```bash
export PATH=$PATH:$HOME/tizen-studio/tools
```

### "Tizen Studio not found"

Verify the path exists:
```bash
ls -la ~/tizen-studio
```

If it's in a different location, adjust the path:
```bash
export TIZEN_SDK=/path/to/your/tizen-studio
```

## Summary

**Quick fix (run these 3 commands):**

```bash
export TIZEN_SDK=$HOME/tizen-studio
export PATH=$PATH:$TIZEN_SDK/tools
./tools/tizen/quick-test.sh
```

That's it! 🚀
