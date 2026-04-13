# Chessight — Release Pipeline

## v1.0 Beta (Current — TestFlight)

Status: Submitted for review

---

## v1.1 — Post-Beta Fixes

Priority fixes based on beta tester feedback. Address before public App Store release.

### Monitor & Fix (from beta)

- [ ] Classification accuracy for edge cases (mate transitions, sacrifice detection)
- [ ] iPad landscape orientation — layouts designed for portrait, landscape untested
- [ ] Share extension compatibility with different apps (Safari, chess.com app, Messages)
- [ ] Long games (100+ moves) performance and stability
- [ ] Chess.com API rate limiting under heavy usage
- [ ] Fifty-move rule and threefold repetition triggering correctly in bot games

### Known Gaps

- [ ] PGN export — allow users to copy/share analyzed game as PGN
- [ ] Undo in free play / analysis variation (currently uses back button only)
- [ ] Board editor should block pawn placement on rank 1/8 (currently shows warning but allows)
- [ ] Sound settings per move type (capture, check, castle) instead of global on/off

---

## v1.2 — Feature Enhancements

### Analysis

- [ ] Opening explorer — show opening name and common continuations
- [ ] Endgame tablebase integration (Syzygy) for perfect endgame play
- [ ] Multi-game analysis — batch analyze multiple games from a profile
- [ ] Analysis depth comparison — show how classification changes at different depths
- [ ] Export analysis as image/PDF (board + classification summary)

### Chess.com Integration

- [ ] Support for daily/correspondence games (currently live games only)
- [ ] Tournament game import
- [ ] Player comparison — compare accuracy between two profiles
- [ ] Game search/filter by opening, result, date, rating range

### Play Modes

- [ ] Timed games with clock (blitz, rapid, bullet)
- [ ] Puzzle streak — consecutive puzzles with scoring
- [ ] Puzzle rating tracking
- [ ] Opening trainer — practice specific openings against the bot
- [ ] Take-back confirmation dialog in bot games

### UI/UX

- [ ] Stitch/Google redesign — full UI/UX revamp (spec ready: chessight-ui-spec.md)
- [ ] Light theme option
- [ ] Board theme customization (wood, blue, green, etc.)
- [ ] Piece set options (cburnett, merida, alpha, etc.)
- [ ] Move notation preference (SAN vs algebraic vs figurine)
- [ ] Haptic feedback customization
- [ ] Accessibility improvements (VoiceOver, Dynamic Type)

### Platform

- [ ] Lichess.org integration (import games, profiles)
- [ ] PGN file association — open .pgn files directly in Chessight
- [ ] iCloud sync for saved profiles and analysis cache
- [ ] Widget — daily puzzle or last game accuracy on home screen
- [ ] Apple Watch complication — daily puzzle status

---

## v2.0 — Major Features

- [ ] Multiplayer — play online against friends (Game Center or custom)
- [ ] Cloud analysis — offload deep analysis to server for faster results
- [ ] Game database — search millions of master games by position
- [ ] Video analysis — import chess video timestamps and sync with board
- [ ] AI coach — natural language explanations of why moves are good/bad
- [ ] Repertoire builder — build and train your opening repertoire

---

## Technical Debt

- [ ] Refactor `computeLegalMoves` into shared ChessBoard method (currently duplicated in 3 ViewModels)
- [ ] Move TCN decoder tests to use real chess.com encoded games for validation
- [ ] Add UI tests (XCUITest) for critical flows (load game, analyze, navigate)
- [ ] CI/CD pipeline — GitHub Actions for build + test on PR
- [ ] Automate dSYM upload in project.yml (currently manual after xcodegen)
- [ ] Reduce Stockfish binary size (strip unused evaluation code)
- [ ] Profile memory usage on older devices (iPhone SE, iPad mini)
- [ ] Add network reachability checks before API calls

---

## App Store Release Checklist

Before moving from TestFlight to public release:

- [ ] All beta feedback addressed
- [ ] No crash reports in Crashlytics for 48 hours
- [ ] Performance traces show acceptable latency in Firebase
- [ ] Screenshots captured for all required device sizes
- [ ] App Store description finalized (draft in appstore-details.txt)
- [ ] Privacy policy URL live and accurate
- [ ] Support URL live
- [ ] App Review notes updated with latest test instructions
- [ ] Version bumped to 1.0 (build 2+)
- [ ] Remove "BETA" badge from Settings → About
