import React from "react";
import { faSmile, faFaceFrown } from "@fortawesome/free-solid-svg-icons";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

import { useBoardContext } from "../context/BoardContext";
import { useScoreboardContext, GameState } from "../context/ScoreboardContext";

export function Scoreboard(): React.ReactElement {
  const { reset } = useBoardContext();
  const { gameState, resetGameState, score } = useScoreboardContext();
  const isGameLost = gameState === GameState.Lost;

  return (
    <div className="scoreboard">
      <div className="mine-count">{score}</div>
      <div className="reset-container">
        <button
          className="reset-button"
          onClick={() => {
            reset();
            resetGameState();
          }}
        >
          <FontAwesomeIcon
            icon={isGameLost ? faFaceFrown : faSmile}
            size="2x"
            color="yellow"
          />
        </button>
      </div>
      <div className="timer-display">00:00</div>
    </div>
  );
}
