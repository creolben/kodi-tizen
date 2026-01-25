# Tizen Build Workflow

This workflow automatically builds Kodi for Tizen (Samsung Smart TVs) using GitHub Actions.

## How It Works

The workflow:
1. **Triggers automatically** on pushes to main/master branches
2. **Builds on Ubuntu 20.04** with proper Tizen SDK
3. **Caches dependencies** for faster subsequent builds
4. **Creates TPK package** ready for installation
5. **Uploads artifact** that you can download

## Manual Trigger

You can manually trigger a build:

1. Go to the **Actions** tab in GitHub
2. Click **"Build Kodi for Tizen"** in the left sidebar
3. Click **"Run workflow"** button
4. Select branch and click **"Run workflow"**

## Download Built TPK

After the build completes:

1. Go to the **Actions** tab
2. Click on the completed workflow run
3. Scroll down to **Artifacts** section
4. Download `kodi-tizen-X.X-arm.zip`
5. Extract the TPK file

## Install on Samsung TV

```bash
# Connect to your TV
sdb connect <TV_IP>:26101

# Install the TPK
sdb install kodi-tizen-*.tpk

# Launch Kodi
sdb shell app_launcher -s org.xbmc.kodi

# View logs
sdb dlog KODI:V
```

## Build Times

- **First build**: 60-90 minutes (builds all dependencies)
- **Incremental builds**: 15-30 minutes (uses cached dependencies)
- **No code changes**: 5-10 minutes (uses all caches)

## Caching

The workflow caches:
- **Tizen SDK** (~2GB) - Cached indefinitely
- **Kodi dependencies** (~5GB) - Cached per dependency changes

This dramatically speeds up subsequent builds.

## Troubleshooting

### Build Fails

Check the workflow logs:
1. Go to Actions tab
2. Click on the failed run
3. Expand the failed step
4. Read the error message

Common issues:
- **Disk space**: Workflow frees up space automatically
- **Tizen SDK**: Cache may be corrupted, clear it and retry
- **Dependencies**: Clear dependency cache and rebuild

### Clear Caches

To clear caches:
1. Go to **Settings** → **Actions** → **Caches**
2. Delete the relevant cache
3. Re-run the workflow

### No TPK File

If no TPK is created:
1. Check the "Create TPK package" step logs
2. Verify the build completed successfully
3. Check for errors in the "Build Kodi" step

## Customization

### Build for Different Tizen Version

Edit the workflow file to change:
```yaml
PLATFORM-6.0-NativeAppDevelopment-CLI
```

To your desired version (e.g., `PLATFORM-7.0-NativeAppDevelopment-CLI`)

### Enable Debug Build

Change in the workflow:
```yaml
--enable-debug=no
```

To:
```yaml
--enable-debug=yes
```

### Build Specific Branch

When manually triggering:
1. Click "Run workflow"
2. Select your branch from dropdown
3. Click "Run workflow"

## Cost

- **Public repositories**: FREE (2,000 minutes/month)
- **Private repositories**: FREE tier includes 2,000 minutes/month
- This workflow uses ~60-90 minutes per full build

## Benefits

✅ **No local setup** - Builds in the cloud
✅ **Consistent environment** - Same every time
✅ **Automatic** - Builds on every push
✅ **Fast** - Parallel builds, caching
✅ **Professional** - Industry standard CI/CD

## Local Development Workflow

1. **Write code** on your Mac
2. **Commit and push** to GitHub
3. **GitHub Actions builds** automatically
4. **Download TPK** from artifacts
5. **Install on TV** and test
6. **View logs** via SDB
7. **Iterate** and repeat

## Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Tizen SDK Documentation](https://developer.tizen.org/)
- [Kodi Tizen Build Guide](../../docs/README.Tizen.md)
- [TV Connection Guide](../../tools/tizen/TV_CONNECTION_GUIDE.md)

## Questions?

See the main documentation:
- `FINAL_RECOMMENDATION.md` - Complete guide
- `BUILD_OPTIONS_COMPARISON.md` - All build options
- `APPLE_SILICON_SOLUTION.md` - macOS-specific info
