import MineSweeperKit
import SwiftUI
import UIKit

struct ContentView: View {
    let model: GameModel
    @AppStorage("difficulty") private var difficultyName = Difficulty.beginner.name
    @State private var orientation = UIInterfaceOrientation.portrait

    var body: some View {
        Group {
            switch placement {
            case .top:
                VStack(spacing: 16) {
                    controls
                    BoardView(model: model)
                }
            case .left:
                HStack(spacing: 16) {
                    sideControls
                    BoardView(model: model)
                }
            case .right:
                HStack(spacing: 16) {
                    BoardView(model: model)
                    sideControls
                }
            }
        }
        .padding()
        .background(Palette.open.opacity(0.5).ignoresSafeArea())
        .background(InterfaceOrientationReader { orientation = $0 })
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

    /// Above the board upright; on the phone's top edge, beside it, on its side.
    private var placement: ControlsPlacement {
        ControlsPlacement(landscape: orientation.isLandscape, topOnRight: orientation == .landscapeLeft)
    }

    /// The controls as a column only as wide as the picker needs, centred on
    /// the edge as they are centred along the top when upright.
    private var sideControls: some View {
        controls
            .fixedSize(horizontal: true, vertical: false)
            .frame(maxHeight: .infinity)
    }

    private var controls: some View {
        @Bindable var model = model
        return VStack(spacing: 16) {
            Picker("Difficulty", selection: difficulty) {
                ForEach(Difficulty.allCases, id: \.self) { difficulty in
                    Text(difficulty.name).tag(difficulty)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("difficulty")

            // When on, a tap flags instead of revealing. Every game starts with it off.
            Toggle(isOn: $model.isFlagMode) {
                Label("Flag", systemImage: "flag.fill")
                    .frame(maxWidth: .infinity)
            }
            .toggleStyle(.button)
            .tint(Palette.flag)
            .accessibilityHint("When on, tapping a cell flags it instead of revealing it")
            .accessibilityIdentifier("flag-mode")

            ScoreboardView(model: model)
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
