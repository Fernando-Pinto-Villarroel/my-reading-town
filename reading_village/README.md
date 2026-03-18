# Reading Village

A gamified reading tracker built with Flutter and Flame. Read books to earn coins, wood, and metal. Build and upgrade structures (up to level 3), attract villagers, and grow your village. Spend gems to speed up construction.

## Required Assets

All game assets must be placed in `assets/images/`. See `assets/images/README.md` for the full list (26 PNG files) and `assets/images/AI_PROMPTS.md` for AI image generation prompts.

New assets needed for the level system:
- Level 2 buildings: `house_lv2.png`, `park_lv2.png`, `school_lv2.png`, `hospital_lv2.png`, `water_plant_lv2.png`, `power_plant_lv2.png`
- Level 3 buildings: `house_lv3.png`, `park_lv3.png`, `school_lv3.png`, `hospital_lv3.png`, `water_plant_lv3.png`, `power_plant_lv3.png`
- Metal resource icon: `metal.png`

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
