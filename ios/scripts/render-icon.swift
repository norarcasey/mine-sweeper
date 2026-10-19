// Draws the app icon: a mine on a 3×3 patch of board, with a flag and a "1".
//
//   swift ios/scripts/render-icon.swift ios/MineSweeper/Assets.xcassets/AppIcon.appiconset/AppIcon.png
//
// 1024×1024, opaque: the App Store refuses an icon with an alpha channel.

import AppKit
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let size = 1024
let out = CommandLine.arguments.dropFirst().first ?? "AppIcon.png"

func color(_ hex: UInt32) -> CGColor {
    CGColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: 1
    )
}

guard
    let context = CGContext(
        data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
    )
else { fatalError("no bitmap context") }

// Background: the board's open-cell colour, dark.
context.setFillColor(color(0x1F2530))
context.fill(CGRect(x: 0, y: 0, width: size, height: size))

// A 3×3 patch of tiles. Row 0 is the bottom in Core Graphics.
let margin: CGFloat = 112
let tile = (CGFloat(size) - margin * 2) / 3
let gap: CGFloat = 14

func cellRect(_ row: Int, _ column: Int) -> CGRect {
    CGRect(
        x: margin + CGFloat(column) * tile + gap / 2,
        y: margin + CGFloat(row) * tile + gap / 2,
        width: tile - gap,
        height: tile - gap
    )
}

for row in 0..<3 {
    for column in 0..<3 {
        let rect = cellRect(row, column)
        let open = (row, column) == (1, 1) || (row, column) == (0, 0)
        context.setFillColor(color(open ? 0xE8ECF1 : 0x7A8699))
        context.addPath(CGPath(roundedRect: rect, cornerWidth: 28, cornerHeight: 28, transform: nil))
        context.fillPath()
    }
}

// The mine, in the centre cell.
let centre = CGPoint(x: cellRect(1, 1).midX, y: cellRect(1, 1).midY)
let radius = tile * 0.24
context.setStrokeColor(color(0x111111))
context.setLineWidth(radius * 0.32)
context.setLineCap(.round)
for spike in 0..<8 {
    let angle = CGFloat(spike) * .pi / 4
    context.move(to: CGPoint(x: centre.x + cos(angle) * radius * 0.5, y: centre.y + sin(angle) * radius * 0.5))
    context.addLine(to: CGPoint(x: centre.x + cos(angle) * radius * 1.45, y: centre.y + sin(angle) * radius * 1.45))
}
context.strokePath()
context.setFillColor(color(0x111111))
context.fillEllipse(in: CGRect(x: centre.x - radius, y: centre.y - radius, width: radius * 2, height: radius * 2))
context.setFillColor(color(0xFFFFFF))
let shine = radius * 0.32
context.fillEllipse(in: CGRect(x: centre.x - radius * 0.55, y: centre.y + radius * 0.15, width: shine, height: shine))

// A flag, top right.
let flagCell = cellRect(2, 2)
let pole = CGRect(x: flagCell.midX - 8, y: flagCell.minY + flagCell.height * 0.2, width: 16, height: flagCell.height * 0.6)
context.setFillColor(color(0x111111))
context.fill(pole)
context.fill(CGRect(x: flagCell.midX - 50, y: pole.minY - 4, width: 100, height: 22))
context.setFillColor(color(0xE03131))
context.move(to: CGPoint(x: pole.maxX, y: pole.maxY))
context.addLine(to: CGPoint(x: pole.maxX, y: pole.maxY - flagCell.height * 0.32))
context.addLine(to: CGPoint(x: pole.maxX - flagCell.width * 0.42, y: pole.maxY - flagCell.height * 0.16))
context.closePath()
context.fillPath()

// A blue "1", bottom left.
let oneCell = cellRect(0, 0)
let font = NSFont.systemFont(ofSize: tile * 0.62, weight: .heavy)
let one = NSAttributedString(string: "1", attributes: [
    .font: font,
    .foregroundColor: NSColor(cgColor: color(0x1D4ED8)) ?? NSColor.blue,
])
let line = CTLineCreateWithAttributedString(one)
let bounds = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
context.textPosition = CGPoint(x: oneCell.midX - bounds.midX, y: oneCell.midY - bounds.midY)
CTLineDraw(line, context)

guard
    let image = context.makeImage(),
    let destination = CGImageDestinationCreateWithURL(
        URL(fileURLWithPath: out) as CFURL, UTType.png.identifier as CFString, 1, nil
    )
else { fatalError("could not write \(out)") }
CGImageDestinationAddImage(destination, image, nil)
guard CGImageDestinationFinalize(destination) else { fatalError("could not write \(out)") }
print("wrote \(out)")
