import React from "react";

import { Difficulty, useBoard } from "./hooks/useBoard";

import "./App.css";
import { Cell } from "./components/Cell";

function App(): React.ReactElement {
  const { board } = useBoard(Difficulty.Intermediate);

  return (
    <div className="board">
      {board.map((row, index) => (
        <div key={`row-${index}`} className="row">
          {row.map((cell, index) => (
            <Cell key={`cell-${index}`} cell={cell} />
          ))}
        </div>
      ))}
    </div>
  );
}

export default App;
