import {
  getAdjacentCoordinates,
  getInitialBoard,
  getSafeCellIds,
  isFlagWin,
  isRevealWin,
} from "./helpers";
import { CellData, CellType, Difficulty } from "./types";

describe("getAdjacentCoordinates", () => {
  it("returns the eight surrounding coordinates", () => {
    const coords = getAdjacentCoordinates(5, 5);

    expect(coords).toHaveLength(8);
    expect(coords).toEqual(
      expect.arrayContaining([
        [4, 4], // northwest
        [4, 5], // north
        [4, 6], // northeast
        [5, 6], // east
        [6, 6], // southeast
        [6, 5], // south
        [6, 4], // southwest
        [5, 4], // west
      ])
    );
  });

  it("never includes the cell itself", () => {
    const coords = getAdjacentCoordinates(3, 7);
    expect(coords).not.toContainEqual([3, 7]);
  });

  it("returns out-of-bounds (negative) coordinates at an edge", () => {
    // Callers are responsible for bounds-checking; the helper is purely
    // arithmetic and should not clamp.
    const coords = getAdjacentCoordinates(0, 0);
    expect(coords).toContainEqual([-1, -1]);
    expect(coords).toContainEqual([-1, 0]);
    expect(coords).toContainEqual([0, -1]);
  });
});

describe("getInitialBoard", () => {
  const cases: Array<[string, Difficulty, number, number, number]> = [
    // [name, difficulty, rows, cols, mines]
    ["Beginner", Difficulty.Beginner, 9, 9, 10],
    ["Intermediate", Difficulty.Intermediate, 16, 16, 40],
    ["Expert", Difficulty.Expert, 16, 30, 99],
  ];

  describe.each(cases)("%s", (_name, difficulty, rows, cols, mineCount) => {
    it(`builds a ${rows}x${cols} board`, () => {
      const { initialBoard } = getInitialBoard(difficulty);

      expect(initialBoard).toHaveLength(rows);
      initialBoard.forEach((row) => expect(row).toHaveLength(cols));
    });

    it(`places exactly ${mineCount} mines`, () => {
      const { initialBoard, mineIds } = getInitialBoard(difficulty);

      expect(mineIds).toHaveLength(mineCount);

      const bombCells = initialBoard
        .flat()
        .filter((cell) => cell.type === CellType.Bomb);
      expect(bombCells).toHaveLength(mineCount);
    });

    it("returns mineIds that are unique, sorted, and in range", () => {
      const { mineIds } = getInitialBoard(difficulty);

      const unique = new Set(mineIds);
      expect(unique.size).toBe(mineIds.length);

      const sorted = [...mineIds].sort((a, b) => a - b);
      expect(mineIds).toEqual(sorted);

      mineIds.forEach((id) => {
        expect(id).toBeGreaterThanOrEqual(0);
        expect(id).toBeLessThan(rows * cols);
      });
    });

    it("maps every mineId to a bomb cell", () => {
      const { initialBoard, mineIds } = getInitialBoard(difficulty);

      mineIds.forEach((id) => {
        const row = Math.floor(id / cols);
        const col = id % cols;
        expect(initialBoard[row][col].type).toBe(CellType.Bomb);
      });
    });

    it("gives every bomb a count of -1", () => {
      const { initialBoard } = getInitialBoard(difficulty);

      initialBoard.flat().forEach((cell) => {
        if (cell.type === CellType.Bomb) {
          expect(cell.count).toBe(-1);
        }
      });
    });

    it("sets each non-bomb count to its number of adjacent bombs", () => {
      const { initialBoard } = getInitialBoard(difficulty);

      const isBomb = (r: number, c: number) =>
        initialBoard[r]?.[c]?.type === CellType.Bomb;

      initialBoard.forEach((row, r) => {
        row.forEach((cell, c) => {
          if (cell.type === CellType.Bomb) return;

          const adjacentBombs = getAdjacentCoordinates(r, c).filter(
            ([ar, ac]) => isBomb(ar, ac)
          ).length;

          expect(cell.count).toBe(adjacentBombs);
        });
      });
    });

    it("types non-bomb cells as Empty when count is 0 and Hidden otherwise", () => {
      const { initialBoard } = getInitialBoard(difficulty);

      initialBoard.flat().forEach((cell) => {
        if (cell.type === CellType.Bomb) return;

        if (cell.count === 0) {
          expect(cell.type).toBe(CellType.Empty);
        } else {
          expect(cell.type).toBe(CellType.Hidden);
        }
      });
    });

    it("creates independent cell objects (no shared references)", () => {
      const { initialBoard } = getInitialBoard(difficulty);

      const cells = initialBoard.flat();
      const uniqueRefs = new Set(cells);
      expect(uniqueRefs.size).toBe(cells.length);
    });
  });
});

