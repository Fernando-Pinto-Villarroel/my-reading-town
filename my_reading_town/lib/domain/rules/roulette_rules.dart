import 'dart:math';
import 'package:my_reading_town/app_constants.dart';

class RouletteRules {
  static const int gemCostPerSpin = 20;

  static const Map<String, double> rewardWeights = {
    'coins_50': 0.20,
    'gems_5': 0.13,
    'coins_100': 0.155,
    'wood_30': 0.08,
    'sandwich': 0.09,
    'metal_15': 0.09,
    'gems_15': 0.09,
    'hammer': 0.06,
    'book': 0.07,
    'glasses': 0.03,
    'species': 0.005,
  };

  static Map<String, double> get _effectiveWeights {
    if (!AppConstants.testMode) return rewardWeights;
    final entries = rewardWeights.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final reversedValues = entries.map((e) => e.value).toList().reversed.toList();
    return {
      for (int i = 0; i < entries.length; i++) entries[i].key: reversedValues[i]
    };
  }

  static int pickWeightedIndex(Random random, List<String> rewardKeys) {
    final weights = _effectiveWeights;
    final roll = random.nextDouble();
    double cumulative = 0.0;
    for (int i = 0; i < rewardKeys.length; i++) {
      cumulative += weights[rewardKeys[i]] ?? 0.0;
      if (roll < cumulative) return i;
    }
    return rewardKeys.length - 1;
  }
}
