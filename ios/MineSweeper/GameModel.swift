import Foundation
import MineSweeperKit
import Observation
import SwiftUI

/// The game on screen: a `Game` from MineSweeperKit plus what the rules do not
/// keep, which is the clock and where the first reveal's randomness comes from.
@MainActor
@Observable
final class GameModel {
    private(set) var game: Game
    /// Set by the first reveal, and frozen with `endedAt` when the game ends.
    private(set) var startedAt: Date?
    private(set) var endedAt: Date?
    /// Set while the game is paused, which holds the clock where it was.
    private(set) var pausedAt: Date?
    /// Time spent paused this game, left off the clock.
    private var pausedFor: TimeInterval = 0
    /// Counts flags placed and removed, so a haptic fires on each. A win that
    /// flags every mine is not a toggle and does not count.
    private(set) var flagToggles = 0
    /// The Flag toggle above the board. While it is on, a tap on a hidden cell
    /// flags it instead of revealing it, so flagging never trips a mine. Every
    /// game starts with it off.
    var isFlagMode = false

    /// When set, each game's first reveal places mines from this seed, so a
    /// UI test knows where they are. Nil in normal play.
    private let seed: UInt64?

    init(difficulty: Difficulty, seed: UInt64? = nil) {
        game = Game(difficulty: difficulty)
        self.seed = seed
    }

    var difficulty: Difficulty {
        get { game.difficulty }
        set {
            guard newValue != game.difficulty else { return }
            game = Game(difficulty: newValue)
            isFlagMode = false
            clearClock()
        }
    }

    /// Whole seconds on the clock at `now`, less any time spent paused.
    func elapsedSeconds(at now: Date) -> Int {
        guard let startedAt else { return 0 }
        let stoppedAt = endedAt ?? pausedAt ?? now
        return max(0, Int(stoppedAt.timeIntervalSince(startedAt) - pausedFor))
    }

    /// True while the game is paused: the board is covered and the clock held.
    var isPaused: Bool { pausedAt != nil }

    // MARK: - Pausing

    /// Holds the clock and covers the board, when the app leaves the
    /// foreground. Only a game under way pauses: before the first reveal and
    /// after the end there is no clock running and nothing to hide.
    func pause(at now: Date = .now) {
        guard game.state == .active, pausedAt == nil else { return }
        pausedAt = now
    }

    /// Takes the paused stretch off the clock and uncovers the board.
    func resume(at now: Date = .now) {
        guard let pausedAt else { return }
        pausedFor += max(0, now.timeIntervalSince(pausedAt))
        self.pausedAt = nil
    }

    // MARK: - Moves

    /// A tap: reveals a hidden cell, or chords a revealed number. In flag
    /// mode it flags a hidden cell instead, and still chords a number.
    func tap(row: Int, column: Int) {
        guard isFlagMode else {
            reveal(row: row, column: column)
            return
        }
        longPress(row: row, column: column)
    }

    /// Reveals a hidden cell, or chords a revealed number.
    func reveal(row: Int, column: Int) {
        let before = game.state
        if let seed {
            var generator = SeededGenerator(seed: seed)
            game.reveal(row: row, column: column, using: &generator)
        } else {
            game.reveal(row: row, column: column)
        }
        noteChange(from: before)
    }

    /// A long-press: flags a hidden cell, or chords a revealed number, as a
    /// right-click does in the component.
    func longPress(row: Int, column: Int) {
        let before = game.state
        if case .revealed = game.appearance(row: row, column: column) {
            game.chord(row: row, column: column)
        } else {
            toggleFlag(row: row, column: column)
        }
        noteChange(from: before)
    }

    private func toggleFlag(row: Int, column: Int) {
        let flags = game.flaggedIDs
        game.toggleFlag(row: row, column: column)
        if game.flaggedIDs.count != flags.count {
            flagToggles += 1
        }
    }

    /// The face button: a fresh board of the same difficulty.
    func newGame() {
        game.reset()
        isFlagMode = false
        clearClock()
    }

    // MARK: - Clock and announcements

    private func noteChange(from before: GameState) {
        let now = Date.now
        if before == .inactive, game.state != .inactive {
            startedAt = now
        }
        if !isOver(before), game.isGameOver {
            endedAt = now
            AccessibilityNotification.Announcement(outcome(game.state)).post()
        }
    }

    private func isOver(_ state: GameState) -> Bool {
        state == .won || state == .lost
    }

    private func clearClock() {
        startedAt = nil
        endedAt = nil
        pausedAt = nil
        pausedFor = 0
    }
}
