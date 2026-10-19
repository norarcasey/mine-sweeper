import MineSweeperKit
import SwiftUI

/// Mines left, the face that starts a new game, and the clock. Mirrors
/// `src/components/Scoreboard.tsx`.
struct ScoreboardView: View {
    let model: GameModel

    var body: some View {
        HStack {
            LEDText(formatCounter(model.game.minesRemaining))
                .accessibilityElement()
                .accessibilityLabel("Mines remaining: \(model.game.minesRemaining)")
                .accessibilityIdentifier("mines-remaining")
            Spacer()
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
            Spacer()
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let seconds = model.elapsedSeconds(at: context.date)
                LEDText(formatTimer(seconds: seconds))
                    .accessibilityElement()
                    .accessibilityLabel(timerLabel(seconds: seconds))
                    .accessibilityIdentifier("timer")
            }
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
