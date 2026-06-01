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
  c.querySelector('.mine-count [aria-hidden="true"]')?.textContent;
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

// --- chording ----------------------------------------------------------------

describe("MineSweeper — chording", () => {
  // Mines at (0,1) and (8,8): opening (0,0) reveals just itself as a "1", so
  // there is a flagged number to chord against without auto-winning.
  const twoMineBoard = () =>
    vi.mocked(getInitialBoard).mockReturnValueOnce(
      buildBoard(9, 9, [
        [0, 1],
        [8, 8],
      ])
    );

  it("reveals the un-flagged neighbours of a correctly flagged number", () => {
    twoMineBoard();
    const { container } = render(<MineSweeper difficulty={Difficulty.Beginner} />);

    fireEvent.click(cells(container)[0]); // (0,0) -> "1", reveals only itself
    fireEvent.contextMenu(cells(container)[1]); // flag the real mine (0,1)
    expect(revealed(container).length).toBe(1);

    fireEvent.contextMenu(cells(container)[0]); // chord the "1"
    // (1,0) and (1,1) open; the flagged mine (0,1) is left alone.
    expect(revealed(container).length).toBeGreaterThan(1);
    expect(face(container)).toBe("face-smile");
    expect(bombs(container)).toHaveLength(0);
  });

  it("detonates when chording a number whose flag is misplaced", () => {
    twoMineBoard();
    const { container } = render(<MineSweeper difficulty={Difficulty.Beginner} />);

    fireEvent.click(cells(container)[0]); // (0,0) -> "1"
    fireEvent.contextMenu(cells(container)[10]); // wrongly flag (1,1), not the mine

    fireEvent.contextMenu(cells(container)[0]); // chord -> reveals the real mine (0,1)
    expect(face(container)).toBe("face-frown");
    expect(bombs(container).length).toBeGreaterThan(0);
  });

  it("does nothing when the surrounding flag count does not match", () => {
    twoMineBoard();
    const { container } = render(<MineSweeper difficulty={Difficulty.Beginner} />);

    fireEvent.click(cells(container)[0]); // (0,0) -> "1", no flags placed
    fireEvent.contextMenu(cells(container)[0]); // chord with 0 flags != 1

    expect(revealed(container).length).toBe(1);
    expect(bombs(container)).toHaveLength(0);
    expect(face(container)).toBe("face-smile");
  });

  it("chords from a keyboard/left-click activation too", () => {
    twoMineBoard();
    const { container } = render(<MineSweeper difficulty={Difficulty.Beginner} />);

    fireEvent.click(cells(container)[0]); // (0,0) -> "1"
    fireEvent.contextMenu(cells(container)[1]); // flag the mine (0,1)

    fireEvent.click(cells(container)[0]); // activating the revealed number chords
    expect(revealed(container).length).toBeGreaterThan(1);
    expect(face(container)).toBe("face-smile");
  });
});

// --- characterization (pin current behavior before the refactor) -------------

