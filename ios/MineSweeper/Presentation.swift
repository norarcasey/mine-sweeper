// What the screen shows, as plain functions of the game: the counter, the
// timer, the VoiceOver labels and the board's layout. None of it is a rule;
// the rules are MineSweeperKit's.

import CoreGraphics
import MineSweeperKit

/// The mines-remaining counter as a fixed-width LED string. Mirrors
/// `src/components/formatCounter.ts`: "009", and "-09" when over-flagged.
func formatCounter(_ value: Int) -> String {
    if value < 0 {
        return "-" + pad(abs(value), to: 2)
    }
    return pad(value, to: 3)
}

/// Elapsed time as "mm:ss". Mirrors `src/components/Timer.tsx`.
func formatTimer(seconds: Int) -> String {
    pad(seconds / 60, to: 2) + ":" + pad(seconds % 60, to: 2)
}

/// "Time elapsed: 1 second". Mirrors the visually hidden text in `Timer.tsx`.
func timerLabel(seconds: Int) -> String {
    "Time elapsed: \(seconds) \(seconds == 1 ? "second" : "seconds")"
}

private func pad(_ value: Int, to width: Int) -> String {
    let digits = String(value)
    return String(repeating: "0", count: max(0, width - digits.count)) + digits
}

/// A cell's VoiceOver label, worded as `describeState` and `aria-label` in
/// `src/components/Cell.tsx` word them: "Row 1, column 2, 3 adjacent mines".
func cellLabel(row: Int, column: Int, appearance: CellAppearance) -> String {
    "Row \(row + 1), column \(column + 1), \(describe(appearance))"
}

private func describe(_ appearance: CellAppearance) -> String {
    switch appearance {
    case .flagged: "flagged"
    case .exploded: "mine, exploded"
    case .mine: "mine"
    case .revealed(count: 0): "empty"
    case .revealed(count: 1): "1 adjacent mine"
    case let .revealed(count): "\(count) adjacent mines"
    case .hidden: "hidden"
    }
}

/// What the scoreboard announces at the end of a game. Mirrors the live
/// region in `src/components/Scoreboard.tsx`.
func outcome(_ state: GameState) -> String {
    switch state {
    case .won: "You won!"
    case .lost: "You lost!"
    case .inactive, .active: ""
    }
}

/// How the board sits in the space it is given.
///
/// A board wider than it is tall (Expert, 16×30) turns on its side when the
/// space is taller than it is wide, so a phone held upright shows Expert as 30
/// rows of 16 and scrolls one way only. Turning it across the diagonal keeps
/// every cell's neighbours, so the game is the same game.
///
/// Cells fit the space, up to `maximumCell`, then scale by `zoom`. A turned
/// board fits the width only and scrolls the rest of its height; every other
/// board fits whole, so a phone on its side shows all of it.
struct BoardLayout: Equatable {
    static let maximumCell: CGFloat = 44

    let transposed: Bool
    /// Rows and columns as drawn, after any turn.
    let rows: Int
    let columns: Int
    let cellSize: CGFloat

    init(rows boardRows: Int, columns boardColumns: Int, available: CGSize, zoom: CGFloat = 1) {
        transposed = boardColumns > boardRows && available.height > available.width
        rows = transposed ? boardColumns : boardRows
        columns = transposed ? boardRows : boardColumns
        let fitWidth = columns > 0 ? available.width / CGFloat(columns) : 0
        let fitHeight = rows > 0 ? available.height / CGFloat(rows) : 0
        let fit = transposed ? fitWidth : min(fitWidth, fitHeight)
        cellSize = (min(fit, Self.maximumCell) * zoom).rounded(.down)
    }

    /// The game's row and column for a cell as drawn.
    func gamePosition(row: Int, column: Int) -> Coordinate {
        transposed ? Coordinate(row: column, column: row) : Coordinate(row: row, column: column)
    }
}

/// Where the picker, the Flag toggle and the scoreboard sit.
///
/// Upright, they sit above the board. On its side, they stay on the edge that
/// was the top of the phone and turn with it, as a column beside the board, so
/// the board has the whole height.
enum ControlsPlacement: Equatable {
    case top, left, right

    /// `landscape` is the screen being wider than tall. `topOnRight` is the
    /// phone turned clockwise, so its top edge is on the right.
    init(landscape: Bool, topOnRight: Bool) {
        self = landscape ? (topOnRight ? .right : .left) : .top
    }

    /// Beside the board, where the controls are a narrow column.
    var isBeside: Bool { self != .top }
}

extension Difficulty {
    /// The name the picker shows and `@AppStorage` keeps.
    var name: String {
        switch self {
        case .beginner: "Beginner"
        case .intermediate: "Intermediate"
        case .expert: "Expert"
        }
    }

    init?(name: String) {
        guard let match = Self.allCases.first(where: { $0.name == name }) else { return nil }
        self = match
    }
}
