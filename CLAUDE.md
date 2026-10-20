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
2. **An iPhone app** (`ios/`, see `ios/README.md`): a **native SwiftUI rewrite**, not a web view around
   the component. Nora decided this on 19 Oct 2026 (`LIN/LIN-67`). The app exists for two
   reasons: to be a real game on her phone, and to let her try out her new Apple Developer team
   and the App Store review process. The tickets: MINE-2 (rules in Swift), MINE-3 (the
   app), MINE-4 (TestFlight), MINE-5 (App Store review).

The repo is **public**, so signing keys, certificates, App Store Connect API keys and
provisioning profiles never go into it. The team id (`6W9DVVF8CY`) and the bundle id
(`club.nora.mine-sweeper`) are not secrets and are committed in the Xcode project; both come
from the "Apple apps" section of Nora's global `CLAUDE.md`.

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
corepack yarn gate        # lint, typecheck, Vitest: the command CI runs
corepack yarn verify      # before pushing
```

`yarn gate` is lint, typecheck and Vitest, in CI's order, and CI's `Gate` step runs the
same command. There is no Prettier here, so there is no `format:check`. `yarn verify` is the
gate, then the library build, the Storybook build and `ios/test.sh all`.

`ios/test.sh` is the iPhone half's one command. `gate` runs `swift test` for
`ios/MineSweeperKit`, then the app's unit tests through `xcodebuild test` on the first
available iPhone simulator. CI's macOS job (`iOS gate`) runs exactly that. `all` adds the UI
tests, a win and a loss on a seeded board, and only `yarn verify` runs it. The UI tests are this
repo's slow suite, and macOS runner minutes cost ten times Linux ones, so they stay out of CI
(the `ci` skill, `LIN/LIN-20`). There is no browser end-to-end suite.

## Working style

- **The plan is in Linora**, as app `MINE` (`.linora-app`; the `runway` skill). Take work with
  `get_next_ticket` → `claim_ticket`, log findings with `log_progress`, and finish with
  `complete_run` and a summary of what was built, what was found and what the plan got wrong.
  Work found on the way is filed with `create_tickets`, not done unasked. Never move a ticket
  to done: Nora does, after review.
- **Every commit carries a `Runway:` trailer**: the ticket key, or `none`. The global hook
  checks it against Linora and refuses a commit without one.
- Commit attribution comes from the harness's own instructions. Never copy a model name
  from an old commit or a template.
- `corepack yarn gate` while working, and `corepack yarn verify` before pushing.

## More than one session at once

Each session that changes code works in its own git worktree, never in a tree another
session is editing, and never in the main checkout. Use `EnterWorktree` named for the ticket
(`mine-9`), `claude --worktree <name>`, or a subagent's `isolation: "worktree"`. If a
worktree for the ticket already exists, enter it by path rather than making a second one.

- **They nest under `.claude/worktrees/`, and nothing here walks into them.** Git reads
  `.gitignore`, and ESLint ignores the directory by name. Vitest only collects tests under
  the root it runs in. A tool added later that walks `.` needs the same.
- **A new worktree does not install itself.** This repo has no SessionStart hook, so run
  `corepack yarn install --frozen-lockfile` after entering one.
- **A new worktree starts from `origin/main`**, Claude Code's default, not from the local
  branch. Push `main` before starting one that needs what just merged.
- **Two Storybooks can run at once.** When 6006 is taken, Storybook asks to use the next
  free port.
- **Merging** is Ship it, below. Two sessions finishing two tickets do not conflict: the
  tickets are in Linora, and a claim there is one transaction.

## Ship it

The four steps from `~/src/linora/docs/ship-it.md`, with this repo's commands.

**Rebase onto main, with no pull request** (decided in MINE-1, 19 Oct 2026). PRs #1–#19 came
from before Linora. Now the repo ends a ticket the way every other repo does. `main` still has
branch protection requiring a PR and both CI checks. It does not apply to admins
(`enforce_admins: false`), so Nora's push to `main` goes through and GitHub notes the bypass.
The checks still run on the push, and local verify has already run the same steps. The
protection was left as it is because changing it is an access change.

1. **Merge to main.** `git fetch origin && git rebase origin/main`, then fast-forward.
2. **Verify.** `corepack yarn verify` on the rebased commit.
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
     team, so **every upload and every submission needs a Shipit**. Ship the commit to
     `main` first (steps 1–3), then, from a clean tree on that commit:
     1. `ios/testflight.sh upload`. It archives a Release build and exports it with
        `destination: upload`. The build number is `git rev-list --count HEAD`, so a new
        commit on `main` gives a new number with no bump commit. The version is
        `MARKETING_VERSION` in the project. The script refuses a dirty tree or a HEAD not
        on `origin/main`. `ios/testflight.sh export` does the same without uploading, and
        leaves the `.ipa` in `ios/build/export/`.
     2. Wait for App Store Connect to finish processing (TestFlight › iOS builds). Internal
        testers on the team get it in the TestFlight app, and no review is needed.
     - **Signing is automatic** (decided in MINE-4). It runs through the Apple ID Xcode
       is signed in with (Xcode › Settings › Accounts), and `-allowProvisioningUpdates`
       fetches the profiles and the cloud-managed Apple Distribution certificate. There is
       no App Store Connect API key, and CI does not upload. The project has one
       maintainer, macOS minutes cost ten times Linux ones, and a key would be a new
       secret in GitHub for nothing this laptop command can't do.
     - **By hand, once, before the first upload** (MINE-4): Nora creates the App Store
       Connect app record (Apps › + › New App: iOS, bundle id `club.nora.mine-sweeper`,
       a SKU, English (U.S.), and a name, which is public and must be unique on the
       store), adds herself to an internal testing group, and installs TestFlight on her
       phone. Without the record, the export fails with "Error Downloading App
       Information": App Store Connect returns no app for the bundle id. Export
       compliance is answered in the project (`ITSAppUsesNonExemptEncryption = NO`), so
       uploads don't stop to ask.

The repo has no project hooks, so no main-checkout fast-forward is needed.
