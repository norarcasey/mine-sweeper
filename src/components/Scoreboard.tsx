import React from "react";
import { useBoardContext } from "../context/BoardContext";

export function Scoreboard(): React.ReactElement {
  const { reset } = useBoardContext();

  return (
    <div className="scoreboard">
      <div className="mine-count">075</div>
      <button className="reset-button" onClick={reset}>
        reset button
      </button>
      <div className="timer-display">00:00</div>
    </div>
  );
}
