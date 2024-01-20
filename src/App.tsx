import React from "react";
import { Difficulty, useBoard } from "./hooks/useBoard";

function App(): React.ReactElement {
  const { board } = useBoard(Difficulty.Expert);

  return (
    <div style={{ display: "flex", flexDirection: "column", margin: "20px" }}>
      {board.map((row, index) => (
        <div
          key={`row-${index}`}
          style={{
            display: "flex",
          }}
        >
          {row.map((cell, index) => (
            <div
              key={`cell-${index}`}
              style={{
                height: "30px",
                width: "30px",
                backgroundColor: "#bdbdbd",
                border: "ridge 4px darkgray",
                borderTop: "ridge 4px #fff",
                borderLeft: "ridge 4px #fff",
                cursor: "pointer",
              }}
            >
              <div>{cell}</div>
            </div>
          ))}
        </div>
      ))}
    </div>
  );
}

export default App;
