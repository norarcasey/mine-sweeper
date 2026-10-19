import CoreGraphics
import MineSweeperKit
import Testing
@testable import MineSweeper

@Suite("formatCounter.test.ts › formatCounter")
struct FormatCounterTests {
    @Test("zero-pads non-negative values to three digits")
    func zeroPads() {
        #expect(formatCounter(0) == "000")
        #expect(formatCounter(9) == "009")
        #expect(formatCounter(40) == "040")
        #expect(formatCounter(99) == "099")
    }

    @Test("renders negative values with a sign and two digits")
    func negative() {
        #expect(formatCounter(-1) == "-01")
        #expect(formatCounter(-9) == "-09")
        #expect(formatCounter(-10) == "-10")
    }
}

@Suite("Timer.tsx, as the app shows it")
struct TimerTests {
    @Test func formatsMinutesAndSeconds() {
        #expect(formatTimer(seconds: 0) == "00:00")
        #expect(formatTimer(seconds: 59) == "00:59")
        #expect(formatTimer(seconds: 61) == "01:01")
        #expect(formatTimer(seconds: 3600) == "60:00")
    }

    @Test func labelsOneSecondInTheSingular() {
        #expect(timerLabel(seconds: 1) == "Time elapsed: 1 second")
        #expect(timerLabel(seconds: 2) == "Time elapsed: 2 seconds")
    }
}

@Suite("Cell.tsx › describeState, as the app labels cells")
struct CellLabelTests {
    @Test func labelsEveryAppearance() {
        #expect(cellLabel(row: 0, column: 0, appearance: .hidden) == "Row 1, column 1, hidden")
        #expect(cellLabel(row: 2, column: 4, appearance: .flagged) == "Row 3, column 5, flagged")
        #expect(cellLabel(row: 0, column: 1, appearance: .revealed(count: 0)) == "Row 1, column 2, empty")
        #expect(cellLabel(row: 0, column: 1, appearance: .revealed(count: 1)) == "Row 1, column 2, 1 adjacent mine")
        #expect(cellLabel(row: 0, column: 1, appearance: .revealed(count: 3)) == "Row 1, column 2, 3 adjacent mines")
        #expect(cellLabel(row: 8, column: 8, appearance: .exploded) == "Row 9, column 9, mine, exploded")
        #expect(cellLabel(row: 8, column: 8, appearance: .mine) == "Row 9, column 9, mine")
    }

    @Test func announcesTheOutcome() {
        #expect(outcome(.won) == "You won!")
        #expect(outcome(.lost) == "You lost!")
        #expect(outcome(.active) == "")
    }
}

@Suite("BoardLayout")
struct BoardLayoutTests {
    let portrait = CGSize(width: 361, height: 600)
    let landscape = CGSize(width: 780, height: 300)

    @Test func turnsExpertOnItsSideInPortrait() {
        let layout = BoardLayout(rows: 16, columns: 30, available: portrait)
        #expect(layout.transposed)
        #expect(layout.rows == 30)
        #expect(layout.columns == 16)
        #expect(layout.cellSize == 22)
    }

    @Test func keepsExpertAsItIsInLandscape() {
        let layout = BoardLayout(rows: 16, columns: 30, available: landscape)
        #expect(!layout.transposed)
        #expect(layout.rows == 16)
        #expect(layout.columns == 30)
        #expect(layout.cellSize == 26)
    }

    @Test func neverTurnsASquareBoard() {
        #expect(!BoardLayout(rows: 9, columns: 9, available: portrait).transposed)
        #expect(!BoardLayout(rows: 16, columns: 16, available: portrait).transposed)
    }

    @Test func capsTheCellAndScalesItByZoom() {
        #expect(BoardLayout(rows: 9, columns: 9, available: CGSize(width: 800, height: 900)).cellSize == 44)
        // The cap is on the fitted size; zoom may go past it.
        #expect(BoardLayout(rows: 16, columns: 16, available: portrait, zoom: 2).cellSize == 45)
    }

    @Test func mapsATurnedCellBackToTheGame() {
        let layout = BoardLayout(rows: 16, columns: 30, available: portrait)
        #expect(layout.gamePosition(row: 29, column: 0) == Coordinate(row: 0, column: 29))
        let flat = BoardLayout(rows: 16, columns: 30, available: landscape)
        #expect(flat.gamePosition(row: 3, column: 7) == Coordinate(row: 3, column: 7))
    }
}

@Suite("GameModel")
@MainActor
struct GameModelTests {
    @Test func theSameSeedLaysTheSameMines() {
        let one = GameModel(difficulty: .beginner, seed: 7)
        let two = GameModel(difficulty: .beginner, seed: 7)
        one.reveal(row: 4, column: 4)
        two.reveal(row: 4, column: 4)
        #expect(one.game.mineIDs == two.game.mineIDs)
        #expect(one.game.mineIDs.count == 10)
    }

    @Test func aNewGameWithASeedLaysTheSameMinesAgain() {
        let model = GameModel(difficulty: .beginner, seed: 7)
        model.reveal(row: 4, column: 4)
        let first = model.game.mineIDs
        model.newGame()
        model.reveal(row: 4, column: 4)
        #expect(model.game.mineIDs == first)
    }

    @Test func startsTheClockOnTheFirstRevealAndStopsItAtTheEnd() throws {
        let model = GameModel(difficulty: .beginner, seed: 7)
        #expect(model.startedAt == nil)
        model.reveal(row: 4, column: 4)
        let started = try #require(model.startedAt)
        #expect(model.endedAt == nil)

        let mine = try #require(model.game.mineIDs.first)
        model.reveal(row: mine / 9, column: mine % 9)
        #expect(model.game.state == .lost)
        let ended = try #require(model.endedAt)
        #expect(model.elapsedSeconds(at: ended.addingTimeInterval(100)) == model.elapsedSeconds(at: ended))
        #expect(ended >= started)
    }

    @Test func longPressFlagsAHiddenCellAndCountsTheToggle() {
        let model = GameModel(difficulty: .beginner)
        model.longPress(row: 0, column: 0)
        #expect(model.game.isFlagged(row: 0, column: 0))
        #expect(model.flagToggles == 1)
        model.longPress(row: 0, column: 0)
        #expect(!model.game.isFlagged(row: 0, column: 0))
        #expect(model.flagToggles == 2)
    }

    @Test func changingDifficultyStartsAFreshBoardAndClock() {
        let model = GameModel(difficulty: .beginner, seed: 7)
        model.reveal(row: 4, column: 4)
        model.difficulty = .expert
        #expect(model.game.rows == 16)
        #expect(model.game.columns == 30)
        #expect(model.game.state == .inactive)
        #expect(model.startedAt == nil)
    }
}
