/**
 * Formats the mines-remaining counter as a fixed-width string, mirroring the
 * classic Minesweeper LED display. Non-negative values are zero-padded to
 * three digits ("009"); negative values (over-flagging) show a sign and two
 * digits ("-09"), since a naive padStart would produce "0-9".
 */
export function formatCounter(value: number): string {
  if (value < 0) {
    return "-" + Math.abs(value).toString().padStart(2, "0");
  }
  return value.toString().padStart(3, "0");
}