describe("getSafeCellIds", () => {
  it("returns the clicked cell plus all eight neighbours mid-board", () => {
    // 9x9 board, click center (4,4) => id 40.
    expect(getSafeCellIds(4, 4, 9, 9).sort((a, b) => a - b)).toEqual([
      30, 31, 32, 39, 40, 41, 48, 49, 50,
    ]);
  });

  it("clamps to on-board neighbours at a corner", () => {
    // (0,0) has only E, S, SE neighbours on the board.
    expect(getSafeCellIds(0, 0, 9, 9).sort((a, b) => a - b)).toEqual([
      0, 1, 9, 10,
    ]);
  });

  it("clamps to on-board neighbours at an edge", () => {
    // Top edge (0,4): the northern row is off-board.
    expect(getSafeCellIds(0, 4, 9, 9).sort((a, b) => a - b)).toEqual([
      3, 4, 5, 12, 13, 14,
    ]);
  });
});

describe("getInitialBoard with safe cells (first-click safety)", () => {
  it("never places a mine on a safe id", () => {
    const safeIds = getSafeCellIds(4, 4, 9, 9);
    const { mineIds } = getInitialBoard(Difficulty.Beginner, safeIds);

    safeIds.forEach((id) => expect(mineIds).not.toContain(id));
  });

  it("still places the full mine count when cells are excluded", () => {
    const safeIds = getSafeCellIds(4, 4, 9, 9);
    const { mineIds } = getInitialBoard(Difficulty.Beginner, safeIds);

    expect(mineIds).toHaveLength(10);
  });

  it("leaves the clicked cell with count 0 so it opens a region", () => {
    // All eight neighbours are safe, so the clicked cell has no adjacent
    // mines and will trigger the flood-fill reveal.
    const safeIds = getSafeCellIds(4, 4, 9, 9);
    const { initialBoard } = getInitialBoard(Difficulty.Beginner, safeIds);

    expect(initialBoard[4][4].count).toBe(0);
    expect(initialBoard[4][4].type).toBe(CellType.Empty);
  });
});

describe("isFlagWin", () => {
  it("wins when the flagged set is exactly the mine set", () => {
    expect(isFlagWin([2, 5, 8], [2, 5, 8])).toBe(true);
  });

  it("does not win when a non-mine cell is also flagged (extra flag)", () => {
    // Regression for the `.every` length bug: an extra flag with an id larger
    // than every mine used to slip through because `every` stops at
    // mines.length.
    expect(isFlagWin([2, 5, 8], [2, 5, 8, 50])).toBe(false);
  });

  it("does not win when not every mine is flagged", () => {
    expect(isFlagWin([2, 5, 8], [2, 5])).toBe(false);
  });

  it("does not win when a flag is on a non-mine instead of a mine", () => {
    // Same length, different membership.
    expect(isFlagWin([2, 5, 8], [2, 5, 9])).toBe(false);
  });

  it("does not win with no flags placed", () => {
    expect(isFlagWin([2, 5, 8], [])).toBe(false);
  });

  it("does not win before any mines exist (empty board)", () => {
    // Guards the pre-first-reveal state where mines have not been placed yet.
    expect(isFlagWin([], [])).toBe(false);
  });
});

describe("isRevealWin", () => {
  // Build a board row from a compact spec. `-1` => bomb, otherwise a count;
  // the second value is the cell's current type.
  const row = (...cells: Array<[number, CellType]>): CellData[] =>
    cells.map(([count, type]) => ({ count, type } as CellData));

  it("wins when every non-bomb cell is revealed (bombs left hidden)", () => {
    const board = [
      row([-1, CellType.Bomb], [1, CellType.Revealed]),
      row([1, CellType.Revealed], [1, CellType.Revealed]),
    ];
    expect(isRevealWin(board)).toBe(true);
  });

  it("wins regardless of how bombs are typed (exploded or not)", () => {
    const board = [
      row([-1, CellType.Exploded], [1, CellType.Revealed]),
      row([-1, CellType.Bomb], [2, CellType.Revealed]),
    ];
    expect(isRevealWin(board)).toBe(true);
  });

  it("does not win while a numbered cell is still hidden", () => {
    const board = [
      row([-1, CellType.Bomb], [1, CellType.Revealed]),
      row([1, CellType.Hidden], [1, CellType.Revealed]),
    ];
    expect(isRevealWin(board)).toBe(false);
  });

  it("does not win while an empty (count 0) cell is unrevealed", () => {
    // Regression for bug #2: count-0 cells keep type Empty until flood-filled
    // and must not be treated as already satisfied.
    const board = [
      row([-1, CellType.Bomb], [1, CellType.Revealed]),
      row([0, CellType.Empty], [1, CellType.Revealed]),
    ];
    expect(isRevealWin(board)).toBe(false);
  });
});
