import React, { createContext, useContext, useState } from "react";

import { getAdjacentCoordinates, getInitialBoard } from "./helpers";
import { Difficulty, CellData, CellType } from "./types";

const BoardContext = createContext<{
  board: CellData[][];
  reveal: (row: number, column: number) => void;
  reset: () => void;
  explode: (row: number, column: number) => void;
  flag: (row: number, column: number) => void;
} | null>(null);

function revealAdjacent(row: number, column: number, board: CellData[][]) {
  const adjCells = getAdjacentCoordinates(row, column);

  adjCells.forEach(([adjRow, adjCol]) => {
    const adjCell = board[adjRow]?.[adjCol];

    if (adjCell && adjCell.type !== CellType.Revealed) {
      adjCell.type = CellType.Revealed;
      if (adjCell.count === 0) {
        revealAdjacent(adjRow, adjCol, board);
      }
    }
  });
}

export function BoardProvider({
  children,
  difficulty,
}: {
  children: React.ReactNode;
  difficulty: Difficulty;
}) {
  const [board, setBoard] = useState<CellData[][]>(getInitialBoard(difficulty));

  function reveal(row: number, column: number): void {
    const boardClone: CellData[][] = JSON.parse(JSON.stringify(board));

    const cell = boardClone[row][column];
    cell.type = CellType.Revealed;

    if (cell.count === 0) {
      revealAdjacent(row, column, boardClone);
    }

    setBoard(boardClone);
  }

  function updateCellType(row: number, column: number, type: CellType): void {
    const boardClone: CellData[][] = JSON.parse(JSON.stringify(board));
    const cell = boardClone[row][column];

    if (cell.type === type) {
      if (cell.count === -1) {
        cell.type = CellType.Bomb;
      }

      if (cell.count === 0) {
        cell.type = CellType.Empty;
      }

      if (cell.count > 0) {
        cell.type = CellType.Hidden;
      }
    } else {
      cell.type = type;
    }

    setBoard(boardClone);
  }

  return (
    <BoardContext.Provider
      value={{
        board,
        reveal,
        reset: () => setBoard(getInitialBoard(difficulty)),
        explode: (row: number, column: number) =>
          updateCellType(row, column, CellType.Exploded),
        flag: (row: number, column: number) =>
          updateCellType(row, column, CellType.Flagged),
      }}
    >
      {children}
    </BoardContext.Provider>
  );
}

export function useBoardContext() {
  const boardContext = useContext(BoardContext);

  if (!boardContext) {
    throw new Error(
      "Board Context not available, please check that the provider has been added to the tree."
    );
  }

  return boardContext;
}
