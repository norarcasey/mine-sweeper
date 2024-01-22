import React, { createContext, useContext } from "react";

const ScoreboardContext = createContext({});

export function ScoreboardProvider({
  children,
}: {
  children: React.ReactNode;
}): React.ReactElement {
  return (
    <ScoreboardContext.Provider value={{}}>
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
