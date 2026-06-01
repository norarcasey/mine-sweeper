import { CellData, CellType, Difficulty } from "./types";

function getBoardSize(difficulty: Difficulty): number[] {
  switch (difficulty) {
    case Difficulty.Intermediate:
      return [16, 16];
    case Difficulty.Expert:
      return [16, 30];
    default:
      return [9, 9];
  }
}

// Callers are responsible for bounds-checking the returned coordinates;
// this helper is purely arithmetic and may return off-board values.
export function getAdjacentCoordinates(row: number, col: number) {
  return [
    [row - 1, col - 1], // northwest
    [row - 1, col], // north
    [row - 1, col + 1], // northeast
    [row, col + 1], // east
    [row + 1, col + 1], // southeast
    [row + 1, col], // south
    [row + 1, col - 1], //southwest
    [row, col - 1], // west
  ];
}

/**
 * The clicked cell plus its on-board neighbours, as cell ids. Used to keep
 * the first reveal (and the region it opens) free of mines.
 */
export function getSafeCellIds(
  row: number,
  column: number,
  rows: number,
  cols: number
): number[] {
  return [[row, column], ...getAdjacentCoordinates(row, column)]
    .filter(([r, c]) => r >= 0 && r < rows && c >= 0 && c < cols)
    .map(([r, c]) => r * cols + c);
}

/**
 * A board of the right size for the difficulty with no mines placed. Used as
 * the starting state so the first reveal can place mines safely around it.
 */
export function getEmptyBoard(difficulty: Difficulty): CellData[][] {
  const [rows, cols] = getBoardSize(difficulty);

  // Using Array.from makes each cell a distinct object rather than sharing
  // one reference across the whole board.
  return Array.from({ length: rows }, () =>
    Array.from({ length: cols }, () => ({
      type: CellType.Empty,
      count: 0,
    }))
  );
}

export function getInitialBoard(
  difficulty: Difficulty,
  safeIds: number[] = []
): {
  initialBoard: CellData[][];
  mineIds: number[];
} {
  const BOARD_SIZE = getBoardSize(difficulty);

  const initialBoard = getEmptyBoard(difficulty);

  const safe = new Set(safeIds);
  const mineIds: number[] = [];

  while (mineIds.length < difficulty) {
    const id = Math.floor(BOARD_SIZE[0] * BOARD_SIZE[1] * Math.random());

    if (!safe.has(id) && !mineIds.includes(id)) {
      mineIds.push(id);
    }
  }

  mineIds.sort((a, b) => a - b);

  for (const id of mineIds) {
    const col = id % BOARD_SIZE[1];
    const row = Math.floor(id / BOARD_SIZE[1]);

    initialBoard[row][col] = { type: CellType.Bomb, count: -1 };

    const adjacentCoordinates = getAdjacentCoordinates(row, col);

    adjacentCoordinates.forEach(([adjRow, adjCol]) => {
      const cell = initialBoard[adjRow]?.[adjCol] ?? {};
      if (cell.type !== undefined && cell.type !== CellType.Bomb) {
        cell.count++;
        cell.type = CellType.Hidden;
      }
    });
  }

  return { initialBoard, mineIds };
}

/**
 * Flag-based win: the player has flagged all and only the bombs.
 * Both arrays are kept sorted ascending by their producers, so an
 * exact length + element match means the flag set equals the mine set.
 */
export function isFlagWin(mineIds: number[], flaggedIds: number[]): boolean {
  return (
    mineIds.length > 0 &&
    mineIds.length === flaggedIds.length &&
    mineIds.every((id, i) => id === flaggedIds[i])
  );
}

/**
 * Reveal-based win: every non-bomb cell has been revealed. Flags are
 * irrelevant to this path — bombs are identified by count === -1.
 */
export function isRevealWin(board: CellData[][]): boolean {
  return board.every((row) =>
    row.every((cell) => cell.count === -1 || cell.type === CellType.Revealed)
  );
}
