import React, { MouseEvent } from "react";
import { useBoardContext } from "../context/BoardContext";

interface CellProps {
  row: number;
  column: number;
  cell: number;
}

export function Cell({ cell, row, column }: CellProps): React.ReactElement {
  const { board } = useBoardContext();

  function handleContextMenuClick(e: MouseEvent<HTMLButtonElement>): void {
    e.preventDefault();

    ["fa-flag-checkered", "fa-solid"].forEach((c) =>
      e.currentTarget.classList.toggle(c)
    );
  }

  function handleOnClick(e: MouseEvent<HTMLButtonElement>, cell: number): void {
    if (cell === 0) {
      e.currentTarget.classList.toggle("revealed");

      let bombCount = 0;

      bombCount += board[row][column - 1] ?? 0;
      bombCount += board[row][column + 1] ?? 0;

      if (board[row - 1]) {
        bombCount += board[row - 1][column - 1] ?? 0;
        bombCount += board[row - 1][column];
        bombCount += board[row - 1][column + 1] ?? 0;
      }

      if (board[row + 1]) {
        bombCount += board[row + 1][column - 1] ?? 0;
        bombCount += board[row + 1][column] ?? 0;
        bombCount += board[row + 1][column + 1] ?? 0;
      }

      if (bombCount > 0) {
        e.currentTarget.textContent = bombCount.toString();
      } else {
        // TODO: Expand the reveal
      }
    }

    if (cell === 1) {
      ["revealed", "fa-solid", "fa-bomb"].forEach((c) =>
        e.currentTarget.classList.toggle(c)
      );
    }
  }

  return (
    <button
      onClick={(e) => handleOnClick(e, cell)}
      onContextMenu={handleContextMenuClick}
      className={`cell`}
    ></button>
  );
}
