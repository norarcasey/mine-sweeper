import React from "react";

export function Timer({ timer }: { timer: number }): React.ReactElement {
  const seconds = Math.floor(timer / 1000);
  const minutes = Math.floor(seconds / 60);
  const remainingSeconds = seconds % 60;

  return (
    <div className="timer-display">
      <span className="visually-hidden">
        Time elapsed: {seconds} {seconds === 1 ? "second" : "seconds"}
      </span>
      <span aria-hidden="true">
        {minutes.toString().padStart(2, "0")}:
        {remainingSeconds.toString().padStart(2, "0")}
      </span>
    </div>
  );
}
