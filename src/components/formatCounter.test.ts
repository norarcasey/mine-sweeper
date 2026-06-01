import { formatCounter } from "./formatCounter";

describe("formatCounter", () => {
  it("zero-pads non-negative values to three digits", () => {
    expect(formatCounter(0)).toBe("000");
    expect(formatCounter(9)).toBe("009");
    expect(formatCounter(40)).toBe("040");
    expect(formatCounter(99)).toBe("099");
  });

  it("renders negative values with a sign and two digits", () => {
    // Over-flagging drops the counter below zero; a naive padStart would
    // produce "0-1" here.
    expect(formatCounter(-1)).toBe("-01");
    expect(formatCounter(-9)).toBe("-09");
    expect(formatCounter(-10)).toBe("-10");
  });
});
