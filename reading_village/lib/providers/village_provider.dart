import 'dart:math';
import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import '../models/placed_building.dart';
import '../models/villager.dart';
import '../models/inventory_item.dart';
import '../models/mission.dart';
import '../config/game_constants.dart';

class VillageProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  List<PlacedBuilding> _placedBuildings = [];
  List<Villager> _villagers = [];
  int _coins = 0;
  int _gems = 0;
  int _wood = 0;
  int _metal = 0;
  Set<String> _roadTiles = {};
  Set<String> _unlockedChunks = {};
  int _expansionCount = 0;
  int _villageLevel = 1;
  int _exp = 0;
  int _playerLevel = 1;
  String _username = '';
  String _townName = 'My Village';

  // Inventory & powerups
  List<InventoryItem> _inventoryItems = [];
  List<ActivePowerup> _activePowerups = [];
  List<MinigameCooldown> _minigameCooldowns = [];

  // Missions
  Map<String, MissionProgress> _missionProgress = {};
  bool _bookItemUsedSinceActive = false; // Tracks if book was used while villager mission active

  /// Set when a level-up occurs; UI should read and clear via consumeLevelUp().
  int? _pendingLevelUp;

  List<PlacedBuilding> get placedBuildings => _placedBuildings;
  List<Villager> get villagers => _villagers;
  int get coins => _coins;
  int get gems => _gems;
  int get wood => _wood;
  int get metal => _metal;
  Set<String> get roadTiles => _roadTiles;
  Set<String> get unlockedChunks => _unlockedChunks;
  int get expansionCount => _expansionCount;
  int get villageLevel => _villageLevel;
  int get exp => _exp;
  int get playerLevel => _playerLevel;
  int? get pendingLevelUp => _pendingLevelUp;
  /// Returns and clears the pending level-up. Call from the UI after showing the popup.
  int? consumeLevelUp() {
    final level = _pendingLevelUp;
    _pendingLevelUp = null;
    return level;
  }
  String get username => _username;
  String get townName => _townName;

  List<InventoryItem> get inventoryItems => _inventoryItems;
  List<ActivePowerup> get activePowerups => _activePowerups;
  List<MinigameCooldown> get minigameCooldowns => _minigameCooldowns;
  Map<String, MissionProgress> get missionProgress => _missionProgress;

  // Constructor system
  static const int baseMaxConstructors = 3;

  int get maxConstructors {
    int max = baseMaxConstructors;
    for (final p in _activePowerups) {
      if (p.type == 'hammer_constructor' && p.isActive) {
        max++;
      }
    }
    return max;
  }

  int get busyConstructors {
    return _placedBuildings.where((b) => !b.isConstructed).length;
  }

  bool get canStartConstruction => busyConstructors < maxConstructors;

  // Check if sandwich speed powerup is active
  bool get isSpeedBoostActive {
    return _activePowerups.any(
      (p) => p.type == 'sandwich_speed' && p.isActive,
    );
  }

  // Get construction speed multiplier
  double get constructionSpeedMultiplier {
    return isSpeedBoostActive ? 2.0 : 1.0;
  }

  // Check if a villager has book happiness powerup
  bool villagerHasHappinessBoost(int villagerId) {
    return _activePowerups.any(
      (p) => p.type == 'book_happiness' && p.targetVillagerId == villagerId && p.isActive,
    );
  }

  // Get item quantity
  int itemQuantity(String type) {
    final item = _inventoryItems.where((i) => i.type == type).firstOrNull;
    return item?.quantity ?? 0;
  }

  // Check minigame cooldown
  bool isMinigameOnCooldown(String minigameId) {
    final cd = _minigameCooldowns.where((c) => c.minigameId == minigameId).firstOrNull;
    if (cd == null) return false;
    return cd.isOnCooldown;
  }

  Duration minigameCooldownRemaining(String minigameId) {
    final cd = _minigameCooldowns.where((c) => c.minigameId == minigameId).firstOrNull;
    if (cd == null) return Duration.zero;
    return cd.remainingCooldown;
  }

  static String tileKey(int x, int y) => '$x,$y';

  static const _needTypes = ['water_plant', 'power_plant', 'hospital', 'school', 'park'];

  int get villageHappiness {
    if (_villagers.isEmpty) return 0;
    final total = _villagers.fold<int>(0, (s, v) => s + v.happiness);
    return (total / _villagers.length).round();
  }

  List<String> get missingBuildingTypes {
    if (_villagers.isEmpty) return [];
    final totalNeeds = _villagers.length;
    final capacityByType = <String, int>{};
    for (final type in ['water_plant', 'power_plant', 'hospital', 'school', 'park']) {
      capacityByType[type] = 0;
    }
    for (var b in _placedBuildings) {
      if (!b.isConstructed || b.type == 'house') continue;
      if (!isBuildingRoadConnected(b)) continue;
      capacityByType[b.type] = (capacityByType[b.type] ?? 0) + GameConstants.buildingCapacity(b.type, b.level);
    }
    return capacityByType.entries
        .where((e) => e.value < totalNeeds)
        .map((e) => e.key)
        .toList();
  }

  /// Returns true if the building has at least one adjacent road tile.
  bool isBuildingRoadConnected(PlacedBuilding b) {
    // Check all border tiles around the building footprint
    for (int dx = 0; dx < b.tileWidth; dx++) {
      for (int dy = 0; dy < b.tileHeight; dy++) {
        final tx = b.tileX + dx;
        final ty = b.tileY + dy;
        // Check the 4 directions for each occupied tile, but only if neighbor is outside footprint
        for (final d in [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
          final nx = tx + d.$1;
          final ny = ty + d.$2;
          if (nx >= b.tileX && nx < b.tileX + b.tileWidth &&
              ny >= b.tileY && ny < b.tileY + b.tileHeight) continue;
          if (_roadTiles.contains(tileKey(nx, ny))) return true;
        }
      }
    }
    return false;
  }

  /// Returns the road tile key adjacent to a building, or null.
  String? adjacentRoadTile(PlacedBuilding b) {
    for (int dx = 0; dx < b.tileWidth; dx++) {
      for (int dy = 0; dy < b.tileHeight; dy++) {
        final tx = b.tileX + dx;
        final ty = b.tileY + dy;
        for (final d in [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
          final nx = tx + d.$1;
          final ny = ty + d.$2;
          if (nx >= b.tileX && nx < b.tileX + b.tileWidth &&
              ny >= b.tileY && ny < b.tileY + b.tileHeight) continue;
          final key = tileKey(nx, ny);
          if (_roadTiles.contains(key)) return key;
        }
      }
    }
    return null;
  }

  /// Map from houseId to a road tile key adjacent to that house.
  Map<int, String> get houseAdjacentRoadTiles {
    final result = <int, String>{};
    for (var b in _placedBuildings) {
      if (b.type == 'house' && b.isConstructed && b.id != null) {
        final road = adjacentRoadTile(b);
        if (road != null) result[b.id!] = road;
      }
    }
    return result;
  }

  bool isTileUnlocked(int tileX, int tileY) {
    final chunkX = tileX ~/ GameConstants.chunkSize;
    final chunkY = tileY ~/ GameConstants.chunkSize;
    return _unlockedChunks.contains(tileKey(chunkX, chunkY));
  }

  bool isRoadTile(int x, int y) => _roadTiles.contains(tileKey(x, y));

  bool hasBuildingAt(int x, int y) =>
      _placedBuildings.any((b) => b.occupiesTile(x, y));

  PlacedBuilding? getBuildingAt(int x, int y) {
    try {
      return _placedBuildings.firstWhere((b) => b.occupiesTile(x, y));
    } catch (_) {
      return null;
    }
  }

  /// Check if placing a building of given dimensions at (x,y) would overlap any existing building.
  bool canPlaceBuildingAtArea(int x, int y, int width, int height) {
    for (int dx = 0; dx < width; dx++) {
      for (int dy = 0; dy < height; dy++) {
        if (hasBuildingAt(x + dx, y + dy)) return false;
        if (isRoadTile(x + dx, y + dy)) return false;
        if (!isTileUnlocked(x + dx, y + dy)) return false;
      }
    }
    return true;
  }

  /// Try all possible top-left positions where the tapped tile (tapX, tapY) is
  /// within the building footprint (width x height). Returns the first valid
  /// top-left corner, or null if none works.
  ({int x, int y})? findValidPlacement(int tapX, int tapY, int width, int height) {
    for (int dy = 0; dy < height; dy++) {
      for (int dx = 0; dx < width; dx++) {
        final originX = tapX - dx;
        final originY = tapY - dy;
        if (canPlaceBuildingAtArea(originX, originY, width, height)) {
          return (x: originX, y: originY);
        }
      }
    }
    return null;
  }

  bool isChunkAdjacentToUnlocked(int chunkX, int chunkY) {
    if (_unlockedChunks.contains(tileKey(chunkX, chunkY))) return false;
    if (chunkX < 0 || chunkX >= GameConstants.chunksPerSide) return false;
    if (chunkY < 0 || chunkY >= GameConstants.chunksPerSide) return false;
    return _unlockedChunks.contains(tileKey(chunkX - 1, chunkY)) ||
        _unlockedChunks.contains(tileKey(chunkX + 1, chunkY)) ||
        _unlockedChunks.contains(tileKey(chunkX, chunkY - 1)) ||
        _unlockedChunks.contains(tileKey(chunkX, chunkY + 1));
  }

  int get _totalHouseCapacity {
    int total = 0;
    for (var b in _placedBuildings) {
      if (b.type == 'house' && b.isConstructed && isBuildingRoadConnected(b)) {
        total += GameConstants.villagersPerHouse(b.level);
      }
    }
    return total;
  }

  int buildingCountOfType(String type) =>
      _placedBuildings.where((b) => b.type == type).length;

  bool canPlaceBuildingType(String type) {
    final maxAllowed = GameConstants.maxBuildingsOfTypeForPlayerLevel(type, _playerLevel);
    return buildingCountOfType(type) < maxAllowed;
  }

  List<Villager> villagersInHouse(int houseId) =>
      _villagers.where((v) => v.houseId == houseId).toList();

  Future<void> loadData() async {
    final placedMaps = await _db.getPlacedBuildings();
    _placedBuildings = placedMaps.map((m) => PlacedBuilding.fromMap(m)).toList();

    final villagerMaps = await _db.getVillagers();
    _villagers = villagerMaps.map((m) => Villager.fromMap(m)).toList();

    final resources = await _db.getResources();
    _coins = resources['coins'] as int? ?? 0;
    _gems = resources['gems'] as int? ?? 0;
    _wood = resources['wood'] as int? ?? 0;
    _metal = resources['metal'] as int? ?? 0;

    final roadMaps = await _db.getRoadTiles();
    _roadTiles = roadMaps.map((m) => tileKey(m['tile_x'] as int, m['tile_y'] as int)).toSet();

    final chunkMaps = await _db.getUnlockedChunks();
    _unlockedChunks = chunkMaps
        .map((m) => tileKey(m['chunk_x'] as int, m['chunk_y'] as int))
        .toSet();

    final gameState = await _db.getGameState();
    _expansionCount = gameState['expansion_count'] as int;
    _villageLevel = gameState['village_level'] as int;
    _exp = gameState['exp'] as int;
    _playerLevel = gameState['player_level'] as int;
    _username = gameState['username'] as String;
    _townName = gameState['town_name'] as String;

    // Load inventory, powerups, cooldowns
    final invMaps = await _db.getInventoryItems();
    _inventoryItems = invMaps.map((m) => InventoryItem.fromMap(m)).toList();

    await _db.deleteExpiredPowerups();
    final powerupMaps = await _db.getActivePowerups();
    _activePowerups = powerupMaps.map((m) => ActivePowerup.fromMap(m)).toList();

    final cdMaps = await _db.getMinigameCooldowns();
    _minigameCooldowns = cdMaps.map((m) => MinigameCooldown.fromMap(m)).toList();

    // Load mission progress
    final missionMaps = await _db.getMissionProgress();
    _missionProgress = {
      for (final m in missionMaps)
        m['mission_id'] as String: MissionProgress.fromMap(m),
    };

    await _reconcileVillagers();
    _updateVillagerHappiness();
    notifyListeners();
  }

  Future<void> refreshResources() async {
    final resources = await _db.getResources();
    _coins = resources['coins'] as int? ?? 0;
    _gems = resources['gems'] as int? ?? 0;
    _wood = resources['wood'] as int? ?? 0;
    _metal = resources['metal'] as int? ?? 0;
    notifyListeners();
  }

  Future<void> _reconcileVillagers() async {
    final capacity = _totalHouseCapacity;
    final random = Random();
    final houses = _placedBuildings.where((b) => b.type == 'house' && b.isConstructed && isBuildingRoadConnected(b)).toList();

    while (_villagers.length < capacity) {
      PlacedBuilding? targetHouse;
      for (var house in houses) {
        final cap = GameConstants.villagersPerHouse(house.level);
        final current = _villagers.where((v) => v.houseId == house.id).length;
        if (current < cap) {
          targetHouse = house;
          break;
        }
      }
      if (targetHouse == null) break;

      final seed = random.nextInt(10000);
      final name = GameConstants.randomVillagerName(seed);
      final species = GameConstants.randomVillagerSpecies(seed ~/ 3);
      final id = await _db.insertVillager(name, species, targetHouse.id!);
      _villagers.add(Villager(id: id, name: name, species: species, happiness: 50, houseId: targetHouse.id!));
    }
    _villageLevel = GameConstants.levelForVillagers(_villagers.length);
    await _db.updateVillageLevel(_villageLevel);
  }

  /// Adds exp and returns the new level if leveled up, or null if no level change.
  Future<int?> addExp(int amount) async {
    _exp += amount;
    await _db.addExp(amount);
    final newLevel = GameConstants.playerLevelFromExp(_exp);
    int? leveledUpTo;
    if (newLevel != _playerLevel) {
      final oldLevel = _playerLevel;
      _playerLevel = newLevel;
      await _db.updatePlayerLevel(_playerLevel);
      // Grant 3 gems per level gained
      final levelsGained = newLevel - oldLevel;
      final gemReward = 3 * levelsGained;
      _gems += gemReward;
      await _db.addResources(gems: gemReward);
      leveledUpTo = newLevel;
      _pendingLevelUp = newLevel;
    }
    notifyListeners();
    return leveledUpTo;
  }

  Future<void> renameVillager(int villagerId, String newName) async {
    final idx = _villagers.indexWhere((v) => v.id == villagerId);
    if (idx == -1) return;
    _villagers[idx].name = newName;
    await _db.renameVillager(villagerId, newName);
    notifyListeners();
  }

  Future<void> updateUsername(String name) async {
    _username = name;
    await _db.updateUsername(name);
    notifyListeners();
  }

  Future<void> updateTownName(String name) async {
    _townName = name;
    await _db.updateTownName(name);
    notifyListeners();
  }

  Future<PlacedBuilding?> placeBuilding({
    required String type,
    required String name,
    required int tileX,
    required int tileY,
    required int coinCost,
    required int gemCost,
    required int woodCost,
    required int metalCost,
    required int happinessBonus,
    required int constructionMinutes,
    bool isFlipped = false,
    int tileWidth = 1,
    int tileHeight = 1,
    bool isDecoration = false,
  }) async {
    if (_coins < coinCost || _gems < gemCost || _wood < woodCost || _metal < metalCost) return null;
    if (!canStartConstruction) return null;

    await _db.subtractResources(coins: coinCost, gems: gemCost, wood: woodCost, metal: metalCost);
    _coins -= coinCost;
    _gems -= gemCost;
    _wood -= woodCost;
    _metal -= metalCost;

    final adjustedMinutes = (constructionMinutes / constructionSpeedMultiplier).round();

    final building = PlacedBuilding(
      type: type,
      name: name,
      tileX: tileX,
      tileY: tileY,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      coinCost: coinCost,
      gemCost: gemCost,
      woodCost: woodCost,
      metalCost: metalCost,
      happinessBonus: happinessBonus,
      constructionStart: DateTime.now().toIso8601String(),
      constructionDurationMinutes: adjustedMinutes,
      isConstructed: false,
      isFlipped: isFlipped,
      isDecoration: isDecoration,
    );

    final id = await _db.insertPlacedBuilding(building.toMap());
    final saved = building.copyWith(id: id);
    _placedBuildings.add(saved);

    notifyListeners();
    return saved;
  }

  Future<List<PlacedBuilding>> checkAndCompleteConstructions() async {
    List<PlacedBuilding> completed = [];
    for (int i = 0; i < _placedBuildings.length; i++) {
      final b = _placedBuildings[i];
      if (!b.isConstructed && b.isConstructionComplete) {
        final template = GameConstants.findTemplate(b.type);
        final baseExp = template?['exp'] as int? ?? 20;
        final expAmount = b.level > 1
            ? (baseExp * GameConstants.upgradeExpMultiplier).round()
            : baseExp;
        b.isConstructed = true;
        await _db.markBuildingConstructed(b.id!);
        await addExp(expAmount);
        completed.add(b);
      }
    }
    if (completed.isNotEmpty) {
      await _reconcileVillagers();
      _updateVillagerHappiness();
      notifyListeners();
    }
    return completed;
  }

  Future<bool> upgradeBuilding(int buildingId) async {
    final idx = _placedBuildings.indexWhere((b) => b.id == buildingId);
    if (idx == -1) return false;

    final building = _placedBuildings[idx];
    if (!building.isConstructed) return false;
    if (building.isDecoration) return false;
    if (building.level >= GameConstants.maxBuildingLevel) return false;
    if (!canStartConstruction) return false;

    final template = GameConstants.findTemplate(building.type);
    if (template == null) return false;

    final coinCost = GameConstants.upgradeCoinCost(template['coinCost'] as int, building.level);
    final woodCost = GameConstants.upgradeWoodCost(template['woodCost'] as int, building.level);
    final metalCost = GameConstants.upgradeMetalCost(template['metalCost'] as int, building.level);

    if (_coins < coinCost || _wood < woodCost || _metal < metalCost) return false;

    await _db.subtractResources(coins: coinCost, wood: woodCost, metal: metalCost);
    _coins -= coinCost;
    _wood -= woodCost;
    _metal -= metalCost;

    final newLevel = building.level + 1;
    final baseConstructionMinutes = GameConstants.upgradeConstructionMinutes(
      template['constructionMinutes'] as int,
      building.level,
    );
    final constructionMinutes = (baseConstructionMinutes / constructionSpeedMultiplier).round();
    final constructionStart = DateTime.now().toIso8601String();

    await _db.upgradePlacedBuilding(buildingId, newLevel, constructionStart, constructionMinutes);

    _placedBuildings[idx].level = newLevel;
    _placedBuildings[idx].isConstructed = false;
    _placedBuildings[idx].constructionStart = constructionStart;
    _placedBuildings[idx].constructionDurationMinutes = constructionMinutes;

    notifyListeners();
    return true;
  }

  Future<bool> speedUpConstruction(int buildingId) async {
    final idx = _placedBuildings.indexWhere((b) => b.id == buildingId);
    if (idx == -1) return false;

    final building = _placedBuildings[idx];
    if (building.isConstructed) return false;

    final remaining = building.remainingConstructionTime;
    final gemCost = GameConstants.gemCostToSpeedUp(remaining);
    if (gemCost <= 0) return false;
    if (_gems < gemCost) return false;

    await _db.subtractResources(gems: gemCost);
    _gems -= gemCost;

    final template = GameConstants.findTemplate(building.type);
    final baseExp = template?['exp'] as int? ?? 20;
    final expAmount = building.level > 1
        ? (baseExp * GameConstants.upgradeExpMultiplier).round()
        : baseExp;
    building.isConstructed = true;
    building.constructionStart = DateTime.now().subtract(Duration(hours: 24)).toIso8601String();
    await _db.markBuildingConstructed(buildingId);
    await addExp(expAmount);

    // Reload buildings & villagers from DB to ensure consistent state
    final placedMaps = await _db.getPlacedBuildings();
    _placedBuildings = placedMaps.map((m) => PlacedBuilding.fromMap(m)).toList();
    final villagerMaps = await _db.getVillagers();
    _villagers = villagerMaps.map((m) => Villager.fromMap(m)).toList();

    await _reconcileVillagers();
    _updateVillagerHappiness();
    notifyListeners();
    return true;
  }

  Future<bool> cancelConstruction(int buildingId) async {
    final idx = _placedBuildings.indexWhere((b) => b.id == buildingId);
    if (idx == -1) return false;

    final building = _placedBuildings[idx];
    if (building.isConstructed) return false;

    final isUpgrade = building.level > 1;

    if (isUpgrade) {
      final previousLevel = building.level - 1;
      final template = GameConstants.findTemplate(building.type);
      if (template == null) return false;
      final refundCoins = GameConstants.upgradeCoinCost(template['coinCost'] as int, previousLevel);
      final refundWood = GameConstants.upgradeWoodCost(template['woodCost'] as int, previousLevel);
      final refundMetal = GameConstants.upgradeMetalCost(template['metalCost'] as int, previousLevel);

      await _db.addResources(coins: refundCoins, wood: refundWood, metal: refundMetal);
      _coins += refundCoins;
      _wood += refundWood;
      _metal += refundMetal;

      final baseMinutes = template['constructionMinutes'] as int;
      await _db.revertBuildingUpgrade(buildingId, previousLevel, baseMinutes);
      _placedBuildings[idx].level = previousLevel;
      _placedBuildings[idx].isConstructed = true;
      _placedBuildings[idx].constructionStart = null;
      _placedBuildings[idx].constructionDurationMinutes = baseMinutes;
    } else {
      await _db.addResources(
        coins: building.coinCost,
        gems: building.gemCost,
        wood: building.woodCost,
        metal: building.metalCost,
      );
      _coins += building.coinCost;
      _gems += building.gemCost;
      _wood += building.woodCost;
      _metal += building.metalCost;

      await _db.deletePlacedBuilding(buildingId);
      _placedBuildings.removeAt(idx);
    }

    await _reconcileVillagers();
    _updateVillagerHappiness();
    notifyListeners();
    return true;
  }

  Future<bool> moveBuilding(int buildingId, int newTileX, int newTileY) async {
    final idx = _placedBuildings.indexWhere((b) => b.id == buildingId);
    if (idx == -1) return false;
    final building = _placedBuildings[idx];

    // Temporarily remove building from collision checks
    final oldX = building.tileX;
    final oldY = building.tileY;
    building.tileX = -999;
    building.tileY = -999;

    // Try smart placement: find valid top-left corner near tapped tile
    final placement = findValidPlacement(newTileX, newTileY, building.tileWidth, building.tileHeight);

    if (placement == null) {
      building.tileX = oldX;
      building.tileY = oldY;
      return false;
    }

    building.tileX = placement.x;
    building.tileY = placement.y;
    await _db.movePlacedBuilding(buildingId, placement.x, placement.y);
    notifyListeners();
    return true;
  }

  Future<void> flipBuilding(int buildingId) async {
    final idx = _placedBuildings.indexWhere((b) => b.id == buildingId);
    if (idx == -1) return;
    _placedBuildings[idx].isFlipped = !_placedBuildings[idx].isFlipped;
    await _db.flipBuilding(buildingId, _placedBuildings[idx].isFlipped);
    notifyListeners();
  }

  Future<void> toggleRoad(int x, int y) async {
    final key = tileKey(x, y);
    if (_roadTiles.contains(key)) {
      _roadTiles.remove(key);
      await _db.deleteRoadTile(x, y);
    } else {
      _roadTiles.add(key);
      await _db.insertRoadTile(x, y);
    }
    notifyListeners();
  }

  Future<bool> expandTerritoryWithGems(int chunkX, int chunkY) async {
    if (!isChunkAdjacentToUnlocked(chunkX, chunkY)) return false;
    final cost = GameConstants.expansionGemCost(_expansionCount);
    if (_gems < cost) return false;
    await _db.subtractResources(gems: cost);
    _gems -= cost;
    return await _finalizeExpansion(chunkX, chunkY);
  }

  Future<bool> expandTerritoryWithCoins(int chunkX, int chunkY) async {
    if (!isChunkAdjacentToUnlocked(chunkX, chunkY)) return false;
    final cost = GameConstants.expansionCoinCost(_expansionCount);
    if (_coins < cost) return false;
    await _db.subtractResources(coins: cost);
    _coins -= cost;
    return await _finalizeExpansion(chunkX, chunkY);
  }

  Future<bool> _finalizeExpansion(int chunkX, int chunkY) async {
    await _db.insertUnlockedChunk(chunkX, chunkY);
    _unlockedChunks.add(tileKey(chunkX, chunkY));
    await _db.incrementExpansionCount();
    _expansionCount++;
    notifyListeners();
    return true;
  }

  /// Returns the need types not covered for a specific villager.
  List<String> missingNeedsForVillager(Villager villager) {
    final idx = _villagers.indexOf(villager);
    if (idx == -1) return [];

    final capacityByType = <String, int>{};
    for (final type in _needTypes) {
      int cap = 0;
      for (var b in _placedBuildings) {
        if (!b.isConstructed || b.type != type) continue;
        if (!isBuildingRoadConnected(b)) continue;
        cap += GameConstants.buildingCapacity(b.type, b.level);
      }
      capacityByType[type] = cap;
    }

    return _needTypes.where((type) => idx >= (capacityByType[type] ?? 0)).toList();
  }

  void _updateVillagerHappiness() {
    if (_villagers.isEmpty) return;

    // Compute capacity for each need type (only road-connected buildings count)
    final capacityByType = <String, int>{};
    for (final type in _needTypes) {
      int cap = 0;
      for (var b in _placedBuildings) {
        if (!b.isConstructed || b.type != type) continue;
        if (!isBuildingRoadConnected(b)) continue;
        cap += GameConstants.buildingCapacity(b.type, b.level);
      }
      capacityByType[type] = cap;
    }

    // Each villager is ranked by index. The first N villagers (up to capacity)
    // have their need covered for that type. This means if you have capacity
    // for 3 but 5 villagers, villagers 4 and 5 miss that need.
    for (int i = 0; i < _villagers.length; i++) {
      double sum = 0;
      for (final type in _needTypes) {
        final cap = capacityByType[type] ?? 0;
        if (i < cap) {
          sum += 1.0; // this villager's need is covered
        }
      }
      int happiness = ((sum / _needTypes.length) * 100).round();

      // Book happiness powerup overrides to 100%
      if (_villagers[i].id != null && villagerHasHappinessBoost(_villagers[i].id!)) {
        happiness = 100;
      }

      _villagers[i].happiness = happiness;
      if (_villagers[i].id != null) {
        _db.updateVillagerHappiness(_villagers[i].id!, happiness);
      }
    }
  }

  // --- Inventory Management ---

  Future<void> addItemToInventory(String type, {int amount = 1}) async {
    await _db.addInventoryItem(type, amount: amount);
    final idx = _inventoryItems.indexWhere((i) => i.type == type);
    if (idx != -1) {
      _inventoryItems[idx].quantity += amount;
    }
    notifyListeners();
  }

  Future<bool> useBookItem(int villagerId) async {
    if (itemQuantity('book') <= 0) return false;
    if (villagerHasHappinessBoost(villagerId)) return false;
    await _db.removeInventoryItem('book');
    final idx = _inventoryItems.indexWhere((i) => i.type == 'book');
    if (idx != -1) _inventoryItems[idx].quantity--;

    final powerup = ActivePowerup(
      type: 'book_happiness',
      targetVillagerId: villagerId,
      activatedAt: DateTime.now().toIso8601String(),
      durationHours: 24,
    );
    final id = await _db.insertPowerup(powerup.toMap());
    _activePowerups.add(ActivePowerup(
      id: id,
      type: powerup.type,
      targetVillagerId: powerup.targetVillagerId,
      activatedAt: powerup.activatedAt,
      durationHours: powerup.durationHours,
    ));

    _updateVillagerHappiness();
    notifyBookItemUsed();
    notifyListeners();
    return true;
  }

  Future<bool> useSandwichItem() async {
    if (itemQuantity('sandwich') <= 0) return false;
    if (isSpeedBoostActive) return false;
    await _db.removeInventoryItem('sandwich');
    final idx = _inventoryItems.indexWhere((i) => i.type == 'sandwich');
    if (idx != -1) _inventoryItems[idx].quantity--;

    final powerup = ActivePowerup(
      type: 'sandwich_speed',
      activatedAt: DateTime.now().toIso8601String(),
      durationHours: 1,
    );
    final id = await _db.insertPowerup(powerup.toMap());
    _activePowerups.add(ActivePowerup(
      id: id,
      type: powerup.type,
      activatedAt: powerup.activatedAt,
      durationHours: powerup.durationHours,
    ));

    notifyListeners();
    return true;
  }

  bool get isHammerActive {
    return _activePowerups.any(
      (p) => p.type == 'hammer_constructor' && p.isActive,
    );
  }

  Future<bool> useHammerItem() async {
    if (itemQuantity('hammer') <= 0) return false;
    if (isHammerActive) return false;
    await _db.removeInventoryItem('hammer');
    final idx = _inventoryItems.indexWhere((i) => i.type == 'hammer');
    if (idx != -1) _inventoryItems[idx].quantity--;

    final powerup = ActivePowerup(
      type: 'hammer_constructor',
      activatedAt: DateTime.now().toIso8601String(),
      durationHours: 24,
    );
    final id = await _db.insertPowerup(powerup.toMap());
    _activePowerups.add(ActivePowerup(
      id: id,
      type: powerup.type,
      activatedAt: powerup.activatedAt,
      durationHours: powerup.durationHours,
    ));

    notifyListeners();
    return true;
  }

  // --- Minigame Cooldowns ---

  Future<void> setMinigameCooldown(String minigameId, int cooldownHours) async {
    final cooldownEnd = DateTime.now().add(Duration(hours: cooldownHours)).toIso8601String();
    await _db.setMinigameCooldown(minigameId, cooldownEnd);
    final existing = _minigameCooldowns.indexWhere((c) => c.minigameId == minigameId);
    final cd = MinigameCooldown(minigameId: minigameId, cooldownEnd: cooldownEnd);
    if (existing != -1) {
      _minigameCooldowns[existing] = cd;
    } else {
      _minigameCooldowns.add(cd);
    }
    notifyListeners();
  }

  // --- Minigame Rewards ---

  /// Returns the reward type: 'gems', 'book', 'sandwich', 'hammer'
  Future<String> grantMinigameReward() async {
    final random = Random();
    final roll = random.nextDouble();

    String rewardType;
    if (roll < 0.45) {
      // 45% - 5 gems
      rewardType = 'gems';
      await _db.addResources(gems: 5);
      _gems += 5;
    } else if (roll < 0.70) {
      // 25% - book item
      rewardType = 'book';
      await addItemToInventory('book');
    } else if (roll < 0.95) {
      // 25% - sandwich item
      rewardType = 'sandwich';
      await addItemToInventory('sandwich');
    } else {
      // 5% - hammer item
      rewardType = 'hammer';
      await addItemToInventory('hammer');
    }

    notifyListeners();
    return rewardType;
  }

  // --- Cleanup expired powerups ---

  Future<void> cleanupExpiredPowerups() async {
    await _db.deleteExpiredPowerups();
    _activePowerups.removeWhere((p) => !p.isActive);
    _updateVillagerHappiness();
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════
  // ─── MISSIONS SYSTEM ──────────────────────────────────────
  // ═══════════════════════════════════════════════════════════

  /// Whether a branch is unlocked (dependencies satisfied).
  bool isBranchUnlocked(MissionBranch branch) {
    final deps = MissionData.branchDependencies(branch);
    for (final dep in deps) {
      if (!isBranchFullyCompleted(dep)) return false;
    }
    return true;
  }

  /// Whether all missions in a branch have been claimed.
  bool isBranchFullyCompleted(MissionBranch branch) {
    final missions = MissionData.getMissionsForBranch(branch);
    return missions.every((m) {
      final progress = _missionProgress[m.id];
      return progress != null && progress.isClaimed;
    });
  }

  /// Get the currently active (next unclaimed) mission for a branch, or null if branch is complete or locked.
  Mission? getActiveMission(MissionBranch branch) {
    if (!isBranchUnlocked(branch)) return null;
    final missions = MissionData.getMissionsForBranch(branch);
    for (final mission in missions) {
      final progress = _missionProgress[mission.id];
      if (progress == null || !progress.isClaimed) {
        return mission;
      }
    }
    return null; // Branch is fully completed
  }

  /// Get all currently active missions (one per unlocked branch).
  List<Mission> getActiveMissions() {
    final result = <Mission>[];
    for (final branch in MissionBranch.values) {
      final active = getActiveMission(branch);
      if (active != null) result.add(active);
    }
    return result;
  }

  /// Get the progress object for a mission, creating one if needed.
  MissionProgress _getOrCreateProgress(Mission mission) {
    if (!_missionProgress.containsKey(mission.id)) {
      _missionProgress[mission.id] = MissionProgress(missionId: mission.id);
    }
    return _missionProgress[mission.id]!;
  }

  /// Ensure the active mission has its activated_at set (for AM missions).
  Future<void> _ensureMissionActivated(Mission mission) async {
    final progress = _getOrCreateProgress(mission);
    if (progress.activatedAt == null) {
      progress.activatedAt = DateTime.now().toIso8601String();
      await _db.upsertMissionProgress(mission.id,
          activatedAt: progress.activatedAt);
    }
  }

  /// Check and update mission completion for all active missions.
  /// Pass totalPagesRead and completedBooks for book tracking missions.
  Future<void> checkMissions({int? totalPagesRead, int? completedBooks}) async {
    for (final branch in MissionBranch.values) {
      final mission = getActiveMission(branch);
      if (mission == null) continue;

      final progress = _getOrCreateProgress(mission);
      if (progress.isCompleted) continue;

      // Ensure activated_at is set
      await _ensureMissionActivated(mission);

      final isComplete = _checkMissionCondition(mission, progress,
          totalPagesRead: totalPagesRead, completedBooks: completedBooks);
      if (isComplete) {
        progress.isCompleted = true;
        await _db.upsertMissionProgress(mission.id, isCompleted: true);
      }
    }
    notifyListeners();
  }

  /// Check if a specific mission's conditions are met.
  bool _checkMissionCondition(Mission mission, MissionProgress progress,
      {int? totalPagesRead, int? completedBooks}) {
    switch (mission.conditionType) {
      case MissionConditionType.buyBuilding:
        // Has at least one building of the given type (constructed)
        return _placedBuildings.any(
            (b) => b.type == mission.buildingType && b.isConstructed);

      case MissionConditionType.upgradeBuilding:
        // Has at least one building of given type at or above target level (constructed)
        return _placedBuildings.any((b) =>
            b.type == mission.buildingType &&
            b.level >= (mission.targetLevel ?? 1) &&
            b.isConstructed);

      case MissionConditionType.reachBuildingCount:
        // Has N+ buildings of given type at or above target level (constructed)
        final count = _placedBuildings.where((b) =>
            b.type == mission.buildingType &&
            b.level >= (mission.targetLevel ?? 1) &&
            b.isConstructed).length;
        return count >= (mission.targetCount ?? 1);

      case MissionConditionType.villagerHappiness:
        // N villagers at 100% happiness right now
        final happyCount = _villagers.where((v) => v.happiness >= 100).length;
        return happyCount >= (mission.targetCount ?? 1);

      case MissionConditionType.villagerHappinessWithBook:
        // A happiness book was used while this mission is active
        return _bookItemUsedSinceActive;

      case MissionConditionType.villagerHappinessNatural:
        // N villagers at 100% happiness with NO book powerup active on any villager
        final hasAnyBookPowerup = _activePowerups
            .any((p) => p.type == 'book_happiness' && p.isActive);
        if (hasAnyBookPowerup) return false;
        final happyCount = _villagers.where((v) => v.happiness >= 100).length;
        return happyCount >= (mission.targetCount ?? 1);

      case MissionConditionType.totalPagesRead:
        return (totalPagesRead ?? 0) >= (mission.targetCount ?? 1);

      case MissionConditionType.booksCompleted:
        return (completedBooks ?? 0) >= (mission.targetCount ?? 1);
    }
  }

  /// Get the current progress value for a mission (for progress bar display).
  /// Returns (current, target).
  ({int current, int target}) getMissionProgressValues(Mission mission,
      {int? totalPagesRead, int? completedBooks}) {
    final target = mission.targetCount ?? 1;
    int current = 0;

    switch (mission.conditionType) {
      case MissionConditionType.buyBuilding:
        current = _placedBuildings
            .where((b) => b.type == mission.buildingType && b.isConstructed)
            .length;
        return (current: current.clamp(0, 1), target: 1);

      case MissionConditionType.upgradeBuilding:
        final maxLevel = _placedBuildings
            .where((b) => b.type == mission.buildingType && b.isConstructed)
            .fold<int>(0, (max, b) => b.level > max ? b.level : max);
        current = maxLevel;
        return (current: current.clamp(0, mission.targetLevel ?? 1),
            target: mission.targetLevel ?? 1);

      case MissionConditionType.reachBuildingCount:
        current = _placedBuildings.where((b) =>
            b.type == mission.buildingType &&
            b.level >= (mission.targetLevel ?? 1) &&
            b.isConstructed).length;
        return (current: current.clamp(0, target), target: target);

      case MissionConditionType.villagerHappiness:
        current = _villagers.where((v) => v.happiness >= 100).length;
        return (current: current.clamp(0, target), target: target);

      case MissionConditionType.villagerHappinessWithBook:
        current = _bookItemUsedSinceActive ? 1 : 0;
        return (current: current, target: 1);

      case MissionConditionType.villagerHappinessNatural:
        final hasAnyBookPowerup = _activePowerups
            .any((p) => p.type == 'book_happiness' && p.isActive);
        if (hasAnyBookPowerup) {
          current = 0;
        } else {
          current = _villagers.where((v) => v.happiness >= 100).length;
        }
        return (current: current.clamp(0, target), target: target);

      case MissionConditionType.totalPagesRead:
        current = totalPagesRead ?? 0;
        return (current: current.clamp(0, target), target: target);

      case MissionConditionType.booksCompleted:
        current = completedBooks ?? 0;
        return (current: current.clamp(0, target), target: target);
    }
  }

  /// Claim a completed mission's reward.
  Future<bool> claimMissionReward(String missionId) async {
    final mission = MissionData.getMissionById(missionId);
    if (mission == null) return false;

    final progress = _missionProgress[missionId];
    if (progress == null || !progress.isCompleted || progress.isClaimed) {
      return false;
    }

    // Grant rewards
    final reward = mission.reward;
    if (reward.exp > 0) await addExp(reward.exp);
    if (reward.coins > 0 || reward.gems > 0) {
      await _db.addResources(coins: reward.coins, gems: reward.gems);
      _coins += reward.coins;
      _gems += reward.gems;
    }

    // Mark as claimed
    progress.isClaimed = true;
    await _db.upsertMissionProgress(missionId, isClaimed: true);

    // If this was the villager book mission, reset the tracker
    if (mission.id == 'vl_book_happy') {
      _bookItemUsedSinceActive = false;
    }

    // Activate the next mission in the branch if applicable
    final nextMission = getActiveMission(mission.branch);
    if (nextMission != null) {
      await _ensureMissionActivated(nextMission);
    }

    notifyListeners();
    return true;
  }

  /// Called when a book item is used - for tracking the villager book mission.
  void notifyBookItemUsed() {
    final activeMission = getActiveMission(MissionBranch.villager);
    if (activeMission != null &&
        activeMission.conditionType == MissionConditionType.villagerHappinessWithBook) {
      _bookItemUsedSinceActive = true;
    }
  }

  /// Get how many missions are completed (but unclaimed) across all branches.
  int get unclaimedCompletedMissionCount {
    int count = 0;
    for (final branch in MissionBranch.values) {
      final mission = getActiveMission(branch);
      if (mission != null) {
        final progress = _missionProgress[mission.id];
        if (progress != null && progress.isCompleted && !progress.isClaimed) {
          count++;
        }
      }
    }
    return count;
  }
}
