# 🗺️ GeoQuest — A Campus-Wide GPS Challenge Competition

> A premium, production-ready Flutter mobile application for team-based GPS-powered campus challenge competitions.

---

## 🎯 Overview

GeoQuest is a **team-based GPS-powered campus challenge competition app** where teams of 3–4 members explore campus locations to unlock and solve time-bound challenges. Each team gets exactly **2 hours** from their start time, earns points for correct answers, and competes on a real-time leaderboard.

### How It Works
1. **Register** a team (3–4 members)
2. **Start** your 2-hour quest
3. **Explore** campus using the live map
4. **Unlock** challenges by physically reaching GPS waypoints (20m geofence)
5. **Solve** category-based challenges under time pressure
6. **Compete** on the real-time leaderboard

### Winner Criteria
- First team to reach the **target score**, OR
- **Highest score** within the 2-hour time limit

---

## 🏗️ Architecture

### Clean Architecture + MVVM + Riverpod

```
lib/
├── core/                          # Shared foundation layer
│   ├── constants/                 # Colors, strings, Firebase paths, assets
│   ├── theme/                     # Dark theme, glassmorphism components
│   ├── utils/                     # Geo utilities, datetime helpers
│   └── widgets/                   # Reusable widgets (NeonButton, GradientScaffold, etc.)
│
├── domain/                        # Business logic (pure Dart, no Flutter imports)
│   ├── entities/                  # Team, Challenge, Session, LeaderboardEntry
│   ├── repositories/              # Abstract repository contracts
│   └── usecases/                  # StartSession, DifficultyEngine
│
├── data/                          # Firebase implementation layer
│   ├── models/                    # Firestore/RTDB serialization models
│   ├── datasources/               # Firebase Auth, Firestore, Realtime DB
│   ├── repositories/              # Concrete repository implementations
│   └── seed/                      # Sample challenge data
│
├── presentation/                  # UI layer
│   ├── providers/                 # Riverpod state management
│   ├── screens/                   # Full-page screens
│   │   ├── auth/                  # Register & Login
│   │   ├── home/                  # Dashboard
│   │   ├── map/                   # Live GPS map
│   │   ├── challenge/             # Challenge solving
│   │   ├── leaderboard/           # Real-time rankings
│   │   └── admin/                 # Event management
│   └── widgets/                   # Screen-specific widgets
│
├── app.dart                       # GoRouter + MaterialApp shell
└── main.dart                      # Entry point with Firebase init
```

### State Management
- **flutter_riverpod** — All state is managed via providers
- `StateNotifierProvider` for auth, session, timers
- `StreamProvider` for real-time session & leaderboard updates
- `FutureProvider` for challenge data fetching

### Navigation
- **go_router** with auth-guarded redirect
- `refreshListenable` pattern for reactive auth-based routing

---

## 🔥 Firebase Schema

### Firestore Collections

| Collection | Purpose |
|---|---|
| `teams` | Registered teams with members |
| `challenges` | GPS-bound challenge questions |
| `challenge_answers` | **Server-only** — correct answers |
| `sessions` | Active 2-hour game sessions |
| `submissions` | Answer submissions for validation |
| `event_config` | Global event configuration |

### Realtime Database

| Path | Purpose |
|---|---|
| `leaderboard/{teamId}` | Live score rankings |
| `active_timers/{teamId}` | Server-side session timers |
| `live_scores/{teamId}` | Real-time score updates |

See `firebase_schema.json` for the complete schema with field types.

### Security Rules
- `firestore.rules` — Firestore security rules
- `database.rules.json` — Realtime Database rules
- **Key principle**: Answers are NEVER sent to clients; scoring happens server-side only

---

## ☁️ Cloud Functions

Located in `functions/index.js`:

| Function | Trigger | Purpose |
|---|---|---|
| `validateSubmission` | Firestore `onCreate` on `submissions` | Server-side answer validation & scoring |
| `autoExpireSessions` | Scheduled (every 5 min) | Auto-lock expired sessions |
| `rateLimitSubmissions` | Firestore `onCreate` on `submissions` | Anti-cheat rate limiting |

---

## 🎨 Design System