describe("MineSweeper — characterization", () => {
  it("keeps flags placed before the first reveal", () => {
    const { container } = render(<MineSweeper difficulty={Difficulty.Beginner} />);
    fireEvent.contextMenu(cells(container)[10]); // flag before any reveal
    expect(flags(container)).toHaveLength(1);

    fireEvent.click(cells(container)[40]); // first reveal places mines
    // The pre-placed flag is re-applied onto the regenerated board.
    expect(flags(container)).toHaveLength(1);
    expect(
      cells(container)[10].querySelector('[data-icon="flag-checkered"]')
    ).not.toBeNull();
  });

  it("does not reveal a flagged cell via the cascade, and a stray flag blocks the reveal-win", () => {
    vi.mocked(getInitialBoard).mockReturnValueOnce(buildBoard(9, 9, [[8, 8]]));
    const { container } = render(<MineSweeper difficulty={Difficulty.Beginner} />);
    fireEvent.contextMenu(cells(container)[40]); // flag the center first
    fireEvent.click(cells(container)[0]); // opener would otherwise flood the center

    expect(cells(container)[40].classList.contains("revealed")).toBe(false);
    expect(flags(container)).toHaveLength(1);
    // Not a win: the flagged safe cell is never revealed.
    expect(face(container)).toBe("face-smile");
  });

  it("drives the counter to 000 on a reveal win", () => {
    // 10 mines clustered in a corner so opening the opposite corner floods the rest.
    const mines: [number, number][] = [];
    for (let r = 7; r <= 8; r++) for (let c = 4; c <= 8; c++) mines.push([r, c]);
    vi.mocked(getInitialBoard).mockReturnValueOnce(buildBoard(9, 9, mines));
    const { container } = render(<MineSweeper difficulty={Difficulty.Beginner} />);

    fireEvent.click(cells(container)[0]);
    expect(face(container)).toBe("face-grin-hearts");
    expect(counter(container)).toBe("000");
  });

  it("shows a negative counter when over-flagging without a false win", () => {
    const { container } = render(<MineSweeper difficulty={Difficulty.Beginner} />);
    for (let i = 0; i < 11; i++) fireEvent.contextMenu(cells(container)[i]); // 11 > 10 mines
    expect(counter(container)).toBe("-01");
    expect(face(container)).toBe("face-smile");
  });

  it("treats clicking an already-revealed cell as a no-op", () => {
    const { container } = render(<MineSweeper difficulty={Difficulty.Beginner} />);
    fireEvent.click(cells(container)[40]);
    const before = revealed(container).length;

    fireEvent.click(revealed(container)[0]); // click an already-revealed cell
    expect(revealed(container).length).toBe(before);
    expect(bombs(container)).toHaveLength(0);
    expect(face(container)).toBe("face-smile");
  });

  it("restores a flagged numbered cell and a flagged mine when unflagged", () => {
    // Two mines so flagging one isn't a flag-win (which would end the game and
    // block the unflag).
    vi.mocked(getInitialBoard).mockReturnValueOnce(
      buildBoard(9, 9, [
        [0, 1],
        [8, 8],
      ])
    );
    const { container } = render(<MineSweeper difficulty={Difficulty.Beginner} />);
    fireEvent.click(cells(container)[0]); // (0,0) is a number -> reveals only itself

    // (0,2) is a hidden numbered cell (adjacent to the mine); (0,1) is the mine.
    for (const idx of [2, 1]) {
      const cell = cells(container)[idx];
      fireEvent.contextMenu(cell); // flag
      expect(cell.querySelector('[data-icon="flag-checkered"]')).not.toBeNull();
      fireEvent.contextMenu(cell); // unflag -> restored, still hidden
      expect(cell.querySelector('[data-icon="flag-checkered"]')).toBeNull();
      expect(cell.classList.contains("revealed")).toBe(false);
    }
  });
});

// --- accessibility -----------------------------------------------------------

describe("MineSweeper — accessibility", () => {
  const label = (cell: HTMLButtonElement) => cell.getAttribute("aria-label");

  it("labels each cell with its position and state", () => {
    const { container } = render(<MineSweeper difficulty={Difficulty.Beginner} />);
    expect(label(cells(container)[0])).toBe("Row 1, column 1, hidden");

    fireEvent.click(cells(container)[40]); // safe opener (4,4) -> empty
    expect(label(cells(container)[40])).toBe("Row 5, column 5, empty");
  });

  it("labels a revealed numbered cell with its adjacent-mine count", () => {
    vi.mocked(getInitialBoard).mockReturnValueOnce(
      buildBoard(9, 9, [
        [0, 1],
        [8, 8],
      ])
    );
    const { container } = render(<MineSweeper difficulty={Difficulty.Beginner} />);
    fireEvent.click(cells(container)[0]); // (0,0) -> 1 adjacent mine
    expect(label(cells(container)[0])).toBe("Row 1, column 1, 1 adjacent mine");
  });

  it("flags a cell with the F key and reflects it in the label", () => {
    const { container } = render(<MineSweeper difficulty={Difficulty.Beginner} />);
    fireEvent.keyDown(cells(container)[0], { key: "f" });
    expect(flags(container)).toHaveLength(1);
    expect(label(cells(container)[0])).toBe("Row 1, column 1, flagged");
    expect(counter(container)).toBe("009");

    fireEvent.keyDown(cells(container)[0], { key: "f" }); // toggle off
    expect(flags(container)).toHaveLength(0);
    expect(label(cells(container)[0])).toBe("Row 1, column 1, hidden");
  });

  it("labels the board region and the reset button", () => {
    const { container } = render(<MineSweeper difficulty={Difficulty.Beginner} />);
    expect(
      container.querySelector('[role="grid"][aria-label="Minesweeper board"]')
    ).not.toBeNull();
    expect(
      container.querySelector(".reset-button")?.getAttribute("aria-label")
    ).toBe("New game");
  });

  it("announces win and loss in a live region", () => {
    const status = (c: HTMLElement) =>
      c.querySelector('[role="status"]')?.textContent;

    // Loss
    vi.mocked(getInitialBoard).mockReturnValueOnce(
      buildBoard(9, 9, [
        [0, 1],
        [8, 8],
      ])
    );
    const lost = render(<MineSweeper difficulty={Difficulty.Beginner} />);
    expect(status(lost.container)).toBe("");
    fireEvent.click(cells(lost.container)[0]); // safe
    fireEvent.click(cells(lost.container)[1]); // mine
    expect(status(lost.container)).toBe("You lost!");

    // Win (single corner mine floods the rest on the opener)
    vi.mocked(getInitialBoard).mockReturnValueOnce(buildBoard(9, 9, [[8, 8]]));
    const won = render(<MineSweeper difficulty={Difficulty.Beginner} />);
    fireEvent.click(cells(won.container)[0]);
    expect(status(won.container)).toBe("You won!");
  });
});

