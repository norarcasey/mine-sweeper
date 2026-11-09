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
| EU trader status (DSA)        | Non-trader, for the whole account (Business, 8 Nov 2026, MINE-27)            |

## Version 1.1

App Store Connect copies every field from the version before, so a new version only changes
what is listed as changed. 1.1 (MINE-26) adds best times: What's New, one line in the
Description, the Notes' item 4, and the won screenshot, which now shows "New best".

| Field            | Value                                                                        |
| ---------------- | ---------------------------------------------------------------------------- |
| Support URL      | https://github.com/norarcasey/mine-sweeper/blob/main/ios/AppStore/support.md |
| Marketing URL    | none                                                                         |
| Copyright        | 2026 Nora Casey                                                              |
| Screenshots      | iPhone 6.3", 1206 × 2622: `1-beginner` … `5-landscape`, in that order        |
| Build            | The 1.1 build from `ios/testflight.sh upload`                                |
| Release          | Manually release this version                                                |
| Sign-in required | No                                                                           |

### What's New in This Version (4000)

```
Best times: the app now keeps your fastest win on each level and shows it under the scoreboard. Beat it and it says "New best". Only the best time is kept, and it stays on your phone.
```

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
The app remembers the level you play, and your best time on each.

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

Notes, which also answer App Review's 2.1 questions (see [Review history](#review-history)):

```
Nora's Mine Sweeper is a single-player Minesweeper game for iPhone. No account, no sign-in, no network, no purchases, no ads.

1. SCREEN RECORDING
Attached to our reply in App Store Connect: recorded on an iPhone running the latest iOS, starting from launching the app. It shows a Beginner game won by opening squares, flagging with long-press and with the Flag switch, chording, a loss, a new game from the face, changing the difficulty, and Expert on its side with pinch to zoom. The app has no account, no user-generated content and no paid content, so the recording has none of those to show.

2. PURPOSE AND AUDIENCE
A classic logic puzzle for anyone who likes Minesweeper and wants to play it on a phone. It is built for touch: a Flag switch so flagging never sets off a mine, an Expert board that turns to fit an upright phone, chording, full VoiceOver support and haptics. Its value is a quick, calm, offline puzzle with no ads or tracking. Rated 4+.

3. HOW TO USE IT
Nothing to set up and no login. Launch the app and a Beginner game is ready.
- Tap a square to open it. The first tap is always safe.
- Long-press a square to flag it, or turn on the Flag button under the clock so a tap flags instead.
- Tap a revealed number whose flags match it to open its other neighbours.
- Win by opening every safe square, or by flagging exactly the mines. Opening a mine loses.
- The face starts a new game. The picker at the top changes the difficulty (Beginner 9x9, Intermediate 16x16, Expert 16x30). Pause stops the clock.
- Under the scoreboard is the best time for the chosen difficulty. A win that beats it shows "New best".
- On Expert, a phone held upright shows the board turned on its side so the squares stay large enough to tap; pinch to zoom.

4. EXTERNAL SERVICES
None. The app makes no network requests and uses no third-party SDKs, data providers, authentication, payment or AI services. It uses only Apple's frameworks (SwiftUI, UIKit). The only things it stores are the chosen difficulty and the best time on each difficulty, on the device.

5. REGIONAL DIFFERENCES
None. The app works the same in every region and is in English only.

6. REGULATED INDUSTRY / THIRD-PARTY MATERIAL
Not applicable. It is not in a regulated industry and contains no third-party material: all artwork, including the squares, counters, face and icon, is drawn in SwiftUI for this app. Minesweeper is a generic game genre; the app uses no other company's names, art or code.
```

## Review history

### 1.0 (116): Guideline 2.1, Information Needed (25 Oct 2026, MINE-21)

Not a rejection of the app. The first submission from a developer account with "a limited App
Review history" gets a request for more information. App Review asked for a reply in App Store
Connect, also pasted into **App Review Information › Notes** for later submissions, with:

1. a screen recording on a physical device running the latest iOS, starting at launch and showing
   the typical flow, plus any account, user-generated or paid content (the app has none);
2. the app's purpose and target audience;
3. how to set up and reach its main features, with any login;
4. the external services it uses;
5. any regional differences;
6. documentation for a regulated industry or third-party material.

Items 2–6 are the Notes above. Item 1 is made on Nora's phone with the TestFlight build of the
submitted version, so it shows exactly what was reviewed:

1. Update the phone to the latest iOS (Settings › General › Software Update).
2. Delete the app, then install the submitted build from TestFlight, so the recording starts from
   a fresh install on Beginner.
3. Start a screen recording from Control Center, then go to the Home Screen and launch the app.
4. Play one Beginner game to a win: open squares, long-press to flag, turn on **Flag** and tap to
   flag, and tap a satisfied number to chord.
5. Tap the face for a new game and open a mine, to show a loss.
6. Pick **Expert** in the picker: the board turns on its side. Pinch to zoom, then tap
   **Pause** and **Resume**.
7. Stop the recording. It lands in Photos; trim it there if it runs long.

Then, in App Store Connect: paste the Notes into App Review Information, reply in App Review
(the Resolution Center) with the same text and the recording attached, and resubmit. The build
does not change, so nothing is uploaded.

### 1.0 (116): Approved (5 Nov 2026, MINE-22)

The reply to the 2.1 request went in with the recording from Nora's phone and the Notes above,
and the same build was resubmitted on 29 Oct 2026 at 5:02 PM PDT (submission ID
`8dc78651-30b6-485e-8475-cc241d16a041`). Apple's email: "Review of your submission has been
completed. It is now eligible for distribution", with App Version 1.0 for iOS accepted and no
guideline cited. None of the earlier risks came up: 4.3(b)
spam/clone, the `minesweeper` keyword (2.3.7) and the GitHub Issues support URL (1.5).

The version is set to **release manually**, so approval didn't publish it. Nora pressed
**Release** in App Store Connect the same day, 5 Nov 2026, so 1.0 (116) is the first public
version, at <https://apps.apple.com/app/noras-mine-sweeper/id6824740774> (Apple ID
`6824740774`). Apple says a release can take up to 24 hours to become publicly available. It
wasn't offered in EU storefronts until the EU trader status was answered (see below).

### 1.1: best times (MINE-26)

The first update. Best times (MINE-23) reached TestFlight as 1.0 (120), after 1.0 (116) had
been submitted, so 116 went out without them. 1.0 can take no new build once released, so the
update is version 1.1.

### EU storefronts: non-trader (8 Nov 2026, MINE-27)

The EU's Digital Services Act has every developer declare in App Store Connect (**Business**)
whether they are a trader, and until that is answered, Apple offers none of their apps in EU
storefronts. 1.0 went out with it unanswered, and a friend of Nora's in Spain found no app.
Nora declared **non-trader**: the app is free, with no ads, purchases or business behind it. A
trader's verified address, phone and email are shown on EU product pages, and a non-trader's
are not; EU users are told instead that consumer-protection law may not apply. The answer is for
the whole account, not per app or version, so it needs no build or review, and Apple says it can
take up to a day to reach EU storefronts. If an app on this account ever charges money, look at
this answer again.
