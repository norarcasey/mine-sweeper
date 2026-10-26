# The App Store listing

What App Store Connect holds for **Nora's Mine Sweeper** (`club.nora.mine-sweeper`), kept here so
the next version starts from it (MINE-5). App Store Connect is the source of truth: when a field
changes there, change it here too.

- `privacy.md` and `support.md` are the privacy policy and support pages the listing links to.
- The screenshots come from `ios/screenshots.sh`, which writes them to `ios/build/screenshots/`.

## App Information

| Field                         | Value                                                                        |
| ----------------------------- | ---------------------------------------------------------------------------- |
| Name (30)                     | Nora's Mine Sweeper                                                          |
| Subtitle (30)                 | Classic mines, made for iPhone                                               |
| Primary category              | Games                                                                        |
| Subcategories                 | Puzzle, Board                                                                |
| Secondary category            | none                                                                         |
| Content rights                | Contains no third-party content                                              |
| Age rating                    | 4+: every questionnaire answer is None or No (no ads, purchases, chat, web)  |
| Privacy policy URL            | https://github.com/norarcasey/mine-sweeper/blob/main/ios/AppStore/privacy.md |
| App Privacy (nutrition label) | Data Not Collected                                                           |

## Version 1.0

| Field            | Value                                                                        |
| ---------------- | ---------------------------------------------------------------------------- |
| Support URL      | https://github.com/norarcasey/mine-sweeper/blob/main/ios/AppStore/support.md |
| Marketing URL    | none                                                                         |
| Copyright        | 2026 Nora Casey                                                              |
| Screenshots      | iPhone 6.3", 1206 × 2622: `1-beginner` … `5-landscape`, in that order        |
| Release          | Manually release this version                                                |
| Sign-in required | No                                                                           |

### Promotional text (170)

```
Every square drawn from scratch, a Flag switch so flagging never sets off a mine, and an Expert board that turns to fit a phone held upright.
```

### Keywords (100, commas, no spaces)

```
minesweeper,mines,puzzle,logic,classic,retro,flag,grid,deduction,brain,offline,expert
```

### Description (4000)

```
The classic game of mines and numbers, rebuilt for iPhone.

Open squares, read the numbers and flag every mine. Your first tap is always safe, and a zero opens its whole neighbourhood at once.

MADE FOR A PHONE
• Flag switch: turn it on and a tap plants a flag instead of opening the square, so flagging a mine never sets it off. A long-press flags too.
• Expert on a phone: the 16 × 30 board turns on its side, so a phone held upright shows every row as large as the screen allows, with pinch to zoom.
• On its side, the controls move to the edge that was the top of the phone, and the board gets the rest of the screen.
• Chording: tap a number whose flags match it to open the rest of its neighbours.
• Leave the app mid-game and the clock stops and the board is covered until you come back.

THE CLASSIC LOOK, ALL OUR OWN
Raised grey squares, red seven-segment counters and a face that smiles, frowns or falls in love, every piece drawn for this app. Dark mode keeps the same shapes in darker greys.

THREE LEVELS
• Beginner: 9 × 9 with 10 mines
• Intermediate: 16 × 16 with 40 mines
• Expert: 16 × 30 with 99 mines
The app remembers the level you play.

TWO WAYS TO WIN
Open every safe square, or flag exactly the mines and nothing else.

FOR EVERYONE
Full VoiceOver support: every square says its row, column and what it shows, with a Flag action. Haptics mark each flag, a win and a loss.

No ads, no purchases, no accounts, no tracking. It works offline and collects nothing.
```

### App Review Information

| Field            | Value                                        |
| ---------------- | -------------------------------------------- |
| Sign-in required | No                                           |
| Contact          | Nora Casey (phone and email: Nora's, in ASC) |

Notes:

```
A single-player Minesweeper game. No account, no network, no purchases.

To play: tap a square to open it (the first tap is always safe). Long-press a square, or turn on the Flag button under the clock and tap, to flag a mine. Tap a revealed number whose flags match it to open its neighbours. The face starts a new game; the picker at the top changes the difficulty.

On Expert, a phone held upright shows the board turned on its side (30 rows of 16) so the squares stay large enough to tap; pinch to zoom. All artwork, including the counters and the face, is drawn in SwiftUI for this app.
```
