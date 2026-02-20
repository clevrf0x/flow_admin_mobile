# CLAUDE.md — flow_admin_mobile

Flutter-based lottery/draw game admin mobile app. Android APK primary target. Solo developer project.

## Build & Run

```bash
flutter pub get
flutter run                          # dev mode
flutter build apk --release          # output: build/app/outputs/flutter-apk/app-release.apk
```

## Tech Stack

| Package | Version | Status |
|---|---|---|
| go_router | ^13.0.0 | Active — all navigation |
| dio | ^5.4.0 | Installed, unused — for API |
| flutter_riverpod | ^2.5.0 | Installed, unused — all state is StatefulWidget |
| riverpod_annotation | ^2.3.0 | Installed, unused |
| font_awesome_flutter | ^10.7.0 | Used in game_card.dart only |
| flutter_secure_storage | ^9.0.0 | Installed, unused — will store auth tokens |
| flutter_dotenv | ^5.1.0 | Installed, unused — will store API base URL |

## File Structure

```
lib/
├── main.dart
├── router/
│   └── app_router.dart              # GoRouter config
├── constants/
│   ├── app_colors.dart              # ALL colors — always use these
│   └── app_text_styles.dart         # Typography
├── models/
│   ├── game.dart                    # Game model + mockGames list
│   └── dashboard_menu_item.dart     # DashboardMenuItem + OthersMenuItem
├── screens/
│   ├── auth/login_screen.dart       # Light theme
│   ├── game_selection/game_selection_screen.dart  # Dark theme
│   ├── dashboard/dashboard_screen.dart            # Dark theme
│   ├── booking/booking_screen.dart                # Dark theme (most complex ~800 lines)
│   ├── change_password/change_password_screen.dart
│   ├── others/others_screen.dart
│   └── settings/settings_screen.dart              # ~605 lines
└── widgets/
    ├── game_card.dart               # Used in game selection
    └── common_toast.dart            # Reusable toast/snackbar
```


## Routes (app_router.dart)

```
/login
/game-selection
/dashboard/:gameId?gameName=
/dashboard/:gameId/others?gameName=
/dashboard/:gameId/change-password?gameName=
/dashboard/:gameId/booking?gameName=
/dashboard/:gameId/settings?gameName=
```

### Navigation Rule — ALWAYS use this pattern:

```dart
context.go('/dashboard/$gameId?gameName=${Uri.encodeComponent(gameName)}');
//                                        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
//                                        REQUIRED — handles spaces/special chars
```

Never use `Navigator.push()` — always go_router.

## Wired Navigation

- Login → Game Selection ✅
- Game Selection → Dashboard ✅
- Dashboard → Booking ✅
- Dashboard → Others ✅
- Dashboard → Change Password ✅
- Dashboard → Game Selection (Change Game) ✅
- Others → Settings ✅

## TODO Screens (not built)

- Monitor
- Today
- Add Results
- Daily Report
- Sales Report
- Monitor Report
- Others sub-screens: Blocked Numbers, Customer, Results, Daily Report, Count Sales Report, Winning Report, Count Winning Report, Deleted Numbers, Rejected Numbers

## Color System

**Always use `AppColors` constants. Never use inline `Color(0xFF...)`.**

### Login (Light Theme)
```dart
AppColors.loginBgTop       // #1B7ACC gradient start
AppColors.loginBgMid       // #1565A0
AppColors.loginBgBottom    // #0D4A85
AppColors.inputBg          // #EAF1FB
AppColors.loginButtonStart // #2186D8
AppColors.loginButtonEnd   // #1565A0
```

### Dark Theme (Game Selection, Dashboard, all sub-screens)
```dart
AppColors.dashboardBg      // #0D1117 — page background
AppColors.dashboardSurface // #161B22 — cards/panels
AppColors.dashboardSurface2// #1C2330 — table headers
AppColors.dashboardBorder  // #21262D — all borders
AppColors.dashboardTextPrim// #E6EDF3 — primary text
AppColors.dashboardTextSub // #8B949E — secondary/muted
AppColors.dashboardTextDim // #484F58 — section labels
AppColors.gsAccentBlue     // #58A6FF — fallback accent
AppColors.dashboardLogout  // #DA3633 — red for delete/logout
```

### Game Gradients (3-stop)
```dart
// 01 PM — Red
[AppColors.game01pmLight, AppColors.game01pmMid, AppColors.game01pmDark]
// KL 3 PM — Teal
[AppColors.gameKl3pmLight, AppColors.gameKl3pmMid, AppColors.gameKl3pmDark]
// 06 PM — Purple
[AppColors.game06pmLight, AppColors.game06pmMid, AppColors.game06pmDark]
// 08 PM — Near Black Navy
[AppColors.game08pmLight, AppColors.game08pmMid, AppColors.game08pmDark]
```

**Known issue:** `game_06pm` in `game.dart:77` uses `Color(0xFFC39BD3)` for `statusColor` — should be an `AppColors` constant.

### Status Colors
```dart
AppColors.statusLive  // #FF6B6B
AppColors.statusOpen  // #4ECDC4
AppColors.statusSoon  // #778CA3
```

### LSK Type Colors (Booking table)
```dart
AppColors.lskAB   // #E53935 red
AppColors.lskAC   // #FF8F00 amber
AppColors.lskBC   // #212121 (use dashboardTextSub for dark bg visibility)
AppColors.lskBox  // #2E7D32 green
AppColors.lskC    // #1976D2 blue
AppColors.lskBoth // #6A1B9A purple
// lskSuper: use dashboardTextSub for dark bg visibility
```

## Universal Header Pattern

Every sub-screen uses this identical header. Copy it exactly:

