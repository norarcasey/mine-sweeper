import React from "react";

import { BoardProvider, Difficulty } from "./context/BoardContext";
import { GameBoard } from "./components/GameBoard";
import { Scoreboard } from "./components/Scoreboard";
import { ScoreboardProvider } from "./context/ScoreboardContext";

import "./App.css";

function App(): React.ReactElement {
  // TODO: allow user to set difficulty
  // TODO: Add a scoreboard, timer, and reset

  return (
    <div className="game">
      <BoardProvider difficulty={Difficulty.Expert}>
        <ScoreboardProvider>
          <Scoreboard />
          <GameBoard />
        </ScoreboardProvider>
      </BoardProvider>
    </div>
  );
}

export default App;
