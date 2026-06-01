import type { Meta, StoryObj } from "@storybook/react";

import MineSweeper from "./MineSweeper";
import { Difficulty } from "./context/BoardContext";

//👇 This default export determines where your story goes in the story list
const meta: Meta<typeof MineSweeper> = {
  component: MineSweeper,
};

export default meta;
type Story = StoryObj<typeof MineSweeper>;

export const Beginner: Story = {
  args: {
    difficulty: Difficulty.Beginner,
  },
};

export const Intermediate: Story = {
  args: {
    difficulty: Difficulty.Intermediate,
  },
};

export const Expert: Story = {
  args: {
    difficulty: Difficulty.Expert,
  },
};
