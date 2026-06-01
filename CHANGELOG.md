# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **Accessibility.** Every cell now has a descriptive `aria-label` (its position
  and state), and flagging has a keyboard equivalent — the `F` key — in addition
  to right-click (reveal was already keyboard-accessible via Enter/Space). The
  board region and the reset button are labelled, the mine counter and timer
  expose screen-reader text, and wins and losses are announced through a live
  region.
- **Keyboard grid navigation.** The board is an ARIA grid with a roving
  tabindex: arrow keys move between cells, Home/End jump to the row ends, and
  Ctrl+Home/Ctrl+End jump to the grid corners, with a visible focus outline.

### Internal

- Refactored the board context for clarity and safety: the `flags` array is now
  the single source of truth for flagged cells (the `Flagged` cell type was
  removed), board updates deep-clone cells instead of mutating shared state, and
  `flag()` is a single toggle. Added a Testing Library + Vitest
  characterization/integration suite and `@vitest/coverage-v8`; board-context
  branch coverage rose from ~83% to ~97%. No change to the published package's
  behavior or output.

## [0.5.1] - 2026-06-01

### Fixed

- **Losing now reveals every mine** (except ones you had already flagged), so
  you can see where the bombs were. Previously only the clicked mine was shown.
- **Changing the `difficulty` prop resets the game to a correctly-sized board.**
  Previously the board kept its original dimensions while the mine count and
  newly placed mines used the new difficulty, leaving them out of sync.

### Internal

- Migrated off the deprecated Create React App toolchain. Tests now run on
  **Vitest** (was `react-scripts test` / Jest 27), Storybook runs on the
  **Vite builder** at **Storybook 10** (was webpack 5 + the CRA preset), and
  `react-scripts` and its webpack/CRA remnants are removed. Added a flat-config
  **ESLint** setup (typescript-eslint + react-hooks), bumped TypeScript to 5
  with `moduleResolution: "bundler"`, and CI now lints, type-checks, tests, and
  builds both the library and Storybook on Node 20 and 22. No change to the
  published package's runtime dependencies or output.

## [0.5.0] - 2026-06-01

### Changed

- **Dependency hygiene.** `react` and `react-dom` are now `peerDependencies`
  (a consuming app provides its single copy), and the build/test tooling
  (`react-scripts`, `typescript`, `@testing-library/*`, `@types/*`,
  `web-vitals`) moved from `dependencies` to `devDependencies`. Installing the
  package no longer drags the entire Create React App toolchain into a
  consumer's `node_modules`; `dependencies` is now just the three FontAwesome
  packages actually imported at runtime.
- Bumped FontAwesome to `^6.7.2` / `react-fontawesome` to `^0.2.6` (the safe,
  backward-compatible upgrades).

### Fixed

- **Clean installs now work on Node 22.** Pinned `strip-ansi` to `^6` via
  `resolutions` so the Create React App / Jest 27 reporter stack resolves the
  CommonJS build instead of the ESM-only `strip-ansi@7`, which broke
  `react-scripts test` on a fresh install. CI now runs on Node 20 and 22.

## [0.4.1] - 2026-06-01

### Fixed

- **The counter now shows mines remaining and counts down.** It previously
  counted flags up from `000`; it now starts at the mine total and decrements
  as you flag, going negative when over-flagging (classic Minesweeper). Flag
  tracking is derived from the board's flag set rather than a separate
  hand-maintained counter, removing a stale-closure update bug. Winning by
  revealing the last safe cell now also flags the mines in the counter, so it
  reads `000` on every win.
- **The timer no longer re-renders every second while idle.** The clock now
  ticks only while the game is active and freezes on win or loss.

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

[0.5.1]: https://github.com/norarcasey/mine-sweeper/compare/v0.5.0...v0.5.1
[0.5.0]: https://github.com/norarcasey/mine-sweeper/compare/v0.4.1...v0.5.0
[0.4.1]: https://github.com/norarcasey/mine-sweeper/compare/v0.4.0...v0.4.1
[0.4.0]: https://github.com/norarcasey/mine-sweeper/compare/v0.3.1...v0.4.0
[0.3.1]: https://github.com/norarcasey/mine-sweeper/compare/v0.3.0...v0.3.1
