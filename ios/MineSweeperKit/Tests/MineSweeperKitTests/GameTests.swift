import Testing
@testable import MineSweeperKit

// Mirrors the board-behaviour cases in src/MineSweeper.test.tsx. Each @Test's
// display name is the TS test it mirrors, word for word; each @Suite names the
// TS describe. What the TS tests read off the DOM maps onto the engine as:
//
//   cells .................. rows × columns
//   revealed ............... cells whose appearance is .revealed
//   bombs .................. cells whose appearance is .exploded or .mine
//   flags / counter ........ flaggedIDs / minesRemaining
//   face smile/frown/hearts  state not over / .lost / .won
//   aria-label state ....... appearance(row:column:)
//
// Not mirrored, because they test presentation the app does its own way:
// "labels the board region and the reset button" and the whole
// "MineSweeper — keyboard grid navigation" describe.

/// A Beginner game whose first reveal places mines exactly at `mines`
/// ([row, column] pairs), as the TS tests' `buildBoard` mock does.
func fixture(_ mines: [(Int, Int)]) -> Game {
    Game(difficulty: .beginner, presetMineIDs: mines.map { $0.0 * 9 + $0.1 })
}

/// The board the TS chording and outcome tests share: mines at (0,1) and (8,8),
/// so opening (0,0) reveals just itself as a "1".
func twoMineBoard() -> Game {
    fixture([(0, 1), (8, 8)])
}

extension Game {
    var appearances: [CellAppearance] {
        (0..<rows).flatMap { row in (0..<columns).map { appearance(row: row, column: $0) } }
    }

    var revealedCount: Int {
        appearances.filter { if case .revealed = $0 { true } else { false } }.count
    }

    var shownBombCount: Int {
        appearances.filter { $0 == .exploded || $0 == .mine }.count
    }

    /// The TS face is a smile until the game is won or lost.
    var isSmiling: Bool { !isGameOver }

    mutating func reveal(row: Int, column: Int, seed: UInt64) {
        var generator = SeededGenerator(seed: seed)
        reveal(row: row, column: column, using: &generator)
    }
}

@Suite("MineSweeper.test.tsx › MineSweeper — behavior")
struct BehaviorTests {
    @Test("renders a board sized for the difficulty")
    func sized() {
        let game = Game(difficulty: .beginner)
        #expect(game.rows * game.columns == 81) // 9 x 9
        #expect(game.board.joined().count == 81)
        #expect(game.minesRemaining == 10) // 10 mines, none flagged
        #expect(game.isSmiling)
    }

    @Test("never loses on the first click and opens a region", arguments: seeds)
    func firstClickSafe(_ seed: UInt64) {
        var game = Game(difficulty: .beginner)
        game.reveal(row: 4, column: 4, seed: seed) // center
        // First-click safety: the opener is mine-free and cascades.
        #expect(game.revealedCount > 1)
        #expect(game.shownBombCount == 0)
        #expect(game.state == .active)
    }

    @Test("toggles a flag on right-click and updates the counter")
    func toggleFlag() {
        var game = Game(difficulty: .beginner)
        game.toggleFlag(row: 0, column: 0)
        #expect(game.flaggedIDs.count == 1)
        #expect(game.minesRemaining == 9)

        game.toggleFlag(row: 0, column: 0)
        #expect(game.flaggedIDs.isEmpty)
        #expect(game.minesRemaining == 10)
    }

    @Test("resets the board, counter, and face", arguments: seeds)
    func reset(_ seed: UInt64) {
        var game = Game(difficulty: .beginner)
        game.reveal(row: 4, column: 4, seed: seed)
        game.toggleFlag(row: 0, column: 0)
        #expect(game.revealedCount > 0)

        game.reset()
        #expect(game.revealedCount == 0)
        #expect(game.flaggedIDs.isEmpty)
        #expect(game.minesRemaining == 10)
        #expect(game.isSmiling)
        #expect(game == Game(difficulty: .beginner))
    }

    @Test("resets to a correctly sized board when difficulty changes")
    func difficultyChange() {
        // In TS the keyed provider remounts; in Swift a new difficulty is a new Game.
        let beginner = Game(difficulty: .beginner)
        #expect(beginner.board.joined().count == 81) // 9 x 9

        let expert = Game(difficulty: .expert)
        #expect(expert.board.count == 16)
        #expect(expert.board.joined().count == 480) // 16 x 30
        #expect(expert.minesRemaining == 99)
    }
}

