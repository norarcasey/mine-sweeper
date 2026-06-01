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

  return (
    <div className="game">
      {/* key on difficulty remounts the providers with a fresh board when the
          difficulty changes, keeping board size, mine count, and game state in
          sync. */}
      <BoardProvider key={difficulty} difficulty={difficulty}>
        <ScoreboardProvider>
          <Scoreboard />
          <GameBoard />
        </ScoreboardProvider>
      </BoardProvider>
    </div>
  );
}

export default MineSweeper;
