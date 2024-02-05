import React, { MouseEvent } from "react";

import { CellData, CellType, useBoardContext } from "../context/BoardContext/";
import { useScoreboardContext } from "../context/ScoreboardContext";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { faBomb, faFlagCheckered } from "@fortawesome/free-solid-svg-icons";

interface CellProps {
  cell: CellData;
  column: number;
  row: number;
}

export function Cell({ cell, row, column }: CellProps): React.ReactElement {
  const { explode, flag, reveal } = useBoardContext();
  const { startGame, setGameLost, incrementScore, decrementScore, isGameOver } =
    useScoreboardContext();

  const isRevealed = cell.type === CellType.Revealed;
  const isExploded = cell.type === CellType.Exploded;
  const isFlagged = cell.type === CellType.Flagged;

  function handleContextMenuClick(e: MouseEvent<HTMLButtonElement>): void {
    e.preventDefault();

    if (isRevealed || isGameOver) {
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
    if (isFlagged || isGameOver) {
      return;
    }

    if (cell.count >= 0) {
      reveal(row, column);
      startGame();
    }

    if (cell.count === -1) {
      explode(row, column);
      setGameLost();
    }
  }

  const isRevealedClassName = isRevealed ? `revealed adj-${cell.count}` : "";
  const isExplodedClassName = isExploded ? `revealed exploded` : "";

  return (
    <button
      onClick={(e) => handleOnClick(e, cell)}
      onContextMenu={handleContextMenuClick}
      className={`cell ${isRevealedClassName} ${isExplodedClassName}`}
    >
      {isExploded && <FontAwesomeIcon icon={faBomb} />}
      {isFlagged && <FontAwesomeIcon icon={faFlagCheckered} />}
      {isRevealed && cell.count > 0 ? cell.count : ""}
    </button>
  );
}
