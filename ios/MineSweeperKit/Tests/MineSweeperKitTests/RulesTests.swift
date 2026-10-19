import Testing
@testable import MineSweeperKit

// Mirrors src/context/BoardContext/helpers.test.ts. Each @Test's display name
// is the TS test it mirrors, word for word; each @Suite names the TS describe.

@Suite("helpers.test.ts › getAdjacentCoordinates")
struct AdjacentCoordinatesTests {
    @Test("returns the eight surrounding coordinates")
    func eightSurrounding() {
        let coordinates = Rules.adjacentCoordinates(row: 5, column: 5)

        #expect(coordinates.count == 8)
        #expect(Set(coordinates) == [
            Coordinate(row: 4, column: 4), // northwest
            Coordinate(row: 4, column: 5), // north
            Coordinate(row: 4, column: 6), // northeast
            Coordinate(row: 5, column: 6), // east
            Coordinate(row: 6, column: 6), // southeast
            Coordinate(row: 6, column: 5), // south
            Coordinate(row: 6, column: 4), // southwest
            Coordinate(row: 5, column: 4), // west
        ])
    }

    @Test("never includes the cell itself")
    func neverItself() {
        #expect(!Rules.adjacentCoordinates(row: 3, column: 7).contains(Coordinate(row: 3, column: 7)))
    }

    @Test("returns out-of-bounds (negative) coordinates at an edge")
    func offBoardAtEdge() {
        // Callers are responsible for bounds-checking; the helper is purely
        // arithmetic and should not clamp.
        let coordinates = Rules.adjacentCoordinates(row: 0, column: 0)
        #expect(coordinates.contains(Coordinate(row: -1, column: -1)))
        #expect(coordinates.contains(Coordinate(row: -1, column: 0)))
        #expect(coordinates.contains(Coordinate(row: 0, column: -1)))
    }
}

@Suite("helpers.test.ts › getInitialBoard")
struct InitialBoardTests {
    // The TS suite runs each case once per difficulty (describe.each) against
    // Math.random; these run per difficulty × seed.
    static func make(_ difficulty: Difficulty, _ seed: UInt64) -> (board: Board, mineIDs: [Int]) {
        var generator = SeededGenerator(seed: seed)
        return Rules.initialBoard(difficulty, using: &generator)
    }

    @Test("[describe.each cases] [name, difficulty, rows, cols, mines]")
    func difficultyTable() {
        // The `cases` table the TS describe.each runs over.
        #expect([Difficulty.beginner.rows, Difficulty.beginner.columns, Difficulty.beginner.mineCount] == [9, 9, 10])
        #expect([Difficulty.intermediate.rows, Difficulty.intermediate.columns, Difficulty.intermediate.mineCount] == [16, 16, 40])
        #expect([Difficulty.expert.rows, Difficulty.expert.columns, Difficulty.expert.mineCount] == [16, 30, 99])
    }

    @Test("builds a ${rows}x${cols} board", arguments: Difficulty.allCases, seeds)
    func size(_ difficulty: Difficulty, _ seed: UInt64) {
        let (board, _) = Self.make(difficulty, seed)

        #expect(board.count == difficulty.rows)
        #expect(board.allSatisfy { $0.count == difficulty.columns })
    }

    @Test("places exactly ${mineCount} mines", arguments: Difficulty.allCases, seeds)
    func mineCount(_ difficulty: Difficulty, _ seed: UInt64) {
        let (board, mineIDs) = Self.make(difficulty, seed)

        #expect(mineIDs.count == difficulty.mineCount)
        #expect(board.joined().filter { $0.type == .bomb }.count == difficulty.mineCount)
    }

    @Test("returns mineIds that are unique, sorted, and in range", arguments: Difficulty.allCases, seeds)
    func mineIDsShape(_ difficulty: Difficulty, _ seed: UInt64) {
        let (_, mineIDs) = Self.make(difficulty, seed)

        #expect(Set(mineIDs).count == mineIDs.count)
        #expect(mineIDs == mineIDs.sorted())
        #expect(mineIDs.allSatisfy { $0 >= 0 && $0 < difficulty.rows * difficulty.columns })
    }

