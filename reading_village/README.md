# Reading Village

A gamified reading tracker built with Flutter and Flame. Read books to earn coins, wood, and metal. Build and upgrade structures (up to level 3), attract villagers, and grow your village. Spend gems to speed up construction.

## Required Assets

All game assets must be placed in `assets/images/`. See `assets/images/README.md` for the full list and `assets/images/AI_PROMPTS.md` for AI image generation prompts.

## Commands

```bash
# Install dependencies
flutter pub get

# List available devices
flutter devices

# Run on a connected device or emulator
flutter run

# Run on a specific device
flutter run -d <device_id>

# Build debug APK
flutter build apk --debug

# Build release APK
flutter build apk --release

# Run static analysis / lint check
flutter analyze

# Run tests
flutter test

# Check Flutter installation and environment
flutter doctor

# Clean build artifacts
flutter clean
```

## Architecture

Hexagonal + Clean Architecture:

```bash
  lib/
    main.dart                          # Composition root (DI + app entry)
    domain/                            # Pure Dart, no Flutter imports
      entities/     (10 files)         # Book, Tag, Villager, PlacedBuilding, etc.
      ports/        (5 files)          # Abstract interfaces (repositories, search, image)
      rules/        (2 files)          # VillageRules, ReadingRules
    application/                       # Use case services, pure Dart
      services/     (7 files)          # Building, Villager, Reading, Inventory, Mission, Player, Tag
    adapters/                          # Implements domain ports, bridges app ↔ infrastructure
      providers/    (3 files)          # VillageProvider, BookProvider, TagProvider (ChangeNotifiers)
      repositories/ (4 files)          # SqliteBookRepository, SqliteVillageRepository, etc.
      services/     (2 files)          # BookSearchAdapter, ImageServiceAdapter
    infrastructure/                    # Flutter UI, SQLite schema, HTTP clients
      di/
        service_locator.dart           # get_it wiring
      persistence/  (5 files)          # DatabaseHelper + 4 part files (schema only)
      ui/
        config/     (2 files)          # AppTheme, UiConstants
        screens/    (4 files)          # GameScreen, GuessAuthor, MatchCharacterRole
        widgets/
          common/   (14 files)         # Reusable widgets (cards, filters, selectors, utils)
          dialogs/  (13 files)         # All modal/dialog widgets
          sheets/   (3 files)          # Bottom sheet widgets
          popups/   (3 files)          # Overlay popup widgets
          hud/      (4 files)          # In-game HUD elements
        game/       (5 files)          # Flame VillageGame + components
```

Dependency rule:

- Domain → nothing (pure Dart)
- Application → Domain only
- Adapters → Domain + Application
- Infrastructure → Domain + Application + Adapters (UI consumes providers)
