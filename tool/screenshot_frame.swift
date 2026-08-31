import AppKit
import Foundation

// usage: frame <in.png> <out.png> <line1> <line2> <subhead> [black|silver]
let a = CommandLine.arguments
guard a.count >= 6 else { print("bad args"); exit(1) }
let (inPath, outPath, l1, l2, sub) = (a[1], a[2], a[3], a[4], a[5])
let style = a.count >= 7 ? a[6] : "black"

let W = 1320, H = 2868
let devW: CGFloat = 940
let devH = devW * CGFloat(H) / CGFloat(W)
let devX = (CGFloat(W) - devW) / 2
let devY: CGFloat = 133          // from the bottom, AppKit origin is bottom-left
let bezel: CGFloat = 14
// 14% of the width. The silhouette is what the eye reads first, and at 10%
// the corners were square enough that the frame passed for an Android phone
// no matter what detail was added inside it.
let radius: CGFloat = 132

guard let shot = NSImage(contentsOfFile: inPath) else { print("cannot read \(inPath)"); exit(1) }

let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: W, pixelsHigh: H,
                           bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                           isPlanar: false, colorSpaceName: .deviceRGB,
                           bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
let ctx = NSGraphicsContext.current!.cgContext

func rgb(_ h: UInt32) -> NSColor {
  NSColor(srgbRed: CGFloat((h >> 16) & 0xff)/255, green: CGFloat((h >> 8) & 0xff)/255,
          blue: CGFloat(h & 0xff)/255, alpha: 1)
}

// background
let grad = NSGradient(colors: [rgb(0x0F766E), rgb(0x065F46), rgb(0x022C22)],
                      atLocations: [0, 0.55, 1], colorSpace: .sRGB)!
grad.draw(in: NSRect(x: 0, y: 0, width: W, height: H), angle: -78)

// headline
func centred(_ s: String, y: CGFloat, size: CGFloat, weight: NSFont.Weight, colour: NSColor) {
  let f = NSFont.systemFont(ofSize: size, weight: weight)
  let p = NSMutableParagraphStyle(); p.alignment = .center
  let at: [NSAttributedString.Key: Any] = [.font: f, .foregroundColor: colour, .paragraphStyle: p]
  let str = NSAttributedString(string: s, attributes: at)
  str.draw(in: NSRect(x: 60, y: y, width: CGFloat(W) - 120, height: size * 1.6))
}
centred(l1,  y: CGFloat(H) - 380, size: 104, weight: .bold,   colour: .white)
centred(l2,  y: CGFloat(H) - 510, size: 104, weight: .bold,   colour: .white)
centred(sub, y: CGFloat(H) - 640, size: 50,  weight: .medium, colour: rgb(0xA7F3D0))

// device shadow, then body
let body = NSRect(x: devX, y: devY, width: devW, height: devH)
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -26), blur: 40,
              color: NSColor(white: 0, alpha: 0.5).cgColor)
rgb(0x0B0F14).setFill()
NSBezierPath(roundedRect: body, xRadius: radius, yRadius: radius).fill()
ctx.restoreGState()

// A polished rail reads as metal only if the light moves across it, so the
// gradient is banded rather than smooth: bright edges, a darker middle, and
// a highlight either side of it.
var screen = body.insetBy(dx: bezel, dy: bezel)
if style == "silver" {
  // Polished titanium: the light has to travel across the rail, so the ramp
  // is banded rather than smooth. Brighter than a grey frame — a real one is
  // nearly white where it catches the light.
  let rail = NSGradient(colors: [rgb(0xC6C8CD), rgb(0xFFFFFF), rgb(0xE2E4E8),
                                 rgb(0xFFFFFF), rgb(0xB4B6BC)],
                        atLocations: [0, 0.14, 0.5, 0.86, 1], colorSpace: .sRGB)!
  ctx.saveGState()
  NSBezierPath(roundedRect: body, xRadius: radius, yRadius: radius).addClip()
  rail.draw(in: body, angle: 0)
  ctx.restoreGState()

  // Left rail: action button, then volume up and down. Right rail: power.
  rgb(0xD3D5DA).setFill()
  for (yFrac, hFrac) in [(0.735, 0.026), (0.655, 0.050), (0.585, 0.050)] {
    NSBezierPath(roundedRect: NSRect(x: devX - 5, y: devY + devH * yFrac,
                                     width: 6, height: devH * hFrac),
                 xRadius: 3, yRadius: 3).fill()
  }
  NSBezierPath(roundedRect: NSRect(x: devX + devW - 1, y: devY + devH * 0.615,
                                   width: 6, height: devH * 0.082),
               xRadius: 3, yRadius: 3).fill()

  // A thin black rim between rail and glass. Thin is the point: wide bezels
  // are what made the first attempt read as a generic handset.
  let rim = body.insetBy(dx: 16, dy: 16)
  rgb(0x05060A).setFill()
  NSBezierPath(roundedRect: rim, xRadius: radius - 16, yRadius: radius - 16).fill()
  screen = rim.insetBy(dx: 8, dy: 8)
}

// the capture, clipped inside the bezel
ctx.saveGState()
let screenR = radius - (body.width - screen.width) / 2
NSBezierPath(roundedRect: screen, xRadius: screenR, yRadius: screenR).addClip()
shot.draw(in: screen, from: .zero, operation: .sourceOver, fraction: 1.0)
ctx.restoreGState()

// The Dynamic Island, drawn over the capture. This is the single feature
// that identifies the device; without it the frame is just a rectangle, and
// the first version of this read as an Android phone for exactly that reason.
if style == "silver" {
  let islandW = screen.width * 0.30
  let islandH = islandW * 37.0 / 125.0
  let island = NSRect(x: screen.midX - islandW / 2,
                      y: screen.maxY - islandH - screen.height * 0.011,
                      width: islandW, height: islandH)
  NSColor.black.setFill()
  NSBezierPath(roundedRect: island, xRadius: islandH / 2, yRadius: islandH / 2).fill()

  // The front camera sits inside the island, right of centre.
  rgb(0x14161C).setFill()
  let lens = islandH * 0.46
  NSBezierPath(ovalIn: NSRect(x: island.maxX - lens - islandH * 0.30,
                              y: island.midY - lens / 2,
                              width: lens, height: lens)).fill()
}

// hairline edge
NSColor(white: 1, alpha: style == "silver" ? 0.42 : 0.18).setStroke()
let edge = NSBezierPath(roundedRect: body, xRadius: radius, yRadius: radius)
edge.lineWidth = 3
edge.stroke()

NSGraphicsContext.restoreGraphicsState()
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: outPath))
print("wrote \(outPath)")