    @Test("maps every mineId to a bomb cell", arguments: Difficulty.allCases, seeds)
    func mineIDsAreBombs(_ difficulty: Difficulty, _ seed: UInt64) {
        let (board, mineIDs) = Self.make(difficulty, seed)

        for id in mineIDs {
            #expect(board[id / difficulty.columns][id % difficulty.columns].type == .bomb)
        }
    }

    @Test("gives every bomb a count of -1", arguments: Difficulty.allCases, seeds)
    func bombCount(_ difficulty: Difficulty, _ seed: UInt64) {
        let (board, _) = Self.make(difficulty, seed)

        for cell in board.joined() where cell.type == .bomb {
            #expect(cell.count == -1)
        }
    }

    @Test("sets each non-bomb count to its number of adjacent bombs", arguments: Difficulty.allCases, seeds)
    func adjacentCounts(_ difficulty: Difficulty, _ seed: UInt64) {
        let (board, _) = Self.make(difficulty, seed)

        for (r, row) in board.enumerated() {
            for (c, cell) in row.enumerated() where cell.type != .bomb {
                let adjacentBombs = Rules.adjacentCoordinates(row: r, column: c)
                    .filter { board.cell(at: $0.row, $0.column)?.type == .bomb }
                    .count
                #expect(cell.count == adjacentBombs)
            }
        }
    }

    @Test("types non-bomb cells as Empty when count is 0 and Hidden otherwise", arguments: Difficulty.allCases, seeds)
    func emptyOrHidden(_ difficulty: Difficulty, _ seed: UInt64) {
        let (board, _) = Self.make(difficulty, seed)

        for cell in board.joined() where cell.type != .bomb {
            #expect(cell.type == (cell.count == 0 ? .empty : .hidden))
        }
    }

    @Test("creates independent cell objects (no shared references)", arguments: Difficulty.allCases)
    func independentCells(_ difficulty: Difficulty) {
        // Cells are values in Swift, so this holds by construction. The check
        // is the observable consequence: changing one cell changes no other.
        var (board, _) = Self.make(difficulty, 0)
        let before = board
        board[0][0].type = .revealed
        board[0][0].count = 8

        for (r, row) in board.enumerated() {
            for (c, cell) in row.enumerated() where !(r == 0 && c == 0) {
                #expect(cell == before[r][c])
            }
        }
    }

    @Test("[Swift only] the same seed builds the same board")
    func deterministic() {
        // Not a rule case: it pins the injectable random source the other tests rely on.
        #expect(Self.make(.expert, 42).mineIDs == Self.make(.expert, 42).mineIDs)
        #expect(Self.make(.expert, 42).mineIDs != Self.make(.expert, 43).mineIDs)
    }
}

@Suite("helpers.test.ts › getSafeCellIds")
struct SafeCellIDsTests {
    @Test("returns the clicked cell plus all eight neighbours mid-board")
    func midBoard() {
        // 9x9 board, click center (4,4) => id 40.
        #expect(Rules.safeCellIDs(row: 4, column: 4, rows: 9, columns: 9).sorted() == [30, 31, 32, 39, 40, 41, 48, 49, 50])
    }

    @Test("clamps to on-board neighbours at a corner")
    func corner() {
        // (0,0) has only E, S, SE neighbours on the board.
        #expect(Rules.safeCellIDs(row: 0, column: 0, rows: 9, columns: 9).sorted() == [0, 1, 9, 10])
    }

    @Test("clamps to on-board neighbours at an edge")
    func edge() {
        // Top edge (0,4): the northern row is off-board.
        #expect(Rules.safeCellIDs(row: 0, column: 4, rows: 9, columns: 9).sorted() == [3, 4, 5, 12, 13, 14])
    }
}

@Suite("helpers.test.ts › getInitialBoard with safe cells (first-click safety)")
struct FirstClickSafetyTests {
    static let safeIDs = Rules.safeCellIDs(row: 4, column: 4, rows: 9, columns: 9)

