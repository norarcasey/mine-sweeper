import MineSweeperKit
import SwiftUI

/// One cell. Tap reveals (or chords a number, or flags in flag mode);
/// long-press flags (or chords).
struct CellView: View {
    let row: Int
    let column: Int
    let appearance: CellAppearance
    let size: CGFloat
    let onTap: () -> Void
    let onLongPress: () -> Void

    var body: some View {
        ZStack {
            background
            content
        }
        .frame(width: size, height: size)
        .contentShape(Rectangle())
        // One gesture, so a long-press is never also a tap: the long press is
        // tried first, and the tap only counts when it fails.
        .gesture(
            LongPressGesture(minimumDuration: 0.3)
                .exclusively(before: TapGesture())
                .onEnded { value in
                    switch value {
                    case .first: onLongPress()
                    case .second: onTap()
                    }
                }
        )
        .accessibilityElement()
        .accessibilityIdentifier("cell-\(row)-\(column)")
        .accessibilityLabel(cellLabel(row: row, column: column, appearance: appearance))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(.default, onTap)
        .accessibilityActions {
            switch appearance {
            case .hidden:
                Button("Flag", action: onLongPress)
            case .flagged:
                Button("Unflag", action: onLongPress)
            case .revealed, .exploded, .mine:
                EmptyView()
            }
        }
    }

    private var isOpen: Bool {
        switch appearance {
        case .revealed, .exploded, .mine: true
        case .hidden, .flagged: false
        }
    }

    @ViewBuilder
    private var background: some View {
        let inset = max(0.5, size * 0.04)
        if appearance == .exploded {
            Rectangle().fill(Color.red)
        } else if isOpen {
            Rectangle()
                .fill(Palette.open)
                .overlay(Rectangle().stroke(Palette.grid, lineWidth: 0.5))
        } else {
            Rectangle()
                .fill(Palette.tile)
                .overlay(Rectangle().stroke(Palette.grid, lineWidth: 0.5))
                .padding(inset)
                .background(Palette.open)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch appearance {
        case .hidden:
            EmptyView()
        case .flagged:
            Image(systemName: "flag.fill")
                .font(.system(size: size * 0.5))
                .foregroundStyle(Palette.flag)
        case .exploded, .mine:
            Text(verbatim: "💣")
                .font(.system(size: size * 0.55))
        case let .revealed(count) where count > 0:
            Text(verbatim: "\(count)")
                .font(.system(size: size * 0.6, weight: .heavy, design: .rounded))
                .foregroundStyle(Palette.number(count))
        case .revealed:
            EmptyView()
        }
    }
}
