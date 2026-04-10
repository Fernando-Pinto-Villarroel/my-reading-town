import 'dart:math';

class VillageRules {
  static const int coinsPerPage = 4;
  static const int woodPerPage = 3;
  static const int metalPerPage = 2;
  static const int bookCompletionGemBonus = 15;
  static const int bookCompletionCoinBonus = 50;
  static const int startingCoins = 50;
  static const int startingGems = 5;
  static const int startingWood = 30;
  static const int startingMetal = 10;

  static const int maxBuildingLevel = 3;
  static const int sadHappinessThreshold = 75;

  static const int mapSize = 150;
  static const int defaultAreaSize = 25;
  static const int chunkSize = 5;
  static const int chunksPerSide = 30;

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
        return 3 * level;
      case 'park':
        return 2 * level;
      case 'restaurant':
        return 2 * level;
      case 'library':
        return 2 * level;
      case 'power_plant':
        return 3 * level;
      default:
        return 0;
    }
  }

  static const List<String> fixedNeedTypes = [
    'water_plant',
    'power_plant',
    'school',
  ];

  static const int totalNeedCount = 4;

  static List<String> rotationalNeedPool(int playerLevel) {
    if (playerLevel >= 5) return ['restaurant', 'park', 'library', 'hospital'];
    if (playerLevel >= 3) return ['restaurant', 'park', 'library'];
    return ['restaurant', 'park'];
  }

  static String rotationalNeedForVillager(int villagerId, int playerLevel) {
    final pool = rotationalNeedPool(playerLevel);
    final epoch = DateTime(2024, 1, 1);
    final daysSinceEpoch = DateTime.now().difference(epoch).inDays;
    return pool[(daysSinceEpoch + villagerId) % pool.length];
  }

  static int minLevelForBuilding(String type) {
    switch (type) {
      case 'library':
        return 3;
      case 'hospital':
        return 5;
      default:
        return 1;
    }
  }

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
      if (accumulated + needed > totalExp) {
        return needed - (totalExp - accumulated);
      }
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

  static int maxHousesForPlayerLevel(int playerLevel) => 4 + playerLevel * 2;

  static int maxBuildingsOfTypeForPlayerLevel(String type, int playerLevel) {
    switch (type) {
      case 'house':
        return 4 + playerLevel * 2;
      case 'restaurant':
      case 'park':
        return playerLevel * 2;
      case 'library':
        return playerLevel >= 3 ? playerLevel * 2 : 0;
      case 'hospital':
        return playerLevel >= 5 ? playerLevel * 2 : 0;
      case 'water_plant':
      case 'power_plant':
      case 'school':
        return 2 + playerLevel * 2;
      default:
        return 4 + playerLevel * 2;
    }
  }

  static const List<String> villagerNames = [
    'Mochi',
    'Biscuit',
    'Clover',
    'Pudding',
    'Maple',
    'Cocoa',
    'Daisy',
    'Pepper',
    'Cinnamon',
    'Sprout',
    'Peanut',
    'Waffle',
    'Olive',
    'Marshmallow',
    'Ginger',
    'Honey',
    'Cookie',
    'Truffle',
    'Basil',
    'Mango',
    'Toffee',
    'Chai',
    'Nutmeg',
    'Poppy',
    'Dango',
    'Miso',
    'Tofu',
    'Latte',
    'Mocha',
    'Berry',
  ];

  static const List<String> villagerSpecies = ['cat', 'dog', 'rabbit'];

  static const List<int> speciesUnlockLevels = [5, 10, 15, 20, 25, 30];

  static String randomVillagerName(int seed) {
    return villagerNames[seed % villagerNames.length];
  }

  static String randomVillagerSpecies(int seed) {
    return villagerSpecies[seed % villagerSpecies.length];
  }

  static const List<Map<String, dynamic>> buildingTemplates = [
    {
      'type': 'house',
      'name': 'Home',
      'coinCost': 60,
      'gemCost': 0,
      'woodCost': 40,
      'metalCost': 10,
      'happinessBonus': 10,
      'constructionMinutes': 10,
      'exp': 20
    },
    {
      'type': 'water_plant',
      'name': 'Water Tower',
      'coinCost': 50,
      'gemCost': 0,
      'woodCost': 30,
      'metalCost': 10,
      'happinessBonus': 8,
      'constructionMinutes': 40,
      'exp': 30
    },
    {
      'type': 'power_plant',
      'name': 'Power Station',
      'coinCost': 70,
      'gemCost': 0,
      'woodCost': 40,
      'metalCost': 15,
      'happinessBonus': 8,
      'constructionMinutes': 45,
      'exp': 35
    },
    {
      'type': 'school',
      'name': 'School',
      'coinCost': 80,
      'gemCost': 0,
      'woodCost': 20,
      'metalCost': 30,
      'happinessBonus': 10,
      'constructionMinutes': 90,
      'exp': 40
    },
    {
      'type': 'restaurant',
      'name': 'Restaurant',
      'coinCost': 90,
      'gemCost': 0,
      'woodCost': 30,
      'metalCost': 50,
      'happinessBonus': 10,
      'constructionMinutes': 120,
      'exp': 50
    },
    {
      'type': 'park',
      'name': 'Park',
      'coinCost': 100,
      'gemCost': 0,
      'woodCost': 60,
      'metalCost': 20,
      'happinessBonus': 15,
      'constructionMinutes': 120,
      'exp': 60
    },
    {
      'type': 'library',
      'name': 'Library',
      'coinCost': 110,
      'gemCost': 0,
      'woodCost': 70,
      'metalCost': 25,
      'happinessBonus': 12,
      'constructionMinutes': 150,
      'exp': 70
    },
    {
      'type': 'hospital',
      'name': 'Hospital',
      'coinCost': 120,
      'gemCost': 0,
      'woodCost': 50,
      'metalCost': 40,
      'happinessBonus': 12,
      'constructionMinutes': 180,
      'exp': 75
    },
  ];

  static const List<Map<String, dynamic>> decorationTemplates = [
    {
      'type': 'bulletin_board',
      'name': 'Bulletin Board',
      'coinCost': 60,
      'gemCost': 0,
      'woodCost': 50,
      'metalCost': 20,
      'happinessBonus': 0,
      'constructionMinutes': 10,
      'exp': 7
    },
    {
      'type': 'flower_garden',
      'name': 'Flower Garden',
      'coinCost': 80,
      'gemCost': 0,
      'woodCost': 40,
      'metalCost': 0,
      'happinessBonus': 0,
      'constructionMinutes': 20,
      'exp': 8
    },
    {
      'type': 'lamp_post',
      'name': 'Lamp Post',
      'coinCost': 50,
      'gemCost': 0,
      'woodCost': 0,
      'metalCost': 75,
      'happinessBonus': 0,
      'constructionMinutes': 15,
      'exp': 10
    },
    {
      'type': 'reading_bench',
      'name': 'Reading Bench',
      'coinCost': 120,
      'gemCost': 20,
      'woodCost': 80,
      'metalCost': 0,
      'happinessBonus': 0,
      'constructionMinutes': 25,
      'exp': 12
    },
    {
      'type': 'water_font',
      'name': 'Water Font',
      'coinCost': 150,
      'gemCost': 0,
      'woodCost': 0,
      'metalCost': 65,
      'happinessBonus': 0,
      'constructionMinutes': 30,
      'exp': 15
    },
    {
      'type': 'wishing_well',
      'name': 'Wishing Well',
      'coinCost': 200,
      'gemCost': 0,
      'woodCost': 0,
      'metalCost': 120,
      'happinessBonus': 0,
      'constructionMinutes': 45,
      'exp': 20
    },
    {
      'type': 'cat_colon_statue',
      'name': 'Villager Statue',
      'coinCost': 300,
      'gemCost': 10,
      'woodCost': 0,
      'metalCost': 200,
      'happinessBonus': 0,
      'constructionMinutes': 60,
      'exp': 25
    },
    {
      'type': 'book_stack_monument',
      'name': 'Book Stack Monument',
      'coinCost': 400,
      'gemCost': 30,
      'woodCost': 100,
      'metalCost': 0,
      'happinessBonus': 0,
      'constructionMinutes': 90,
      'exp': 35
    },
  ];

  static const List<Map<String, dynamic>> tileTemplates = [
    {
      'type': 'grass',
      'name': 'Grass',
      'coinCost': 0,
      'gemCost': 0,
      'woodCost': 0,
      'metalCost': 0
    },
    {
      'type': 'road',
      'name': 'Road',
      'coinCost': 0,
      'gemCost': 0,
      'woodCost': 0,
      'metalCost': 0
    },
    {
      'type': 'sea',
      'name': 'Water',
      'coinCost': 0,
      'gemCost': 0,
      'woodCost': 0,
      'metalCost': 0
    },
    {
      'type': 'sand',
      'name': 'Sand',
      'coinCost': 0,
      'gemCost': 0,
      'woodCost': 0,
      'metalCost': 0
    },
    {
      'type': 'rock',
      'name': 'Rock',
      'coinCost': 0,
      'gemCost': 0,
      'woodCost': 0,
      'metalCost': 0
    },
  ];

  static const Set<String> decorationTypes = {
    'water_font',
    'lamp_post',
    'cat_colon_statue',
    'bulletin_board',
    'flower_garden',
    'reading_bench',
    'book_stack_monument',
    'wishing_well',
  };
  static const Set<String> tileTypes = {'grass', 'road', 'sea', 'sand', 'rock'};
  static const Set<String> specialTileTypes = {'sea', 'sand', 'rock'};

  static bool isDecorationType(String type) => decorationTypes.contains(type);
  static bool isTileType(String type) => tileTypes.contains(type);

  static int buildingTileWidth(String type) {
    if (isDecorationType(type)) return 1;
    return 2;
  }

  static int buildingTileHeight(String type) {
    if (isDecorationType(type)) return 1;
    return 2;
  }

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
