import MineSweeperKit
import SwiftUI

struct ContentView: View {
    let model: GameModel
    @AppStorage("difficulty") private var difficultyName = Difficulty.beginner.name

    var body: some View {
        VStack(spacing: 16) {
            Picker("Difficulty", selection: difficulty) {
                ForEach(Difficulty.allCases, id: \.self) { difficulty in
                    Text(difficulty.name).tag(difficulty)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("difficulty")

            ScoreboardView(model: model)
            BoardView(model: model)
        }
        .padding()
        .background(Palette.open.opacity(0.5).ignoresSafeArea())
        .onAppear { model.difficulty = difficulty.wrappedValue }
        .sensoryFeedback(.impact(weight: .medium), trigger: model.flagToggles)
        .sensoryFeedback(trigger: model.game.state) { _, new in
            switch new {
            case .lost: .error
            case .won: .success
            case .inactive, .active: nil
            }
        }
    }

    /// The picker's choice, kept between launches. Changing it starts a new game.
    private var difficulty: Binding<Difficulty> {
        Binding(
            get: { Difficulty(name: difficultyName) ?? .beginner },
            set: { newValue in
                difficultyName = newValue.name
                model.difficulty = newValue
            }
        )
    }
}

#Preview {
    ContentView(model: GameModel(difficulty: .beginner))
}
