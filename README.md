# Chessight

A native iOS chess analysis app built with SwiftUI and C++ Stockfish engine. Analyzes chess games move-by-move with real-time evaluation, move classification, and accuracy scores — inspired by chess.com's game review.

## Features

### Game Analysis
- **Real-time move-by-move evaluation** using Stockfish 18 (native C++ — no JS bridge overhead)
- **Move classification**: Brilliant, Great, Best, Excellent, Good, Ok, Book, Miss, Inaccuracy, Mistake, Blunder
- **Accuracy scores** for both players using WintrChess/chess.com formula
- **Engine lines** showing top 3 variations with eval
- **Interactive board** — tap or drag pieces to explore variations
- **Eval bar** with animated transitions between moves
- **Best move arrows** and attack/defense visualization

### Chess.com Integration
- **Import games** by pasting chess.com game links
- **Save player profiles** — fetch and browse recent games
- **Share extension** — share a game link from Safari/chess.com and open directly in Chessight

### Play Modes
- **Play vs Bot** — adjustable engine strength (depth 1-20)
- **Free Play** — move pieces freely with optional engine hints
- **Board Editor** — set up custom positions, then analyze or play from them
- **Daily Puzzle** — chess.com puzzle of the day + random puzzles

### Other
- **PGN import** — paste PGN text or import .pgn files
- **FEN import** — paste FEN strings in the board editor to load any position
- **Opening book** detection (~3600 positions)
- **Piece sounds** and haptic feedback
- **Dark theme** inspired by chess.com
- **iPad support** with adaptive side-by-side layout
- **Firebase Crashlytics** for crash monitoring

## Screenshots

<!-- Add screenshots here -->

## Requirements

- macOS with Xcode 15+
- iOS 17.0+ deployment target
- [xcodegen](https://github.com/yonaskolb/XcodeGen) — `brew install xcodegen`

## Setup

### 1. Clone the repository

```bash
git clone <repo-url>
cd ChessAnalyser
```

### 2. Add required files (not in repo)

These files are gitignored for security/size reasons. You must add them manually:

**Firebase config:**
- Place your `GoogleService-Info.plist` in `ChessAnalyser/`
- Get it from [Firebase Console](https://console.firebase.google.com) → Project Settings → iOS app

**Stockfish NNUE models:**
- Download from the [Stockfish releases](https://github.com/official-stockfish/Stockfish/releases)
- Place in `ChessAnalyser/Resources/`:
  - `nn-7bf13f9655c8.nnue` (85 MB — large network)
  - `nn-47fc8b7fff06.nnue` (3.8 MB — small network)

### 3. Generate Xcode project

```bash
xcodegen generate
```

### 4. Open in Xcode

```bash
open ChessAnalyser.xcodeproj
```

### 5. Configure signing

- Select the **ChessAnalyser** target → Signing & Capabilities
- Choose your development team
- Do the same for the **ChessAnalyserShare** target

### 6. Build and run

Select your device or simulator and press `Cmd+R`.

### Crashlytics dSYM upload (Release builds)

After every Release build or Archive, add a Run Script Build Phase in Xcode:

```bash
"${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run"
```

Input files:
- `$(DWARF_DSYM_FOLDER_PATH)/$(DWARF_DSYM_FILE_NAME)`
- `$(DWARF_DSYM_FOLDER_PATH)/$(DWARF_DSYM_FILE_NAME)/Contents/Resources/DWARF/$(PRODUCT_NAME)`
- `$(DWARF_DSYM_FOLDER_PATH)/$(DWARF_DSYM_FILE_NAME)/Contents/Info.plist`
- `$(TARGET_BUILD_DIR)/$(INFOPLIST_PATH)`

> Note: This build phase is cleared when xcodegen regenerates the project. Re-add it after running `xcodegen generate`.

## Running Tests

```bash
xcodebuild test -project ChessAnalyser.xcodeproj -scheme ChessAnalyser \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Architecture

```
ChessAnalyser/
├── App/                    # Entry point, app state, tab navigation
├── Models/                 # Game, Analysis, Classification, Profile
├── Chess/                  # ChessBoard, PGN parser, game state, opening book
├── Engine/                 # Stockfish bridge, UCI protocol, analysis pipeline, move classifier
├── Network/                # Chess.com API, game resolver, puzzle API
├── Storage/                # Profile store, analysis cache
├── ViewModels/             # MVVM view models
├── Views/                  # All SwiftUI views
│   ├── Analysis/           # Main analysis screen, controls, move list, engine lines
│   ├── Board/              # Eval bar, interactive board
│   ├── Play/               # Free play, bot game
│   ├── Editor/             # Board editor
│   ├── Puzzle/             # Daily puzzle
│   ├── Import/             # PGN import, shared game handler
│   ├── Profile/            # Chess.com profiles
│   └── Tabs/               # Home, profiles, settings tabs
├── Theme/                  # Colors, fonts, spacing
├── Utilities/              # Sound manager, crash logger, extensions
├── Resources/              # Assets, NNUE models, opening book JSON
└── Stockfish/              # C++ source, wrapper, bridging header
```

## Tech Stack

- **UI**: SwiftUI, iOS 17+
- **Engine**: Stockfish 18 (C++17, compiled natively for arm64)
- **NNUE**: Dual neural network evaluation (large + small)
- **Networking**: URLSession async/await
- **Persistence**: UserDefaults + JSON files
- **Crash reporting**: Firebase Crashlytics + Analytics
- **Project generation**: xcodegen
- **Package management**: Swift Package Manager (Firebase SDK)
