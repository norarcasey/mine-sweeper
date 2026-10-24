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

    /// A raised grey tile until it opens; then flat, with a thin line on its
    /// top and left edges as the classic board draws it.
    @ViewBuilder
    private var background: some View {
        if isOpen {
            Rectangle()
                .fill(appearance == .exploded ? Palette.exploded : Palette.open)
                .overlay(alignment: .topLeading) {
                    BevelEdge(width: max(0.5, size * 0.03), topLeft: true).fill(Palette.grid)
                }
        } else {
            Rectangle()
                .fill(Palette.panel)
                .bevel(max(1.5, size * 0.1))
        }
    }

    @ViewBuilder
    private var content: some View {
        switch appearance {
        case .hidden:
            EmptyView()
        case .flagged:
            FlagView()
                .padding(size * 0.12)
        case .exploded, .mine:
            MineView()
                .padding(size * 0.1)
        case let .revealed(count) where count > 0:
            Text(verbatim: "\(count)")
                .font(.system(size: size * 0.6, weight: .heavy, design: .rounded))
                .foregroundStyle(Palette.number(count))
        case .revealed:
            EmptyView()
        }
    }
}
