import React from "react";

import { BoardProvider, Difficulty } from "./context/BoardContext";
import { GameBoard } from "./components/GameBoard";
import { Scoreboard } from "./components/Scoreboard";
import { ScoreboardProvider } from "./context/ScoreboardContext";

import "./MineSweeper.css";

function MineSweeper({
  difficulty,
}: {
  difficulty: Difficulty;
}): React.ReactElement {
  // TODO: allow user to set difficulty
  // TODO: Add a scoreboard, timer

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

export default MineSweeper;
