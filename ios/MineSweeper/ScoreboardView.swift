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
            SevenSegmentView(text: formatCounter(model.game.minesRemaining))
                .accessibilityElement()
                .accessibilityLabel("Mines remaining: \(model.game.minesRemaining)")
                .accessibilityIdentifier("mines-remaining")
            spacer
            Button(action: model.newGame) {
                FaceView(state: model.game.state)
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(FaceButtonStyle())
            .accessibilityLabel("New game")
            .accessibilityValue(outcome(model.game.state))
            .accessibilityIdentifier("new-game")
            spacer
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let seconds = model.elapsedSeconds(at: context.date)
                SevenSegmentView(text: formatTimer(seconds: seconds))
                    .accessibilityElement()
                    .accessibilityLabel(timerLabel(seconds: seconds))
                    .accessibilityIdentifier("timer")
            }
        }
        .padding(10)
        .background(Palette.panel)
        .bevel(3, raised: false)
    }

    /// Spreads the row across the width; a column stays packed.
    @ViewBuilder private var spacer: some View {
        if axis == .horizontal {
            Spacer()
        }
    }
}

/// The face's square button: raised, and sunken while pressed.
private struct FaceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .offset(x: configuration.isPressed ? 1 : 0, y: configuration.isPressed ? 1 : 0)
            .frame(width: 48, height: 48)
            .background(Palette.panel)
            .bevel(3, raised: !configuration.isPressed)
            .overlay(Rectangle().stroke(Palette.grid, lineWidth: 1))
    }
}
