// Ported from src/context/BoardContext/helpers.ts. The TypeScript copy is the
// reference: a change to these rules is a change to both copies.

/// Board building, safe cells and win checks.
public enum Rules {
    /// The eight surrounding coordinates, clockwise from the northwest.
    /// Callers are responsible for bounds-checking the returned coordinates;
    /// this helper is purely arithmetic and may return off-board values.
    public static func adjacentCoordinates(row: Int, column: Int) -> [Coordinate] {
        [
            Coordinate(row: row - 1, column: column - 1), // northwest
            Coordinate(row: row - 1, column: column), // north
            Coordinate(row: row - 1, column: column + 1), // northeast
            Coordinate(row: row, column: column + 1), // east
            Coordinate(row: row + 1, column: column + 1), // southeast
            Coordinate(row: row + 1, column: column), // south
            Coordinate(row: row + 1, column: column - 1), // southwest
            Coordinate(row: row, column: column - 1), // west
        ]
    }

    /// The clicked cell plus its on-board neighbours, as cell ids. Used to keep
    /// the first reveal (and the region it opens) free of mines.
    public static func safeCellIDs(row: Int, column: Int, rows: Int, columns: Int) -> [Int] {
        ([Coordinate(row: row, column: column)] + adjacentCoordinates(row: row, column: column))
            .filter { $0.row >= 0 && $0.row < rows && $0.column >= 0 && $0.column < columns }
            .map { $0.row * columns + $0.column }
    }

    /// A board of the right size for the difficulty with no mines placed. Used as
    /// the starting state so the first reveal can place mines safely around it.
    public static func emptyBoard(_ difficulty: Difficulty) -> Board {
        Array(
            repeating: Array(repeating: Cell(type: .empty, count: 0), count: difficulty.columns),
            count: difficulty.rows
        )
    }

    /// A board with mines placed at random, never on `safeIDs`. `mineIDs` comes
    /// back sorted ascending.
    ///
    /// The TS copy draws ids with `Math.random` and rejects repeats; this picks
    /// from the allowed ids directly. Both are uniform over the allowed layouts.
    public static func initialBoard(
        _ difficulty: Difficulty,
        safeIDs: [Int] = [],
        using generator: inout some RandomNumberGenerator
    ) -> (board: Board, mineIDs: [Int]) {
        let safe = Set(safeIDs)
        let candidates = (0..<(difficulty.rows * difficulty.columns)).filter { !safe.contains($0) }
        precondition(candidates.count >= difficulty.mineCount, "Not enough cells outside the safe area")

        let mineIDs = candidates.shuffled(using: &generator).prefix(difficulty.mineCount).sorted()
        let board = board(rows: difficulty.rows, columns: difficulty.columns, mineIDs: mineIDs)
        return (board, mineIDs)
    }

    /// An initial board with mines at exactly `mineIDs`: each mine has count -1
    /// and type `.bomb`, every cell next to one counts it and becomes `.hidden`,
    /// and the rest stay `.empty` with count 0.
    public static func board(rows: Int, columns: Int, mineIDs: [Int]) -> Board {
        var board = Array(
            repeating: Array(repeating: Cell(type: .empty, count: 0), count: columns),
            count: rows
        )

        for id in mineIDs {
            let row = id / columns
            let column = id % columns
            board[row][column] = Cell(type: .bomb, count: -1)

            for adjacent in adjacentCoordinates(row: row, column: column) {
                guard let cell = board.cell(at: adjacent.row, adjacent.column), cell.type != .bomb else {
                    continue
                }
                board[adjacent.row][adjacent.column].count += 1
                board[adjacent.row][adjacent.column].type = .hidden
            }
        }

        return board
    }

    /// Flag-based win: the player has flagged all and only the bombs.
    /// Both arrays are kept sorted ascending by their producers, so an
    /// exact length + element match means the flag set equals the mine set.
    public static func isFlagWin(mineIDs: [Int], flaggedIDs: [Int]) -> Bool {
        !mineIDs.isEmpty && mineIDs == flaggedIDs
    }

    /// Reveal-based win: every non-bomb cell has been revealed. Flags are
    /// irrelevant to this path; bombs are identified by count == -1.
    public static func isRevealWin(_ board: Board) -> Bool {
        board.allSatisfy { row in
            row.allSatisfy { $0.isMine || $0.type == .revealed }
        }
    }
}
