# CLAUDE.md — Mine Sweeper

Context for Claude Code. Read this first. It says what the repo holds, the one rule that
spans both halves of it, and how each half ships.

Work items live in Linora as app **MINE** (`.linora-app`). Every commit carries a
`Runway: MINE-<n>` trailer, or `Runway: none`.

## What this is

Classic Minesweeper, in two halves that share one set of rules.

1. **`@norarcasey/mine-sweeper`**: an embeddable React + TypeScript component on npm
   (`src/`, Storybook for development, Vitest for tests). This is the original repo, versions
   0.x–1.0.2, released through GitHub Releases.
2. **An iPhone app** (planned in `ios/`): a **native SwiftUI rewrite**, not a web view around
   the component. Nora decided this on 19 Oct 2026 (`LIN/LIN-67`). The app exists for two
   reasons: to be a real game on her phone, and to let her try out her new Apple Developer team
   and the App Store review process. The tickets: MINE-2 (rules in Swift), MINE-3 (the
   app), MINE-4 (TestFlight), MINE-5 (App Store review).

The repo is **public**, so signing keys, certificates, App Store Connect API keys and
provisioning profiles never go into it.

## Invariant: the rules live twice, and they are the same rules

Because the app is a rewrite, the game logic exists in TypeScript and again in Swift. Nothing
shares code across the two, so the only thing that keeps them the same game is this rule:

**The TypeScript copy is the reference.** It lives in `src/context/BoardContext/`.
`helpers.ts` holds board building, safe cells and win checks. `BoardContext.tsx` holds reveal,
flood fill, flagging and chording. The Swift copy is `ios/MineSweeperKit`: `Rules.swift`
matches `helpers.ts`, and `Game.swift` matches `BoardContext.tsx` plus the move guards in
`Cell.tsx`. Its README maps each name across the two copies.

- **Board sizes.** Beginner 9×9 with 10 mines, Intermediate 16×16 with 40, and Expert 16 rows
  × 30 columns with 99 (`getBoardSize`, `Difficulty`).
- **The first reveal is safe.** Mines are placed only on the first reveal, never on the
  revealed cell or its on-board neighbours (`getSafeCellIds`), so the first reveal always
  opens a region.
- **Reveal flood-fills zeros** and skips flagged cells.
- **There are two ways to win.** You win by revealing every non-mine cell (`isRevealWin`), or by
  flagging exactly the mines: all of them and nothing else (`isFlagWin`). Revealing a mine
  loses.
- **Chording.** Tap a revealed number whose flag count matches it, and its un-flagged
  neighbours are revealed (1.0.0, `feat/chord-reveal`).

**A change to one copy is a change to both**, in the same ticket. The Swift tests (MINE-2) mirror
the cases in `helpers.test.ts` and the board-behaviour cases in `MineSweeper.test.tsx`. Each Swift
case names the TS test it mirrors. A new rule case is added to both suites.

Only the presentation may differ. The app can lay out Expert differently, use long-press to
flag, or add haptics. The component's in-game difficulty selector is **on hold** (the `TODO`
in `MineSweeper.tsx`, decided 2 Jun 2026), but the app has a picker from day one (MINE-3).
The hold applies to the component only.

## Develop

`yarn` is not on the PATH here. Run it through corepack:

```bash
corepack yarn install --frozen-lockfile
corepack yarn storybook   # develop the component on :6006
corepack yarn test        # Vitest
```

**Verify**, the same steps CI runs (`.github/workflows/ci.yml`):

```bash
corepack yarn lint && corepack yarn typecheck && corepack yarn test && corepack yarn ts-build && STORYBOOK_DISABLE_TELEMETRY=1 corepack yarn build-storybook
(cd ios/MineSweeperKit && swift test)
```

There is no end-to-end suite. The Swift rules (`ios/MineSweeperKit`, MINE-2) run locally
only: CI runs on Ubuntu and has no Swift job yet. Once the app exists (MINE-3), verify also
runs its `xcodebuild test`.

## Ship it

The four steps from `~/src/linora/docs/ship-it.md`, with this repo's commands.

**Rebase onto main, with no pull request** (decided in MINE-1, 19 Oct 2026). PRs #1–#19 came
from before Linora. Now the repo ends a ticket the way every other repo does. `main` still has
branch protection requiring a PR and both CI checks. It does not apply to admins
(`enforce_admins: false`), so Nora's push to `main` goes through and GitHub notes the bypass.
The checks still run on the push, and local verify has already run the same steps. The
protection was left as it is because changing it is an access change.

1. **Merge to main.** `git fetch origin && git rebase origin/main`, then fast-forward.
2. **Verify.** Run the verify line above on the rebased commit.
3. **Push.** `git push origin HEAD:main`.
4. **Deploy:**
   - **Component, ordinary change:** nothing deploys. Watch CI on the pushed commit to the end
     (`gh run watch --exit-status`). The change reaches npm with the next release.
   - **Component release** (publishes to npm, so **ask Nora for a Shipit first**):
     1. Add a `## [X.Y.Z] - <date>` section to `CHANGELOG.md` (Keep a Changelog) and the
        compare link at the bottom. Commit it as `docs: changelog for X.Y.Z`.
     2. Bump `package.json` only, in a commit whose message is just `X.Y.Z`. Tag it `vX.Y.Z`
        and push the tag.
     3. Publish the GitHub Release for the tag with `gh release create`. **Publishing the
        release is the npm publish.** `publish.yml` publishes through npm Trusted Publishing
        (OIDC, no token, provenance attached), refuses a tag that doesn't match `package.json`,
        and skips a version already on the registry. Watch that run to the end.
        Release body style: a one-sentence lead-in, then `## Added` / `## Changed` /
        `## Internal`, with no version heading, ending in
        `**Full changelog:** https://github.com/norarcasey/mine-sweeper/compare/vPREV...vX.Y.Z`.
   - **iOS app:** ships through TestFlight and then the App Store. Both publish to Nora's
     team, so **every upload and every submission needs a Shipit**. MINE-4 writes the exact
     archive and upload commands here once the first build has gone up. Until then, there
     is no iOS ship.

The repo has no project hooks, so no main-checkout fast-forward is needed.
