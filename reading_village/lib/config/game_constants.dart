import 'dart:math';

class GameConstants {
  static const int coinsPerPage = 3;
  static const int woodPerPage = 2;
  static const int metalPerPage = 1;
  static const int bookCompletionGemBonus = 20;
  static const int bookCompletionCoinBonus = 50;
  static const int startingCoins = 100;
  static const int startingGems = 5;
  static const int startingWood = 30;
  static const int startingMetal = 15;

  static const int maxBuildingLevel = 3;
  static const int sadHappinessThreshold = 80;

  static const int mapSize = 150;
  static const int defaultAreaSize = 25;
  static const int chunkSize = 5;
  static const int chunksPerSide = 30;
  static const double tilePixelSize = 256.0;
  static const double worldPixelSize = mapSize * tilePixelSize;

  static const double defaultZoom = 0.42;
  static const double minZoom = 0.1;
  static const double maxZoom = 3.0;
  static const double zoomStep = 0.2;

  static int get defaultChunkStart =>
      (chunksPerSide - defaultAreaSize ~/ chunkSize) ~/ 2;
  static int get defaultChunkEnd =>
      defaultChunkStart + defaultAreaSize ~/ chunkSize - 1;

  static int get defaultAreaCenterTile {
    final startTile = defaultChunkStart * chunkSize;
    final endTile = (defaultChunkEnd + 1) * chunkSize - 1;
    return (startTile + endTile) ~/ 2;
  }

  static int expansionGemCost(int expansionCount) => 5 * (expansionCount + 1);
  static int expansionCoinCost(int expansionCount) => 100 + 50 * expansionCount;

  static int villagersForLevel(int level) => level * 5;

  static int levelForVillagers(int villagerCount) =>
      max(1, (villagerCount / 5).ceil());

  static int villagersPerHouse(int houseLevel) => houseLevel;

  static int buildingCapacity(String type, int level) {
    switch (type) {
      case 'water_plant':
        return 3 * level;
      case 'hospital':
        return 2 * level;
      case 'school':
        return 4 * level;
      case 'park':
        return 3 * level;
      case 'power_plant':
        return 3 * level;
      default:
        return 0;
    }
  }

  static const int expPerPage = 2;
  /// Multiplier applied to a building's base exp when upgrading (e.g. 1.5x).
  static const double upgradeExpMultiplier = 1.5;

  static int expForLevel(int level) {
    if (level <= 1) return 0;
    return (100 * pow(1.5, level - 2)).round();
  }

  static int playerLevelFromExp(int totalExp) {
    int level = 1;
    int accumulated = 0;
    while (true) {
      final needed = expForLevel(level + 1);
      if (accumulated + needed > totalExp) break;
      accumulated += needed;
      level++;
      if (level >= 50) break;
    }
    return level;
  }

  static int expToNextLevel(int totalExp) {
    int level = 1;
    int accumulated = 0;
    while (true) {
      final needed = expForLevel(level + 1);
      if (accumulated + needed > totalExp) return needed - (totalExp - accumulated);
      accumulated += needed;
      level++;
      if (level >= 50) return 0;
    }
  }

  static double expProgressToNextLevel(int totalExp) {
    int level = 1;
    int accumulated = 0;
    while (true) {
      final needed = expForLevel(level + 1);
      if (needed == 0) return 1.0;
      if (accumulated + needed > totalExp) {
        return (totalExp - accumulated) / needed;
      }
      accumulated += needed;
      level++;
      if (level >= 50) return 1.0;
    }
  }

  static int maxHousesForPlayerLevel(int playerLevel) => playerLevel * 2;

  static int maxBuildingsOfTypeForPlayerLevel(String type, int playerLevel) {
    final maxHouses = maxHousesForPlayerLevel(playerLevel);
    final maxVillagers = maxHouses * 3;
    switch (type) {
      case 'house':
        return maxHouses;
      case 'park':
        return (maxVillagers / 3).ceil();
      case 'school':
        return (maxVillagers / 4).ceil();
      case 'hospital':
        return (maxVillagers / 2).ceil();
      case 'water_plant':
        return (maxVillagers / 3).ceil();
      case 'power_plant':
        return (maxVillagers / 3).ceil();
      default:
        return maxHouses;
    }
  }

  static const List<String> villagerNames = [
    'Mochi', 'Biscuit', 'Clover', 'Pudding', 'Maple',
    'Cocoa', 'Daisy', 'Pepper', 'Cinnamon', 'Sprout',
    'Peanut', 'Waffle', 'Olive', 'Marshmallow', 'Ginger',
    'Honey', 'Cookie', 'Truffle', 'Basil', 'Mango',
    'Toffee', 'Chai', 'Nutmeg', 'Poppy', 'Dango',
    'Miso', 'Tofu', 'Latte', 'Mocha', 'Berry',
  ];

