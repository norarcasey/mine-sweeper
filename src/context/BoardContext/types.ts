export enum CellType {
  Bomb,
  Empty,
  Hidden,
  Revealed,
  Flagged,
}

export interface CellData {
  type: CellType;
  count: -1 | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8;
}

export enum Difficulty {
  // Beginner board is 9x9 with 10 mines
  Beginner = 10,
  // Intermediate 16x16 board with 40 mines
  Intermediate = 40,
  // Expert 30x16 board with 99 mines
  Expert = 99,
}
