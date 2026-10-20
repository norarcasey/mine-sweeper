// Ported from src/context/BoardContext/BoardContext.tsx (reveal, flood fill,
// flagging, chording) and the move guards in src/components/Cell.tsx plus the
// game state in src/context/ScoreboardContext. The TypeScript copy is the
// reference: a change to these rules is a change to both copies.

public enum GameState: Sendable, Hashable {
    /// No reveal yet, so no mines are placed.
    case inactive
    case active
    case won
    case lost
}

/// What a cell shows the player. Mirrors the order of checks in `Cell.tsx`'s
/// `describeState`: a flag wins over everything else.
public enum CellAppearance: Sendable, Hashable {
    case hidden
    case flagged
    /// A revealed safe cell and its adjacent-mine count (0 is an open, empty cell).
    case revealed(count: Int)
    /// The mine the player set off.
    case exploded
    /// After a loss, a mine the player had not flagged.
    case mine
}

/// One game of Minesweeper: the board, the moves and the rules, as a value.
public struct Game: Sendable, Hashable {
    public let difficulty: Difficulty
    public private(set) var board: Board
    /// Sorted ascending. Empty until the first reveal places the mines.
    public private(set) var mineIDs: [Int] = []
    /// Sorted ascending. The single source of truth for which cells are
    /// flagged: flagging never changes a cell's type.
    public private(set) var flaggedIDs: [Int] = []
    public private(set) var state: GameState = .inactive

    /// When set, the first reveal places mines exactly here instead of at
    /// random, ignoring the safe area. Tests use it the way the TS tests mock
    /// `getInitialBoard`; `reset()` clears it.
    var presetMineIDs: [Int]?

    public init(difficulty: Difficulty) {
        self.init(difficulty: difficulty, presetMineIDs: nil)
    }

    init(difficulty: Difficulty, presetMineIDs: [Int]?) {
        self.difficulty = difficulty
        self.board = Rules.emptyBoard(difficulty)
        self.presetMineIDs = presetMineIDs
    }

    public var rows: Int { difficulty.rows }
    public var columns: Int { difficulty.columns }
    public var isGameOver: Bool { state == .won || state == .lost }

    /// The scoreboard counter: mines less flags. Goes negative when over-flagged.
    public var minesRemaining: Int { difficulty.mineCount - flaggedIDs.count }

    public func id(row: Int, column: Int) -> Int { row * columns + column }

    public func isFlagged(row: Int, column: Int) -> Bool {
        flaggedIDs.contains(id(row: row, column: column))
    }

    public func appearance(row: Int, column: Int) -> CellAppearance {
        guard let cell = board.cell(at: row, column) else { return .hidden }
        if isFlagged(row: row, column: column) { return .flagged }
        if cell.type == .exploded { return .exploded }
        if state == .lost && cell.isMine { return .mine }
        if cell.type == .revealed { return .revealed(count: cell.count) }
        return .hidden
    }

    // MARK: - Moves

    /// Reveal a cell with the system random source for the first-reveal mine
    /// placement.
    public mutating func reveal(row: Int, column: Int) {
        var generator = SystemRandomNumberGenerator()
        reveal(row: row, column: column, using: &generator)
    }

    /// Reveal a cell. The first reveal places the mines, never on this cell or
    /// its neighbours. Revealing a zero flood-fills; revealing a mine loses;
    /// revealing an already-revealed number chords it. A flagged cell, or any
    /// cell once the game is over, does nothing.
    public mutating func reveal(row: Int, column: Int, using generator: inout some RandomNumberGenerator) {
        guard !isGameOver, let cell = board.cell(at: row, column), !isFlagged(row: row, column: column) else {
            return
        }

        if cell.type == .revealed {
            chord(row: row, column: column)
            return
        }

        if cell.isMine {
            board[row][column].type = .exploded
            state = .lost
            return
        }

        if state == .inactive {
            // First reveal: place mines, keeping the clicked cell and its
            // neighbours mine-free so the opener never loses and always opens a
            // zero-region.
            if let presetMineIDs {
                mineIDs = presetMineIDs.sorted()
                board = Rules.board(rows: rows, columns: columns, mineIDs: mineIDs)
            } else {
                let safeIDs = Rules.safeCellIDs(row: row, column: column, rows: rows, columns: columns)
                (board, mineIDs) = Rules.initialBoard(difficulty, safeIDs: safeIDs, using: &generator)
            }
            state = .active
        }

        board[row][column].type = .revealed
        if board[row][column].count == 0 {
            revealAdjacent(row: row, column: column)
        }

        if Rules.isRevealWin(board) {
            // Flag every mine so the mines-remaining counter reads 0.
            flaggedIDs = mineIDs
            state = .won
        }
    }

