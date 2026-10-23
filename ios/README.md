# Mine Sweeper for iPhone

A native SwiftUI app over `MineSweeperKit`, the Swift copy of the component's rules. The app
only draws the game and handles gestures: every rule is `MineSweeperKit`'s, and a rule change
is a change to the TypeScript copy as well (see the repo's `CLAUDE.md`).

```
ios/
  MineSweeper.xcodeproj   the app, its unit tests and its UI tests (scheme MineSweeper)
  MineSweeper/            the app
  MineSweeperTests/       unit tests: counter, timer, VoiceOver labels, layout, the model
  MineSweeperUITests/     a win and a loss on a seeded board
  MineSweeperKit/         the rules, a Swift package (its own README)
  scripts/render-icon.swift  draws the app icon
  test.sh                 gate | all
```

Open `ios/MineSweeper.xcodeproj` in Xcode 26 and run the **MineSweeper** scheme. The project
uses folder-synchronized groups, so a file added to one of the three folders joins its target
without editing the project.

## Running it on a phone

The project is signed automatically, by team `6W9DVVF8CY`, as `club.nora.mine-sweeper`. Plug
the phone in (with Developer Mode on, under Settings › Privacy & Security), pick it as the run
destination in Xcode and press Run.

## How it plays

- **Tap** reveals. Tapping a revealed number **chords**: when its flags match its number, its
  other neighbours open.
- **Long-press** flags or unflags. A long-press on a revealed number chords, as a right-click
  does in the component.
- The **Flag** toggle under the picker makes a tap flag or unflag a hidden cell instead of
  revealing it, so flagging a mine never trips it. A tap on a revealed number still chords, and
  a long-press still flags. Every game starts with Flag off, from the face or the picker. It is
  there because a long-press cut short is a tap, and a tap on the mine being flagged ends the
  game. It is presentation only, so the component has no equivalent.
- The **face** starts a new game. The **picker** changes difficulty and starts a new game, and
  the choice is kept between launches.
- **Haptics:** a tap on each flag, an error on a loss, a success on a win.
- **VoiceOver:** each cell reads as the component's `aria-label` does ("Row 3, column 5,
  2 adjacent mines"), activates to reveal, and has a Flag/Unflag action. The game announces
  "You won!" or "You lost!".

### Expert on a phone

Expert is 16 rows × 30 columns. When the board is wider than tall and the screen is taller than
wide, the app **turns the board on its side**, so a phone held upright shows 30 rows of 16. Cells
are sized to fit the width (at most 44pt), so only the extra height scrolls, and a **pinch
zooms** from 1× to 3× when the cells are too small to hit (about 22pt on a 6.1" phone). Turning
the board across its diagonal keeps every cell's neighbours, so it is the same game: only the
picture differs, which `CLAUDE.md` allows. In landscape, Expert is drawn as it is.

### On its side

Upright, the picker, the Flag toggle and the scoreboard sit above the board. Turned on its side,
the phone keeps them on the edge that was its top, as a column beside the board with the text
upright: on the left when the phone is turned anticlockwise, on the right when clockwise. The
board then has the whole height, and every board that is not turned fits whole, both ways, so
landscape shows all of it without scrolling. For Expert that means cells of about 13pt on a 6.3"
phone; a pinch zooms them as it does upright. The size classes say the phone is on its side but
not which way, so `InterfaceOrientationReader` watches the window scene's orientation.

The other options were a 2-D scrolling grid at a fixed size, which means panning across 30
columns to play, and zoom alone, which starts with 12pt cells. Turning the board leaves only one
direction to scroll and keeps the cells as large as the width allows.

## Tests

```bash
ios/test.sh gate   # swift test for the Kit, then the app's unit tests (what CI runs)
ios/test.sh all    # and the UI tests (what `yarn verify` runs)
```

The UI tests launch the app with `-seed 7`. A Debug build lays every game's mines from that
seed with the Kit's `SeededGenerator`. The test replays the same `Game` with the same seed, so
it knows where the mines are without the app telling it.

## The icon

```bash
swift ios/scripts/render-icon.swift ios/MineSweeper/Assets.xcassets/AppIcon.appiconset/AppIcon.png
```

1024×1024 and opaque, because App Store Connect refuses an icon with an alpha channel.
