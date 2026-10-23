import MineSweeperKit
import XCTest

/// A win and a loss on a seeded Beginner board. The app is launched with
/// `-seed`, and the test replays the same `Game` with the same seed, so it
/// knows where every mine is without the app telling it.
@MainActor
final class GameUITests: XCTestCase {
    private static let seed: UInt64 = 7
    private static let opener = Coordinate(row: 4, column: 4)

    private let app = XCUIApplication()

    override func setUp() async throws {
        continueAfterFailure = false
        app.launchArguments = ["-seed", String(Self.seed), "-difficulty", "Beginner"]
        app.launch()
    }

    override func tearDown() async throws {
        XCUIDevice.shared.orientation = .portrait
    }

    /// The board the app will lay down after the opening reveal.
    private func replay() -> Game {
        var game = Game(difficulty: .beginner)
        var generator = SeededGenerator(seed: Self.seed)
        game.reveal(row: Self.opener.row, column: Self.opener.column, using: &generator)
        return game
    }

    private func cell(_ row: Int, _ column: Int) -> XCUIElement {
        app.descendants(matching: .any)["cell-\(row)-\(column)"]
    }

    private func tap(_ row: Int, _ column: Int) {
        let element = cell(row, column)
        XCTAssertTrue(element.waitForExistence(timeout: 5), "no cell at \(row), \(column)")
        element.tap()
    }

    func testRevealingEverySafeCellWins() {
        var game = replay()
        tap(Self.opener.row, Self.opener.column)
        XCTAssertEqual(cell(Self.opener.row, Self.opener.column).label, "Row 5, column 5, empty")

        // Tap each safe cell the flood fill has not opened, in the app and in
        // the replay, until the replay says the game is won.
        for row in 0..<game.rows {
            for column in 0..<game.columns where game.state == .active {
                guard game.appearance(row: row, column: column) == .hidden,
                      !game.board[row][column].isMine
                else { continue }
                game.reveal(row: row, column: column)
                tap(row, column)
            }
        }
        XCTAssertEqual(game.state, .won)

        XCTAssertEqual(app.buttons["new-game"].value as? String, "You won!")
        XCTAssertEqual(app.descendants(matching: .any)["mines-remaining"].label, "Mines remaining: 0")
    }

    func testRevealingAMineLoses() throws {
        let game = replay()
        tap(Self.opener.row, Self.opener.column)

        // A long-press flags, and never reveals: one mine is flagged, another
        // is tapped.
        let flagged = try XCTUnwrap(game.mineIDs.last)
        let flaggedRow = flagged / game.columns
        let flaggedColumn = flagged % game.columns
        cell(flaggedRow, flaggedColumn).press(forDuration: 0.6)
        XCTAssertEqual(
            cell(flaggedRow, flaggedColumn).label,
            "Row \(flaggedRow + 1), column \(flaggedColumn + 1), flagged"
        )
        XCTAssertEqual(app.descendants(matching: .any)["mines-remaining"].label, "Mines remaining: 9")

        let mine = try XCTUnwrap(game.mineIDs.first)
        let row = mine / game.columns
        let column = mine % game.columns
        tap(row, column)

        XCTAssertEqual(app.buttons["new-game"].value as? String, "You lost!")
        XCTAssertEqual(cell(row, column).label, "Row \(row + 1), column \(column + 1), mine, exploded")

        // The face starts a fresh board.
        app.buttons["new-game"].tap()
        XCTAssertEqual(app.buttons["new-game"].value as? String, "")
        XCTAssertEqual(cell(row, column).label, "Row \(row + 1), column \(column + 1), hidden")
    }

    /// On its side, the controls stay on the phone's top edge, beside the
    /// board, and the whole board shows.
    func testTheControlsFollowTheTopOfThePhone() {
        let flagMode = app.descendants(matching: .any)["flag-mode"]
        let window = app.windows.firstMatch
        XCTAssertTrue(flagMode.waitForExistence(timeout: 5))
        XCTAssertLessThan(flagMode.frame.maxY, cell(0, 0).frame.minY, "upright, the controls are above the board")

        // Turned anticlockwise (the home indicator on the right): top on the left.
        XCUIDevice.shared.orientation = .landscapeLeft
        let turnedLeft = expectation(for: NSPredicate { _, _ in
            flagMode.frame.maxX < self.cell(0, 0).frame.minX
        }, evaluatedWith: nil)
        wait(for: [turnedLeft], timeout: 5)
        XCTAssertTrue(window.frame.contains(cell(8, 8).frame), "the whole board shows")
        XCTAssertLessThan(flagMode.frame.width, window.frame.width / 5, "beside the board, the controls are a narrow column")

        // Turned clockwise: top on the right.
        XCUIDevice.shared.orientation = .landscapeRight
        let turnedRight = expectation(for: NSPredicate { _, _ in
            flagMode.frame.minX > self.cell(0, 8).frame.maxX
        }, evaluatedWith: nil)
        wait(for: [turnedRight], timeout: 5)
        XCTAssertTrue(window.frame.contains(cell(8, 8).frame), "the whole board shows")
    }

    func testFlagModeFlagsATappedMine() throws {
        let game = replay()
        tap(Self.opener.row, Self.opener.column)

        let flagMode = app.descendants(matching: .any)["flag-mode"]
        XCTAssertTrue(flagMode.waitForExistence(timeout: 5))
        flagMode.tap()

        // With Flag on, a tap on a mine flags it instead of losing.
        let mine = try XCTUnwrap(game.mineIDs.first)
        let row = mine / game.columns
        let column = mine % game.columns
        tap(row, column)
        XCTAssertEqual(cell(row, column).label, "Row \(row + 1), column \(column + 1), flagged")
        XCTAssertEqual(app.buttons["new-game"].value as? String, "")
        XCTAssertEqual(app.descendants(matching: .any)["mines-remaining"].label, "Mines remaining: 9")

        // A new game starts with Flag off, so a tap reveals again.
        app.buttons["new-game"].tap()
        tap(Self.opener.row, Self.opener.column)
        XCTAssertEqual(cell(Self.opener.row, Self.opener.column).label, "Row 5, column 5, empty")
    }
}
