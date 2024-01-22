import React, { createContext, useContext, useState } from "react";

export enum GameState {
  Lost,
  Won,
  Active,
  Inactive,
}

interface UseScoreBoardContext {
  gameState: GameState;
  setGameLost: () => void;
  resetGameState: () => void;
}

const ScoreboardContext = createContext<UseScoreBoardContext | null>(null);

export function ScoreboardProvider({
  children,
}: {
  children: React.ReactNode;
}): React.ReactElement {
  const [gameState, setGameState] = useState(GameState.Inactive);

  function setGameLost() {
    setGameState(GameState.Lost);
  }

  function resetGameState() {
    setGameState(GameState.Inactive);
  }

  return (
    <ScoreboardContext.Provider
      value={{ gameState, setGameLost, resetGameState }}
    >
      {children}
    </ScoreboardContext.Provider>
  );
}

export function useScoreboardContext() {
  const scoreboardContext = useContext(ScoreboardContext);

  if (!scoreboardContext) {
    throw new Error(
      "Scoreboard Context not available, please check that the provider has been added to the tree."
    );
  }

  return scoreboardContext;
}
