#!/usr/bin/env swift
// Generates the full macOS iconset (all required pixel sizes) for an app:
// a document page with a folded corner, a centered glyph, and a magnifying
// glass to signal "viewer". Usage:
//   swift generate_icon.swift <outputDir> [glyph] [bgTopHex] [bgBottomHex] [glyphHex]
import AppKit

let sizes: [(name: String, pixels: Int)] = [
    ("icon_16x16", 16),
    ("icon_16x16@2x", 32),
    ("icon_32x32", 32),
    ("icon_32x32@2x", 64),
    ("icon_128x128", 128),
    ("icon_128x128@2x", 256),
    ("icon_256x256", 256),
    ("icon_256x256@2x", 512),
    ("icon_512x512", 512),
    ("icon_512x512@2x", 1024),
]

let args = CommandLine.arguments
let outputDir = args.count > 1 ? args[1] : "AppIcon.iconset"
let glyphText = args.count > 2 ? args[2] : "{ }"
let bgTopHex = args.count > 3 ? args[3] : "5C9EFF"
let bgBottomHex = args.count > 4 ? args[4] : "243D9E"
let glyphHex = args.count > 5 ? args[5] : "6B339E"

func cgColor(hex: String, alpha: CGFloat = 1.0) -> CGColor {
    var s = hex
    if s.hasPrefix("#") { s.removeFirst() }
    var value: UInt64 = 0
    Scanner(string: s).scanHexInt64(&value)
    let r = CGFloat((value & 0xFF0000) >> 16) / 255.0
    let g = CGFloat((value & 0x00FF00) >> 8) / 255.0
    let b = CGFloat(value & 0x0000FF) / 255.0
    return CGColor(red: r, green: g, blue: b, alpha: alpha)
}

func nsColor(hex: String, alpha: CGFloat = 1.0) -> NSColor {
    var s = hex
    if s.hasPrefix("#") { s.removeFirst() }
    var value: UInt64 = 0
    Scanner(string: s).scanHexInt64(&value)
    let r = CGFloat((value & 0xFF0000) >> 16) / 255.0
    let g = CGFloat((value & 0x00FF00) >> 8) / 255.0
    let b = CGFloat(value & 0x0000FF) / 255.0
    return NSColor(calibratedRed: r, green: g, blue: b, alpha: alpha)
}

let fm = FileManager.default
try? fm.removeItem(atPath: outputDir)
try! fm.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

func roundedPagePath(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, radius: CGFloat, fold: CGFloat) -> CGPath {
    let path = CGMutablePath()
    path.move(to: CGPoint(x: x + radius, y: y))
    path.addLine(to: CGPoint(x: x + width - fold, y: y))
    path.addLine(to: CGPoint(x: x + width, y: y + fold))
    path.addLine(to: CGPoint(x: x + width, y: y + height - radius))
    path.addArc(center: CGPoint(x: x + width - radius, y: y + height - radius), radius: radius, startAngle: 0, endAngle: .pi / 2, clockwise: false)
    path.addLine(to: CGPoint(x: x + radius, y: y + height))
    path.addArc(center: CGPoint(x: x + radius, y: y + height - radius), radius: radius, startAngle: .pi / 2, endAngle: .pi, clockwise: false)
    path.addLine(to: CGPoint(x: x, y: y + radius))
    path.addArc(center: CGPoint(x: x + radius, y: y + radius), radius: radius, startAngle: .pi, endAngle: .pi * 1.5, clockwise: false)
    path.closeSubpath()
    return path
}

