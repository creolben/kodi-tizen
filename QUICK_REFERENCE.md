# Quick Reference: Kodi Tizen Build

## GitHub Actions (Recommended) ⭐

### Enable & Trigger (5 minutes)
```
1. https://github.com/creolben/kodi-tizen/settings/actions
   → Enable "Allow all actions"
   
2. https://github.com/creolben/kodi-tizen/actions
   → Cancel stuck workflow
   → Click "Build Kodi for Tizen"
   → Click "Run workflow"
   
3. Wait 60-90 minutes
   
4. Download TPK from Artifacts section
```

### Install on TV (5 minutes)
```bash
sdb connect <TV_IP>:26101
sdb install kodi-tizen-*.tpk
sdb shell app_launcher -s org.xbmc.kodi
```

## Local Container Build (Not Recommended)

### Restart Build
```bash
podman exec -it fbe0eaf11081 bash
pkill -9 make; pkill -9 gcc; pkill -9 g++
cd /workspace
bash fix-and-build-tizen.sh
```

### Check Status
```bash
./check-build-status.sh
```

### Monitor Progress
```bash
./monitor-build.sh
```

## Useful Commands

### SDB (Samsung TV)
```bash
# Connect
sdb connect <TV_IP>:26101

# List devices
sdb devices

# Install TPK
sdb install <file>.tpk

# Launch Kodi
sdb shell app_launcher -s org.xbmc.kodi

# View logs
sdb dlog KODI:V

# Uninstall
sdb shell pkgcmd -u -n org.xbmc.kodi
```

### Container Management
```bash
# List containers
podman ps -a

# Enter container
podman exec -it fbe0eaf11081 bash

# Stop container
podman stop fbe0eaf11081

# Remove container
podman rm fbe0eaf11081
```

## File Locations

### Important Files
- `.github/workflows/build-tizen.yml` - GitHub Actions workflow
- `docs/README.Tizen.md` - Complete build guide
- `fix-and-build-tizen.sh` - Local build script
- `ACTION_PLAN_NOW.md` - Detailed action plan
- `GITHUB_ACTIONS_FIX.md` - GitHub Actions troubleshooting

### Build Outputs
- `build/*.tpk` - TPK package (local build)
- GitHub Actions Artifacts - TPK package (cloud build)

## Troubleshooting

### GitHub Actions stuck in queue
→ Enable Actions in repository settings
→ Cancel and re-trigger workflow

### Local build stalled
→ Use GitHub Actions instead
→ Or: Kill processes and restart

### TPK install fails
→ Enable developer mode on TV
→ Check TV IP address
→ Verify sdb connection

### Kodi won't launch
→ Check logs: `sdb dlog KODI:V`
→ Check crash logs in TV
→ Reinstall TPK

## Support Resources

- **Tizen Developer Guide**: https://developer.tizen.org/
- **Kodi Forums**: https://forum.kodi.tv/
- **Samsung Developer**: https://developer.samsung.com/smarttv

## Quick Decision Tree

```
Need TPK file?
├─ Yes, quickly → Use GitHub Actions ⭐
├─ Yes, locally → Use container (not recommended)
└─ Just testing → Get pre-built TPK

Have TPK file?
├─ Yes → Install on TV
└─ No → Build using GitHub Actions

Build failed?
├─ GitHub Actions → Check logs, retry
└─ Local build → Switch to GitHub Actions

Kodi installed?
├─ Yes → Test and enjoy!
└─ No → Check SDB connection
```

## Time Estimates

| Task | Time |
|------|------|
| Enable GitHub Actions | 2 min |
| Trigger workflow | 1 min |
| Build (first time) | 60-90 min |
| Build (cached) | 15-30 min |
| Download TPK | 1 min |
| Install on TV | 5 min |
| **Total** | **~90 min** |

## Success Checklist

- [ ] GitHub Actions enabled
- [ ] Workflow triggered
- [ ] Build completed successfully
- [ ] TPK downloaded
- [ ] TV in developer mode
- [ ] SDB connected to TV
- [ ] TPK installed
- [ ] Kodi launched
- [ ] Testing complete

## Remember

✅ **GitHub Actions is the recommended approach**
✅ **Native Linux builds are more reliable**
✅ **First build takes longer, subsequent builds are faster**
✅ **All Tizen code is already implemented**
✅ **C++17 patches are in the workflow**

🚀 **You're ready to build!**
