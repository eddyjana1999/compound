import AppKit
import Foundation

// usage: real <capture.png> <bezel.png> <out.png> <line1> <line2> <subhead>
let a = CommandLine.arguments
guard a.count >= 7 else { print("bad args"); exit(1) }
let (capPath, bezPath, outPath, l1, l2, sub) = (a[1], a[2], a[3], a[4], a[5], a[6])

let W = 1320, H = 2868

guard let cap = NSImage(contentsOfFile: capPath),
      let bez = NSImage(contentsOfFile: bezPath),
      let bezTiff = bez.tiffRepresentation,
      let bezRep = NSBitmapImageRep(data: bezTiff) else { print("cannot read inputs"); exit(1) }

// Find the cut-out the same way the probe did: from inside, off-centre so the
// Dynamic Island is not mistaken for the top edge.
let bw = bezRep.pixelsWide, bh = bezRep.pixelsHigh
func alpha(_ x: Int, _ y: Int) -> CGFloat { bezRep.colorAt(x: x, y: y)?.alphaComponent ?? 1 }
let px = bw * 3 / 10, cy = bh / 2
var t = cy; while t > 0 && alpha(px, t) < 0.5 { t -= 1 }
var b = cy; while b < bh-1 && alpha(px, b) < 0.5 { b += 1 }
let my = (t + b) / 2
var l = bw/2; while l > 0 && alpha(l, my) < 0.5 { l -= 1 }
var r = bw/2; while r < bw-1 && alpha(r, my) < 0.5 { r += 1 }
let winX = CGFloat(l + 1), winW = CGFloat(r - l - 1)
let winYTop = CGFloat(t + 1), winH = CGFloat(b - t - 1)

// The whole bezel, scaled so its cut-out is a chosen width on the canvas.
let targetScreenW: CGFloat = 940
let scale = targetScreenW / winW
let bezW = CGFloat(bw) * scale, bezH = CGFloat(bh) * scale
let bezX = (CGFloat(W) - bezW) / 2
let bezY: CGFloat = 96                      // AppKit origin is bottom-left

// Where the cut-out lands once the bezel is placed.
let scrW = winW * scale, scrH = winH * scale
let scrX = bezX + winX * scale
let scrY = bezY + (CGFloat(bh) - winYTop - winH) * scale

let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: W, pixelsHigh: H,
                           bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                           isPlanar: false, colorSpaceName: .deviceRGB,
                           bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

func rgb(_ h: UInt32) -> NSColor {
  NSColor(srgbRed: CGFloat((h >> 16) & 0xff)/255, green: CGFloat((h >> 8) & 0xff)/255,
          blue: CGFloat(h & 0xff)/255, alpha: 1)
}

NSGradient(colors: [rgb(0x0F766E), rgb(0x065F46), rgb(0x022C22)],
           atLocations: [0, 0.55, 1], colorSpace: .sRGB)!
  .draw(in: NSRect(x: 0, y: 0, width: W, height: H), angle: -78)

func centred(_ s: String, y: CGFloat, size: CGFloat, weight: NSFont.Weight, colour: NSColor) {
  let p = NSMutableParagraphStyle(); p.alignment = .center
  NSAttributedString(string: s, attributes: [
    .font: NSFont.systemFont(ofSize: size, weight: weight),
    .foregroundColor: colour, .paragraphStyle: p
  ]).draw(in: NSRect(x: 60, y: y, width: CGFloat(W) - 120, height: size * 1.6))
}
centred(l1,  y: CGFloat(H) - 372, size: 100, weight: .bold,   colour: .white)
centred(l2,  y: CGFloat(H) - 496, size: 100, weight: .bold,   colour: .white)
centred(sub, y: CGFloat(H) - 620, size: 48,  weight: .medium, colour: rgb(0xA7F3D0))

// Capture first, then Apple's bezel over it — the cut-out is transparent, so
// the frame lands on top with its own corners, rail and island intact.
// Clipped to the glass, not to its bounding box. The cut-out is a rectangle
// but the screen is a squircle, and drawing the capture square let its
// corners show through the transparent corners of the bezel — four pale
// patches sitting outside the phone's own silhouette.
let glass = NSRect(x: scrX, y: scrY, width: scrW, height: scrH)
let glassR = scrW * 62.0 / 440.0        // the device's own screen radius
NSGraphicsContext.current!.saveGraphicsState()
NSBezierPath(roundedRect: glass, xRadius: glassR, yRadius: glassR).addClip()
cap.draw(in: glass, from: .zero, operation: .sourceOver, fraction: 1.0)
NSGraphicsContext.current!.restoreGraphicsState()
bez.draw(in: NSRect(x: bezX, y: bezY, width: bezW, height: bezH),
         from: .zero, operation: .sourceOver, fraction: 1.0)

NSGraphicsContext.restoreGraphicsState()
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: outPath))
print("wrote \(outPath)")