    static func make(_ seed: UInt64) -> (board: Board, mineIDs: [Int]) {
        var generator = SeededGenerator(seed: seed)
        return Rules.initialBoard(.beginner, safeIDs: safeIDs, using: &generator)
    }

    @Test("never places a mine on a safe id", arguments: seeds)
    func noMineOnSafe(_ seed: UInt64) {
        let (_, mineIDs) = Self.make(seed)
        #expect(Set(mineIDs).isDisjoint(with: Self.safeIDs))
    }

    @Test("still places the full mine count when cells are excluded", arguments: seeds)
    func fullCount(_ seed: UInt64) {
        #expect(Self.make(seed).mineIDs.count == 10)
    }

    @Test("leaves the clicked cell with count 0 so it opens a region", arguments: seeds)
    func opensRegion(_ seed: UInt64) {
        // All eight neighbours are safe, so the clicked cell has no adjacent
        // mines and will trigger the flood-fill reveal.
        let (board, _) = Self.make(seed)
        #expect(board[4][4].count == 0)
        #expect(board[4][4].type == .empty)
    }
}

@Suite("helpers.test.ts › isFlagWin")
struct FlagWinTests {
    @Test("wins when the flagged set is exactly the mine set")
    func exact() {
        #expect(Rules.isFlagWin(mineIDs: [2, 5, 8], flaggedIDs: [2, 5, 8]))
    }

    @Test("does not win when a non-mine cell is also flagged (extra flag)")
    func extraFlag() {
        #expect(!Rules.isFlagWin(mineIDs: [2, 5, 8], flaggedIDs: [2, 5, 8, 50]))
    }

    @Test("does not win when not every mine is flagged")
    func missingFlag() {
        #expect(!Rules.isFlagWin(mineIDs: [2, 5, 8], flaggedIDs: [2, 5]))
    }

    @Test("does not win when a flag is on a non-mine instead of a mine")
    func wrongFlag() {
        // Same length, different membership.
        #expect(!Rules.isFlagWin(mineIDs: [2, 5, 8], flaggedIDs: [2, 5, 9]))
    }

    @Test("does not win with no flags placed")
    func noFlags() {
        #expect(!Rules.isFlagWin(mineIDs: [2, 5, 8], flaggedIDs: []))
    }

    @Test("does not win before any mines exist (empty board)")
    func noMines() {
        // Guards the pre-first-reveal state where mines have not been placed yet.
        #expect(!Rules.isFlagWin(mineIDs: [], flaggedIDs: []))
    }
}

@Suite("helpers.test.ts › isRevealWin")
struct RevealWinTests {
    // Build a board row from a compact spec. `-1` => bomb, otherwise a count;
    // the second value is the cell's current type.
    func row(_ cells: (Int, CellType)...) -> [Cell] {
        cells.map { Cell(type: $0.1, count: $0.0) }
    }

    @Test("wins when every non-bomb cell is revealed (bombs left hidden)")
    func allRevealed() {
        let board = [
            row((-1, .bomb), (1, .revealed)),
            row((1, .revealed), (1, .revealed)),
        ]
        #expect(Rules.isRevealWin(board))
    }

    @Test("wins regardless of how bombs are typed (exploded or not)")
    func bombTypeIrrelevant() {
        let board = [
            row((-1, .exploded), (1, .revealed)),
            row((-1, .bomb), (2, .revealed)),
        ]
        #expect(Rules.isRevealWin(board))
    }

    @Test("does not win while a numbered cell is still hidden")
    func numberedHidden() {
        let board = [
            row((-1, .bomb), (1, .revealed)),
            row((1, .hidden), (1, .revealed)),
        ]
        #expect(!Rules.isRevealWin(board))
    }

    @Test("does not win while an empty (count 0) cell is unrevealed")
    func emptyUnrevealed() {
        // Regression for bug #2: count-0 cells keep type Empty until flood-filled
        // and must not be treated as already satisfied.
        let board = [
            row((-1, .bomb), (1, .revealed)),
            row((0, .empty), (1, .revealed)),
        ]
        #expect(!Rules.isRevealWin(board))
    }
}
