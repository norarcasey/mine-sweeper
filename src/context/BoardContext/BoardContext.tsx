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
  chord: (
    row: number,
    column: number
  ) => { exploded: boolean; won: boolean };
} | null>(null);

// Deep clone so updates never mutate the cell objects held by current state.
function cloneBoard(board: CellData[][]): CellData[][] {
  return board.map((row) => row.map((cell) => ({ ...cell })));
}

// Flood-fill from an empty cell, revealing neighbours and skipping flagged ones.
function revealAdjacent(
  row: number,
  column: number,
  board: CellData[][],
  flagged: Set<number>
) {
  const cols = board[0].length;

  for (const [adjRow, adjCol] of getAdjacentCoordinates(row, column)) {
    const adjCell = board[adjRow]?.[adjCol];

    if (
      adjCell &&
      adjCell.type !== CellType.Revealed &&
      !flagged.has(adjRow * cols + adjCol)
    ) {
      adjCell.type = CellType.Revealed;
      if (adjCell.count === 0) {
        revealAdjacent(adjRow, adjCol, board, flagged);
      }
    }
  }
}

export function BoardProvider({
  children,
  difficulty,
}: {
  children: React.ReactNode;
  difficulty: Difficulty;
}) {
  // The board starts empty (no mines); mines are placed on the first reveal so
  // the opening click is always safe. `flags` is the single source of truth for
  // which cells are flagged — flagging never changes a cell's type.
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
      // First reveal: place mines, keeping the clicked cell and its neighbours
      // mine-free so the opener never loses and always opens a zero-region.
      const safeIds = getSafeCellIds(row, column, board.length, board[0].length);
      const generated = getInitialBoard(difficulty, safeIds);
      activeBoard = generated.initialBoard;
      activeMines = generated.mineIds;
      setMines(activeMines);
      setStarted(true);
    }

    const nextBoard = cloneBoard(activeBoard);
    const cell = nextBoard[row][column];
    cell.type = CellType.Revealed;

    if (cell.count === 0) {
      revealAdjacent(row, column, nextBoard, new Set(flags));
    }

    const boardComplete = isRevealWin(nextBoard);
    if (boardComplete) {
      // Flag every mine so the mines-remaining counter reads 0.
      setFlags([...activeMines]);
    }

    setBoard(nextBoard);
    return boardComplete;
  }

  // "Chording": once the player has placed as many flags around a revealed
  // number as the number itself, this reveals every remaining un-flagged
  // neighbour in one move. If a flag was placed wrongly, the un-flagged mine it
  // left behind is revealed and detonates — exactly like clicking it directly.
  function chord(
    row: number,
    column: number
  ): { exploded: boolean; won: boolean } {
    const cols = board[0].length;
    const flagged = new Set(flags);

    const adjacent = getAdjacentCoordinates(row, column).filter(
      ([adjRow, adjCol]) => board[adjRow]?.[adjCol] !== undefined
    );

    // Only fire when the surrounding flag count matches the cell's number —
    // the player's assertion that every adjacent mine is already flagged.
    const adjacentFlagCount = adjacent.filter(([adjRow, adjCol]) =>
      flagged.has(adjRow * cols + adjCol)
    ).length;

    if (adjacentFlagCount !== board[row][column].count) {
      return { exploded: false, won: false };
    }

    const nextBoard = cloneBoard(board);
    let exploded = false;

    for (const [adjRow, adjCol] of adjacent) {
      const id = adjRow * cols + adjCol;
      const adjCell = nextBoard[adjRow][adjCol];

      // Flagged cells are the player's marked mines and stay untouched;
      // already-revealed neighbours need no work.
      if (flagged.has(id) || adjCell.type === CellType.Revealed) {
        continue;
      }

      if (adjCell.count === -1) {
        // A misplaced flag: this un-flagged mine goes off.
        adjCell.type = CellType.Exploded;
        exploded = true;
      } else {
        adjCell.type = CellType.Revealed;
        if (adjCell.count === 0) {
          revealAdjacent(adjRow, adjCol, nextBoard, flagged);
        }
      }
    }

    setBoard(nextBoard);

    if (exploded) {
      return { exploded: true, won: false };
    }

    const won = isRevealWin(nextBoard);
    if (won) {
      // Flag every mine so the mines-remaining counter reads 0.
      setFlags([...mines]);
    }

    return { exploded: false, won };
  }

  return (
    <BoardContext.Provider
      value={{
        board,
        reveal,
        chord,
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
        explode: (row: number, column: number) => {
          const nextBoard = cloneBoard(board);
          nextBoard[row][column].type = CellType.Exploded;
          setBoard(nextBoard);
        },
        flag: (row: number, column: number) => {
          const id = row * board[0].length + column;
          const nextFlags = flags.includes(id)
            ? flags.filter((flagId) => flagId !== id)
            : [...flags, id].sort((a, b) => a - b);
          setFlags(nextFlags);

          const boardComplete = isFlagWin(mines, nextFlags);
          if (boardComplete) {
            const nextBoard = cloneBoard(board);
            for (const cellRow of nextBoard) {
              for (const cell of cellRow) {
                if (cell.type === CellType.Hidden) {
                  cell.type = CellType.Revealed;
                }
              }
            }
            setBoard(nextBoard);
          }

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
