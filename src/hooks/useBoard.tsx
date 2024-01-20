import React from "react";

export enum Difficulty {
  // Beginner board is 9x9 with 10 mines
  Beginner = 10,
  // Intermediate 16x16 board with 40 mines
  Intermediate = 40,
  // Expert 30x16 board with 99 mines
  Expert = 99,
}

interface UseBoard {
  board: number[][];
}

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

export function useBoard(difficulty = Difficulty.Beginner): UseBoard {
  const BOARD_SIZE = getBoardSize(difficulty);

  const board: number[][] = Array.from({ length: BOARD_SIZE[0] }, () =>
    Array(BOARD_SIZE[1]).fill(0)
  );

  // get X random mine locations
  // add them to the board

  const mineIds: number[] = [];

  while (mineIds.length < difficulty) {
    let id = Math.floor(BOARD_SIZE[0] * BOARD_SIZE[1] * Math.random());

    if (!mineIds.includes(id)) {
      mineIds.push(id);
    }
  }

  // add the mines to the board

  for (const id of mineIds) {
    const col = id % BOARD_SIZE[1];
    const row = Math.floor(id / BOARD_SIZE[1]);

    board[row][col] = 1;
  }

  return {
    board,
  };
}