    /// Toggle a flag on a cell that is not revealed. Flagging exactly the mines
    /// wins and reveals every non-mine cell.
    public mutating func toggleFlag(row: Int, column: Int) {
        guard !isGameOver, let cell = board.cell(at: row, column), cell.type != .revealed else {
            return
        }

        let id = id(row: row, column: column)
        if let index = flaggedIDs.firstIndex(of: id) {
            flaggedIDs.remove(at: index)
        } else {
            flaggedIDs.append(id)
            flaggedIDs.sort()
        }

        if Rules.isFlagWin(mineIDs: mineIDs, flaggedIDs: flaggedIDs) {
            // Reveal every non-mine cell: numbered (`.hidden`) and count-0
            // (`.empty`) alike. The mines are all flagged and stay as they are.
            for r in board.indices {
                for c in board[r].indices where !board[r][c].isMine {
                    board[r][c].type = .revealed
                }
            }
            state = .won
        }
    }

    /// "Chording": once the player has placed as many flags around a revealed
    /// number as the number itself, this reveals every remaining un-flagged
    /// neighbour in one move. If a flag was placed wrongly, the un-flagged mine
    /// it left behind is revealed and detonates, exactly like revealing it.
    public mutating func chord(row: Int, column: Int) {
        guard !isGameOver, let cell = board.cell(at: row, column), cell.type == .revealed, cell.count > 0 else {
            return
        }

        let adjacent = Rules.adjacentCoordinates(row: row, column: column)
            .filter { board.cell(at: $0.row, $0.column) != nil }

        // Only fire when the surrounding flag count matches the cell's number:
        // the player's assertion that every adjacent mine is already flagged.
        let adjacentFlagCount = adjacent.filter { isFlagged(row: $0.row, column: $0.column) }.count
        guard adjacentFlagCount == cell.count else { return }

        var exploded = false
        for position in adjacent {
            let adjacentCell = board[position.row][position.column]

            // Flagged cells are the player's marked mines and stay untouched;
            // already-revealed neighbours need no work.
            if isFlagged(row: position.row, column: position.column) || adjacentCell.type == .revealed {
                continue
            }

            if adjacentCell.isMine {
                // A misplaced flag: this un-flagged mine goes off.
                board[position.row][position.column].type = .exploded
                exploded = true
            } else {
                board[position.row][position.column].type = .revealed
                if adjacentCell.count == 0 {
                    revealAdjacent(row: position.row, column: position.column)
                }
            }
        }

        if exploded {
            state = .lost
        } else if Rules.isRevealWin(board) {
            // Flag every mine so the mines-remaining counter reads 0.
            flaggedIDs = mineIDs
            state = .won
        }
    }

    /// A fresh board of the same difficulty, with no mines placed yet.
    public mutating func reset() {
        self = Game(difficulty: difficulty)
    }

    // MARK: - Flood fill

    /// Flood-fill from an empty cell, revealing neighbours and skipping flagged
    /// ones. Iterative where the TS copy recurses; it reveals the same cells.
    private mutating func revealAdjacent(row: Int, column: Int) {
        var pending = [Coordinate(row: row, column: column)]

        while let current = pending.popLast() {
            for position in Rules.adjacentCoordinates(row: current.row, column: current.column) {
                guard
                    let adjacentCell = board.cell(at: position.row, position.column),
                    adjacentCell.type != .revealed,
                    !isFlagged(row: position.row, column: position.column)
                else {
                    continue
                }

                board[position.row][position.column].type = .revealed
                if adjacentCell.count == 0 {
                    pending.append(position)
                }
            }
        }
    }
}
