import React, { MouseEvent, useState } from "react";
import { CellData, CellType, useBoardContext } from "../context/BoardContext/";

interface CellProps {
  cell: CellData;
  column: number;
  row: number;
}

export function Cell({ cell, row, column }: CellProps): React.ReactElement {
  const { reveal } = useBoardContext();
  const [flagged, setFlagged] = useState(false);
  const isRevealed = cell.type === CellType.Revealed;

  function handleContextMenuClick(e: MouseEvent<HTMLButtonElement>): void {
    e.preventDefault();

    if (!isRevealed) {
      setFlagged(!flagged);
    }
  }

  function handleOnClick(
    e: MouseEvent<HTMLButtonElement>,
    cell: CellData
  ): void {
    // Can't click a flagged cell
    if (flagged) {
      return;
    }

    if (cell.count >= 0) {
      reveal(row, column);
    }

    if (cell.count === -1) {
      ["revealed", "fa-solid", "fa-bomb"].forEach((c) =>
        e.currentTarget.classList.toggle(c)
      );
    }
  }

  const isRevealedClassName = isRevealed ? `revealed adj-${cell.count}` : "";
  const isFlaggedClassName = flagged ? "fa-flag-checkered fa-solid" : "";

  return (
    <button
      onClick={(e) => handleOnClick(e, cell)}
      onContextMenu={handleContextMenuClick}
      className={`cell ${isFlaggedClassName} ${isRevealedClassName}`}
    >
      {isRevealed && cell.count > 0 ? cell.count : ""}
    </button>
  );
}
