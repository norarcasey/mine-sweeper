import React, { KeyboardEvent, FocusEvent, useRef, useState } from "react";

import { useBoardContext } from "../context/BoardContext/BoardContext";
import { Cell } from "./Cell";

export function GameBoard(): React.ReactElement {
  const { board } = useBoardContext();
  const rows = board.length;
  const cols = board[0].length;

  // Roving tabindex: exactly one cell is in the tab order at a time; arrow keys
  // move focus (and that index) around the grid.
  const [focusedIndex, setFocusedIndex] = useState(0);
  const boardRef = useRef<HTMLDivElement>(null);

  function cellButtons(): HTMLButtonElement[] {
    return Array.from(
      boardRef.current?.querySelectorAll<HTMLButtonElement>("button.cell") ?? []
    );
  }

  // Keep the active index in sync with wherever focus actually lands (tabbing
  // in, clicking, or arrow navigation).
  function handleFocus(event: FocusEvent<HTMLDivElement>): void {
    const target = event.target as HTMLElement;
    const index = cellButtons().indexOf(target as HTMLButtonElement);
    if (index >= 0) {
      setFocusedIndex(index);
    }
  }

  function handleKeyDown(event: KeyboardEvent<HTMLDivElement>): void {
    let row = Math.floor(focusedIndex / cols);
    let column = focusedIndex % cols;

    switch (event.key) {
      case "ArrowUp":
        row = Math.max(0, row - 1);
        break;
      case "ArrowDown":
        row = Math.min(rows - 1, row + 1);
        break;
      case "ArrowLeft":
        column = Math.max(0, column - 1);
        break;
      case "ArrowRight":
        column = Math.min(cols - 1, column + 1);
        break;
      case "Home":
        column = 0;
        if (event.ctrlKey) row = 0;
        break;
      case "End":
        column = cols - 1;
        if (event.ctrlKey) row = rows - 1;
        break;
      default:
        return;
    }

    event.preventDefault();
    const nextIndex = row * cols + column;
    setFocusedIndex(nextIndex);
    cellButtons()[nextIndex]?.focus();
  }

  return (
    <div
      className="board"
      role="grid"
      aria-label="Minesweeper board"
      ref={boardRef}
      onKeyDown={handleKeyDown}
      onFocus={handleFocus}
    >
      {board.map((row, rowIndex) => (
        <div key={`row-${rowIndex}`} className="row" role="row">
          {row.map((cell, cellIndex) => (
            <Cell
              key={`cell-${cellIndex}`}
              cell={cell}
              row={rowIndex}
              column={cellIndex}
              tabIndex={rowIndex * cols + cellIndex === focusedIndex ? 0 : -1}
            />
          ))}
        </div>
      ))}
    </div>
  );
}
