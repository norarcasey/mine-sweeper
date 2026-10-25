import MineSweeperKit
import XCTest

/// The App Store screenshots (MINE-5), taken from seeded games so every run
/// draws the same boards. `ios/screenshots.sh` runs only this class and copies
/// the attachments out. `ios/test.sh` skips it: it checks nothing.
@MainActor
final class StoreScreenshots: XCTestCase {
    private static let seed: UInt64 = 7

    private let app = XCUIApplication()

    override func setUp() async throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    override func tearDown() async throws {
        XCUIDevice.shared.orientation = .portrait
    }

    private func launch(_ difficulty: String) {
        app.launchArguments = ["-seed", String(Self.seed), "-difficulty", difficulty]
        app.launch()
    }

    /// The board the app will lay down after its first reveal at `opener`.
    private func replay(_ difficulty: Difficulty, opener: Coordinate) -> Game {
        var game = Game(difficulty: difficulty)
        var generator = SeededGenerator(seed: Self.seed)
        game.reveal(row: opener.row, column: opener.column, using: &generator)
        return game
    }

    private func cell(_ row: Int, _ column: Int) -> XCUIElement {
        app.descendants(matching: .any)["cell-\(row)-\(column)"]
    }

    private func tap(_ coordinate: Coordinate) {
        let element = cell(coordinate.row, coordinate.column)
        XCTAssertTrue(element.waitForExistence(timeout: 5))
        element.tap()
    }

    private func isRevealed(_ game: Game, _ coordinate: Coordinate) -> Bool {
        if case .revealed = game.appearance(row: coordinate.row, column: coordinate.column) { return true }
        return false
    }

    /// Hidden cells that touch a revealed one: where a player would be working.
    private func frontier(_ game: Game) -> [Coordinate] {
        var cells: [Coordinate] = []
        for row in 0..<game.rows {
            for column in 0..<game.columns where game.appearance(row: row, column: column) == .hidden {
                let touches = Rules.adjacentCoordinates(row: row, column: column).contains { neighbour in
                    neighbour.row >= 0 && neighbour.row < game.rows
                        && neighbour.column >= 0 && neighbour.column < game.columns
                        && isRevealed(game, neighbour)
                }
                if touches { cells.append(Coordinate(row: row, column: column)) }
            }
        }
        return cells
    }

    /// Plays a game part-way: flags `flags` frontier mines by long-press and
    /// opens `reveals` frontier safe cells, in the app and in the replay.
    private func playPartWay(_ game: inout Game, flags: Int, reveals: Int, flagByTap: Bool = false) {
        var flagged = 0
        var revealed = 0
        for coordinate in frontier(game) {
            let isMine = game.board[coordinate.row][coordinate.column].isMine
            if isMine, flagged < flags {
                if flagByTap { tap(coordinate) } else {
                    cell(coordinate.row, coordinate.column).press(forDuration: 0.6)
                }
                game.toggleFlag(row: coordinate.row, column: coordinate.column)
                flagged += 1
            } else if !isMine, !flagByTap, revealed < reveals,
                      game.appearance(row: coordinate.row, column: coordinate.column) == .hidden {
                tap(coordinate)
                game.reveal(row: coordinate.row, column: coordinate.column)
                revealed += 1
            }
        }
    }

    private func snap(_ name: String) {
        // Let the haptic-free redraw and any rotation settle.
        Thread.sleep(forTimeInterval: 1)
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func test1BeginnerMidGame() {
        let opener = Coordinate(row: 4, column: 4)
        launch("Beginner")
        var game = replay(.beginner, opener: opener)
        tap(opener)
        playPartWay(&game, flags: 3, reveals: 4)
        snap("1-beginner")
    }

    func test2FlagMode() {
        let opener = Coordinate(row: 8, column: 8)
        launch("Intermediate")
        var game = replay(.intermediate, opener: opener)
        tap(opener)
        playPartWay(&game, flags: 0, reveals: 6)
        app.descendants(matching: .any)["flag-mode"].tap()
        playPartWay(&game, flags: 6, reveals: 0, flagByTap: true)
        snap("2-flag-mode")
    }

    func test3ExpertUpright() {
        let opener = Coordinate(row: 8, column: 15)
        launch("Expert")
        var game = replay(.expert, opener: opener)
        tap(opener)
        playPartWay(&game, flags: 8, reveals: 0)
        snap("3-expert")
    }

    func test4Won() {
        let opener = Coordinate(row: 4, column: 4)
        launch("Beginner")
        var game = replay(.beginner, opener: opener)
        tap(opener)
        for row in 0..<game.rows {
            for column in 0..<game.columns where game.state == .active {
                guard game.appearance(row: row, column: column) == .hidden,
                      !game.board[row][column].isMine
                else { continue }
                game.reveal(row: row, column: column)
                tap(Coordinate(row: row, column: column))
            }
        }
        XCTAssertEqual(app.buttons["new-game"].value as? String, "You won!")
        snap("4-won")
    }

    func test5Landscape() {
        let opener = Coordinate(row: 8, column: 8)
        launch("Intermediate")
        var game = replay(.intermediate, opener: opener)
        tap(opener)
        playPartWay(&game, flags: 5, reveals: 6)
        XCUIDevice.shared.orientation = .landscapeLeft
        snap("5-landscape")
    }
}
