# Tizen Build Troubleshooting Guide

This guide addresses persistent build failures when packaging Kodi (and other Tizen apps) into `.tpk` files. These failures typically stem from **Code Signing** and **Certificate Profile** misconfigurations, which are strictly enforced by the Tizen SDK but often opaque in build logs.

## 1. The Root Cause: Security Profiles
Tizen enforces a strict security model. You **cannot** create a valid `.tpk` without a designated **Security Profile**.
*   **Local Failure:** `make tpk` fails or produces an invalid zip because no active security profile is configured in the local Tizen CLI environment.
*   **CI/CD Failure:** GitHub Actions runners are "clean slates" and lack the certificate stores present on your development machine. Without explicitly generating or importing a certificate during the workflow, the packaging step fails.

### Understanding the Certificate Chain
1.  **Author Certificate:** Identifies YOU as the developer. Used for updates (keeping the same app ID).
2.  **Distributor Certificate:** IDENTIFIES THE DEVICE.
    *   **Crucial:** For "Developer" or "Partner" level apps (sideloaded), the Distributor Certificate **MUST** contain the specific **DUID (Device Unique ID)** of your TV.
    *   If the DUID is missing, the build might succeed, but `sdb install` will fail with errors like `check_certificate_error` or `signature_error`.

---

## 2. Fixing Local Build Environment

### Step 1: Connect to Your TV
Ensure your TV is in Developer Mode and connected.
```bash
sdb connect <TV_IP_ADDRESS>:26101
sdb devices
# Output should show: <TV_IP>:26101   device   <DUID_STRING>
```
*Note the DUID (e.g., `H123456789`).*

### Step 2: Create Certificates (CLI Method)
If you rely on the UI, it's easy to miss the profile link. Use the CLI to generally set it up inside your container or host.

1.  **Create Author Certificate:**
    ```bash
    tizen certificate -a "KodiDev" -f kodi_author -p "1234" -c "US" -s "CA" -ct "City" -o "Kodi" -n "KodiDev" -e "email@example.com"
    ```

2.  **Create Distributor Certificate (Placeholder):**
    *Note: The CLI does not explicitly support DUID generation. We generate a compliant certificate to allow the build to proceed. You must Re-Sign later for installation.*
    ```bash
    tizen certificate -a "KodiDist" -f kodi_distributor -p "1234" -c "US" -s "CA" -ct "City" -o "Kodi" -n "KodiDist" -e "email@example.com"
    ```

3.  **Create and Activate Security Profile:**
    This links the certs to a profile named `tv-samsung`, matching your `tizen-manifest.xml`.
    *Note: The distributor cert is located in `keystore/author` by default when generated this way.*
    ```bash
    tizen security-profiles add -n "tv-samsung" -a "$HOME/tizen-studio-data/keystore/author/kodi_author.p12" -p "1234" -d "$HOME/tizen-studio-data/keystore/author/kodi_distributor.p12" -dp "1234"
    ```

4.  **Verify Profile:**
    ```bash
    tizen cli-config "default.profiles.path=$HOME/tizen-studio-data/profile/profiles.xml"
    tizen security-profiles list
    # Should show 'tv-samsung' as active (marked with *)
    ```

### Step 3: Run the Build
Now `make tpk` will pick up the profile.
```bash
export TIZEN_SECURITY_PROFILE="tv-samsung"
make tpk
```

---

## 3. Fixing GitHub Actions CI/CD

Since you cannot easily expose your specific TV's DUID to a public CI runner, the strategy is:
1.  **CI Builds with a Generic Cert:** The workflow generates a temporary self-signed certificate to allow the `.tpk` packaging to succeed.
2.  **User Re-signs Locally:** You download the artifact and re-sign it for your specific TV.

### Updated Workflow Logic
See the `FIXED_BUILD_WORKFLOW.md` (or updated `.github/workflows/build-tizen.yml`) artifact for the complete code. The key addition is the **Certificate Setup Step**:

```yaml
      - name: Setup Tizen Certificate
        run: |
          mkdir -p $HOME/tizen-studio-data/keystore/author
          mkdir -p $HOME/tizen-studio-data/keystore/distributor
          
          # 1. Generate Author Cert
          $HOME/tizen-studio/tools/ide/bin/tizen certificate -a "KodiCI" \
            -f ci_author -p "1234" -c "US" -o "Kodi" -n "KodiCI" -e "ci@kodi.tv"
            
          # 2. Generate Distributor Cert (Placeholder/Generic)
          $HOME/tizen-studio/tools/ide/bin/tizen certificate -a "KodiCI_Dist" \
            -f ci_dist -p "1234" -c "US" -o "Kodi" -n "KodiCI_Dist" -e "ci@kodi.tv"
            
          # 3. Create Profile
          $HOME/tizen-studio/tools/ide/bin/tizen security-profiles add \
            -n "tv-samsung" \
            -a "$HOME/tizen-studio-data/keystore/author/ci_author.p12" -p "1234" \
            -d "$HOME/tizen-studio-data/keystore/author/ci_dist.p12" -dp "1234"
```

### Installation of CI Artifacts
When you download the TPK from GitHub Actions, it is signed with the **CI generic cert**. It will likely fail to install on your TV with "Signature Error".

**Solution: Re-sign script**
Run this on your local machine (where you performed Section 2 above):

```bash
# Usage: ./resign.sh kodi-downloaded.tpk
tizen package -t tpk -s "tv-samsung" -- "$1"
```
Or simply unzip it and repackage:
```bash
unzip kodi.tpk -d temp_folder
tizen package -t tpk -s "tv-samsung" -- temp_folder
mv temp_folder/org.xbmc.kodi-*.tpk ./kodi-resigned.tpk
```

## 4. Common Error Code Reference

| Error | Meaning | Solution |
| :--- | :--- | :--- |
| `make: *** [tpk] Error 1` | Packaging script failed | Check if `TIZEN_SECURITY_PROFILE` is set and valid. |
| `Author certificate path is invalid` | Profile points to missing file | Re-run `tizen security-profiles add` with absolute paths. |
| `check_certificate_error [-12]` | Installation failed on TV | The TPK is signed, but usually missing the specific DUID of the TV. Check your Distributor cert. |
| `signature_error` | Cert chain invalid | The Author and Distributor certs don't match or are corrupted. Regenerate both. |
| `processing_result_error [-10]` | XML Manifest invalid | Verify `tizen-manifest.xml` syntax, especially `api-version` matching your SDK (6.0/6.5). |
