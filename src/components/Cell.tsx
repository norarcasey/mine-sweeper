import React, { MouseEvent } from "react";

import { CellData, CellType, useBoardContext } from "../context/BoardContext/";
import { useScoreboardContext, GameState } from "../context/ScoreboardContext";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { faBomb, faFlagCheckered } from "@fortawesome/free-solid-svg-icons";

interface CellProps {
  cell: CellData;
  column: number;
  row: number;
}

export function Cell({ cell, row, column }: CellProps): React.ReactElement {
  const { explode, flag, reveal, flags, board } = useBoardContext();
  const { startGame, setGameLost, setGameWon, isGameOver, gameState } =
    useScoreboardContext();

  const isRevealed = cell.type === CellType.Revealed;
  const isExploded = cell.type === CellType.Exploded;
  const isFlagged = flags.includes(row * board[0].length + column);
  const isMine = cell.count === -1;
  // On a loss, reveal every mine the player hadn't already flagged so they can
  // see where the bombs were.
  const isRevealedMine =
    gameState === GameState.Lost && isMine && !isFlagged && !isExploded;

  function handleContextMenuClick(e: MouseEvent<HTMLButtonElement>): void {
    e.preventDefault();

    if (isRevealed || isGameOver) {
      return;
    }

    const allMinesFlagged = flag(row, column);

    if (allMinesFlagged) {
      // TODO: Reveal the rest of the unrevealed.
      setGameWon();
    }
  }

  function handleOnClick(): void {
    if (isFlagged || isRevealed || isGameOver) {
      return;
    }

    if (cell.count >= 0) {
      const allRevealed = reveal(row, column);

      if (gameState === GameState.Inactive) {
        startGame();
      }

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
  const isRevealedMineClassName = isRevealedMine ? "revealed mine" : "";
  const isFlaggedClassName = isFlagged ? "flagged" : "";

  return (
    <button
      onClick={handleOnClick}
      onContextMenu={handleContextMenuClick}
      className={`cell ${isRevealedClassName} ${isExplodedClassName} ${isRevealedMineClassName} ${isFlaggedClassName}`}
    >
      {(isExploded || isRevealedMine) && <FontAwesomeIcon icon={faBomb} />}
      {isFlagged && <FontAwesomeIcon icon={faFlagCheckered} />}
      {isRevealed && cell.count > 0 ? cell.count : ""}
    </button>
  );
}
