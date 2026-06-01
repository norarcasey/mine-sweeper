import React, { useEffect, useState } from "react";
import {
  faSmile,
  faFaceFrown,
  faGrinHearts,
} from "@fortawesome/free-solid-svg-icons";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

import { useBoardContext } from "../context/BoardContext";
import { useScoreboardContext, GameState } from "../context/ScoreboardContext";
import { Timer } from "./Timer";
import { formatCounter } from "./formatCounter";

export function Scoreboard(): React.ReactElement {
  const { reset, flags, mineCount } = useBoardContext();
  const { gameState, resetGameState } = useScoreboardContext();
  const isGameLost = gameState === GameState.Lost;
  const isGameWon = gameState === GameState.Won;
  const [timer, setTimer] = useState(0);

  const minesRemaining = mineCount - flags.length;

  useEffect(() => {
    // Only run the clock while the game is active; this avoids a re-render
    // every second when idle and freezes the timer on win/loss.
    if (gameState !== GameState.Active) {
      return;
    }

    // Resume from the current elapsed time (0 on a fresh game).
    const start = Date.now() - timer;
    const ticks = setInterval(() => setTimer(Date.now() - start), 1000);

    return () => clearInterval(ticks);
    // `timer` is read only to resume on the active transition, not to retick.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [gameState]);

  return (
    <div className="scoreboard">
      <div className="mine-count">
        <span className="visually-hidden">
          Mines remaining: {minesRemaining}
        </span>
        <span aria-hidden="true">{formatCounter(minesRemaining)}</span>
      </div>
      <div className="reset-container">
        <button
          type="button"
          className="reset-button"
          aria-label="New game"
          onClick={() => {
            reset();
            resetGameState();
            setTimer(0);
          }}
        >
          <FontAwesomeIcon
            icon={isGameLost ? faFaceFrown : isGameWon ? faGrinHearts : faSmile}
            size="2x"
            color="yellow"
          />
        </button>
      </div>
      <Timer timer={timer} />
      <div className="visually-hidden" role="status">
        {isGameWon ? "You won!" : isGameLost ? "You lost!" : ""}
      </div>
    </div>
  );
}
