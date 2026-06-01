import React, { createContext, useContext, useState } from "react";

import {
  getAdjacentCoordinates,
  getEmptyBoard,
  getInitialBoard,
  getSafeCellIds,
  isFlagWin,
  isRevealWin,
} from "./helpers";
import { Difficulty, CellData, CellType } from "./types";

const BoardContext = createContext<{
  board: CellData[][];
  mines: number[];
  mineCount: number;
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
  // The board starts empty (no mines); mines are placed on the first reveal so
  // the opening click is always safe. Lazy initialisers avoid rebuilding the
  // board on every render.
  const [mines, setMines] = useState<number[]>([]);
  const [board, setBoard] = useState<CellData[][]>(() =>
    getEmptyBoard(difficulty)
  );
  const [flags, setFlags] = useState<number[]>([]);
  const [started, setStarted] = useState(false);

  function reveal(row: number, column: number): boolean {
    let activeBoard = board;
    let activeMines = mines;

    if (!started) {
      // First reveal: regenerate the board with the clicked cell and its
      // neighbours guaranteed mine-free, so the opener never loses and always
      // opens a zero-region.
      const cols = board[0].length;
      const safeIds = getSafeCellIds(row, column, board.length, cols);
      const generated = getInitialBoard(difficulty, safeIds);
      activeBoard = generated.initialBoard;
      activeMines = generated.mineIds;

      // Preserve any flags placed before the first reveal.
      for (const id of flags) {
        activeBoard[Math.floor(id / cols)][id % cols].type = CellType.Flagged;
      }

      setMines(activeMines);
      setStarted(true);
    }

    const boardClone: CellData[][] = activeBoard.map((row) => [...row]);

    const cell = boardClone[row][column];
    cell.type = CellType.Revealed;

    if (cell.count === 0) {
      revealAdjacent(row, column, boardClone);
    }

    const boardComplete = isRevealWin(boardClone);

    if (boardComplete) {
      // put flags on all mines
      const rowLength = boardClone[0].length;
      for (const mineId of activeMines) {
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
        // The difficulty's enum value is the total number of mines.
        mineCount: difficulty,
        flags,
        reset: () => {
          setBoard(getEmptyBoard(difficulty));
          setMines([]);
          setFlags([]);
          setStarted(false);
        },
        explode: (row: number, column: number) =>
          updateCellType(row, column, CellType.Exploded),
        flag: (row: number, column: number) => {
          const flagClone = [...flags];
          const id = row * board[0].length + column;
          if (flagClone.includes(id)) {
            flagClone.splice(flagClone.indexOf(id), 1);
          } else {
            flagClone.push(id);
            flagClone.sort((a, b) => a - b);
          }

          setFlags(flagClone);
          updateCellType(row, column, CellType.Flagged);

          const boardComplete = isFlagWin(mines, flagClone);

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
