# Kodi Tizen Application Icons

This directory contains the application icons used for the Kodi Tizen TPK package.

## Icon Requirements

Tizen TV applications require the following icon specifications:

- **Format**: PNG with transparency
- **Recommended Size**: 512x512 pixels (will be scaled as needed)
- **Minimum Size**: 117x117 pixels
- **File Name**: kodi.png (referenced in tizen-manifest.xml)

## Current Icons

- `kodi.png` - Main application icon (256x256, sourced from media/icon256x256.png)

## Icon Usage

The icon is used in:
1. Samsung TV home screen app launcher
2. Application manager
3. Task switcher
4. Installation dialogs

## Updating Icons

To update the application icon:

1. Replace `kodi.png` with your new icon file
2. Ensure the icon meets the size requirements above
3. Rebuild the TPK package using `package.sh`

Alternatively, you can source icons from the main Kodi media directory:
- `media/icon256x256.png` - Default icon (current source)
- `media/icon120x120.png` - Alternative smaller icon
- `media/icon512x512.png` - High resolution icon (if available)

## Icon Guidelines

For best results, follow these guidelines:

1. **Transparency**: Use transparent backgrounds for better integration
2. **Simplicity**: Keep the design simple and recognizable at small sizes
3. **Branding**: Use official Kodi branding and colors
4. **Contrast**: Ensure good contrast for visibility on various backgrounds
5. **Testing**: Test icon appearance on actual Samsung TV devices

## Tizen Icon Specifications

Tizen supports the following icon types:

- **Application Icon**: Displayed in the app launcher (this directory)
- **Splash Screen**: Optional launch screen (can be added to res/ directory)
- **Notification Icon**: For system notifications (optional)

For more information, see:
https://developer.samsung.com/smarttv/develop/guides/user-interface/ui-design-principles.html
