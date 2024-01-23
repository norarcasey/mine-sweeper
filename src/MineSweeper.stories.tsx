import type { Meta, StoryObj } from "@storybook/react";

import MineSweeper from "./MineSweeper";

//👇 This default export determines where your story goes in the story list
const meta: Meta<typeof MineSweeper> = {
  component: MineSweeper,
};

export default meta;
type Story = StoryObj<typeof MineSweeper>;

export const App: Story = {
  args: {
    //👇 The args you need here will depend on your component
  },
};
