# 🎵 Paatufy

<p align="center">
  <img src="assets/images/paatufy_logo.png" alt="Paatufy Logo" width="120" height="120" style="border-radius: 50%;">
</p>

<p align="center">
  <strong>High-Quality, Ad-Free Music Streaming App for Tamil & English Music Lovers</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Hive-Storage-orange?style=for-the-badge" alt="Hive" />
  <img src="https://img.shields.io/badge/Riverpod-State%20Management-blueviolet?style=for-the-badge" alt="Riverpod" />
  <img src="https://img.shields.io/badge/Google_Fonts-Poppins-blue?style=for-the-badge" alt="Poppins Font" />
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-green?style=for-the-badge" alt="Platforms" />
</p>

---

## 📌 Overview

**Paatufy** is a modern, Spotify-inspired music streaming application built using Flutter. Designed with a sleek dark-mode aesthetic, vibrant green accents, and smooth Poppins typography, Paatufy delivers seamless background audio playback, instant Spotify playlist conversion, dynamic Tamil and English discovery feeds, auto-collaging playlist artwork, offline caching, and real-time playback controls with zero advertisements.

---

## ✨ Features

### 🎧 Audio & Playback Experience

- **Background Playback & Lockscreen Media**: System notification and lockscreen media player featuring track artwork, seek slider, and responsive playback actions using `audio_service` and `just_audio`.
- **Full Player Modal**: Interactive playback interface with animated equalizer bars, live seek progress, shuffle, repeat modes (One / All), and a sleep timer.
- **Continuous Playback & True Random Shuffle**: Seamless queue loopback when playlists end, and random track selection when initiating playback via the shuffle button.
- **Sleep Timer with Volume Fade-Out**: Configurable sleep timers that automatically fade track volume down smoothly over the final 15 seconds before pausing.
- **Persistent MiniPlayer**: Quick Previous, Play/Pause, Next, and reactive Like toggles accessible from anywhere in the app.

### 📥 Spotify Playlist Importer

- **One-Tap Public Playlist Import**: Convert any public Spotify playlist URL into an ad-free Paatufy playlist.
- **Automated High-Bitrate Track Matching**: Scrapes track metadata and automatically matches songs to high-quality audio streams.
- **Smart Filter & Badging**: Imported playlists display a dedicated Spotify indicator and are protected from accidental duplicate playlist additions.

### 📚 Library & Smart Playlist Artworks

- **Dynamic 2×2 Collage Covers**: User-created playlists automatically assemble dynamic 2×2 thumbnail collages using their contained track artworks.
- **Cumulative Runtime Calculation**: Real-time duration aggregation displaying total listening time (hours, minutes, and seconds) for albums, playlists, and liked songs.
- **Liked Songs & Saved Albums**: Local persistence powered by Hive with immediate state synchronization across all tabs.
- **Universal "Add to Playlist"**: Easily add tracks to custom playlists from Search, Albums, or the active Player.

### 🔍 Instant Live Search & Autocomplete

- **Debounced Live Search**: Real-time query matching as you type with zero UI stutter.
- **Search Suggestions & Autocomplete**: Quick-completion chips based on recent queries and search history.
- **Rich Recent Search Items**: Displays the 4 most recent search items (songs, albums, playlists, or artists) as interactive tiles with single-tap replay and entity navigation.
- **Artist Discography**: Explore complete artist profiles with their catalog of top tracks and albums.

### 🎨 Visuals, Splash & Audio Settings

- **Fluid Water Ripple Splash Screen**: Smooth droplet impact physics with propagating concentric water ripples on startup.
- **Global Poppins Typography**: Clean, modern aesthetic across all UI elements using `google_fonts`.
- **Configurable Streaming Quality**: Choose between Auto, Normal (160kbps), and High (320kbps) streaming bitrates.
- **Playback & Cache Tools**: Volume normalization, gapless playback toggles, and one-tap cache clearing.

---

## 🛠️ Tech Stack & Architecture

- **Framework**: [Flutter](https://flutter.dev/) (Dart 3.x)
- **State Management**: [Flutter Riverpod](https://riverpod.dev/)
- **Audio Engine**: [`just_audio`](https://pub.dev/packages/just_audio) & [`audio_service`](https://pub.dev/packages/audio_service)
- **Local Database**: [Hive](https://docs.hivedb.dev/) & `hive_flutter`
- **Typography**: [Google Fonts (Poppins)](https://pub.dev/packages/google_fonts)
- **Networking**: [Dio](https://pub.dev/packages/dio) with custom backend API resolvers
- **Image Caching**: [`cached_network_image`](https://pub.dev/packages/cached_network_image)
- **Navigation**: [`go_router`](https://pub.dev/packages/go_router)

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`3.x` or higher)
- Android Studio / VS Code
- Physical Android/iOS device or emulator

### Installation

1. **Clone the repository:**

   ```bash
   git clone https://github.com/madhanrajdeveloper/paatufy.git
   cd paatufy

   ```

2. **Install dependencies:**

   ```bash
   flutter pub get

   ```

3. **Generate Hive type adapters & app icons:**

   ```bash
   dart run build_runner build --delete-conflicting-outputs
   dart run flutter_launcher_icons

   ```

4. **Run the application:**
   ```bash
   flutter run
   ```

### 🔧 Permissions Setup

**Android (`android/app/src/main/AndroidManifest.xml`)**
Ensure the following permissions and service declarations are included for background playback, media keys, and network streaming:

```bash
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

 <!-- Audio Streaming & Background Service Permissions -->
 <uses-permission android:name="android.permission.INTERNET"/>
 <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
 <uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK"/>
 <uses-permission android:name="android.permission.WAKE_LOCK"/>

 <application
     android:label="Paatufy"
     android:name="${applicationName}"
     android:icon="@mipmap/ic_launcher">

     <!-- AudioService Background Engine -->
     <service
         android:name="com.ryanheise.audioservice.AudioService"
         android:foregroundServiceType="mediaPlayback"
         android:exported="true">
         <intent-filter>
             <action android:name="android.media.browse.MediaBrowserService" />
         </intent-filter>
     </service>

     <!-- Media Button Receiver for Hardware & Headset Controls -->
     <receiver
         android:name="com.ryanheise.audioservice.MediaButtonReceiver"
         android:exported="true">
         <intent-filter>
             <action android:name="android.intent.action.MEDIA_BUTTON" />
         </intent-filter>
     </receiver>

 </application>
</manifest>
```
