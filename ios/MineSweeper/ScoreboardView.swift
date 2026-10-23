import MineSweeperKit
import SwiftUI

/// Mines left, the face that starts a new game, and the clock. Mirrors
/// `src/components/Scoreboard.tsx`. A row above the board; a column, top to
/// bottom in the same order, beside it.
struct ScoreboardView: View {
    let model: GameModel
    var axis: Axis = .horizontal

    var body: some View {
        let layout = axis == .horizontal ? AnyLayout(HStackLayout()) : AnyLayout(VStackLayout(spacing: 12))
        layout {
            LEDText(formatCounter(model.game.minesRemaining))
                .accessibilityElement()
                .accessibilityLabel("Mines remaining: \(model.game.minesRemaining)")
                .accessibilityIdentifier("mines-remaining")
            spacer
            Button(action: model.newGame) {
                Text(verbatim: face)
                    .font(.system(size: 34))
                    .frame(width: 52, height: 52)
                    .background(Palette.tile, in: RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("New game")
            .accessibilityValue(outcome(model.game.state))
            .accessibilityIdentifier("new-game")
            spacer
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let seconds = model.elapsedSeconds(at: context.date)
                LEDText(formatTimer(seconds: seconds))
                    .accessibilityElement()
                    .accessibilityLabel(timerLabel(seconds: seconds))
                    .accessibilityIdentifier("timer")
            }
        }
    }

    /// Spreads the row across the width; a column stays packed.
    @ViewBuilder private var spacer: some View {
        if axis == .horizontal {
            Spacer()
        }
    }

    /// The component's smile, frown and heart-eyes.
    private var face: String {
        switch model.game.state {
        case .lost: "🙁"
        case .won: "😍"
        case .inactive, .active: "🙂"
        }
    }
}

/// Red digits on black, like the classic game's counters.
private struct LEDText: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(verbatim: text)
            .font(.system(size: 26, weight: .bold, design: .monospaced))
            .foregroundStyle(Color.red)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.black, in: RoundedRectangle(cornerRadius: 6))
    }
}
