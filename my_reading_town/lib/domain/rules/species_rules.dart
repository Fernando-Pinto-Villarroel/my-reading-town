import 'dart:math';

enum VillagerRarity { common, rare, extraordinary, legendary, godly }

class VillagerSpeciesData {
  final String id;
  final VillagerRarity rarity;
  final String unlockType;
  final int? unlockLevel;
  final double? realPrice;
  final String nameKey;
  final String descriptionKey;

  const VillagerSpeciesData({
    required this.id,
    required this.rarity,
    required this.unlockType,
    this.unlockLevel,
    this.realPrice,
    required this.nameKey,
    required this.descriptionKey,
  });
}

class SpeciesRules {
  static const double speciesBonusProbability = 0.005;
  static const int duplicateSpeciesGemCompensation = 20;

  static const List<VillagerSpeciesData> allSpecies = [
    VillagerSpeciesData(
      id: 'cat', rarity: VillagerRarity.common, unlockType: 'starter',
      nameKey: 'species_cat', descriptionKey: 'species_desc_cat',
    ),
    VillagerSpeciesData(
      id: 'dog', rarity: VillagerRarity.common, unlockType: 'starter',
      nameKey: 'species_dog', descriptionKey: 'species_desc_dog',
    ),
    VillagerSpeciesData(
      id: 'rabbit', rarity: VillagerRarity.common, unlockType: 'starter',
      nameKey: 'species_rabbit', descriptionKey: 'species_desc_rabbit',
    ),
    VillagerSpeciesData(
      id: 'koala', rarity: VillagerRarity.common, unlockType: 'level',
      unlockLevel: 5, nameKey: 'species_koala', descriptionKey: 'species_desc_koala',
    ),
    VillagerSpeciesData(
      id: 'raccoon', rarity: VillagerRarity.common, unlockType: 'level',
      unlockLevel: 10, nameKey: 'species_raccoon', descriptionKey: 'species_desc_raccoon',
    ),
    VillagerSpeciesData(
      id: 'elephant', rarity: VillagerRarity.common, unlockType: 'level',
      unlockLevel: 15, nameKey: 'species_elephant', descriptionKey: 'species_desc_elephant',
    ),
    VillagerSpeciesData(
      id: 'grizzly_bear', rarity: VillagerRarity.common, unlockType: 'level',
      unlockLevel: 20, nameKey: 'species_grizzly_bear', descriptionKey: 'species_desc_grizzly_bear',
    ),
    VillagerSpeciesData(
      id: 'pig', rarity: VillagerRarity.common, unlockType: 'level',
      unlockLevel: 25, nameKey: 'species_pig', descriptionKey: 'species_desc_pig',
    ),
    VillagerSpeciesData(
      id: 'hamster', rarity: VillagerRarity.common, unlockType: 'level',
      unlockLevel: 30, nameKey: 'species_hamster', descriptionKey: 'species_desc_hamster',
    ),
    VillagerSpeciesData(
      id: 'polar_bear', rarity: VillagerRarity.rare, unlockType: 'special',
      realPrice: 1.99, nameKey: 'species_polar_bear', descriptionKey: 'species_desc_polar_bear',
    ),
    VillagerSpeciesData(
      id: 'panda_bear', rarity: VillagerRarity.extraordinary, unlockType: 'special',
      realPrice: 4.99, nameKey: 'species_panda_bear', descriptionKey: 'species_desc_panda_bear',
    ),
    VillagerSpeciesData(
      id: 'monkey', rarity: VillagerRarity.legendary, unlockType: 'special',
      realPrice: 9.99, nameKey: 'species_monkey', descriptionKey: 'species_desc_monkey',
    ),
    VillagerSpeciesData(
      id: 'lion', rarity: VillagerRarity.godly, unlockType: 'special',
      realPrice: 19.99, nameKey: 'species_lion', descriptionKey: 'species_desc_lion',
    ),
  ];

  static const List<String> starterSpecies = ['cat', 'dog', 'rabbit'];

  static VillagerSpeciesData? findById(String id) {
    try {
      return allSpecies.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  static String? speciesUnlockedAtLevel(int level) {
    for (final s in allSpecies) {
      if (s.unlockType == 'level' && s.unlockLevel == level) return s.id;
    }
    return null;
  }

  static List<VillagerSpeciesData> getByRarity(VillagerRarity rarity) =>
      allSpecies.where((s) => s.rarity == rarity).toList();

  static List<VillagerSpeciesData> getSpecialSpecies() =>
      allSpecies.where((s) => s.unlockType == 'special').toList();

  static List<VillagerSpeciesData> getAvailableForStore(List<String> unlockedIds) {
    final today = DateTime.now();
    final dayseed = today.year * 10000 + today.month * 100 + today.day;
    final result = <VillagerSpeciesData>[];
    for (final rarity in [
      VillagerRarity.rare,
      VillagerRarity.extraordinary,
      VillagerRarity.legendary,
      VillagerRarity.godly,
    ]) {
      final pool = allSpecies
          .where((s) => s.rarity == rarity && !unlockedIds.contains(s.id))
          .toList();
      if (pool.isEmpty) continue;
      final rng = Random(dayseed + rarity.index);
      pool.shuffle(rng);
      result.add(pool.first);
    }
    return result;
  }

  static List<VillagerSpeciesData> getNonCommonNonOwned(List<String> unlockedIds) {
    return allSpecies
        .where((s) => s.rarity != VillagerRarity.common && !unlockedIds.contains(s.id))
        .toList();
  }

  static VillagerSpeciesData? pickRandomSpeciesReward(
      List<String> unlockedIds, Random random) {
    final available = getNonCommonNonOwned(unlockedIds);
    if (available.isEmpty) return null;
    return available[random.nextInt(available.length)];
  }

  static bool rollSpeciesBonus(Random random) =>
      random.nextDouble() < speciesBonusProbability;

  static VillagerSpeciesData? weeklySpeciesReward() {
    final now = DateTime.now();
    final seed = now.year * 100 + _isoWeek(now);
    final rng = Random(seed);
    final pool = allSpecies.where((s) => s.rarity != VillagerRarity.common).toList();
    if (pool.isEmpty) return null;
    return pool[rng.nextInt(pool.length)];
  }

  static int _isoWeek(DateTime date) {
    final doy = date.difference(DateTime(date.year, 1, 1)).inDays + 1;
    return ((doy - date.weekday + 10) / 7).floor();
  }

  static String productIdForSpecies(String speciesId) => 'species_$speciesId';

  static String rarityKey(VillagerRarity rarity) {
    switch (rarity) {
      case VillagerRarity.common: return 'rarity_common';
      case VillagerRarity.rare: return 'rarity_rare';
      case VillagerRarity.extraordinary: return 'rarity_extraordinary';
      case VillagerRarity.legendary: return 'rarity_legendary';
      case VillagerRarity.godly: return 'rarity_godly';
    }
  }
}
