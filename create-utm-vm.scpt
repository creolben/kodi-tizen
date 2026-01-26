-- AppleScript to create UTM VM for Kodi Tizen build
-- Run with: osascript create-utm-vm.scpt

tell application "UTM"
    -- Specify the boot ISO
    set iso to POSIX file "/Users/benjerome/Downloads/ubuntu-22.04.5-live-server-arm64.iso"
    
    -- Create a new Apple VM for Linux (uses native virtualization on Apple Silicon)
    set vm to make new virtual machine with properties {backend:apple, configuration:{name:"kodi-tizen-builder", drives:{{removable:true, source:iso}, {guest size:102400}}}}
    
end tell
