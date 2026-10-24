// The classic look's pieces, every one drawn here in SwiftUI: the bevel, the
// mine, the flag and the face. None is copied or traced from any other game's
// art (MINE-18), and none is an emoji, so App Store guideline 5.2.5 doesn't come
// into it.

import MineSweeperKit
import SwiftUI

/// One side of a bevel: the top and left edges, or the bottom and right, each
/// `width` deep with mitred corners. The CSS `ridge` borders, drawn.
struct BevelEdge: Shape {
    let width: CGFloat
    let topLeft: Bool

    func path(in rect: CGRect) -> Path {
        let w = min(width, rect.width / 2, rect.height / 2)
        var path = Path()
        if topLeft {
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - w, y: rect.minY + w))
            path.addLine(to: CGPoint(x: rect.minX + w, y: rect.minY + w))
            path.addLine(to: CGPoint(x: rect.minX + w, y: rect.maxY - w))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        } else {
            path.move(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX + w, y: rect.maxY - w))
            path.addLine(to: CGPoint(x: rect.maxX - w, y: rect.maxY - w))
            path.addLine(to: CGPoint(x: rect.maxX - w, y: rect.minY + w))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        }
        path.closeSubpath()
        return path
    }
}

extension View {
    /// Raised: lit top and left, shaded bottom and right. Sunken is the other
    /// way round, as a well or a pressed button.
    func bevel(_ width: CGFloat, raised: Bool = true) -> some View {
        overlay {
            ZStack {
                BevelEdge(width: width, topLeft: true)
                    .fill(raised ? Palette.highlight : Palette.shadow)
                BevelEdge(width: width, topLeft: false)
                    .fill(raised ? Palette.shadow : Palette.highlight)
            }
            .allowsHitTesting(false)
        }
    }
}

/// A round mine with eight spikes and a shine.
struct MineView: View {
    var body: some View {
        Canvas { context, size in
            let side = min(size.width, size.height)
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let ink = GraphicsContext.Shading.color(Palette.mine)

            var spikes = Path()
            for step in 0..<8 {
                let angle = Double(step) * .pi / 4
                // The straight spikes reach further than the diagonal ones.
                let reach = side * (step.isMultiple(of: 2) ? 0.42 : 0.33)
                spikes.move(to: center)
                spikes.addLine(to: CGPoint(
                    x: center.x + reach * cos(angle),
                    y: center.y + reach * sin(angle)
                ))
            }
            context.stroke(spikes, with: ink, style: StrokeStyle(lineWidth: max(1, side * 0.08), lineCap: .round))

            let radius = side * 0.27
            context.fill(Path(ellipseIn: CGRect(
                x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2
            )), with: ink)

            let shine = radius * 0.38
            context.fill(Path(ellipseIn: CGRect(
                x: center.x - radius * 0.55, y: center.y - radius * 0.55, width: shine, height: shine
            )), with: .color(Palette.mineShine))
        }
        .accessibilityHidden(true)
    }
}

/// A red pennant on a pole, standing on a two-step foot.
struct FlagView: View {
    var body: some View {
        Canvas { context, size in
            let side = min(size.width, size.height)
            let origin = CGPoint(x: (size.width - side) / 2, y: (size.height - side) / 2)
            func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
                CGPoint(x: origin.x + x * side, y: origin.y + y * side)
            }
            func box(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> Path {
                Path(CGRect(x: origin.x + x * side, y: origin.y + y * side, width: width * side, height: height * side))
            }

            var pennant = Path()
            pennant.move(to: point(0.56, 0.14))
            pennant.addLine(to: point(0.56, 0.52))
            pennant.addLine(to: point(0.2, 0.33))
            pennant.closeSubpath()
            context.fill(pennant, with: .color(Palette.flag))

            let ink = GraphicsContext.Shading.color(Palette.ink)
            context.fill(box(0.5, 0.14, 0.08, 0.6), with: ink)
            context.fill(box(0.36, 0.7, 0.36, 0.07), with: ink)
            context.fill(box(0.24, 0.77, 0.6, 0.09), with: ink)
        }
        .accessibilityHidden(true)
    }
}

/// The new-game face: a smile while playing, a frown on a loss, and heart eyes
/// on a win, as the component's 🙂 🙁 😍.
struct FaceView: View {
    let state: GameState

    var body: some View {
        Canvas { context, size in
            let side = min(size.width, size.height)
            let rect = CGRect(
                x: (size.width - side) / 2, y: (size.height - side) / 2, width: side, height: side
            ).insetBy(dx: side * 0.04, dy: side * 0.04)
            let ink = GraphicsContext.Shading.color(Palette.smileyInk)
            let line = max(1, side * 0.06)
            func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
                CGPoint(x: rect.minX + x * rect.width, y: rect.minY + y * rect.height)
            }

            let head = Path(ellipseIn: rect)
            context.fill(head, with: .color(Palette.smiley))
            context.stroke(head, with: ink, lineWidth: line)

            for x in [0.34, 0.66] {
                if state == .won {
                    context.fill(heart(at: point(x, 0.38), size: rect.width * 0.2), with: .color(Palette.flag))
                } else {
                    let eye = rect.width * 0.1
                    let center = point(x, 0.38)
                    context.fill(Path(ellipseIn: CGRect(
                        x: center.x - eye / 2, y: center.y - eye / 2, width: eye, height: eye
                    )), with: ink)
                }
            }

            var mouth = Path()
            if state == .lost {
                mouth.move(to: point(0.3, 0.74))
                mouth.addQuadCurve(to: point(0.7, 0.74), control: point(0.5, 0.56))
            } else {
                mouth.move(to: point(0.28, 0.6))
                mouth.addQuadCurve(to: point(0.72, 0.6), control: point(0.5, 0.84))
            }
            context.stroke(mouth, with: ink, style: StrokeStyle(lineWidth: line, lineCap: .round))
        }
        .accessibilityHidden(true)
    }

    /// A heart `size` across, centred on `center`.
    private func heart(at center: CGPoint, size: CGFloat) -> Path {
        let half = size / 2
        var path = Path()
        path.move(to: CGPoint(x: center.x, y: center.y + half))
        path.addCurve(
            to: CGPoint(x: center.x - half, y: center.y - half * 0.3),
            control1: CGPoint(x: center.x - half * 0.3, y: center.y + half * 0.6),
            control2: CGPoint(x: center.x - half, y: center.y + half * 0.2)
        )
        path.addArc(
            center: CGPoint(x: center.x - half / 2, y: center.y - half * 0.3),
            radius: half / 2, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false
        )
        path.addArc(
            center: CGPoint(x: center.x + half / 2, y: center.y - half * 0.3),
            radius: half / 2, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false
        )
        path.addCurve(
            to: CGPoint(x: center.x, y: center.y + half),
            control1: CGPoint(x: center.x + half, y: center.y + half * 0.2),
            control2: CGPoint(x: center.x + half * 0.3, y: center.y + half * 0.6)
        )
        path.closeSubpath()
        return path
    }
}
