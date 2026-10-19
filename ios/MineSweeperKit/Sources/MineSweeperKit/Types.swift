// Ported from src/context/BoardContext/types.ts. The TypeScript copy is the
// reference: a change to these rules is a change to both copies.

/// A cell's state. Mirrors the TS `CellType` enum case for case.
public enum CellType: Sendable, Hashable {
    case bomb
    case exploded
    /// A count-0 cell that has not been revealed yet.
    case empty
    /// A numbered cell that has not been revealed yet.
    case hidden
    case revealed
}

/// One cell. `count` is -1 for a mine, otherwise the number of adjacent mines (0–8).
public struct Cell: Sendable, Hashable {
    public var type: CellType
    public var count: Int

    public init(type: CellType, count: Int) {
        self.type = type
        self.count = count
    }

    public var isMine: Bool { count == -1 }
}

/// Rows of cells, indexed `board[row][column]`.
public typealias Board = [[Cell]]

/// A row/column pair. May be off-board: see `Rules.adjacentCoordinates`.
public struct Coordinate: Sendable, Hashable {
    public var row: Int
    public var column: Int

    public init(row: Int, column: Int) {
        self.row = row
        self.column = column
    }
}

public enum Difficulty: Sendable, Hashable, CaseIterable {
    /// 9×9 with 10 mines.
    case beginner
    /// 16×16 with 40 mines.
    case intermediate
    /// 16 rows × 30 columns with 99 mines.
    case expert

    public var rows: Int {
        switch self {
        case .beginner: 9
        case .intermediate, .expert: 16
        }
    }

    public var columns: Int {
        switch self {
        case .beginner: 9
        case .intermediate: 16
        case .expert: 30
        }
    }

    public var mineCount: Int {
        switch self {
        case .beginner: 10
        case .intermediate: 40
        case .expert: 99
        }
    }
}

extension Array where Element == [Cell] {
    /// The cell at a position, or nil when it is off the board. The TS copy gets
    /// this from `board[r]?.[c]`; Swift subscripts trap instead.
    func cell(at row: Int, _ column: Int) -> Cell? {
        guard indices.contains(row), self[row].indices.contains(column) else {
            return nil
        }
        return self[row][column]
    }
}
