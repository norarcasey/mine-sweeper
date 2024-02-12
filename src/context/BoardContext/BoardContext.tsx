import React, { createContext, useContext, useState } from "react";

import { getAdjacentCoordinates, getInitialBoard } from "./helpers";
import { Difficulty, CellData, CellType } from "./types";

const BoardContext = createContext<{
  board: CellData[][];
  mines: number[];
  flags: number[];
  reveal: (row: number, column: number) => boolean;
  reset: () => void;
  explode: (row: number, column: number) => void;
  flag: (row: number, column: number) => boolean;
} | null>(null);

function revealAdjacent(row: number, column: number, board: CellData[][]) {
  const adjCells = getAdjacentCoordinates(row, column);

  adjCells.forEach(([adjRow, adjCol]) => {
    const adjCell = board[adjRow]?.[adjCol];

    if (
      adjCell &&
      adjCell.type !== CellType.Revealed &&
      adjCell.type !== CellType.Flagged
    ) {
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
  const { initialBoard, mineIds } = getInitialBoard(difficulty);
  const [mines, setMines] = useState(mineIds);
  const [board, setBoard] = useState<CellData[][]>(initialBoard);
  const [flags, setFlags] = useState<number[]>([]);

  function reveal(row: number, column: number): boolean {
    const boardClone: CellData[][] = board.map((row) => [...row]);

    const cell = boardClone[row][column];
    cell.type = CellType.Revealed;

    if (cell.count === 0) {
      revealAdjacent(row, column, boardClone);
    }

    const cellsToMonitor: number[] = [];

    for (let i = 0; i < boardClone.length; i++) {
      for (let j = 0; j < boardClone[i].length; j++) {
        if (
          [CellType.Hidden, CellType.Bomb, CellType.Flagged].includes(
            boardClone[i][j].type
          )
        ) {
          cellsToMonitor.push(boardClone[i].length * i + j);
        }
      }
    }

    console.log({ cellsToMonitor });

    const boardComplete = mines.every((m, i) => m === cellsToMonitor[i]);

    if (boardComplete) {
      // put flags on all mines
      const rowLength = boardClone[0].length;
      for (const mineId of mines) {
        const col = mineId % boardClone[0].length;
        const row = Math.floor(mineId / rowLength);
        boardClone[row][col].type = CellType.Flagged;
      }
    }

    setBoard(boardClone);
    return boardComplete;
  }

  function updateCellType(row: number, column: number, type: CellType): void {
    const boardClone: CellData[][] = board.map((row) => [...row]);
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
        mines,
        flags,
        reset: () => {
          const { initialBoard, mineIds } = getInitialBoard(difficulty);
          setBoard(initialBoard);
          setMines(mineIds);
          setFlags([]);
        },
        explode: (row: number, column: number) =>
          updateCellType(row, column, CellType.Exploded),
        flag: (row: number, column: number) => {
          const flagClone = [...flags];
          const id = row * initialBoard[0].length + column;
          if (flagClone.includes(id)) {
            flagClone.splice(flagClone.indexOf(id), 1);
          } else {
            flagClone.push(id);
            flagClone.sort((a, b) => a - b);
          }

          setFlags(flagClone);
          updateCellType(row, column, CellType.Flagged);

          const boardComplete = mines.every(
            (val, index) => val === flagClone[index]
          );

          const boardClone = board.map((row) => [...row]);

          if (boardComplete) {
            for (let i = 0; i < boardClone.length; i++) {
              for (let j = 0; j < boardClone[i].length; j++) {
                if (boardClone[i][j].type === CellType.Hidden) {
                  boardClone[i][j].type = CellType.Revealed;
                }
              }
            }
          }

          setBoard(boardClone);
          return boardComplete;
        },
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
