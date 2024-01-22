import React, { MouseEvent } from "react";

import { CellData, CellType, useBoardContext } from "../context/BoardContext/";

interface CellProps {
  cell: CellData;
  column: number;
  row: number;
}

export function Cell({ cell, row, column }: CellProps): React.ReactElement {
  const { explode, flag, reveal } = useBoardContext();
  const isRevealed = cell.type === CellType.Revealed;
  const isExploded = cell.type === CellType.Exploded;
  const isFlagged = cell.type === CellType.Flagged;

  function handleContextMenuClick(e: MouseEvent<HTMLButtonElement>): void {
    e.preventDefault();

    if (!isRevealed) {
      flag(row, column);
    }
  }

  function handleOnClick(
    e: MouseEvent<HTMLButtonElement>,
    cell: CellData
  ): void {
    // Can't click a flagged cell
    if (isFlagged) {
      return;
    }

    if (cell.count >= 0) {
      reveal(row, column);
    }

    if (cell.count === -1) {
      explode(row, column);
    }
  }

  const isRevealedClassName = isRevealed ? `revealed adj-${cell.count}` : "";
  const isFlaggedClassName = isFlagged ? "fa-flag-checkered fa-solid" : "";
  const boomedClassName = isExploded ? "revealed fa-solid fa-bomb" : "";

  return (
    <button
      onClick={(e) => handleOnClick(e, cell)}
      onContextMenu={handleContextMenuClick}
      className={`cell ${isFlaggedClassName} ${isRevealedClassName} ${boomedClassName}`}
    >
      {isRevealed && cell.count > 0 ? cell.count : ""}
    </button>
  );
}
