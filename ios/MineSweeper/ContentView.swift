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
        .background(Palette.window.ignoresSafeArea())
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
        VStack(spacing: 16) {
            Group {
                if beside {
                    picker.pickerStyle(.menu)
                } else {
                    picker.pickerStyle(.segmented)
                }
            }
            .accessibilityIdentifier("difficulty")

            ScoreboardView(model: model, axis: beside ? .vertical : .horizontal)

            // Under the scoreboard, Flag under the clock and away from the face, so
            // reaching for it never starts a new game. Beside the board the two are
            // icons, to keep the column narrow.
            HStack(spacing: 8) {
                pauseButton
                flagToggle
            }
            .labelStyle(ControlLabelStyle(iconOnly: beside))
        }
    }

    /// When on, a tap flags instead of revealing. Every game starts with it off.
    /// Outlined like Pause while off, and filled while on, so its state shows at
    /// a glance.
    @ViewBuilder private var flagToggle: some View {
        @Bindable var model = model
        let toggle = Toggle(isOn: $model.isFlagMode) {
            Label("Flag", systemImage: "flag.fill")
                .frame(maxWidth: .infinity)
        }
        .toggleStyle(.button)
        .tint(Palette.flag)
        .accessibilityLabel("Flag")
        .accessibilityHint("When on, tapping a cell flags it instead of revealing it")
        .accessibilityIdentifier("flag-mode")

        if model.isFlagMode {
            toggle.buttonStyle(.borderedProminent)
        } else {
            toggle.buttonStyle(.bordered)
        }
    }

    /// Pauses a game under way, as looking away does, and resumes it. Before the
    /// first reveal and after the end there is no clock to hold.
    private var pauseButton: some View {
        Button {
            if model.isPaused {
                model.resume()
            } else {
                model.pause()
            }
        } label: {
            Label(pauseTitle, systemImage: model.isPaused ? "play.fill" : "pause.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(Palette.ink)
        .disabled(model.game.state != .active)
        .accessibilityLabel(pauseTitle)
        .accessibilityIdentifier("pause")
    }

    private var pauseTitle: String { model.isPaused ? "Resume" : "Pause" }

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

/// A control's icon and title, or the icon alone in the narrow column beside
/// the board. Each control sets its VoiceOver label itself, so dropping the
/// title loses nothing.
private struct ControlLabelStyle: LabelStyle {
    let iconOnly: Bool

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) {
            configuration.icon
            if !iconOnly {
                configuration.title
            }
        }
    }
}

#Preview {
    ContentView(model: GameModel(difficulty: .beginner))
}
