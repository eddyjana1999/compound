import AppKit
import Foundation

// usage: frame <in.png> <out.png> <line1> <line2> <subhead>
let a = CommandLine.arguments
guard a.count >= 6 else { print("bad args"); exit(1) }
let (inPath, outPath, l1, l2, sub) = (a[1], a[2], a[3], a[4], a[5])

let W = 1320, H = 2868
let devW: CGFloat = 900
let devH = devW * CGFloat(H) / CGFloat(W)
let devX = (CGFloat(W) - devW) / 2
let devY: CGFloat = 133          // from the bottom, AppKit origin is bottom-left
let bezel: CGFloat = 14
let radius: CGFloat = 92

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

// the capture, clipped inside the bezel
let screen = body.insetBy(dx: bezel, dy: bezel)
ctx.saveGState()
NSBezierPath(roundedRect: screen, xRadius: radius - bezel, yRadius: radius - bezel).addClip()
shot.draw(in: screen, from: .zero, operation: .sourceOver, fraction: 1.0)
ctx.restoreGState()

// hairline edge
NSColor(white: 1, alpha: 0.18).setStroke()
let edge = NSBezierPath(roundedRect: body, xRadius: radius, yRadius: radius)
edge.lineWidth = 3
edge.stroke()

NSGraphicsContext.restoreGraphicsState()
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: outPath))
print("wrote \(outPath)")
