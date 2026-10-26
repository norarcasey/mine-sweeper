// Draws the App Store product page header (MINE-5): a board filling the frame,
// with the icon's NORA tiles (N, a mine, a flag, 4) at its centre. The board is
// a real one: the mine and the flag are mines, the rest are laid from a fixed
// seed, and the open cells around NORA show their true counts.
//
//   swift ios/scripts/render-header.swift 5244 2950 ios/build/header/header-5244x2950.png
//   swift ios/scripts/render-header.swift 3840 1646 ios/build/header/header-3840x1646.png
//
// Opaque PNG. App Store Connect takes either size.

import AppKit
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let arguments = Array(CommandLine.arguments.dropFirst())
guard arguments.count == 3, let width = Int(arguments[0]), let height = Int(arguments[1]) else {
    fatalError("usage: render-header.swift WIDTH HEIGHT OUT.png")
}
let out = arguments[2]

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
        data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
    )
else { fatalError("no bitmap context") }

context.setFillColor(color(0x1F2530))
context.fill(CGRect(x: 0, y: 0, width: width, height: height))

// The grid: a tile size that puts about seven rows in the frame, laid so the
// 2×2 NORA block sits at the centre. Row 0 is the bottom in Core Graphics.
let pitch = (CGFloat(height) / 7).rounded()
let gap = (pitch * 0.06).rounded()
let columns = Int((CGFloat(width) / pitch).rounded(.up)) + 2
let rows = Int((CGFloat(height) / pitch).rounded(.up)) + 2
let originX = CGFloat(width) / 2 - pitch * CGFloat(columns / 2)
let originY = CGFloat(height) / 2 - pitch * CGFloat(rows / 2)
let left = columns / 2 - 1
let bottom = rows / 2 - 1

func rect(_ row: Int, _ column: Int) -> CGRect {
    CGRect(
        x: originX + CGFloat(column) * pitch + gap / 2,
        y: originY + CGFloat(row) * pitch + gap / 2,
        width: pitch - gap,
        height: pitch - gap
    )
}

// NORA reads left to right, top to bottom: N and the mine on top, the flag and 4 below.
let nCell = (bottom + 1, left)
let mineCell = (bottom + 1, left + 1)
let flagCell = (bottom, left)
let fourCell = (bottom, left + 1)
func isNora(_ row: Int, _ column: Int) -> Bool {
    (bottom...bottom + 1).contains(row) && (left...left + 1).contains(column)
}
func isRing(_ row: Int, _ column: Int) -> Bool {
    (bottom - 1...bottom + 2).contains(row) && (left - 1...left + 2).contains(column) && !isNora(row, column)
}

// Mines: the mine and the flag, then about one cell in six from a fixed seed,
// none in the ring around NORA so that it opens.
var state: UInt64 = 0x4E4F5241  // "NORA"
func random() -> Double {
    state = state &* 6364136223846793005 &+ 1442695040888963407
    return Double(state >> 11) / Double(1 << 53)
}
var mines = Set<Int>()
func id(_ row: Int, _ column: Int) -> Int { row * columns + column }
mines.insert(id(mineCell.0, mineCell.1))
mines.insert(id(flagCell.0, flagCell.1))
for row in 0..<rows {
    for column in 0..<columns where !isNora(row, column) && !isRing(row, column) {
        if random() < 0.17 { mines.insert(id(row, column)) }
    }
}

func neighbours(_ row: Int, _ column: Int) -> [(Int, Int)] {
    var cells: [(Int, Int)] = []
    for dr in -1...1 {
        for dc in -1...1 where !(dr == 0 && dc == 0) {
            let r = row + dr, c = column + dc
            if r >= 0, r < rows, c >= 0, c < columns { cells.append((r, c)) }
        }
    }
    return cells
}
func count(_ row: Int, _ column: Int) -> Int {
    neighbours(row, column).filter { mines.contains(id($0.0, $0.1)) }.count
}

// Open the ring, then flood out from any zero in it, as a reveal does.
var open = Set<Int>()
var queue: [(Int, Int)] = []
for row in 0..<rows {
    for column in 0..<columns where isRing(row, column) { queue.append((row, column)) }
}
while let (row, column) = queue.popLast() {
    guard !open.contains(id(row, column)), !isNora(row, column), !mines.contains(id(row, column)) else { continue }
    open.insert(id(row, column))
    if count(row, column) == 0 { queue.append(contentsOf: neighbours(row, column)) }
}

