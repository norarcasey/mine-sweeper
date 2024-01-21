import React from "react";

import { useBoardContext } from "../context/BoardContext";
import { Cell } from "./Cell";

export function GameBoard(): React.ReactElement {
  const { board } = useBoardContext();

  return (
    <div className="board">
      {board.map((row, rowIndex) => (
        <div key={`row-${rowIndex}`} className="row">
          {row.map((cell, cellIndex) => (
            <Cell
              key={`cell-${cellIndex}`}
              cell={cell}
              row={rowIndex}
              column={cellIndex}
            />
          ))}
        </div>
      ))}
    </div>
  );
}
