import React, { MouseEvent } from "react";

export function Cell({ cell }: { cell: number }): React.ReactElement {
  function handleContextMenuClick(e: MouseEvent<HTMLButtonElement>): void {
    e.preventDefault();

    e.currentTarget.classList.toggle("fa-flag-checkered");
    e.currentTarget.classList.toggle("fa-solid");
  }

  function handleOnClick(e: MouseEvent<HTMLButtonElement>, cell: number): void {
    if (cell === 0) {
      e.currentTarget.classList.toggle("revealed");
      // check which other spots to show and how many bombs to reveal
    }

    if (cell === 1) {
      e.currentTarget.classList.toggle("revealed");
      e.currentTarget.classList.toggle("fa-solid");
      e.currentTarget.classList.toggle("fa-bomb");
    }
  }

  return (
    <button
      onClick={(e) => handleOnClick(e, cell)}
      onContextMenu={handleContextMenuClick}
      className={`cell`}
    ></button>
  );
}
