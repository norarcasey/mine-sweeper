// TODO: Add unit tests for these functions
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

// TODO: Should I omitted know invalid coords?
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

export function getInitialBoard(difficulty: Difficulty) {
  const BOARD_SIZE = getBoardSize(difficulty);

  // Using Array.from makes each cell different and
  // not reference the same location in memory.
  const initialBoard: CellData[][] = Array.from({ length: BOARD_SIZE[0] }, () =>
    Array.from({ length: BOARD_SIZE[1] }, () => ({
      type: CellType.Empty,
      count: 0,
    }))
  );

  const mineIds: number[] = [];

  while (mineIds.length < difficulty) {
    let id = Math.floor(BOARD_SIZE[0] * BOARD_SIZE[1] * Math.random());

    if (!mineIds.includes(id)) {
      mineIds.push(id);
    }
  }

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

  return initialBoard;
}
