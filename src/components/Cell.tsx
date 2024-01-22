import React, { MouseEvent } from "react";

import { CellData, CellType, useBoardContext } from "../context/BoardContext/";
import { useScoreboardContext } from "../context/ScoreboardContext";

interface CellProps {
  cell: CellData;
  column: number;
  row: number;
}

export function Cell({ cell, row, column }: CellProps): React.ReactElement {
  const { explode, flag, reveal } = useBoardContext();
  const { setGameLost, incrementScore, decrementScore } =
    useScoreboardContext();
  const isRevealed = cell.type === CellType.Revealed;
  const isExploded = cell.type === CellType.Exploded;
  const isFlagged = cell.type === CellType.Flagged;

  function handleContextMenuClick(e: MouseEvent<HTMLButtonElement>): void {
    e.preventDefault();

    if (isRevealed) {
      return;
    }

    if (cell.type !== CellType.Flagged) {
      flag(row, column);
      incrementScore();
    } else {
      flag(row, column);
      decrementScore();
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
      setGameLost();
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
