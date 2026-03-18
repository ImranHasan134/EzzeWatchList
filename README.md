# EzzeWatchList 🎬

A personal movie & series watchlist tracker built with **Flutter + Dart**.

## Features
- 🏠 **Home** — Tabbed grid view (Watched / Watching / Planned)
- ➕ **Add / Edit** — Poster upload, genres, rating slider, season/episode for series
- 📄 **Detail** — Full info with collapsing poster header, edit & delete
- 🔍 **Search & Filter** — Real-time search by title + genre & category chips
- 📊 **Stats** — Total count, watched count, average rating, top genre
- 🌙 **Settings** — Dark mode toggle, Supabase sync placeholder

## Tech Stack
| Layer        | Technology                   |
|-------------|------------------------------|
| Framework   | Flutter 3.x                  |
| Language    | Dart 3.x                     |
| Database    | SQLite via `sqflite`         |
| State       | `provider` (ChangeNotifier)  |
| Image Pick  | `image_picker`               |
| Dark Mode   | `shared_preferences`         |

## Getting Started

### Prerequisites
- Flutter SDK ≥ 3.0.0 installed ([flutter.dev](https://flutter.dev/docs/get-started/install))
- Android Studio with Android SDK installed
- A connected Android device or emulator

### ⚡ Quick Setup (Recommended)

The fastest way to get running — this generates all native Android files correctly
and sets up `local.properties` with your machine's actual SDK paths automatically:

```bash
# 1. Extract the zip and open a terminal in the EzzeWatchList/ folder

# 2. Let Flutter scaffold the native platform files (won't touch your Dart code)
flutter create . --org com.ezzewatchlist

# 3. Install dependencies
flutter pub get

# 4. Run the app
flutter run
```

### Manual Setup (if you prefer not to run flutter create)

If you want to use the Android files already in the zip:

1. Open `android/local.properties`
2. Update `sdk.dir` to your Android SDK path
3. Update `flutter.sdk` to your Flutter installation path
4. Then run:

```bash
flutter pub get
flutter run
```

**Windows paths example:**
```
sdk.dir=C\:\\Users\\YourName\\AppData\\Local\\Android\\sdk
flutter.sdk=C\:\\flutter
```

**macOS/Linux paths example:**
```
sdk.dir=/Users/yourname/Library/Android/sdk
flutter.sdk=/home/yourname/flutter
```


## Project Structure
```
lib/
├── main.dart                   # Entry point, providers setup
├── data/
│   ├── models/watch_item.dart  # WatchItem + constants (WatchStatus, Category, Genre)
│   └── database/
│       ├── db_helper.dart      # SQLite CRUD & queries
│       └── watch_provider.dart # ChangeNotifier (state management)
├── ui/
│   ├── main_scaffold.dart      # Bottom NavigationBar shell
│   ├── home/home_screen.dart   # TabBar + grid views
│   ├── add_edit/               # Add & Edit form
│   ├── detail/                 # Detail screen
│   ├── search/                 # Search + filter
│   ├── stats/                  # Stats dashboard
│   └── settings/               # Settings (dark mode, future sync)
├── widgets/
│   └── poster_card.dart        # Reusable grid card
└── utils/
    ├── app_theme.dart           # Material3 light/dark themes
    └── theme_provider.dart      # Dark mode persistence

## Future Upgrade: Supabase
To add Supabase login & cloud sync, update `WatchRepository` in
`lib/data/database/watch_provider.dart`:
1. Add `supabase_flutter` to `pubspec.yaml`
2. Initialize Supabase in `main.dart`
3. In `WatchProvider`, replace `DbHelper` calls with Supabase table queries
4. Add auth screens and connect the Settings "Connect Account" button
```