// Flag the mines that touch the open area, as a player part-way through would.
var flags = Set<Int>([id(flagCell.0, flagCell.1)])
for cell in open {
    for (r, c) in neighbours(cell / columns, cell % columns) where mines.contains(id(r, c)) && !isNora(r, c) {
        if random() < 0.5 { flags.insert(id(r, c)) }
    }
}

let numberColors: [UInt32] = [0, 0x1D4ED8, 0x15803D, 0xDC2626, 0x1E1B8F, 0x7F1D1D, 0x0E7490, 0x111111, 0x555555]

func tile(_ frame: CGRect, _ fill: UInt32) {
    context.setFillColor(color(fill))
    let corner = frame.width * 0.11
    context.addPath(CGPath(roundedRect: frame, cornerWidth: corner, cornerHeight: corner, transform: nil))
    context.fillPath()
}

func text(_ string: String, _ hex: UInt32, in frame: CGRect) {
    let attributed = NSAttributedString(string: string, attributes: [
        .font: NSFont.systemFont(ofSize: frame.width * 0.64, weight: .heavy),
        .foregroundColor: NSColor(cgColor: color(hex)) ?? NSColor.black,
    ])
    let line = CTLineCreateWithAttributedString(attributed)
    let bounds = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
    context.textPosition = CGPoint(x: frame.midX - bounds.midX, y: frame.midY - bounds.midY)
    CTLineDraw(line, context)
}

func flag(in frame: CGRect) {
    // Pointing right, as on the icon, where it is the R.
    let pennant = frame.width * 0.42
    let poleWidth = frame.width * 0.06
    let pole = CGRect(
        x: frame.midX - (poleWidth + pennant) / 2, y: frame.minY + frame.height * 0.2,
        width: poleWidth, height: frame.height * 0.6
    )
    context.setFillColor(color(0x111111))
    context.fill(pole)
    context.fill(CGRect(
        x: pole.midX - frame.width * 0.135, y: pole.minY - frame.height * 0.016,
        width: frame.width * 0.27, height: frame.height * 0.085
    ))
    context.setFillColor(color(0xE03131))
    context.move(to: CGPoint(x: pole.minX, y: pole.maxY))
    context.addLine(to: CGPoint(x: pole.minX, y: pole.maxY - frame.height * 0.32))
    context.addLine(to: CGPoint(x: pole.minX + pennant + poleWidth, y: pole.maxY - frame.height * 0.16))
    context.closePath()
    context.fillPath()
}

func mine(in frame: CGRect) {
    let centre = CGPoint(x: frame.midX, y: frame.midY)
    let radius = frame.width * 0.21
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
}

// The board, with the field a step darker than NORA so the name stands out.
for row in 0..<rows {
    for column in 0..<columns where !isNora(row, column) {
        let frame = rect(row, column)
        if open.contains(id(row, column)) {
            tile(frame, 0xC5CCD6)
            let n = count(row, column)
            if n > 0 { text(String(n), numberColors[n], in: frame) }
        } else {
            tile(frame, 0x4B5567)
            if flags.contains(id(row, column)) { flag(in: frame) }
        }
    }
}

tile(rect(nCell.0, nCell.1), 0xE8ECF1)
text("N", 0x1D4ED8, in: rect(nCell.0, nCell.1))
tile(rect(mineCell.0, mineCell.1), 0xE8ECF1)
mine(in: rect(mineCell.0, mineCell.1))
tile(rect(flagCell.0, flagCell.1), 0x7A8699)
flag(in: rect(flagCell.0, flagCell.1))
tile(rect(fourCell.0, fourCell.1), 0xE8ECF1)
text("4", 0x1E1B8F, in: rect(fourCell.0, fourCell.1))

guard
    let image = context.makeImage(),
    let destination = CGImageDestinationCreateWithURL(
        URL(fileURLWithPath: out) as CFURL, UTType.png.identifier as CFString, 1, nil
    )
else { fatalError("could not write \(out)") }
CGImageDestinationAddImage(destination, image, nil)
guard CGImageDestinationFinalize(destination) else { fatalError("could not write \(out)") }
print("wrote \(out)")