// --- keyboard grid navigation ------------------------------------------------

describe("MineSweeper — keyboard grid navigation", () => {
  it("keeps only the focused cell in the tab order (roving tabindex)", () => {
    const { container } = render(<MineSweeper difficulty={Difficulty.Beginner} />);
    const cs = cells(container);
    expect(cs[0].tabIndex).toBe(0);
    expect(cs[1].tabIndex).toBe(-1);
    expect(cs[80].tabIndex).toBe(-1);
  });

  it("moves focus with the arrow keys and rolls the tab order", () => {
    const { container } = render(<MineSweeper difficulty={Difficulty.Beginner} />);
    const cs = cells(container);

    fireEvent.keyDown(cs[0], { key: "ArrowRight" });
    expect(document.activeElement).toBe(cs[1]);
    expect(cs[1].tabIndex).toBe(0);
    expect(cs[0].tabIndex).toBe(-1);

    fireEvent.keyDown(cs[1], { key: "ArrowDown" });
    expect(document.activeElement).toBe(cs[1 + 9]); // down a row (9 columns)

    fireEvent.keyDown(cs[10], { key: "ArrowLeft" });
    expect(document.activeElement).toBe(cs[9]);

    fireEvent.keyDown(cs[9], { key: "ArrowUp" });
    expect(document.activeElement).toBe(cs[0]);
  });

  it("clamps at the board edges", () => {
    const { container } = render(<MineSweeper difficulty={Difficulty.Beginner} />);
    const cs = cells(container);
    fireEvent.keyDown(cs[0], { key: "ArrowLeft" });
    expect(document.activeElement).toBe(cs[0]);
    fireEvent.keyDown(cs[0], { key: "ArrowUp" });
    expect(document.activeElement).toBe(cs[0]);
  });

  it("jumps to row ends with Home/End and grid corners with Ctrl", () => {
    const { container } = render(<MineSweeper difficulty={Difficulty.Beginner} />);
    const cs = cells(container);

    fireEvent.keyDown(cs[0], { key: "End" });
    expect(document.activeElement).toBe(cs[8]); // end of row 0

    fireEvent.keyDown(cs[8], { key: "Home" });
    expect(document.activeElement).toBe(cs[0]); // start of row 0

    fireEvent.keyDown(cs[0], { key: "End", ctrlKey: true });
    expect(document.activeElement).toBe(cs[80]); // last cell

    fireEvent.keyDown(cs[80], { key: "Home", ctrlKey: true });
    expect(document.activeElement).toBe(cs[0]); // first cell
  });

  it("still flags the focused cell with F after navigating", () => {
    const { container } = render(<MineSweeper difficulty={Difficulty.Beginner} />);
    const cs = cells(container);
    fireEvent.keyDown(cs[0], { key: "ArrowRight" }); // focus cs[1]
    fireEvent.keyDown(cs[1], { key: "f" });
    expect(cs[1].getAttribute("aria-label")).toContain("flagged");
  });
});
