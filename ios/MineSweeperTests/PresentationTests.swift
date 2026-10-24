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
        // 300 / 16 rows: the whole board fits, rather than 780 / 30 = 26.
        #expect(layout.cellSize == 18)
    }

    @Test func fitsAnUnturnedBoardToTheHeightToo() {
        // Beside the controls on a phone on its side, Beginner fits whole.
        #expect(BoardLayout(rows: 9, columns: 9, available: CGSize(width: 450, height: 340)).cellSize == 37)
        // A turned board fits the width and scrolls the rest of its height.
        #expect(BoardLayout(rows: 16, columns: 30, available: CGSize(width: 361, height: 500)).cellSize == 22)
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

@Suite("ControlsPlacement")
struct ControlsPlacementTests {
    @Test func sitsAboveTheBoardUpright() {
        #expect(ControlsPlacement(landscape: false, topOnRight: false) == .top)
        #expect(ControlsPlacement(landscape: false, topOnRight: true) == .top)
    }

    @Test func followsTheTopOfThePhoneOnItsSide() {
        #expect(ControlsPlacement(landscape: true, topOnRight: false) == .left)
        #expect(ControlsPlacement(landscape: true, topOnRight: true) == .right)
    }

    @Test func isBesideTheBoardOnlyOnItsSide() {
        #expect(!ControlsPlacement.top.isBeside)
        #expect(ControlsPlacement.left.isBeside)
        #expect(ControlsPlacement.right.isBeside)
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

    @Test func pausingHoldsTheClockAndResumingLeavesThePauseOffIt() throws {
        let model = GameModel(difficulty: .beginner, seed: 7)
        model.reveal(row: 4, column: 4)
        let started = try #require(model.startedAt)

        model.pause(at: started.addingTimeInterval(10))
        #expect(model.isPaused)
        #expect(model.elapsedSeconds(at: started.addingTimeInterval(500)) == 10)

        // Paused for 60 seconds, so 75 seconds in the clock shows 15.
        model.resume(at: started.addingTimeInterval(70))
        #expect(!model.isPaused)
        #expect(model.elapsedSeconds(at: started.addingTimeInterval(75)) == 15)

        // A second pause adds to the first.
        model.pause(at: started.addingTimeInterval(80))
        model.resume(at: started.addingTimeInterval(100))
        #expect(model.elapsedSeconds(at: started.addingTimeInterval(105)) == 25)
    }

    @Test func pausingAgainKeepsTheFirstPause() throws {
        let model = GameModel(difficulty: .beginner, seed: 7)
        model.reveal(row: 4, column: 4)
        let started = try #require(model.startedAt)
        model.pause(at: started.addingTimeInterval(10))
        model.pause(at: started.addingTimeInterval(40))
        #expect(model.pausedAt == started.addingTimeInterval(10))
    }

    @Test func onlyAGameUnderWayPauses() throws {
        let model = GameModel(difficulty: .beginner, seed: 7)
        model.pause()
        #expect(!model.isPaused)

        model.reveal(row: 4, column: 4)
        let mine = try #require(model.game.mineIDs.first)
        model.reveal(row: mine / 9, column: mine % 9)
        #expect(model.game.state == .lost)
        model.pause()
        #expect(!model.isPaused)
    }

    @Test func aNewGameClearsAPause() throws {
        let model = GameModel(difficulty: .beginner, seed: 7)
        model.reveal(row: 4, column: 4)
        model.pause()
        model.newGame()
        #expect(!model.isPaused)
        #expect(model.elapsedSeconds(at: .now) == 0)
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

    @Test func aTapRevealsUntilFlagModeIsOn() throws {
        let model = GameModel(difficulty: .beginner, seed: 7)
        #expect(!model.isFlagMode)
        model.tap(row: 4, column: 4)
        #expect(model.game.state == .active)

        // In flag mode a tap on a mine flags it, and the game goes on.
        model.isFlagMode = true
        let mine = try #require(model.game.mineIDs.first)
        model.tap(row: mine / 9, column: mine % 9)
        #expect(model.game.isFlagged(row: mine / 9, column: mine % 9))
        #expect(model.game.state == .active)
        #expect(model.flagToggles == 1)
        model.tap(row: mine / 9, column: mine % 9)
        #expect(!model.game.isFlagged(row: mine / 9, column: mine % 9))
    }

    @Test func aTapOnANumberStillChordsInFlagMode() throws {
        let model = GameModel(difficulty: .beginner, seed: 7)
        model.tap(row: 4, column: 4)
        model.isFlagMode = true

        // A revealed number with exactly one mine around it.
        let game = model.game
        let neighbours = { (row: Int, column: Int) in
            (-1...1).flatMap { dr in (-1...1).map { dc in (row + dr, column + dc) } }
                .filter { $0 != (row, column) && (0..<9).contains($0.0) && (0..<9).contains($0.1) }
        }
        let number = try #require(
            (0..<81).map { ($0 / 9, $0 % 9) }.first { row, column in
                game.appearance(row: row, column: column) == .revealed(count: 1)
                    && neighbours(row, column).contains { game.appearance(row: $0.0, column: $0.1) == .hidden }
            }
        )
        let mine = try #require(
            neighbours(number.0, number.1).first { game.board[$0.0][$0.1].isMine }
        )
        model.tap(row: mine.0, column: mine.1)
        model.tap(row: number.0, column: number.1)

        for (row, column) in neighbours(number.0, number.1) where (row, column) != mine {
            #expect(model.game.appearance(row: row, column: column) != .hidden)
        }
        #expect(model.game.state != .lost)
    }

    @Test func everyGameStartsWithFlagModeOff() {
        let model = GameModel(difficulty: .beginner)
        model.isFlagMode = true
        model.newGame()
        #expect(!model.isFlagMode)
        model.isFlagMode = true
        model.difficulty = .intermediate
        #expect(!model.isFlagMode)
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

@Suite("The seven-segment counters (presentation only, no TS counterpart)")
struct SevenSegmentTests {
    @Test func lightsEachDigitsSegments() {
        #expect(segments(for: "1") == [.b, .c])
        #expect(segments(for: "7") == [.a, .b, .c])
        #expect(segments(for: "8") == Set(Segment.allCases))
        #expect(segments(for: "0") == Set(Segment.allCases).subtracting([.g]))
    }

    @Test func givesEveryDigitADifferentShape() {
        let shapes = "0123456789".map { segments(for: $0) }
        #expect(Set(shapes).count == 10)
    }

    @Test func drawsTheMinusOfAnOverFlaggedCounter() {
        #expect(segments(for: "-") == [.g])
    }

    @Test func lightsNothingForAnythingElse() {
        #expect(segments(for: ":").isEmpty)
        #expect(segments(for: " ").isEmpty)
    }
}
