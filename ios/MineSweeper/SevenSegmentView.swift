import SwiftUI

/// The seven segments of an LED digit: a across the top, then b to f clockwise,
/// and g across the middle.
enum Segment: CaseIterable, Hashable {
    case a, b, c, d, e, f, g
}

/// The segments a character lights. Digits and "-"; anything else lights none.
func segments(for character: Character) -> Set<Segment> {
    switch character {
    case "0": [.a, .b, .c, .d, .e, .f]
    case "1": [.b, .c]
    case "2": [.a, .b, .d, .e, .g]
    case "3": [.a, .b, .c, .d, .g]
    case "4": [.b, .c, .f, .g]
    case "5": [.a, .c, .d, .f, .g]
    case "6": [.a, .c, .d, .e, .f, .g]
    case "7": [.a, .b, .c]
    case "8": Set(Segment.allCases)
    case "9": [.a, .b, .c, .d, .f, .g]
    case "-": [.g]
    default: []
    }
}

/// Red segments on black, like the classic game's counters, with the unlit
/// segments faintly showing. Drawn, not a font, so there is no font licence to
/// carry (MINE-18). The text is the formatted counter or clock: digits, "-" and
/// ":". It reads to VoiceOver as whatever label the caller gives it.
struct SevenSegmentView: View {
    let text: String
    var digitHeight: CGFloat = 30

    var body: some View {
        HStack(spacing: digitHeight * 0.12) {
            ForEach(Array(text.enumerated()), id: \.offset) { _, character in
                if character == ":" {
                    colon
                } else {
                    digit(segments(for: character))
                }
            }
        }
        .padding(.horizontal, digitHeight * 0.18)
        .padding(.vertical, digitHeight * 0.15)
        .background(Palette.ledBackground)
        .bevel(2, raised: false)
    }

    private func digit(_ lit: Set<Segment>) -> some View {
        ZStack {
            SegmentsShape(segments: Set(Segment.allCases).subtracting(lit)).fill(Palette.ledUnlit)
            SegmentsShape(segments: lit).fill(Palette.ledLit)
        }
        .frame(width: digitHeight * 0.55, height: digitHeight)
    }

    private var colon: some View {
        let dot = digitHeight * 0.12
        return VStack(spacing: digitHeight * 0.3) {
            Rectangle().fill(Palette.ledLit).frame(width: dot, height: dot)
            Rectangle().fill(Palette.ledLit).frame(width: dot, height: dot)
        }
        .frame(height: digitHeight)
    }
}

/// The given segments of one digit, each a bar with pointed ends.
private struct SegmentsShape: Shape {
    let segments: Set<Segment>

    func path(in rect: CGRect) -> Path {
        let thickness = rect.width * 0.2
        let gap = thickness * 0.15
        let left = rect.minX + thickness / 2
        let right = rect.maxX - thickness / 2
        let top = rect.minY + thickness / 2
        let middle = rect.midY
        let bottom = rect.maxY - thickness / 2

        var path = Path()
        for segment in segments {
            let (start, end): (CGPoint, CGPoint) = switch segment {
            case .a: (CGPoint(x: left, y: top), CGPoint(x: right, y: top))
            case .b: (CGPoint(x: right, y: top), CGPoint(x: right, y: middle))
            case .c: (CGPoint(x: right, y: middle), CGPoint(x: right, y: bottom))
            case .d: (CGPoint(x: left, y: bottom), CGPoint(x: right, y: bottom))
            case .e: (CGPoint(x: left, y: middle), CGPoint(x: left, y: bottom))
            case .f: (CGPoint(x: left, y: top), CGPoint(x: left, y: middle))
            case .g: (CGPoint(x: left, y: middle), CGPoint(x: right, y: middle))
            }
            path.addPath(bar(from: start, to: end, thickness: thickness, gap: gap))
        }
        return path
    }

    /// A horizontal or vertical bar along a centre line, its ends pointed and
    /// pulled in by `gap` so neighbouring segments don't touch.
    private func bar(from start: CGPoint, to end: CGPoint, thickness: CGFloat, gap: CGFloat) -> Path {
        let half = thickness / 2
        var path = Path()
        if start.y == end.y {
            let x0 = start.x + gap, x1 = end.x - gap, y = start.y
            path.move(to: CGPoint(x: x0, y: y))
            path.addLine(to: CGPoint(x: x0 + half, y: y - half))
            path.addLine(to: CGPoint(x: x1 - half, y: y - half))
            path.addLine(to: CGPoint(x: x1, y: y))
            path.addLine(to: CGPoint(x: x1 - half, y: y + half))
            path.addLine(to: CGPoint(x: x0 + half, y: y + half))
        } else {
            let y0 = start.y + gap, y1 = end.y - gap, x = start.x
            path.move(to: CGPoint(x: x, y: y0))
            path.addLine(to: CGPoint(x: x + half, y: y0 + half))
            path.addLine(to: CGPoint(x: x + half, y: y1 - half))
            path.addLine(to: CGPoint(x: x, y: y1))
            path.addLine(to: CGPoint(x: x - half, y: y1 - half))
            path.addLine(to: CGPoint(x: x - half, y: y0 + half))
        }
        path.closeSubpath()
        return path
    }
}
