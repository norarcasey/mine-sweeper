import { render, fireEvent, cleanup } from "@testing-library/react";

import MineSweeper from "./MineSweeper";
import { Difficulty } from "./context/BoardContext";
import { CellType, CellData } from "./context/BoardContext/types";
import {
  getInitialBoard,
  getAdjacentCoordinates,
} from "./context/BoardContext/helpers";

// Wrap getInitialBoard in a spy that delegates to the real implementation by
// default; outcome tests override it with a hand-built board for determinism.
vi.mock("./context/BoardContext/helpers", async (importOriginal) => {
  const actual =
    await importOriginal<typeof import("./context/BoardContext/helpers")>();
  return { ...actual, getInitialBoard: vi.fn(actual.getInitialBoard) };
});

afterEach(() => {
  cleanup();
  vi.mocked(getInitialBoard).mockClear();
});

// --- helpers -----------------------------------------------------------------

const cells = (c: HTMLElement) =>
  Array.from(c.querySelectorAll<HTMLButtonElement>("button.cell"));
const revealed = (c: HTMLElement) => c.querySelectorAll("button.cell.revealed");
const bombs = (c: HTMLElement) => c.querySelectorAll('[data-icon="bomb"]');
const flags = (c: HTMLElement) =>
  c.querySelectorAll('[data-icon="flag-checkered"]');
const counter = (c: HTMLElement) =>
  c.querySelector(".mine-count")?.textContent;
const face = (c: HTMLElement) =>
  c.querySelector(".reset-button svg")?.getAttribute("data-icon");

// Build a deterministic board (mirrors getInitialBoard's counting) for the
// outcome tests. `mines` are [row, col] pairs.
function buildBoard(rows: number, cols: number, mines: [number, number][]) {
  const board: CellData[][] = Array.from({ length: rows }, () =>
    Array.from({ length: cols }, () => ({ type: CellType.Empty, count: 0 }))
  );
  for (const [r, c] of mines) {
    board[r][c] = { type: CellType.Bomb, count: -1 };
    for (const [ar, ac] of getAdjacentCoordinates(r, c)) {
      const cell = board[ar]?.[ac];
      if (cell && cell.type !== CellType.Bomb) {
        cell.count = (cell.count + 1) as CellData["count"];
        cell.type = CellType.Hidden;
      }
    }
  }
  const mineIds = mines.map(([r, c]) => r * cols + c).sort((a, b) => a - b);
  return { initialBoard: board, mineIds };
}

// --- behavior (real RNG) -----------------------------------------------------

describe("MineSweeper — behavior", () => {
  it("renders a board sized for the difficulty", () => {
    const { container } = render(<MineSweeper difficulty={Difficulty.Beginner} />);
    expect(cells(container)).toHaveLength(81); // 9 x 9
    expect(counter(container)).toBe("010"); // 10 mines, none flagged
    expect(face(container)).toBe("face-smile");
  });

  it("never loses on the first click and opens a region", () => {
    const { container } = render(<MineSweeper difficulty={Difficulty.Beginner} />);
    fireEvent.click(cells(container)[40]); // center
    // First-click safety: the opener is mine-free and cascades.
    expect(revealed(container).length).toBeGreaterThan(1);
    expect(bombs(container)).toHaveLength(0);
    expect(face(container)).toBe("face-smile");
  });

  it("toggles a flag on right-click and updates the counter", () => {
    const { container } = render(<MineSweeper difficulty={Difficulty.Beginner} />);
    fireEvent.contextMenu(cells(container)[0]);
    expect(flags(container)).toHaveLength(1);
    expect(counter(container)).toBe("009");

    fireEvent.contextMenu(cells(container)[0]);
    expect(flags(container)).toHaveLength(0);
    expect(counter(container)).toBe("010");
  });

  it("resets the board, counter, and face", () => {
    const { container } = render(<MineSweeper difficulty={Difficulty.Beginner} />);
    fireEvent.click(cells(container)[40]);
    fireEvent.contextMenu(cells(container)[0]);
    expect(revealed(container).length).toBeGreaterThan(0);

    fireEvent.click(container.querySelector(".reset-button")!);
    expect(revealed(container)).toHaveLength(0);
    expect(flags(container)).toHaveLength(0);
    expect(counter(container)).toBe("010");
    expect(face(container)).toBe("face-smile");
  });

  it("resets to a correctly sized board when difficulty changes", () => {
    // Regression for the difficulty-desync fix: the keyed provider remounts.
    const { container, rerender } = render(
      <MineSweeper difficulty={Difficulty.Beginner} />
    );
    expect(cells(container)).toHaveLength(81); // 9 x 9

    rerender(<MineSweeper difficulty={Difficulty.Expert} />);
    expect(cells(container)).toHaveLength(480); // 16 x 30
    expect(counter(container)).toBe("099");
  });
});

// --- outcomes (mocked board) -------------------------------------------------

describe("MineSweeper — outcomes", () => {
  it("loses and reveals every mine when a bomb is clicked", () => {
    // Mine at (0,1) makes the opener (0,0) a number (reveals only itself, no
    // auto-win); a second mine at (8,8) must surface on the loss.
    vi.mocked(getInitialBoard).mockReturnValueOnce(
      buildBoard(9, 9, [
        [0, 1],
        [8, 8],
      ])
    );
    const { container } = render(<MineSweeper difficulty={Difficulty.Beginner} />);

    fireEvent.click(cells(container)[0]); // (0,0) — safe opener
    expect(bombs(container)).toHaveLength(0);
    expect(face(container)).toBe("face-smile");

    fireEvent.click(cells(container)[1]); // (0,1) — a mine
    expect(face(container)).toBe("face-frown");
    expect(bombs(container)).toHaveLength(2); // clicked + the revealed (8,8)
  });

  it("wins when every safe cell is revealed", () => {
    // A single corner mine: opening (0,0) floods the rest -> reveal win.
    vi.mocked(getInitialBoard).mockReturnValueOnce(buildBoard(9, 9, [[8, 8]]));
    const { container } = render(<MineSweeper difficulty={Difficulty.Beginner} />);

    fireEvent.click(cells(container)[0]);
    expect(face(container)).toBe("face-grin-hearts");
  });

  it("wins when exactly the mines are flagged", () => {
    vi.mocked(getInitialBoard).mockReturnValueOnce(
      buildBoard(9, 9, [
        [0, 1],
        [8, 8],
      ])
    );
    const { container } = render(<MineSweeper difficulty={Difficulty.Beginner} />);

    fireEvent.click(cells(container)[0]); // place mines via the first reveal
    fireEvent.contextMenu(cells(container)[1]); // flag (0,1)
    expect(face(container)).toBe("face-smile");
    fireEvent.contextMenu(cells(container)[80]); // flag (8,8) -> win
    expect(face(container)).toBe("face-grin-hearts");
  });
});
