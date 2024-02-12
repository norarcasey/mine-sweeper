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
  const {
    startGame,
    setGameLost,
    setGameWon,
    incrementScore,
    decrementScore,
    isGameOver,
  } = useScoreboardContext();

  const isRevealed = cell.type === CellType.Revealed;
  const isExploded = cell.type === CellType.Exploded;
  const isFlagged = cell.type === CellType.Flagged;

  function handleContextMenuClick(e: MouseEvent<HTMLButtonElement>): void {
    e.preventDefault();

    if (isRevealed || isGameOver) {
      return;
    }

    let allMinesFlagged = false;
    if (cell.type !== CellType.Flagged) {
      allMinesFlagged = flag(row, column);
      incrementScore();
    } else {
      allMinesFlagged = flag(row, column);
      decrementScore();
    }

    if (allMinesFlagged) {
      // TODO: Reveal the rest of the unrevealed.
      setGameWon();
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
      const allRevealed = reveal(row, column);

      //TODO: this seems excessive
      startGame();

      if (allRevealed) {
        setGameWon();
      }
    }

    if (cell.count === -1) {
      explode(row, column);
      setGameLost();
    }
  }

  const isRevealedClassName = isRevealed ? `revealed adj-${cell.count}` : "";
  const isExplodedClassName = isExploded ? `revealed exploded` : "";
  const isFlaggedClassName = isFlagged ? "flagged" : "";

  return (
    <button
      onClick={(e) => handleOnClick(e, cell)}
      onContextMenu={handleContextMenuClick}
      className={`cell ${isRevealedClassName} ${isExplodedClassName} ${isFlaggedClassName}`}
    >
      {isExploded && <FontAwesomeIcon icon={faBomb} />}
      {isFlagged && <FontAwesomeIcon icon={faFlagCheckered} />}
      {isRevealed && cell.count > 0 ? cell.count : ""}
    </button>
  );
}
