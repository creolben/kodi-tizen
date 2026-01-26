# ⚠️ Permission Warnings Are Normal

## What You're Seeing

```
chown: changing ownership of '/workspace/.git/objects/...': Permission denied
```

## Why This Happens

Podman mounts your Mac's directory into the container with special SELinux permissions. The `.git` directory is owned by your Mac user, and the container can't change its ownership.

## Is This a Problem?

**NO!** These are just warnings. The build will continue successfully because:

1. The `.git` directory doesn't need to be modified during the build
2. The script sets permissions with `|| true` which means it continues even if some files can't be changed
3. The builder user can still READ the files, which is all that's needed

## What Happens Next

After these warnings, you should see:

```
==========================================
Step 1/4: Installing Tizen SDK
==========================================
```

The build is proceeding normally!

## If the Build Stops

If the script stops after the permission warnings, just re-run it:

```bash
chmod +x /workspace/container-build-as-root.sh && /workspace/container-build-as-root.sh
```

The script will detect what's already done and skip those steps.

## Summary

✅ Permission warnings = **NORMAL**  
✅ Build continues = **GOOD**  
✅ Just wait for "Step 1/4: Installing Tizen SDK" message
