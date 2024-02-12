import React, { createContext, useContext, useState } from "react";

export enum GameState {
  Lost,
  Won,
  Active,
  Inactive,
}

interface UseScoreBoardContext {
  gameState: GameState;
  startGame: () => void;
  setGameLost: () => void;
  setGameWon: () => void;
  resetGameState: () => void;
  incrementScore: () => void;
  decrementScore: () => void;
  score: string;
  isGameOver: boolean;
}

const ScoreboardContext = createContext<UseScoreBoardContext | null>(null);

export function ScoreboardProvider({
  children,
}: {
  children: React.ReactNode;
}): React.ReactElement {
  const [gameState, setGameState] = useState(GameState.Inactive);
  const [flagCount, setFlagCount] = useState(0);

  function setGameLost() {
    setGameState(GameState.Lost);
  }

  function resetGameState() {
    setGameState(GameState.Inactive);
    setFlagCount(0);
  }

  function incrementScore(): void {
    setFlagCount(flagCount + 1);
  }

  function decrementScore(): void {
    setFlagCount(flagCount - 1);
  }

  function startGame(): void {
    setGameState(GameState.Active);
  }

  function setGameWon(): void {
    setGameState(GameState.Won);
  }

  const isGameOver =
    gameState === GameState.Lost || gameState === GameState.Won;

  return (
    <ScoreboardContext.Provider
      value={{
        gameState,
        startGame,
        setGameLost,
        setGameWon,
        resetGameState,
        incrementScore,
        decrementScore,
        score: flagCount.toString().padStart(3, "0"),
        isGameOver,
      }}
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
