#!/usr/bin/env bash

IGNORE_CLASS=$(kreadconfig6 --file kwinrc --group Script-krohnkite --key ignoreClass 2>/dev/null)
if [[ -z "$IGNORE_CLASS" ]]; then
    # Default list if missing, plus quickshell
    NEW_IGNORE="krunner,yakuake,spectacle,kded5,xwaylandvideobridge,plasmashell,ksplashqml,org.kde.plasmashell,org.kde.polkit-kde-authentication-agent-1,quickshell"
else
    if ! echo "$IGNORE_CLASS" | grep -q '\bquickshell\b'; then
        NEW_IGNORE="${IGNORE_CLASS},quickshell"
    else
        NEW_IGNORE="$IGNORE_CLASS"
    fi
fi
kwriteconfig6 --file kwinrc --group Script-krohnkite --key ignoreClass "$NEW_IGNORE"

# Set default tiling gaps for Krohnkite
kwriteconfig6 --file kwinrc --group Script-krohnkite --key screenGapBetween 10
kwriteconfig6 --file kwinrc --group Script-krohnkite --key screenGapBottom 4
kwriteconfig6 --file kwinrc --group Script-krohnkite --key screenGapLeft 4
kwriteconfig6 --file kwinrc --group Script-krohnkite --key screenGapRight 4
kwriteconfig6 --file kwinrc --group Script-krohnkite --key screenGapTop 4

# Set binary as the tiling method and disable others to avoid interference
kwriteconfig6 --file kwinrc --group Script-krohnkite --key binaryTreeLayoutOrder 1
kwriteconfig6 --file kwinrc --group Script-krohnkite --key cascadeLayoutOrder 0
kwriteconfig6 --file kwinrc --group Script-krohnkite --key columnsLayoutOrder 0
kwriteconfig6 --file kwinrc --group Script-krohnkite --key monocleLayoutOrder 0
kwriteconfig6 --file kwinrc --group Script-krohnkite --key quarterLayoutOrder 0
kwriteconfig6 --file kwinrc --group Script-krohnkite --key spiralLayoutOrder 0
kwriteconfig6 --file kwinrc --group Script-krohnkite --key spreadLayoutOrder 0
kwriteconfig6 --file kwinrc --group Script-krohnkite --key stackedLayoutOrder 0
kwriteconfig6 --file kwinrc --group Script-krohnkite --key stairLayoutOrder 0
kwriteconfig6 --file kwinrc --group Script-krohnkite --key threeColumnLayoutOrder 0
kwriteconfig6 --file kwinrc --group Script-krohnkite --key tileLayoutOrder 0
kwriteconfig6 --file kwinrc --group Script-krohnkite --key floatingLayoutOrder 2



echo "StartupTasks: Added quickshell to Krohnkite exceptions, configured layouts and shortcuts"

# Return 1 to indicate KWin reconfigure is needed
exit 1
