import React from "react";

import { BoardProvider, Difficulty } from "./context/BoardContext";
import { GameBoard } from "./components/GameBoard";

import "./App.css";

function App(): React.ReactElement {
  // TODO: allow user to set difficulty
  // TODO: Add a scoreboard, timer, and reset

  return (
    <BoardProvider difficulty={Difficulty.Expert}>
      <GameBoard />
    </BoardProvider>
  );
}

export default App;
