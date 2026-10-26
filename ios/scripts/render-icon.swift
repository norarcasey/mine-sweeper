// Draws the app icon: NORA spelled on the board, as N, a mine, a flag and 4.
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

// NORA on a 2×2 patch of board, read left to right, top to bottom: an N, a mine
// for the O, a flag for the R and a 4 for the A. Row 0 is the bottom in Core
// Graphics.
let margin: CGFloat = 112
let tile = (CGFloat(size) - margin * 2) / 2
let gap: CGFloat = 24

func cellRect(_ row: Int, _ column: Int) -> CGRect {
    CGRect(
        x: margin + CGFloat(column) * tile + gap / 2,
        y: margin + CGFloat(row) * tile + gap / 2,
        width: tile - gap,
        height: tile - gap
    )
}

let flagCell = cellRect(0, 0)
for row in 0..<2 {
    for column in 0..<2 {
        let rect = cellRect(row, column)
        // A flag sits on a hidden tile; the letters are open ones.
        context.setFillColor(color(rect == flagCell ? 0x7A8699 : 0xE8ECF1))
        context.addPath(CGPath(roundedRect: rect, cornerWidth: 40, cornerHeight: 40, transform: nil))
        context.fillPath()
    }
}

// The N and the 4, in number colours: blue and navy.
func draw(_ text: String, _ hex: UInt32, in cell: CGRect) {
    let string = NSAttributedString(string: text, attributes: [
        .font: NSFont.systemFont(ofSize: tile * 0.6, weight: .heavy),
        .foregroundColor: NSColor(cgColor: color(hex)) ?? NSColor.black,
    ])
    let line = CTLineCreateWithAttributedString(string)
    let bounds = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
    context.textPosition = CGPoint(x: cell.midX - bounds.midX, y: cell.midY - bounds.midY)
    CTLineDraw(line, context)
}
draw("N", 0x1D4ED8, in: cellRect(1, 0))
draw("4", 0x1E1B8F, in: cellRect(0, 1))

// The mine, for the O.
let mineCell = cellRect(1, 1)
let centre = CGPoint(x: mineCell.midX, y: mineCell.midY)
let radius = tile * 0.2
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

// The flag, for the R: the pennant points right off the top of the pole, as an
// R's bowl comes off its stem. Pole and pennant together sit centred.
let pennant = flagCell.width * 0.42
let pole = CGRect(
    x: flagCell.midX - (22 + pennant) / 2, y: flagCell.minY + flagCell.height * 0.2,
    width: 22, height: flagCell.height * 0.6
)
context.setFillColor(color(0x111111))
context.fill(pole)
context.fill(CGRect(x: pole.midX - 50, y: pole.minY - 6, width: 100, height: 32))
context.setFillColor(color(0xE03131))
context.move(to: CGPoint(x: pole.minX, y: pole.maxY))
context.addLine(to: CGPoint(x: pole.minX, y: pole.maxY - flagCell.height * 0.32))
context.addLine(to: CGPoint(x: pole.minX + pennant + 22, y: pole.maxY - flagCell.height * 0.16))
context.closePath()
context.fillPath()

guard
    let image = context.makeImage(),
    let destination = CGImageDestinationCreateWithURL(
        URL(fileURLWithPath: out) as CFURL, UTType.png.identifier as CFString, 1, nil
    )
else { fatalError("could not write \(out)") }
CGImageDestinationAddImage(destination, image, nil)
guard CGImageDestinationFinalize(destination) else { fatalError("could not write \(out)") }
print("wrote \(out)")
