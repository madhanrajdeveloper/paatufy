# 🎵 Paatufy

<p align="center">
  <img src="assets/images/paatufy.png" alt="Paatufy Logo" width="120" height="120" style="border-radius: 50%;">
</p>

<p align="center">
  <strong>High-Quality Music Streaming App for Tamil & English Music Lovers</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Hive-Storage-orange?style=for-the-badge" alt="Hive" />
  <img src="https://img.shields.io/badge/Riverpod-State%20Management-blueviolet?style=for-the-badge" alt="Riverpod" />
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-green?style=for-the-badge" alt="Platforms" />
</p>

---

## 📌 Overview

**Paatufy** is a modern, Spotify-inspired music streaming application built using Flutter. Designed with a sleek dark-mode aesthetic and vibrant green accents, Paatufy delivers background audio playback, dynamic Tamil and English discovery feeds, complete playlist management, offline caching, and real-time audio controls.

---

## ✨ Features

### 🎧 Audio & Playback Experience
* **Background Audio & Lockscreen Controls**: Full system notification and lockscreen media player with track artwork, seek slider, and responsive playback actions using `audio_service` and `just_audio`.
* **Full Player Modal**: Interactive playback screen featuring animated equalizer bars, live seek progress, shuffle, loop modes (One / All), and a sleep timer.
* **Spotify-Style MiniPlayer**: Persistent bottom mini-player with quick Previous, Play/Pause, Next, and reactive Like toggles.
* **Sleep Timer**: Set custom countdown timers or automatically stop playback at the end of the currently playing track.

### 🏠 Dynamic Discovery & Feed
* **Dynamic Feed**: Generates fresh selections of new and trending Tamil and English hits, trending albums, top playlists, and featured artists on every launch or refresh.
* **Recently Played Shelf (6-Hour TTL)**: Automatically stores played songs, albums, and playlists. Entries automatically expire after 6 hours to keep your home feed fresh.

### 📚 Library & Custom Playlists
* **Create & Organize Playlists**: Create custom playlists with custom names and covers directly from your library.
* **Universal "Add to Playlist"**: Add any track across Search, Albums, MiniPlayer, or Full Player into your existing or newly created playlists via bottom sheets.
* **Liked Songs & Saved Albums**: Fast local caching powered by Hive with instant UI synchronization across all screens.

### 🔍 Universal Search
* **Multi-Category Search**: Instant search indexing across Songs, Albums, Artists, and Curated Playlists.
* **Artist Discography**: Explore complete artist profiles with their top tracks and albums.

### ⚙️ Profile & Audio Settings
* **Playback Preferences**: Configurable streaming quality (Auto, 160kbps, 320kbps), gapless playback, and volume normalization.
* **Cache Management**: One-tap clearing for search history and recently played caches.

---

## 🛠️ Tech Stack & Architecture

* **Framework**: [Flutter](https://flutter.dev/) (Dart)
* **State Management**: [Flutter Riverpod](https://riverpod.dev/)
* **Audio Engine**: [`just_audio`](https://pub.dev/packages/just_audio) & [`audio_service`](https://pub.dev/packages/audio_service)
* **Local Database**: [Hive](https://docs.hivedb.dev/) & `hive_flutter`
* **Networking**: [Dio](https://pub.dev/packages/dio) with custom JioSaavn API endpoints
* **Image Caching**: [`cached_network_image`](https://pub.dev/packages/cached_network_image)
* **Navigation**: [`go_router`](https://pub.dev/packages/go_router)

---

## 📁 Project Structure

```text
lib/
├── core/
│   ├── storage/
│   │   └── hive_service.dart          # Local database, 6-hr TTL logic & playlists
│   └── theme/
│       └── app_theme.dart             # Dark Spotify theme colors & typography
├── features/
│   ├── audio/
│   │   ├── data/
│   │   │   └── audio_handler.dart     # Background AudioService & media notifications
│   │   └── presentation/
│   │       └── controllers/           # Riverpod playback controllers
│   ├── home/
│   │   └── presentation/
│   │       └── screens/home_screen.dart # Dynamic Tamil/English discovery feed
│   ├── library/
│   │   └── presentation/
│   │       └── screens/               # Liked songs, custom user playlists & albums
│   ├── player/
│   │   └── presentation/
│   │       └── widgets/               # Full player, Mini player, Sleep timer, Add to playlist
│   ├── profile/
│   │   └── presentation/
│   │       └── screens/               # User profile & audio quality settings
│   ├── search/
│   │   ├── data/                      # JioSaavn and Audius API services
│   │   └── presentation/screens/      # Multi-category search & entity detail screens
│   └── splash/
│       └── presentation/screens/      # Animated startup splash screen
├── models/
│   ├── search_result.dart             # Search, Album & Artist models
│   ├── song.dart                      # Core Song model & Hive Adapter
│   └── user_playlist.dart             # Custom user playlist model
├── routing/
│   └── app_router.dart                # GoRouter shell & routes configuration
└── main.dart                          # App entry point & initialization