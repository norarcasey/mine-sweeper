import React, { createContext, useContext, useState } from "react";

import { getAdjacentCoordinates, getInitialBoard } from "./helpers";
import { Difficulty, CellData, CellType } from "./types";

const BoardContext = createContext<{
  board: CellData[][];
  reveal: (row: number, column: number) => void;
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
  children: React.ReactElement;
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

  return (
    <BoardContext.Provider
      value={{
        board,
        reveal: (row: number, column: number) => reveal(row, column),
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
