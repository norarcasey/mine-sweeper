# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.4.0] - 2026-06-01

### Added

- **First-click safety.** Mines are now placed on the first reveal instead of
  up front, with the clicked cell and its neighbours guaranteed mine-free. The
  opening click can never lose and always opens a zero-region cascade, matching
  classic Minesweeper. New `getEmptyBoard` and `getSafeCellIds` helpers back
  this, both unit-tested.

### Changed

- The board now starts empty and mine generation accepts a set of "safe" cell
  ids to exclude. No change to the public component API.

### Fixed

- The board is no longer regenerated on every render; the initial board and
  mines now use lazy state initialisers.

## [0.3.1] - 2026-06-01

### Fixed

- **Flag-to-win no longer triggers on extra flags.** Winning by flagging now
  requires flagging _all and only_ the mines; previously, flagging additional
  non-mine cells could still register a win because the comparison stopped
  after the mine count.
- **Reveal-to-win no longer triggers prematurely.** The game now wins only when
  every non-bomb cell is actually revealed; previously, unrevealed empty
  (zero-adjacency) regions could be skipped and falsely count as complete.
- Removed a stray `console.log` that fired on every cell reveal.

### Changed

- Win detection was extracted into pure, unit-tested helpers (`isFlagWin`,
  `isRevealWin`) in the board context. No public API change.

### Added

- Unit test suite covering board generation and both win conditions.

### Internal

- Publishing now builds from a dedicated `tsconfig.build.json` and runs via
  `prepublishOnly`, so test files, Storybook stories, and CRA dev-only files
  (`setupTests`, `reportWebVitals`) are no longer included in the published
  package.

## [0.3.0] - 2024

Earlier releases (0.1.x – 0.3.0) predate this changelog; see the git history
for details. 0.3.0 added winning game states.

[0.4.0]: https://github.com/norarcasey/mine-sweeper/compare/v0.3.1...v0.4.0
[0.3.1]: https://github.com/norarcasey/mine-sweeper/compare/v0.3.0...v0.3.1