```dart
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: headerColors.length >= 2
          ? [headerColors[0], headerColors.last]
          : [headerColors[0], headerColors[0]],
    ),
  ),
  child: Padding(
    padding: EdgeInsets.fromLTRB(6, statusBarHeight + 4, 16, 14),
    child: Row(
      children: [
        // LEFT: back button with game name
        InkWell(
          onTap: () => context.go(parentRoute),
          child: Row(children: [
            Icon(Icons.chevron_left_rounded, color: Colors.white, size: 22),
            Text(gameName, style: TextStyle(color: Colors.white.withOpacity(0.9))),
          ]),
        ),
        // CENTER: screen title
        Expanded(
          child: Text('Screen Title',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        // RIGHT: frosted glass button (home icon or power icon)
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.22),
            border: Border.all(color: Colors.white.withOpacity(0.35)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.home_rounded, color: Colors.white),
        ),
      ],
    ),
  ),
)
```

Status bar must always be `SystemUiOverlayStyle.light` (white icons).

## Dark Game Accent Color Helper

**Always use this** — handles the 08 PM near-black gradient where the game color is invisible:

```dart
Color _resolvedAccentColor(List<Color> headerColors) {
  final luminance = headerColors.first.computeLuminance();
  if (luminance < 0.08) return AppColors.gsAccentBlue;
  return headerColors.first;
}
```

## Dark Body Pattern (All Sub-Screens)

```dart
Scaffold(
  backgroundColor: AppColors.dashboardBg,
  body: ListView(children: [
    Container(
      decoration: BoxDecoration(
        color: AppColors.dashboardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.dashboardBorder, width: 1),
      ),
      child: Column(children: [ /* rows with indented dividers */ ]),
    ),
  ]),
)
```

### Section headers:
```dart
Text('SECTION LABEL', style: TextStyle(
  color: AppColors.dashboardTextDim,
  fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2.0,
))
```

### Menu row icon box:
```dart
Container(
  decoration: BoxDecoration(
    color: accentColor.withOpacity(0.13),
    border: Border.all(color: accentColor.withOpacity(0.22)),
    borderRadius: BorderRadius.circular(10),
  ),
  child: Icon(icon, color: accentColor),
)
```

### Indented dividers (never full-width):
```dart
Container(
  height: 1,
  margin: EdgeInsets.only(left: 68), // 38 icon + 14 gap + 16 padding
  color: AppColors.dashboardBorder,
)
```

## Toast Usage

```dart
CommonToast.showSuccess(context, 'Operation successful');
CommonToast.showError(context, 'Operation failed. Please try again.');
CommonToast.showInfo(context, 'Information message');
CommonToast.showLoading(context, 'Saving entries...',
  gradientColors: [game.gradientColors.first, game.gradientColors.last]);
```

Settings screen uses game gradient for success (not default green) — visual consistency with header.

## Dialog Pattern

```dart
Dialog(
  backgroundColor: Colors.transparent,
  child: Container(
    decoration: BoxDecoration(
      color: AppColors.dashboardSurface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.dashboardBorder),
    ),
    child: Column(children: [
      // Gradient header band (6px height)
      Container(
        height: 6,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: headerColors),
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
      ),
      // Dark-themed content rows
    ]),
  ),
)
```

## Booking Screen Key Details

Pricing constants at top of file: `kDRate = 9`, `kCRate = 10` — TODO replace with API.

### Digit Mode → Action Buttons
- 1 digit: A, B, C, ALL
- 2 digits: AB, AC, BC, ALL
- 3 digits: SUPER, BOX, BOTH

### Book Types (gated by digit mode)
- 1-digit: Book only
- 2-digit: Book, Range
- 3-digit: Book, Range, Set, 10s, 100s, 111s

### Input constraints
- Number field: `maxLength = digit count`, zero-pads on submit (e.g., `5` → `05` in 2-digit mode)
- All fields: `FilteringTextInputFormatter.digitsOnly`

### Set deduplication fix (critical — do not revert)
```dart
// WRONG — [1,1,1].toSet() compares by reference → 3 identical entries
final unique = permutations.toSet().toList();

// CORRECT
final seen = <String>{};
final unique = permutations.where((p) => seen.add(p.join())).toList();
```

### Radio mode switch: does NOT clear the table (intentional — user can mix digit modes)

## Common Pitfalls

1. **gameName encoding** — always `Uri.encodeComponent(gameName)` in routes
2. **Dark game accent** — always `_resolvedAccentColor()`, never use raw `headerColors.first`
3. **Toast background** — `SnackBar(backgroundColor: Colors.transparent)`, gradient goes in content Container
4. **Gradient direction** — always `topLeft → bottomRight`
5. **Set deduplication** — use `Set<String>` on joined string, not `.toSet()` on list

## Imports Order Convention

```dart
import 'dart:async';           // 1. Dart SDK
import 'package:flutter/material.dart';  // 2. Flutter
import 'package:go_router/go_router.dart';  // 3. External packages
import '../../constants/app_colors.dart';   // 4. Project (relative)
```

## What's NOT Implemented Yet

- Any API calls (all data mocked, `// TODO: API call` comments throughout)
- Auth logic (login navigates unconditionally — no validation, no token)
- Riverpod providers (all state is local `StatefulWidget`)
- Settings screen (file doesn't exist, route not in router)
- 9 remaining screens listed above

## Before Building Any New Screen

1. Read app_colors.dart — use correct constants
2. Use the universal header pattern exactly
3. Add `_resolvedAccentColor()` helper
4. Test with all 4 games, especially 08 PM (dark gradient)
5. Use `CommonToast` for all notifications
6. Use game gradient for success toasts (not default green)
7. Add `// TODO: API call` comments where API calls will go
8. Indent all dividers — never full-width in grouped lists
9. Register new route in `app_router.dart`
10. Wire navigation in the calling screen