### Theme
- **Primary**: Dark (#0A0E21) with neon accents
- **Typography**: Orbitron (headers) + Inter (body) via Google Fonts
- **Components**: Glassmorphism containers, neon-glow buttons, gradient scaffolds
- **Material 3** customized for competition aesthetic

### Color Tokens
| Token | Hex | Usage |
|---|---|---|
| `neonCyan` | #00F5FF | Primary accent, buttons, scores |
| `neonPurple` | #BB86FC | Secondary accent, categories |
| `neonPink` | #FF2D87 | Tertiary, expert difficulty |
| `neonGreen` | #39FF14 | Success, easy difficulty |
| `neonOrange` | #FF6B35 | Hard difficulty, warnings |

---

## 📱 Screens

### 1. Authentication (Register / Login)
- Team name + 3–4 member names
- Unique team ID generation
- Glassmorphic card layout with gradient logo

### 2. Home Dashboard
- Radial countdown timer (CustomPainter)
- Score, difficulty, accuracy stat cards
- Map & Leaderboard quick-access buttons
- Time-expired overlay

### 3. Live Map
- Full-screen Google Map with dark styling
- Color-coded markers (locked/unlocked/completed)
- Geofence circles around challenge locations
- Auto-popup bottom sheet on GPS proximity

### 4. Challenge
- Category chip + difficulty badge + points
- Per-challenge countdown timer bar
- Text input or multiple-choice answer
- Submit/Skip with penalty logic
- Animated result card

### 5. Real-Time Leaderboard
- Top 3 podium with trophy icons
- Highlighted current team row
- Live score streaming from Realtime DB

### 6. Admin Panel
- Teams overview with live counts
- Challenge management
- Event configuration
- Category performance analytics

---

## 🧠 Progressive Difficulty Engine

Difficulty scales based on three factors:

| Factor | Effect |
|---|---|
| **Score thresholds** | 0–50 Easy, 50–150 Medium, 150–300 Hard, 300+ Expert |
| **Accuracy rate** | >80% → bump up, <40% → bump down |
| **Solve speed** | <60s average → bump up |

Points per difficulty:
- Easy: 10 base + up to 5 time bonus
- Medium: 25 base + up to 12 time bonus
- Hard: 50 base + up to 25 time bonus
- Expert: 100 base + up to 50 time bonus

---

## 🔐 Security

| Measure | Implementation |
|---|---|
| Server-side scoring | Cloud Functions validate all answers |
| Answer isolation | `challenge_answers` collection is client-unreadable |
| Rate limiting | Max 3 submissions per 10 seconds |
| Session binding | Sessions tied to Firebase Auth UID |
| Timer integrity | Server timestamps, auto-expiry via scheduled function |
| GPS spoofing mitigation | Multiple position samples, movement pattern analysis (suggested) |
| Replay prevention | Submission dedup via completed challenge tracking |

---

## 🚀 Setup Instructions

### Prerequisites
- Flutter SDK ^3.5.0
- Firebase project with Auth, Firestore, Realtime Database enabled
- Google Maps API key (Maps SDK for Android & iOS)
- Node.js 18+ (for Cloud Functions)

### 1. Clone & Install
```bash
flutter pub get
```

### 2. Firebase Setup
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase
flutterfire configure

# Deploy security rules
firebase deploy --only firestore:rules,database

# Deploy Cloud Functions
cd functions && npm install && firebase deploy --only functions
```

### 3. Google Maps API Key
- Enable Maps SDK in Google Cloud Console
- Add key to `android/app/src/main/AndroidManifest.xml` (replace `YOUR_GOOGLE_MAPS_API_KEY_HERE`)
- For iOS: Add to `ios/Runner/AppDelegate.swift`

### 4. Seed Challenges
Reference `lib/data/seed/sample_challenges.dart` and upload to Firestore. Store answers in the separate `challenge_answers` collection.

### 5. Run
```bash
flutter run
```

---

## 📦 Dependencies

| Package | Purpose |
|---|---|
| `flutter_riverpod` | State management |
| `firebase_core/auth/firestore/database` | Backend services |
| `google_maps_flutter` | Map display |
| `geolocator` | GPS positioning |
| `go_router` | Declarative routing |
| `google_fonts` | Orbitron + Inter typography |
| `flutter_animate` | Micro-interactions & transitions |
| `shimmer` | Loading skeleton effects |
| `uuid` | Unique ID generation |
| `intl` | Date/number formatting |

---

## 📐 Scalability

Designed to support **100+ simultaneous teams**:
- Firestore auto-scales reads/writes
- Realtime Database for leaderboard (optimized for frequent updates)
- Indexed queries for session & challenge lookups
- Efficient provider architecture prevents unnecessary rebuilds

---

*Built with ❤️ for university tech fests.*
