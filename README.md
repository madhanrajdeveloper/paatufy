# 🎵 Paatufy

<p align="center">
  <img src="assets/images/paatufy-purple.png" alt="Paatufy Logo" width="120" height="120" style="border-radius: 50%;">
</p>

<p align="center">
  <strong>High-Quality, Ad-Free Music Streaming App for Tamil & English Music Lovers</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Firebase-Backend-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase" />
  <img src="https://img.shields.io/badge/Hive-Storage-orange?style=for-the-badge" alt="Hive" />
  <img src="https://img.shields.io/badge/Riverpod-State%20Management-blueviolet?style=for-the-badge" alt="Riverpod" />
  <img src="https://img.shields.io/badge/Google_Fonts-Poppins-blue?style=for-the-badge" alt="Poppins Font" />
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-green?style=for-the-badge" alt="Platforms" />
</p>

---

## 📌 Overview

**Paatufy** is a modern, Spotify-inspired music streaming application built using Flutter. Designed with a sleek dark-mode aesthetic, vibrant green accents, and smooth Poppins typography, Paatufy delivers seamless background audio playback, instant Spotify playlist conversion, multi-account isolation, in-app auto-updates, dynamic discovery feeds, auto-collaging playlist artwork, offline caching, and real-time playback controls with zero advertisements.

---

## ✨ Features

### 🎧 Audio & Playback Experience

- **MediaSession & Lockscreen Controls**: Android 13+ native media center integration with track artwork, seek slider, and a clean 3-button playback layout (**Previous**, **Play/Pause**, and **Next**).
- **Background & Task Lifecycle Handling**: Audio streams seamlessly in the background while multitasking or locked; background processes and notifications cleanly shut down when the app is swiped away from recent apps.
- **Full Player Modal**: Interactive playback interface with animated equalizer bars, live seek progress, shuffle, repeat modes (One / All), and a sleep timer.
- **Continuous Playback & True Random Shuffle**: Seamless queue loopback when playlists end, and random track selection when initiating playback via shuffle.
- **Sleep Timer with Volume Fade-Out**: Configurable sleep timers that automatically fade track volume smoothly over the final 15 seconds before pausing.
- **Floating MiniPlayer**: Quick playback and persistent like controls with intelligent safe-area inset management across all sheets and modals.

### 📥 Spotify Playlist Importer

- **One-Tap Public Playlist Import**: Convert any public Spotify playlist URL into an ad-free Paatufy playlist.
- **Automated High-Bitrate Track Matching**: Scrapes track metadata and automatically matches songs to high-quality audio streams.
- **Smart Filter & Badging**: Imported playlists display a dedicated Spotify indicator and are protected from accidental duplicate playlist additions.

### 👥 Multi-Account & Profile Isolation

- **Seamless Account Switching**: Multi-account manager supporting instant profile switching with locally isolated playlist and history scopes.
- **Google & Email Authentication**: Firebase authentication backend with Google sign-in support and cloud-synced account profiles.
- **Listening Stats & Summary Shelf**: Aggregates total listening time, liked song counts, created playlists, and saved albums.

### 🔄 In-App OTA Updates

- **Automatic Version Checks**: Cloud-driven version checking against Firebase Firestore configuration.
- **Direct APK Installation**: Built-in update dialog and background APK download using native Android `FileProvider` package installer intents.

### 📚 Library & Smart Playlist Artworks

- **Dynamic 2×2 Collage Covers**: User-created playlists automatically assemble dynamic 2×2 thumbnail collages using their contained track artworks.
- **Cumulative Runtime Calculation**: Real-time duration aggregation displaying total listening time for albums, playlists, and liked songs.
- **Liked Songs & Saved Albums**: Local persistence powered by Hive with immediate state synchronization across all tabs.

### 🔍 Instant Live Search & Autocomplete

- **Debounced Live Search**: Real-time query matching as you type with zero UI stutter.
- **Search Suggestions & Autocomplete**: Quick-completion chips based on recent queries and search history.
- **Rich Recent Search Items**: Displays the 4 most recent search items as interactive tiles with single-tap replay and entity navigation.
- **Artist Discography**: Explore complete artist profiles with their catalog of top tracks and albums.

---

## 🛠️ Tech Stack & Architecture

- **Framework**: [Flutter](https://flutter.dev/) (Dart 3.x)
- **State Management**: [Flutter Riverpod](https://riverpod.dev/)
- **Backend & Auth**: [Firebase Core](https://firebase.google.com/), [Firebase Auth](https://firebase.google.com/products/auth), [Cloud Firestore](https://firebase.google.com/products/firestore)
- **Audio Engine**: [`just_audio`](https://pub.dev/packages/just_audio) & [`audio_service`](https://pub.dev/packages/audio_service)
- **Local Database**: [Hive](https://docs.hivedb.dev/) & `hive_flutter`
- **Typography**: [Google Fonts (Poppins)](https://pub.dev/packages/google_fonts)
- **Networking**: [Dio](https://pub.dev/packages/dio) with custom backend API resolvers
- **Image Caching**: [`cached_network_image`](https://pub.dev/packages/cached_network_image)
- **Navigation**: [`go_router`](https://pub.dev/packages/go_router)

---
