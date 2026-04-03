import 'dart:math';

class MinigameRules {
  static const Map<String, MinigameConfig> configs = {
    'guess_author': MinigameConfig(winsNeeded: 5, cooldownHours: 4),
    'match_character_role': MinigameConfig(winsNeeded: 10, cooldownHours: 5),
  };

  // Reward probabilities for completing a minigame.
  // gems: 45%, book: 25%, sandwich: 25%, hammer: 5%
  static const double _gemsThreshold = 0.45;
  static const double _bookThreshold = 0.70;
  static const double _sandwichThreshold = 0.95;
  // hammer fills the remaining 5%

  static const int gemsRewardAmount = 5;

  static String pickRewardType(Random random) {
    final roll = random.nextDouble();
    if (roll < _gemsThreshold) return 'gems';
    if (roll < _bookThreshold) return 'book';
    if (roll < _sandwichThreshold) return 'sandwich';
    return 'hammer';
  }
}

class MinigameConfig {
  final int winsNeeded;
  final int cooldownHours;

  const MinigameConfig({required this.winsNeeded, required this.cooldownHours});
}