@Suite("MineSweeper.test.tsx › MineSweeper — outcomes")
struct OutcomeTests {
    @Test("loses and reveals every mine when a bomb is clicked")
    func loses() {
        // Mine at (0,1) makes the opener (0,0) a number (reveals only itself, no
        // auto-win); a second mine at (8,8) must surface on the loss.
        var game = twoMineBoard()

        game.reveal(row: 0, column: 0) // safe opener
        #expect(game.shownBombCount == 0)
        #expect(game.isSmiling)

        game.reveal(row: 0, column: 1) // a mine
        #expect(game.state == .lost)
        #expect(game.shownBombCount == 2) // clicked + the revealed (8,8)
        #expect(game.appearance(row: 0, column: 1) == .exploded)
        #expect(game.appearance(row: 8, column: 8) == .mine)
    }

    @Test("wins when every safe cell is revealed")
    func revealWin() {
        // A single corner mine: opening (0,0) floods the rest -> reveal win.
        var game = fixture([(8, 8)])
        game.reveal(row: 0, column: 0)
        #expect(game.state == .won)
    }

    @Test("wins when exactly the mines are flagged")
    func flagWin() {
        var game = twoMineBoard()

        game.reveal(row: 0, column: 0) // place mines via the first reveal
        game.toggleFlag(row: 0, column: 1)
        #expect(game.isSmiling)
        game.toggleFlag(row: 8, column: 8) // -> win
        #expect(game.state == .won)
    }

    @Test("reveals every safe cell, empty ones included, on a flag win")
    func flagWinRevealsAll() {
        var game = twoMineBoard()

        game.reveal(row: 0, column: 0) // (0,0) is a number -> reveals only itself
        #expect(game.revealedCount == 1)
        game.toggleFlag(row: 0, column: 1)
        game.toggleFlag(row: 8, column: 8) // -> win

        #expect(game.state == .won)
        // Every cell but the two flagged mines, the count-0 ones too.
        #expect(game.revealedCount == 79)
        #expect(game.appearance(row: 4, column: 4) == .revealed(count: 0))
        #expect(game.flaggedIDs.count == 2)
    }
}

@Suite("MineSweeper.test.tsx › MineSweeper — chording")
struct ChordingTests {
    @Test("reveals the un-flagged neighbours of a correctly flagged number")
    func chordReveals() {
        var game = twoMineBoard()

        game.reveal(row: 0, column: 0) // "1", reveals only itself
        game.toggleFlag(row: 0, column: 1) // flag the real mine
        #expect(game.revealedCount == 1)

        game.chord(row: 0, column: 0)
        // (1,0) and (1,1) open; the flagged mine (0,1) is left alone.
        #expect(game.revealedCount > 1)
        #expect(game.isSmiling)
        #expect(game.shownBombCount == 0)
    }

    @Test("detonates when chording a number whose flag is misplaced")
    func chordDetonates() {
        var game = twoMineBoard()

        game.reveal(row: 0, column: 0) // "1"
        game.toggleFlag(row: 1, column: 1) // wrongly flag (1,1), not the mine

        game.chord(row: 0, column: 0) // reveals the real mine (0,1)
        #expect(game.state == .lost)
        #expect(game.shownBombCount > 0)
    }

    @Test("does nothing when the surrounding flag count does not match")
    func chordMismatch() {
        var game = twoMineBoard()

        game.reveal(row: 0, column: 0) // "1", no flags placed
        let before = game
        game.chord(row: 0, column: 0) // 0 flags != 1

        #expect(game.revealedCount == 1)
        #expect(game.shownBombCount == 0)
        #expect(game.isSmiling)
        #expect(game == before)
    }

    @Test("chords from a keyboard/left-click activation too")
    func revealChords() {
        var game = twoMineBoard()

        game.reveal(row: 0, column: 0) // "1"
        game.toggleFlag(row: 0, column: 1) // flag the mine

        game.reveal(row: 0, column: 0) // revealing the revealed number chords
        #expect(game.revealedCount > 1)
        #expect(game.isSmiling)
    }
}

@Suite("MineSweeper.test.tsx › MineSweeper — characterization")
struct CharacterizationTests {
    @Test("keeps flags placed before the first reveal", arguments: seeds)
    func flagsBeforeFirstReveal(_ seed: UInt64) {
        var game = Game(difficulty: .beginner)
        game.toggleFlag(row: 1, column: 1) // flag before any reveal
        #expect(game.flaggedIDs.count == 1)

        game.reveal(row: 4, column: 4, seed: seed) // first reveal places mines
        #expect(game.flaggedIDs.count == 1)
        #expect(game.appearance(row: 1, column: 1) == .flagged)
    }

