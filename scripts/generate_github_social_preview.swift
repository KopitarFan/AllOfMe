#!/usr/bin/env swift

import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let iconURL = root.appendingPathComponent("assets/brand/allofme-icon.png")
let outputURL = root.appendingPathComponent("assets/brand/github-social-preview.png")

let width: CGFloat = 1280
let height: CGFloat = 640
let canvasSize = NSSize(width: width, height: height)

func color(_ hex: Int, alpha: CGFloat = 1) -> NSColor {
    let red = CGFloat((hex >> 16) & 0xff) / 255
    let green = CGFloat((hex >> 8) & 0xff) / 255
    let blue = CGFloat(hex & 0xff) / 255
    return NSColor(calibratedRed: red, green: green, blue: blue, alpha: alpha)
}

func rectFromTop(x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat) -> NSRect {
    NSRect(x: x, y: height - y - h, width: w, height: h)
}

func drawRoundedRect(
    x: CGFloat,
    y: CGFloat,
    w: CGFloat,
    h: CGFloat,
    radius: CGFloat,
    fill: NSColor? = nil,
    stroke: NSColor? = nil,
    lineWidth: CGFloat = 1
) {
    let path = NSBezierPath(
        roundedRect: rectFromTop(x: x, y: y, w: w, h: h),
        xRadius: radius,
        yRadius: radius
    )
    if let fill {
        fill.setFill()
        path.fill()
    }
    if let stroke {
        stroke.setStroke()
        path.lineWidth = lineWidth
        path.stroke()
    }
}

func drawText(_ text: String, x: CGFloat, y: CGFloat, font: NSFont, color textColor: NSColor) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.lineBreakMode = .byClipping
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: textColor,
        .paragraphStyle: paragraph,
    ]
    let attributed = NSAttributedString(string: text, attributes: attributes)
    let size = attributed.size()
    attributed.draw(at: NSPoint(x: x, y: height - y - size.height))
}

guard let icon = NSImage(contentsOf: iconURL) else {
    fputs("Could not read icon at \(iconURL.path)\n", stderr)
    exit(1)
}

guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(width),
    pixelsHigh: Int(height),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    fputs("Could not create bitmap context\n", stderr)
    exit(1)
}

guard let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
    fputs("Could not create graphics context\n", stderr)
    exit(1)
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context
context.shouldAntialias = true

let bounds = NSRect(origin: .zero, size: canvasSize)
NSGradient(
    starting: color(0xf8f4ec),
    ending: color(0xebece7)
)?.draw(in: bounds, angle: -90)

drawRoundedRect(x: 885, y: -70, w: 455, h: 340, radius: 70, fill: color(0xef9b73, alpha: 0.16))
drawRoundedRect(x: 975, y: 345, w: 350, h: 365, radius: 80, fill: color(0xbcb6d2, alpha: 0.18))
drawRoundedRect(x: -110, y: 420, w: 475, h: 325, radius: 80, fill: color(0xcfdcca, alpha: 0.20))
drawRoundedRect(
    x: 760,
    y: 70,
    w: 360,
    h: 480,
    radius: 90,
    stroke: color(0x31464f, alpha: 0.14),
    lineWidth: 3
)

let iconSize: CGFloat = 314
let iconX: CGFloat = 94
let iconY: CGFloat = 146

let shadow = NSShadow()
shadow.shadowOffset = NSSize(width: 8, height: -12)
shadow.shadowBlurRadius = 20
shadow.shadowColor = color(0x22343a, alpha: 0.24)
NSGraphicsContext.saveGraphicsState()
shadow.set()
drawRoundedRect(x: iconX, y: iconY, w: iconSize, h: iconSize, radius: 70, fill: color(0xffffff))
NSGraphicsContext.restoreGraphicsState()

let iconRect = rectFromTop(x: iconX, y: iconY, w: iconSize, h: iconSize)
let iconClip = NSBezierPath(roundedRect: iconRect, xRadius: 70, yRadius: 70)
NSGraphicsContext.saveGraphicsState()
iconClip.addClip()
icon.draw(in: iconRect, from: .zero, operation: .sourceOver, fraction: 1)
NSGraphicsContext.restoreGraphicsState()

let titleFont = NSFont.systemFont(ofSize: 104, weight: .bold)
let subtitleFont = NSFont.systemFont(ofSize: 43, weight: .medium)
let bodyFont = NSFont.systemFont(ofSize: 30, weight: .regular)
let tagFont = NSFont.systemFont(ofSize: 30, weight: .medium)

let textX: CGFloat = 470
drawText("All Of Me", x: textX, y: 184, font: titleFont, color: color(0x243941))
drawRoundedRect(x: textX, y: 316, w: 432, h: 10, radius: 5, fill: color(0x24786d))
drawText("Local-first system tracking", x: textX, y: 354, font: subtitleFont, color: color(0x53666b))
drawText(
    "Private by default. Device-owned data. Optional sync later.",
    x: textX,
    y: 425,
    font: bodyFont,
    color: color(0x6b7475)
)

let tag = "Flutter | iOS | Local-first"
let tagSize = NSAttributedString(string: tag, attributes: [.font: tagFont]).size()
drawRoundedRect(
    x: textX - 18,
    y: 493,
    w: tagSize.width + 36,
    h: tagSize.height + 28,
    radius: 22,
    fill: color(0xffffff, alpha: 0.54),
    stroke: color(0x31464f, alpha: 0.16)
)
drawText(tag, x: textX, y: 505, font: tagFont, color: color(0x31464f))

NSGraphicsContext.restoreGraphicsState()

guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
    fputs("Could not render PNG data\n", stderr)
    exit(1)
}

do {
    try pngData.write(to: outputURL)
    print(outputURL.path)
} catch {
    fputs("Could not write \(outputURL.path): \(error)\n", stderr)
    exit(1)
}
