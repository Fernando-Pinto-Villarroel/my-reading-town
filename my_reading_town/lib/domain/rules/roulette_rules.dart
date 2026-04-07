import 'dart:math';

class RouletteRules {
  static const int gemCostPerSpin = 20;

  static const Map<String, double> rewardWeights = {
    'coins_50':  0.17,
    'gems_5':    0.10,
    'coins_100': 0.12,
    'wood_30':   0.08,
    'sandwich':  0.09,
    'coins_300': 0.10,
    'metal_15':  0.09,
    'gems_15':   0.09,
    'hammer':    0.06,
    'book':      0.07,
    'glasses':   0.03,
  };

  static int pickWeightedIndex(Random random, List<String> rewardKeys) {
    final roll = random.nextDouble();
    double cumulative = 0.0;
    for (int i = 0; i < rewardKeys.length; i++) {
      cumulative += rewardWeights[rewardKeys[i]] ?? 0.0;
      if (roll < cumulative) return i;
    }
    return rewardKeys.length - 1;
  }
}
