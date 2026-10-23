import MineSweeperKit
import SwiftUI
import UIKit

struct ContentView: View {
    let model: GameModel
    @AppStorage("difficulty") private var difficultyName = Difficulty.beginner.name
    @State private var orientation = UIInterfaceOrientation.portrait
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            switch placement {
            case .top:
                VStack(spacing: 16) {
                    controls(beside: false)
                    board
                }
            case .left:
                HStack(spacing: 16) {
                    sideControls
                    board
                }
            case .right:
                HStack(spacing: 16) {
                    board
                    sideControls
                }
            }
        }
        // On its side the safe area already holds the content 59pt off each end.
        .padding(placement.isBeside ? .vertical : .all)
        .background(Palette.open.opacity(0.5).ignoresSafeArea())
        .background(InterfaceOrientationReader { orientation = $0 })
        .onAppear { model.difficulty = difficulty.wrappedValue }
        // Looking away (another app, the app switcher, Control Center, the lock
        // button) pauses a game under way. It stays paused until the paused screen
        // is tapped.
        .onChange(of: scenePhase) { _, phase in
            if phase != .active {
                model.pause()
            }
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: model.flagToggles)
        .sensoryFeedback(trigger: model.game.state) { _, new in
            switch new {
            case .lost: .error
            case .won: .success
            case .inactive, .active: nil
            }
        }
    }

    /// The board, covered while the game is paused. It stays underneath so it
    /// keeps its zoom, but out of reach of a tap and of VoiceOver.
    private var board: some View {
        BoardView(model: model)
            .accessibilityHidden(model.isPaused)
            .overlay {
                if model.isPaused {
                    PausedView { model.resume() }
                }
            }
    }

    /// Above the board upright; on the phone's top edge, beside it, on its side.
    private var placement: ControlsPlacement {
        ControlsPlacement(landscape: orientation.isLandscape, topOnRight: orientation == .landscapeLeft)
    }

    /// The controls as a narrow column, centred on the edge as they are centred
    /// along the top when upright. The picker is a menu and the scoreboard a
    /// column, so the board gets the width a row of either would take.
    private var sideControls: some View {
        controls(beside: true)
            .fixedSize(horizontal: true, vertical: false)
            .frame(maxHeight: .infinity)
    }

    private func controls(beside: Bool) -> some View {
        @Bindable var model = model
        return VStack(spacing: 16) {
            Group {
                if beside {
                    picker.pickerStyle(.menu)
                } else {
                    picker.pickerStyle(.segmented)
                }
            }
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

            ScoreboardView(model: model, axis: beside ? .vertical : .horizontal)
        }
    }

    private var picker: some View {
        Picker("Difficulty", selection: difficulty) {
            ForEach(Difficulty.allCases, id: \.self) { difficulty in
                Text(difficulty.name).tag(difficulty)
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
