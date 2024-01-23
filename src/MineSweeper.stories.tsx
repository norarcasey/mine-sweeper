import type { Meta, StoryObj } from "@storybook/react";

import MineSweeper from "./MineSweeper";
import { Difficulty } from "./context/BoardContext";

//👇 This default export determines where your story goes in the story list
const meta: Meta<typeof MineSweeper> = {
  component: MineSweeper,
};

export default meta;
type Story = StoryObj<typeof MineSweeper>;

export const App: Story = {
  args: {
    difficulty: Difficulty.Expert,
    //👇 The args you need here will depend on your component
  },
};
