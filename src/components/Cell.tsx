import React, { KeyboardEvent, MouseEvent } from "react";

import { CellData, CellType, useBoardContext } from "../context/BoardContext/";
import { useScoreboardContext, GameState } from "../context/ScoreboardContext";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { faBomb, faFlagCheckered } from "@fortawesome/free-solid-svg-icons";

interface CellProps {
  cell: CellData;
  column: number;
  row: number;
  tabIndex: number;
}

export function Cell({
  cell,
  row,
  column,
  tabIndex,
}: CellProps): React.ReactElement {
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

  function toggleFlag(): void {
    if (isRevealed || isGameOver) {
      return;
    }

    const allMinesFlagged = flag(row, column);

    if (allMinesFlagged) {
      // TODO: Reveal the rest of the unrevealed.
      setGameWon();
    }
  }

  function handleContextMenuClick(e: MouseEvent<HTMLButtonElement>): void {
    e.preventDefault();
    toggleFlag();
  }

  // Reveal is keyboard-accessible by default (Enter/Space activate the button);
  // "F" provides a keyboard equivalent for the right-click flag.
  function handleKeyDown(e: KeyboardEvent<HTMLButtonElement>): void {
    if (e.key === "f" || e.key === "F") {
      e.preventDefault();
      toggleFlag();
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

  const describeState = (): string => {
    if (isFlagged) return "flagged";
    if (isExploded) return "mine, exploded";
    if (isRevealedMine) return "mine";
    if (isRevealed) {
      if (cell.count === 0) return "empty";
      return `${cell.count} adjacent ${cell.count === 1 ? "mine" : "mines"}`;
    }
    return "hidden";
  };
  const ariaLabel = `Row ${row + 1}, column ${column + 1}, ${describeState()}`;

  return (
    <button
      type="button"
      role="gridcell"
      tabIndex={tabIndex}
      aria-label={ariaLabel}
      aria-keyshortcuts="F"
      onClick={handleOnClick}
      onContextMenu={handleContextMenuClick}
      onKeyDown={handleKeyDown}
      className={`cell ${isRevealedClassName} ${isExplodedClassName} ${isRevealedMineClassName} ${isFlaggedClassName}`}
    >
      {(isExploded || isRevealedMine) && <FontAwesomeIcon icon={faBomb} />}
      {isFlagged && <FontAwesomeIcon icon={faFlagCheckered} />}
      {isRevealed && cell.count > 0 ? cell.count : ""}
    </button>
  );
}
