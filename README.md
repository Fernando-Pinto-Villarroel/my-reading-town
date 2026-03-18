<div align="center">

  <img src="reading_village/assets/images/reading_village_icon_rounded.png" alt="My Reading Town" width="220" />

  <br>

# My Reading Town

**A mobile village-building game that turns real-world reading into dopamine-driven gameplay — built with Flutter and Flame Engine.**

  <br>

![Flutter](https://img.shields.io/badge/Flutter-3.5-02569B?style=flat-square&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.5-0175C2?style=flat-square&logo=dart&logoColor=white)
![Flame](https://img.shields.io/badge/Flame-1.21-FF6D00?style=flat-square&logo=firebase&logoColor=white)
![SQLite](https://img.shields.io/badge/SQLite-Local_DB-003B57?style=flat-square&logo=sqlite&logoColor=white)
![Provider](https://img.shields.io/badge/Provider-6.1-6C63FF?style=flat-square)
![Privacy](https://img.shields.io/badge/Data-Device--Only-64748B?style=flat-square&logo=lock&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?style=flat-square&logo=android&logoColor=white)
![License](https://img.shields.io/badge/License-Community_v1.0-blue?style=flat-square)

</div>

---

## Table of Contents

- [Overview](#overview)
- [Why I Built This](#why-i-built-this)
- [Features](#features)
- [Core Gameplay Loop](#core-gameplay-loop)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Database Schema](#database-schema)
- [Getting Started](#getting-started)
- [Building for Android](#building-for-android)
- [License](#license)

---

## Overview

**My Reading Town** is a privacy-first mobile game that rewards real-world reading with in-game village-building progression. Log the pages you read, earn coins, gems, wood, and metal, then use those resources to construct and upgrade buildings in a charming 2D isometric village populated by cute animal villagers.

The game replicates the dopamine reward loops found in addictive mobile games like Clash of Clans — but redirects them toward building a healthy reading habit. All data stays on your device — no accounts, no cloud, no tracking.

---

## Why I Built This

Most people struggle to replace addictive digital habits (social media scrolling, mobile games, etc.) with positive ones like reading. The reason is simple: those apps are carefully engineered to exploit dopamine feedback loops, and reading a book can't compete on that front.

This app bridges that gap:

- _Log pages you've read and instantly receive satisfying rewards._
- _Build a village that grows with every reading session._
- _Watch cute villagers move in, express happiness, and thrive._
- _Keep everything offline — no sign-ups, no subscriptions, no data leaving your phone._

The goal is to make reading **feel as rewarding as playing a mobile game**, creating a positive habit loop that gradually replaces screen-time addictions.

---

## Features

<table>
  <thead>
    <tr>
      <th>Feature</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><strong>Reading tracker</strong></td>
      <td>Add books with title, author, and total pages — log reading sessions and track progress toward completion</td>
    </tr>
    <tr>
      <td><strong>Resource rewards</strong></td>
      <td>Earn coins, gems, wood, and metal for every page read — bonus rewards for completing books</td>
    </tr>
    <tr>
      <td><strong>Isometric village builder</strong></td>
      <td>Place and upgrade buildings on a 2D isometric tile grid with real-time Flame Engine rendering</td>
    </tr>
    <tr>
      <td><strong>Construction system</strong></td>
      <td>Buildings require real time to construct and upgrade — spend gems to speed up or wait it out</td>
    </tr>
    <tr>
      <td><strong>6 building types</strong></td>
      <td>Houses, parks, schools, hospitals, water towers, and power stations — each with 3 upgrade levels</td>
    </tr>
    <tr>
      <td><strong>Villager system</strong></td>
      <td>Cute animal villagers (cats, dogs, rabbits) move into houses, wander the village, and have mood states</td>
    </tr>
    <tr>
      <td><strong>Happiness mechanics</strong></td>
      <td>Villagers need housing, water, power, healthcare, education, and parks — missing services lower village happiness</td>
    </tr>
    <tr>
      <td><strong>Player leveling</strong></td>
      <td>Earn XP from reading, building, and upgrading — higher player levels unlock more building slots</td>
    </tr>
    <tr>
      <td><strong>Village stats</strong></td>
      <td>Track village level, resources, pages read, books completed, building count, and overall happiness</td>
    </tr>
    <tr>
      <td><strong>Map expansion</strong></td>
      <td>Expand your village territory by spending coins and gems as your settlement grows</td>
    </tr>
    <tr>
      <td><strong>Kawaii art style</strong></td>
      <td>Pastel color palette with adorable character sprites and building artwork — AI-assisted asset creation</td>
    </tr>
    <tr>
      <td><strong>Privacy by design</strong></td>
      <td>Zero network requests — everything lives exclusively on your device in a local SQLite database</td>
    </tr>
  </tbody>
</table>

---

## Core Gameplay Loop

```
Read real pages
      ↓
Log pages in app
      ↓
Earn coins, gems, wood, metal
      ↓
Build & upgrade village
      ↓
Villagers move in & become happier
      ↓
Unlock more building slots
      ↓
Read more
```

This loop mimics dopamine feedback patterns found in modern mobile games — but the trigger is real-world reading.

---

## Tech Stack

| Category         | Technology                                     |
| ---------------- | ---------------------------------------------- |
| Framework        | Flutter 3.5                                    |
| Language         | Dart 3.5                                       |
| Game Engine      | Flame 1.21                                     |
| State Management | Provider 6.1                                   |
| Database         | sqflite 2.3 (local SQLite)                     |
| Animations       | Confetti 0.7                                   |
| Icons            | Cupertino Icons + Material Icons               |
| Art Pipeline     | AI-generated sprites (Gemini + manual cleanup) |

---

## Project Structure

```
my-reading-town/
├── reading_village/
│   ├── assets/
│   │   └── images/                  # Sprites, building art, icons
│   ├── lib/
│   │   ├── config/
│   │   │   ├── app_theme.dart       # Colors and theme constants
│   │   │   └── game_constants.dart  # Game balance values
│   │   ├── data/
│   │   │   ├── database_helper.dart # SQLite init & queries
│   │   │   └── villager_favorites.dart
│   │   ├── game/
│   │   │   ├── village_game.dart    # Main Flame game class
│   │   │   └── components/          # Flame components (buildings, villagers, tiles)
│   │   ├── models/
│   │   │   ├── placed_building.dart # Building data model
│   │   │   └── villager.dart        # Villager data model
│   │   ├── providers/
│   │   │   ├── book_provider.dart   # Book & reading state
│   │   │   └── village_provider.dart# Village & resource state
│   │   ├── screens/
│   │   │   └── game_screen.dart     # Main game screen with UI overlays
│   │   └── widgets/                 # Reusable UI components
│   ├── pubspec.yaml
│   └── android/                     # Android platform files
├── tools/                           # Development utilities
├── README.md
└── CONTRIBUTORS.md
```

---

## Database Schema

The app uses a local SQLite database. All data stays on-device.

| Table              | Purpose                                                        |
| ------------------ | -------------------------------------------------------------- |
| `books`            | Book catalog (title, author, total pages, pages read, status)  |
| `reading_sessions` | Individual reading session logs (book, pages, date, rewards)   |
| `village_state`    | Village resources, level, XP, and expansion state              |
| `placed_buildings` | Building instances (type, level, position, construction state) |
| `villagers`        | Villager data (name, species, mood, assigned house)            |

---

## Getting Started

### Prerequisites

- **[Flutter SDK](https://docs.flutter.dev/get-started/install)** >= 3.5
- **Android Studio** or **VS Code** with Flutter extension
- An Android device or emulator

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/FernandoPV02/my-reading-town.git
cd my-reading-town/reading_village

# 2. Install dependencies
flutter pub get

# 3. Run on a connected device or emulator
flutter run
```

---

## Building for Android

```bash
# Build a release APK
cd reading_village
flutter build apk --release

# The APK will be at:
# build/app/outputs/flutter-apk/app-release.apk
```

---

## License

This project is licensed under the **My Reading Town Community License v1.0** — see [LICENSE.md](LICENSE.md) for details.

- Personal and non-commercial use is permitted.
- Commercial use requires prior written authorization.
- Forks must remain public and carry this same license.
- Attribution to the original author is mandatory.

---

<div align="center">
  <br>
  <sub>
    Developed by <a href="https://www.linkedin.com/in/fernando-pinto-villarroel/">Fernando Pinto Villarroel</a>
    <br>
    A personal project — not affiliated with any organization.
  </sub>
  <br><br>
</div>