  static const List<String> villagerSpecies = ['cat', 'dog', 'rabbit'];

  static String randomVillagerName(int seed) {
    return villagerNames[seed % villagerNames.length];
  }

  static String randomVillagerSpecies(int seed) {
    return villagerSpecies[seed % villagerSpecies.length];
  }

  static const List<Map<String, dynamic>> buildingTemplates = [
    {'type': 'house', 'name': 'Home', 'coinCost': 60, 'gemCost': 0, 'woodCost': 40, 'metalCost': 10, 'happinessBonus': 10, 'constructionMinutes': 10, 'exp': 20},
    {'type': 'park', 'name': 'Tiny Park', 'coinCost': 50, 'gemCost': 0, 'woodCost': 30, 'metalCost': 10, 'happinessBonus': 8, 'constructionMinutes': 40, 'exp': 30},
    {'type': 'school', 'name': 'Little School', 'coinCost': 100, 'gemCost': 0, 'woodCost': 60, 'metalCost': 20, 'happinessBonus': 15, 'constructionMinutes': 120, 'exp': 60},
    {'type': 'hospital', 'name': 'Clinic', 'coinCost': 120, 'gemCost': 0, 'woodCost': 50, 'metalCost': 40, 'happinessBonus': 12, 'constructionMinutes': 180, 'exp': 75},
    {'type': 'water_plant', 'name': 'Water Tower', 'coinCost': 80, 'gemCost': 0, 'woodCost': 20, 'metalCost': 30, 'happinessBonus': 10, 'constructionMinutes': 90, 'exp': 40},
    {'type': 'power_plant', 'name': 'Power Station', 'coinCost': 90, 'gemCost': 0, 'woodCost': 30, 'metalCost': 50, 'happinessBonus': 10, 'constructionMinutes': 120, 'exp': 50},
  ];

  static const List<Map<String, dynamic>> decorationTemplates = [
    {'type': 'water_font', 'name': 'Water Font', 'coinCost': 150, 'gemCost': 0, 'woodCost': 0, 'metalCost': 65, 'happinessBonus': 0, 'constructionMinutes': 30, 'exp': 15},
    {'type': 'lamp_post', 'name': 'Lamp Post', 'coinCost': 50, 'gemCost': 0, 'woodCost': 0, 'metalCost': 75, 'happinessBonus': 0, 'constructionMinutes': 15, 'exp': 10},
    {'type': 'cat_colon_statue', 'name': 'Villager Statue', 'coinCost': 300, 'gemCost': 10, 'woodCost': 0, 'metalCost': 200, 'happinessBonus': 0, 'constructionMinutes': 60, 'exp': 25},
  ];

  static const List<Map<String, dynamic>> tileTemplates = [
    {'type': 'road', 'name': 'Road', 'coinCost': 0, 'gemCost': 0, 'woodCost': 0, 'metalCost': 0},
  ];

  static const Set<String> decorationTypes = {'water_font', 'lamp_post', 'cat_colon_statue'};
  static const Set<String> tileTypes = {'road'};

  static bool isDecorationType(String type) => decorationTypes.contains(type);
  static bool isTileType(String type) => tileTypes.contains(type);

  /// Returns the tile width for a building type (most are 1x1, power_plant and water_plant are 2x2).
  static int buildingTileWidth(String type) {
    if (type == 'lamp_post') return 1;
    return 2;
  }

  /// Returns the tile height for a building type.
  static int buildingTileHeight(String type) {
    if (type == 'lamp_post') return 1;
    return 2;
  }

  /// Find a template (building or decoration) by type.
  static Map<String, dynamic>? findTemplate(String type) {
    for (final t in buildingTemplates) {
      if (t['type'] == type) return t;
    }
    for (final t in decorationTemplates) {
      if (t['type'] == type) return t;
    }
    return null;
  }

  static int upgradeCoinCost(int baseCost, int currentLevel) =>
      baseCost * (currentLevel + 1);

  static int upgradeWoodCost(int baseWoodCost, int currentLevel) =>
      baseWoodCost * (currentLevel + 1);

  static int upgradeMetalCost(int baseMetalCost, int currentLevel) =>
      baseMetalCost * (currentLevel + 1);

  static int upgradeConstructionMinutes(int baseMinutes, int currentLevel) =>
      baseMinutes * (currentLevel * 3 - 1);

  static int gemCostToSpeedUp(Duration remaining) {
    final minutes = remaining.inMinutes;
    if (minutes <= 0) return 0;
    return (minutes / 5).ceil();
  }

  static String spriteForBuilding(String type, int level) {
    if (level <= 1) return '$type.png';
    return '${type}_lv$level.png';
  }
}
