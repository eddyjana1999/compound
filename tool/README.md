# Store screenshot frames

`screenshot_frame.swift` draws the App Store marketing images: a gradient
ground, a device body with a shadow, a real capture clipped inside the bezel,
and two headline lines with a subhead.

It exists because nothing else on a stock Mac can produce a tall image at exact
pixel dimensions. QuickLook renders SVG but pads the result into a square, and
there is no ImageMagick, rsvg or Pillow here. CoreGraphics through Swift gives
both the exact canvas and real system fonts.

    swiftc -O tool/screenshot_frame.swift -o /tmp/frame
    /tmp/frame screenshots/store-1-home.png out.png "Line one" "Line two" "Subhead"

Output is 1320 x 2868 — the 6.9" iPhone size Apple asks for. Feed it captures
from `integration_test/store_screenshots_test.dart`, which runs with ads
overridden off so no banner reaches a product page.
