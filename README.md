# 🎬 EzzeWatchList  (A Ezze Softwares Product)

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=flat-square&logo=dart)](https://dart.dev/)
[![Database](https://img.shields.io/badge/Database-SQLite-003B57?style=flat-square&logo=sqlite)](https://pub.dev/packages/sqflite)
[![State Management](https://img.shields.io/badge/State-Provider-FFCA28?style=flat-square)](#)

> A premium, highly polished personal movie & series watchlist tracker built with **Flutter** and **Dart**. Keep track of your cinematic journey with beautiful UI, robust local storage, and seamless animations.

<p align="center">
  <img src="assets/icon/splash.gif" alt="EzzeWatchList Splash Animation" width="480"/>
</p>

---

## ✨ Key Features

- 🏠 **Dynamic Library** — Tabbed grid view organized by *Watched*, *Watching*, and *Planned*
- ➕ **Comprehensive Entry** — Add/Edit shows with posters, genres, rating sliders, and episode tracking
- 📄 **Immersive Details** — Hero-animated poster header with detailed view
- 🔍 **Smart Search & Filter** — Real-time search with genre/category filters
- 📊 **User Statistics** — Runtime tracking, average rating, top genre insights
- 🌙 **Adaptive Theming** — Persistent Dark/Light mode toggle

---

## 🛠️ Tech Stack

| Layer | Technology |
|------|-----------|
| **Framework** | Flutter 3.x |
| **Language** | Dart 3.x |
| **Database** | SQLite (`sqflite`) |
| **State Management** | Provider (`ChangeNotifier`) |
| **Media Handling** | `image_picker`, `cached_network_image` |
| **Persistence** | `shared_preferences` |

---
### 📌 Prerequisites

- Flutter SDK ≥ 3.0.0 ([Install Guide](https://flutter.dev/docs/get-started/install))
- Android Studio with SDK
- Emulator or physical device

---

## 📁 Project Architecture

```
lib/
├── main.dart
├── data/
│   ├── models/
│   ├── database/
│   └── network/
├── ui/
│   ├── splash/
│   ├── home/
│   ├── add_edit/
│   ├── detail/
│   ├── search/
│   ├── stats/
│   └── profile/
├── widgets/
│   └── poster_card.dart
└── utils/
    ├── app_theme.dart
    └── theme_provider.dart
```

---

## 🔮 Future Roadmap: Supabase Cloud Sync

Planned upgrade to enable cloud synchronization.

### Implementation Steps

1. Add dependency:
```yaml
supabase_flutter
```

2. Initialize in `main.dart`

3. Create sync service:
- Two-way sync (SQLite ↔ Supabase)

4. Connect UI button:
- `SyncService.syncCloudToLocal()`

---

## ❤️ Developer

Developed by **Imran Hasan**
