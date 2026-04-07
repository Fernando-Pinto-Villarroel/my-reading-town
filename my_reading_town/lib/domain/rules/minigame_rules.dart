import 'dart:math';

class MinigameRules {
  static const Map<String, MinigameConfig> configs = {
    'guess_author': MinigameConfig(winsNeeded: 5, cooldownHours: 4),
    'match_character_role': MinigameConfig(winsNeeded: 10, cooldownHours: 5),
  };

  // Reward probabilities for completing a minigame.
  // gems: 43%, book: 24%, sandwich: 23%, hammer: 7%, glasses: 3%
  static const double _gemsThreshold = 0.43;
  static const double _bookThreshold = 0.67;
  static const double _sandwichThreshold = 0.90;
  static const double _hammerThreshold = 0.97;
  // glasses fills the remaining 3%

  static const int gemsRewardAmount = 5;

  static String pickRewardType(Random random) {
    final roll = random.nextDouble();
    if (roll < _gemsThreshold) return 'gems';
    if (roll < _bookThreshold) return 'book';
    if (roll < _sandwichThreshold) return 'sandwich';
    if (roll < _hammerThreshold) return 'hammer';
    return 'glasses';
  }
}

class MinigameConfig {
  final int winsNeeded;
  final int cooldownHours;

  const MinigameConfig({required this.winsNeeded, required this.cooldownHours});
}
