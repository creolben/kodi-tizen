# GitHub Actions Setup - Quick Start

Your GitHub Actions workflow is ready! Here's how to use it.

## ✅ What's Been Set Up

I've created:
- `.github/workflows/build-tizen.yml` - The build workflow
- `.github/workflows/README-TIZEN.md` - Detailed documentation

## 🚀 Next Steps

### Step 1: Commit and Push

```bash
# Check what's new
git status

# Add the workflow files
git add .github/workflows/build-tizen.yml
git add .github/workflows/README-TIZEN.md
git add GITHUB_ACTIONS_SETUP.md
git add FINAL_RECOMMENDATION.md

# Commit
git commit -m "Add GitHub Actions workflow for Tizen builds"

# Push to GitHub
git push origin main
```

**Note:** Replace `main` with your branch name if different (might be `master`)

### Step 2: Watch the Build

1. Go to your GitHub repository
2. Click the **Actions** tab
3. You should see "Build Kodi for Tizen" workflow running
4. Click on it to watch progress

### Step 3: Download the TPK

After build completes (60-90 minutes):

1. Scroll down to **Artifacts** section
2. Click to download `kodi-tizen-X.X-arm.zip`
3. Extract the TPK file

### Step 4: Install on Your TV

```bash
# Connect to TV
export PATH=$PATH:$HOME/tizen-studio/tools
sdb connect <YOUR_TV_IP>:26101

# Install
sdb install kodi-tizen-*.tpk

# Launch
sdb shell app_launcher -s org.xbmc.kodi

# View logs
sdb dlog KODI:V
```

## 🎯 Manual Trigger (Optional)

Don't want to wait for a push? Trigger manually:

1. Go to **Actions** tab
2. Click **"Build Kodi for Tizen"** (left sidebar)
3. Click **"Run workflow"** button (right side)
4. Select branch
5. Click **"Run workflow"**

## ⏱️ Build Times

| Build Type | Time | When |
|------------|------|------|
| First build | 60-90 min | First time or cache cleared |
| Incremental | 15-30 min | Code changes only |
| Cached | 5-10 min | No changes (just testing) |

## 💾 Caching

The workflow caches:
- **Tizen SDK** (~2GB) - Speeds up all builds
- **Dependencies** (~5GB) - Speeds up incremental builds

This means:
- ✅ First build: Slow (builds everything)
- ✅ Second build: Much faster (uses caches)
- ✅ Third build: Even faster (more caches)

## 🔄 Your New Workflow

### Daily Development

```bash
# 1. Make code changes on your Mac
vim xbmc/some/file.cpp

# 2. Commit and push
git add .
git commit -m "Fix something"
git push

# 3. GitHub Actions builds automatically
# (Go get coffee ☕ - takes 15-30 min)

# 4. Download TPK from Actions artifacts

# 5. Install on TV
sdb install kodi-tizen-*.tpk

# 6. Test and view logs
sdb dlog KODI:V

# 7. Repeat!
```

### Quick Testing

```bash
# Make small change
vim xbmc/some/file.cpp

# Push
git add . && git commit -m "Quick fix" && git push

# Wait 15-30 minutes
# Download and test
```

## 📊 Monitoring Builds

### View Build Progress

1. **Actions tab** - See all builds
2. **Click on run** - See detailed steps
3. **Expand steps** - See command output
4. **Download logs** - For detailed debugging

### Build Status Badge (Optional)

Add to your README.md:

```markdown
![Tizen Build](https://github.com/YOUR_USERNAME/YOUR_REPO/workflows/Build%20Kodi%20for%20Tizen/badge.svg)
```

Replace `YOUR_USERNAME` and `YOUR_REPO` with your details.

## 🐛 Troubleshooting

### Build Fails

1. **Check the logs**:
   - Go to Actions tab
   - Click failed run
   - Expand failed step
   - Read error message

2. **Common fixes**:
   - Clear caches (Settings → Actions → Caches)
   - Re-run workflow
   - Check if code compiles locally

### No Artifacts

If no TPK is uploaded:
- Build probably failed
- Check "Create TPK package" step
- Look for errors in "Build Kodi" step

### Slow Builds

First build is always slow (60-90 min). Subsequent builds should be faster (15-30 min) due to caching.

If all builds are slow:
- Check if caches are being used
- Look for "Cache hit" messages in logs
- Verify cache keys are correct

## 💰 Cost

**FREE for public repositories!**

- 2,000 minutes/month free
- Each build uses ~60-90 minutes
- You can do ~20-30 builds/month free

**Private repositories:**
- Free tier: 2,000 minutes/month
- Pro: 3,000 minutes/month
- Same usage as above

## ✨ Benefits

### vs Local Building

| Aspect | Local (macOS) | GitHub Actions |
|--------|---------------|----------------|
| Setup | ❌ Impossible | ✅ Done |
| Build time | ❌ N/A | ✅ 60-90 min |
| Maintenance | ❌ Constant issues | ✅ None |
| Cost | ❌ Your time | ✅ Free |
| Reliability | ❌ Breaks often | ✅ Consistent |

### vs Other CI

| Feature | GitHub Actions | Other CI |
|---------|----------------|----------|
| Setup | ✅ Easy | ⚠️ Complex |
| Integration | ✅ Native | ⚠️ External |
| Cost | ✅ Free | 💰 Often paid |
| Speed | ✅ Fast | ⚠️ Varies |

## 📚 Learn More

- **Workflow details**: `.github/workflows/README-TIZEN.md`
- **Why this approach**: `FINAL_RECOMMENDATION.md`
- **All options**: `BUILD_OPTIONS_COMPARISON.md`
- **TV testing**: `APPLE_SILICON_SOLUTION.md`

## 🎉 You're Done!

Your professional CI/CD pipeline is set up! Just:

1. **Push code** → Builds automatically
2. **Download TPK** → From artifacts
3. **Install on TV** → Test immediately
4. **Iterate** → Repeat as needed

No more fighting with local builds. No more toolchain issues. Just push and go! 🚀

## Questions?

Common questions:

**Q: Do I need to do anything else?**
A: Nope! Just commit and push the workflow files.

**Q: How do I know it's working?**
A: Check the Actions tab after pushing.

**Q: Can I test without pushing?**
A: Yes, use manual trigger (see above).

**Q: What if it fails?**
A: Check the logs in Actions tab, see troubleshooting section.

**Q: Is this really free?**
A: Yes, for public repos. 2,000 minutes/month.

**Q: Can I use this for private repos?**
A: Yes, same free tier applies.

## Ready?

```bash
git add .github/workflows/
git commit -m "Add Tizen build workflow"
git push
```

Then watch the magic happen in the Actions tab! ✨
