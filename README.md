# flow_admin_mobile

Admin mobile application for managing lottery/draw games. Built in Flutter.

---

## Quick Start

### 1. Create the Flutter project

```bash
flutter create flow_admin_mobile
cd flow_admin_mobile
```

### 2. Replace `pubspec.yaml` with the provided file

Then run:
```bash
flutter pub get
```

### 3. Replace/create all files from the `lib/` folder

Copy all provided files into your `lib/` directory, maintaining the structure:

```
lib/
├── main.dart
├── router/
│   └── app_router.dart
├── constants/
│   ├── app_colors.dart
│   └── app_text_styles.dart
├── models/
│   └── game.dart
├── screens/
│   ├── auth/
│   │   └── login_screen.dart
│   ├── game_selection/
│   │   └── game_selection_screen.dart
│   └── dashboard/
│       └── dashboard_screen.dart
└── widgets/
    └── game_card.dart
```

### 4. Run the app

```bash
# On connected device or emulator
flutter run

# Build release APK (free, local, no cloud)
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

---

## What's Built

| Screen | Route | Status |
|--------|-------|--------|
| Login | `/login` | ✅ Complete |
| Game Selection | `/game-selection` | ✅ Complete |
| Dashboard | `/dashboard/:gameId` | 🚧 Placeholder |

### Login Screen
- Full-screen gradient background (blue tones)
- Decorative translucent circles
- Animated logo with layered rings + gradient icon box
- Username + password fields with focus state animation
- Password show/hide toggle
- Login button navigates to game selection
- Footer version label

### Game Selection Screen
- Dark admin aesthetic (`#0D1117` background)
- Dynamic header with game count badge
- 4 game cards filling exact screen height (no scroll)
- Each card: unique gradient, diagonal stripe texture, ghost number, status badge, icon box
- Cards: 01 PM (red), KL 3 PM (teal), 06 PM (purple), 08 PM (dark navy)

### Dashboard Screen
- Placeholder only — will be fully designed later
- Back navigation to game selection
- Receives `gameId` + `gameName` from route params

---

## Not Yet Implemented

- [ ] State management (Riverpod)
- [ ] API calls (Dio)
- [ ] Authentication logic + token storage
- [ ] Form validation
- [ ] Error handling / loading states
- [ ] Real data from backend

---

## Tech Stack

| Concern | Package |
|---------|---------|
| Navigation | `go_router` |
| HTTP | `dio` |
| State | `flutter_riverpod` |
| Secure storage | `flutter_secure_storage` |
| Env config | `flutter_dotenv` |
