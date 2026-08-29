# Icon source

The icon is drawn, not photographed: `icon.svg` is the master and the PNGs beside it are rendered
from it. Edit the SVG, never the PNGs.

    qlmanage -t -s 1024 -o . icon.svg && sips -z 1024 1024 icon.svg.png --out ../icon.png
    qlmanage -t -s 1024 -o . icon_foreground.svg && sips -z 1024 1024 icon_foreground.svg.png --out ../icon_foreground.png
    dart run flutter_launcher_icons

`icon_foreground.svg` is the same artwork with the chart scaled to 66%, for Android's adaptive
mask — a launcher that crops to a circle would otherwise cut the outer bars off.

The green is the app's own `#10B981`, so the icon and the first screen agree.

**If a rebuilt icon looks like it has a dark border on the simulator, that is the springboard's
icon cache, not the file.** Uninstall, `xcrun simctl spawn booted launchctl stop com.apple.SpringBoard`,
then reinstall.
