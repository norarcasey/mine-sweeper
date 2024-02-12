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

export function Scoreboard(): React.ReactElement {
  const { reset } = useBoardContext();
  const { gameState, resetGameState, score } = useScoreboardContext();
  const isGameLost = gameState === GameState.Lost;
  const isGameWon = gameState === GameState.Won;
  const [startTime, setStartTime] = useState(Date.now());
  const [timer, setTimer] = useState(0);

  useEffect(() => {
    const ticks = setInterval(() => {
      if (gameState === GameState.Inactive) {
        setStartTime(Date.now());
      }
      if (gameState === GameState.Active) {
        setTimer(Date.now() - startTime);
      }
    }, 1000);

    return () => {
      clearInterval(ticks);
    };
  }, [startTime, gameState]);

  return (
    <div className="scoreboard">
      <div className="mine-count">{score}</div>
      <div className="reset-container">
        <button
          className="reset-button"
          onClick={() => {
            reset();
            resetGameState();
            setStartTime(Date.now());
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
    </div>
  );
}