func drawIcon(canvas s: CGFloat) {
    guard let ctx = NSGraphicsContext.current?.cgContext else { return }

    // Background squircle with a blue-to-indigo gradient.
    let bgPath = CGPath(roundedRect: CGRect(x: 0, y: 0, width: s, height: s),
                         cornerWidth: s * 0.219, cornerHeight: s * 0.219, transform: nil)
    ctx.saveGState()
    ctx.addPath(bgPath)
    ctx.clip()
    let bgColors = [
        cgColor(hex: bgTopHex),
        cgColor(hex: bgBottomHex),
    ] as CFArray
    let bgGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: bgColors, locations: [0, 1])!
    ctx.drawLinearGradient(bgGradient, start: CGPoint(x: 0, y: s), end: CGPoint(x: 0, y: 0), options: [])
    ctx.restoreGState()

    // Page with a folded top-right corner.
    let pageX = s * 0.195
    let pageWidth = s * 0.61
    let pageHeight = s * 0.66
    let pageY = s * 0.19
    let fold = s * 0.115
    let radius = s * 0.035

    let page = roundedPagePath(x: pageX, y: pageY, width: pageWidth, height: pageHeight, radius: radius, fold: fold)

    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -s * 0.012), blur: s * 0.03, color: CGColor(red: 0, green: 0.08, blue: 0.2, alpha: 0.35))
    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
    ctx.addPath(page)
    ctx.fillPath()
    ctx.restoreGState()

    // Shaded fold triangle.
    let ear = CGMutablePath()
    ear.move(to: CGPoint(x: pageX + pageWidth - fold, y: pageY + pageHeight))
    ear.addLine(to: CGPoint(x: pageX + pageWidth, y: pageY + pageHeight - fold))
    ear.addLine(to: CGPoint(x: pageX + pageWidth - fold, y: pageY + pageHeight - fold))
    ear.closeSubpath()
    ctx.setFillColor(CGColor(red: 0.80, green: 0.85, blue: 0.95, alpha: 1.0))
    ctx.addPath(ear)
    ctx.fillPath()

    // Glyph centered in the page, in the app's accent color.
    let glyphIsWide = glyphText.count > 3
    let glyphFont = NSFont.systemFont(ofSize: s * (glyphIsWide ? 0.19 : 0.34), weight: .bold)
    let glyphColor = nsColor(hex: glyphHex)
    let glyphAttrs: [NSAttributedString.Key: Any] = [.font: glyphFont, .foregroundColor: glyphColor]
    let glyphString = glyphText as NSString
    let glyphSize = glyphString.size(withAttributes: glyphAttrs)
    let glyphOrigin = CGPoint(
        x: pageX + (pageWidth - glyphSize.width) / 2,
        y: pageY + pageHeight * 0.56 - glyphSize.height / 2
    )
    glyphString.draw(at: glyphOrigin, withAttributes: glyphAttrs)

    // Magnifying glass overlapping the bottom-right of the page.
    let lensCenter = CGPoint(x: s * 0.665, y: s * 0.255)
    let lensRadius = s * 0.115
    let ringWidth = s * 0.045

    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -s * 0.008), blur: s * 0.02, color: CGColor(red: 0, green: 0.05, blue: 0.15, alpha: 0.4))
    ctx.setFillColor(CGColor(red: 0.90, green: 0.95, blue: 1.0, alpha: 0.55))
    ctx.addArc(center: lensCenter, radius: lensRadius - ringWidth / 2, startAngle: 0, endAngle: .pi * 2, clockwise: false)
    ctx.fillPath()
    ctx.restoreGState()

    let handleAngle = CGFloat.pi * 1.25
    let handleStart = CGPoint(
        x: lensCenter.x + cos(handleAngle) * lensRadius,
        y: lensCenter.y + sin(handleAngle) * lensRadius
    )
    let handleEnd = CGPoint(
        x: lensCenter.x + cos(handleAngle) * (lensRadius + s * 0.15),
        y: lensCenter.y + sin(handleAngle) * (lensRadius + s * 0.15)
    )
    let ringColor = CGColor(red: 0.10, green: 0.15, blue: 0.30, alpha: 1.0)
    ctx.setStrokeColor(ringColor)
    ctx.setLineWidth(s * 0.055)
    ctx.setLineCap(.round)
    ctx.move(to: handleStart)
    ctx.addLine(to: handleEnd)
    ctx.strokePath()

    ctx.setStrokeColor(ringColor)
    ctx.setLineWidth(ringWidth)
    ctx.addArc(center: lensCenter, radius: lensRadius - ringWidth / 2, startAngle: 0, endAngle: .pi * 2, clockwise: false)
    ctx.strokePath()
}

for (name, pixels) in sizes {
    let s = CGFloat(pixels)
    let image = NSImage(size: NSSize(width: s, height: s))
    image.lockFocus()
    drawIcon(canvas: s)
    image.unlockFocus()

    guard let tiff = image.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
        fatalError("Failed to render \(name)")
    }
    let path = (outputDir as NSString).appendingPathComponent("\(name).png")
    try! png.write(to: URL(fileURLWithPath: path))
    print("Wrote \(path)")
}