    @Test("does not reveal a flagged cell via the cascade, and a stray flag blocks the reveal-win")
    func flagBlocksCascade() {
        var game = fixture([(8, 8)])
        game.toggleFlag(row: 4, column: 4) // flag the center first
        game.reveal(row: 0, column: 0) // opener would otherwise flood the center

        #expect(game.board[4][4].type != .revealed)
        #expect(game.flaggedIDs.count == 1)
        // Not a win: the flagged safe cell is never revealed.
        #expect(game.isSmiling)
    }

    @Test("drives the counter to 000 on a reveal win")
    func counterZeroOnWin() {
        // 10 mines clustered in a corner so opening the opposite corner floods the rest.
        var game = fixture((7...8).flatMap { r in (4...8).map { c in (r, c) } })

        game.reveal(row: 0, column: 0)
        #expect(game.state == .won)
        #expect(game.minesRemaining == 0)
    }

    @Test("shows a negative counter when over-flagging without a false win")
    func negativeCounter() {
        var game = Game(difficulty: .beginner)
        for id in 0..<11 { // 11 > 10 mines
            game.toggleFlag(row: id / 9, column: id % 9)
        }
        #expect(game.minesRemaining == -1)
        #expect(game.isSmiling)
    }

    @Test("treats clicking an already-revealed cell as a no-op", arguments: seeds)
    func revealRevealedIsNoOp(_ seed: UInt64) {
        var game = Game(difficulty: .beginner)
        game.reveal(row: 4, column: 4, seed: seed)
        let before = game

        // The first revealed cell in board order, as the TS test picks it.
        let first = (0..<81).first { game.board[$0 / 9][$0 % 9].type == .revealed }
        guard let first else {
            Issue.record("the opener revealed nothing")
            return
        }
        game.reveal(row: first / 9, column: first % 9, seed: seed)
        #expect(game == before)
        #expect(game.shownBombCount == 0)
        #expect(game.isSmiling)
    }

    @Test("restores a flagged numbered cell and a flagged mine when unflagged")
    func unflagRestores() {
        // Two mines so flagging one isn't a flag-win (which would end the game and
        // block the unflag).
        var game = twoMineBoard()
        game.reveal(row: 0, column: 0) // a number -> reveals only itself

        // (0,2) is a hidden numbered cell (adjacent to the mine); (0,1) is the mine.
        for column in [2, 1] {
            game.toggleFlag(row: 0, column: column)
            #expect(game.appearance(row: 0, column: column) == .flagged)
            game.toggleFlag(row: 0, column: column) // unflag -> restored, still hidden
            #expect(game.appearance(row: 0, column: column) == .hidden)
        }
    }
}

@Suite("MineSweeper.test.tsx › MineSweeper — accessibility")
struct AccessibilityStateTests {
    @Test("labels each cell with its position and state", arguments: seeds)
    func hiddenThenEmpty(_ seed: UInt64) {
        var game = Game(difficulty: .beginner)
        #expect(game.appearance(row: 0, column: 0) == .hidden)

        game.reveal(row: 4, column: 4, seed: seed) // safe opener -> empty
        #expect(game.appearance(row: 4, column: 4) == .revealed(count: 0))
    }

    @Test("labels a revealed numbered cell with its adjacent-mine count")
    func numbered() {
        var game = twoMineBoard()
        game.reveal(row: 0, column: 0) // 1 adjacent mine
        #expect(game.appearance(row: 0, column: 0) == .revealed(count: 1))
    }

    @Test("flags a cell with the F key and reflects it in the label")
    func flagState() {
        var game = Game(difficulty: .beginner)
        game.toggleFlag(row: 0, column: 0)
        #expect(game.flaggedIDs.count == 1)
        #expect(game.appearance(row: 0, column: 0) == .flagged)
        #expect(game.minesRemaining == 9)

        game.toggleFlag(row: 0, column: 0) // toggle off
        #expect(game.flaggedIDs.isEmpty)
        #expect(game.appearance(row: 0, column: 0) == .hidden)
    }

    @Test("announces win and loss in a live region")
    func winAndLossStates() {
        var lost = twoMineBoard()
        #expect(lost.state == .inactive)
        lost.reveal(row: 0, column: 0) // safe
        lost.reveal(row: 0, column: 1) // mine
        #expect(lost.state == .lost)

        // Win (single corner mine floods the rest on the opener)
        var won = fixture([(8, 8)])
        won.reveal(row: 0, column: 0)
        #expect(won.state == .won)
    }
}
