# MineSweeperKit

The game rules for the iPhone app, in Swift. Just the engine: the board, the moves and the
rules, as a value type, with no UI. The app (MINE-3) draws `Game` and calls its moves.

```bash
cd ios/MineSweeperKit
swift test
```

## The TypeScript copy is the reference

This package is a port of `src/context/BoardContext/` (`types.ts`, `helpers.ts`,
`BoardContext.tsx`). It also takes in the move guards from `src/components/Cell.tsx` and the
game state from `src/context/ScoreboardContext`. **A change to one copy is a change to both**
(see the repo's `CLAUDE.md`).

| TypeScript                               | Swift                                  |
| ---------------------------------------- | -------------------------------------- |
| `CellType`, `CellData`, `Difficulty`     | `CellType`, `Cell`, `Difficulty`       |
| `getAdjacentCoordinates`                 | `Rules.adjacentCoordinates`            |
| `getSafeCellIds`                         | `Rules.safeCellIDs`                    |
| `getEmptyBoard`                          | `Rules.emptyBoard`                     |
| `getInitialBoard`                        | `Rules.initialBoard(_:safeIDs:using:)` |
| (mine counting inside `getInitialBoard`) | `Rules.board(rows:columns:mineIDs:)`   |
| `isFlagWin`, `isRevealWin`               | `Rules.isFlagWin`, `Rules.isRevealWin` |
| `reveal` + `Cell.handleOnClick`          | `Game.reveal(row:column:using:)`       |
| `flag` + `Cell.toggleFlag`               | `Game.toggleFlag(row:column:)`         |
| `chord` + `Cell.chordCell`               | `Game.chord(row:column:)`              |
| `revealAdjacent` (flood fill)            | `Game.revealAdjacent` (private)        |
| `explode`                                | part of `Game.reveal` on a mine        |
| `reset`                                  | `Game.reset()`                         |
| `GameState`                              | `GameState`                            |
| `Cell.describeState`                     | `Game.appearance(row:column:)`         |

There are three deliberate differences, and none of them changes a rule:

- **Random source.** `initialBoard` and `reveal` take any `RandomNumberGenerator`, so tests
  are deterministic. Mines are drawn from the allowed cells directly, where TS draws any id
  and rejects repeats. Both are uniform over the allowed layouts.
- **Flood fill** is iterative where TS recurses. It reveals the same cells.
- **Activating a revealed number chords** inside `reveal`, as `Cell.handleOnClick` does in
  TS. `toggleFlag` on a revealed cell does nothing. A long-press or right-click that should
  chord calls `chord` directly.

The package builds in Swift 6 language mode (strict concurrency). Every type is `Sendable`,
and there are no force unwraps or casts.

## The case list

Every test's display name is the TS test it mirrors, word for word, and its `@Suite` names
the TS file and `describe`. Parameterised cases run per difficulty × 20 seeds where TS runs
once against `Math.random`.

### `helpers.test.ts` → `RulesTests.swift`

| TS `describe`                                        | TS test                                                            |
| ---------------------------------------------------- | ------------------------------------------------------------------ |
| getAdjacentCoordinates                               | returns the eight surrounding coordinates                          |
|                                                      | never includes the cell itself                                     |
|                                                      | returns out-of-bounds (negative) coordinates at an edge            |
| getInitialBoard (× Beginner, Intermediate, Expert)   | the `cases` table: `[describe.each cases]`                         |
|                                                      | builds a ${rows}x${cols} board                                     |
|                                                      | places exactly ${mineCount} mines                                  |
|                                                      | returns mineIds that are unique, sorted, and in range              |
|                                                      | maps every mineId to a bomb cell                                   |
|                                                      | gives every bomb a count of -1                                     |
|                                                      | sets each non-bomb count to its number of adjacent bombs           |
|                                                      | types non-bomb cells as Empty when count is 0 and Hidden otherwise |
|                                                      | creates independent cell objects (no shared references)            |
| getSafeCellIds                                       | returns the clicked cell plus all eight neighbours mid-board       |
|                                                      | clamps to on-board neighbours at a corner                          |
|                                                      | clamps to on-board neighbours at an edge                           |
| getInitialBoard with safe cells (first-click safety) | never places a mine on a safe id                                   |
|                                                      | still places the full mine count when cells are excluded           |
|                                                      | leaves the clicked cell with count 0 so it opens a region          |
| isFlagWin                                            | wins when the flagged set is exactly the mine set                  |
|                                                      | does not win when a non-mine cell is also flagged (extra flag)     |
|                                                      | does not win when not every mine is flagged                        |
|                                                      | does not win when a flag is on a non-mine instead of a mine        |
|                                                      | does not win with no flags placed                                  |
|                                                      | does not win before any mines exist (empty board)                  |
| isRevealWin                                          | wins when every non-bomb cell is revealed (bombs left hidden)      |
|                                                      | wins regardless of how bombs are typed (exploded or not)           |
|                                                      | does not win while a numbered cell is still hidden                 |
|                                                      | does not win while an empty (count 0) cell is unrevealed           |

Swift only, and not a rule case: `[Swift only] the same seed builds the same board` pins the
injectable random source. That source, `SeededGenerator` (SplitMix64), is public, because the
app's UI tests use it too: they launch the app with a seed and replay the same board.

### `MineSweeper.test.tsx` → `GameTests.swift`

| TS `describe`                  | TS test                                                                                |
| ------------------------------ | -------------------------------------------------------------------------------------- |
| MineSweeper — behavior         | renders a board sized for the difficulty                                               |
|                                | never loses on the first click and opens a region                                      |
|                                | toggles a flag on right-click and updates the counter                                  |
|                                | resets the board, counter, and face                                                    |
|                                | resets to a correctly sized board when difficulty changes                              |
| MineSweeper — outcomes         | loses and reveals every mine when a bomb is clicked                                    |
|                                | wins when every safe cell is revealed                                                  |
|                                | wins when exactly the mines are flagged                                                |
|                                | reveals every safe cell, empty ones included, on a flag win                            |
| MineSweeper — chording         | reveals the un-flagged neighbours of a correctly flagged number                        |
|                                | detonates when chording a number whose flag is misplaced                               |
|                                | does nothing when the surrounding flag count does not match                            |
|                                | chords from a keyboard/left-click activation too                                       |
| MineSweeper — characterization | keeps flags placed before the first reveal                                             |
|                                | does not reveal a flagged cell via the cascade, and a stray flag blocks the reveal-win |
|                                | drives the counter to 000 on a reveal win                                              |
|                                | shows a negative counter when over-flagging without a false win                        |
|                                | treats clicking an already-revealed cell as a no-op                                    |
|                                | restores a flagged numbered cell and a flagged mine when unflagged                     |
| MineSweeper — accessibility    | labels each cell with its position and state                                           |
|                                | labels a revealed numbered cell with its adjacent-mine count                           |
|                                | flags a cell with the F key and reflects it in the label                               |
|                                | announces win and loss in a live region                                                |

These are not mirrored, because they test presentation, which the app does its own way:
"labels the board region and the reset button", and the whole "MineSweeper — keyboard grid
navigation" describe (5 tests).
