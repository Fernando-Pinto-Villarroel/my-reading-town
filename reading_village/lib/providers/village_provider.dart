import 'dart:math';
import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import '../models/placed_building.dart';
import '../models/villager.dart';
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
  String get username => _username;
  String get townName => _townName;

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
    return _roadTiles.contains(tileKey(b.tileX + 1, b.tileY)) ||
        _roadTiles.contains(tileKey(b.tileX - 1, b.tileY)) ||
        _roadTiles.contains(tileKey(b.tileX, b.tileY + 1)) ||
        _roadTiles.contains(tileKey(b.tileX, b.tileY - 1));
  }

  /// Returns the road tile key adjacent to a building, or null.
  String? adjacentRoadTile(PlacedBuilding b) {
    for (final d in [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
      final key = tileKey(b.tileX + d.$1, b.tileY + d.$2);
      if (_roadTiles.contains(key)) return key;
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
      _placedBuildings.any((b) => b.tileX == x && b.tileY == y);

  PlacedBuilding? getBuildingAt(int x, int y) {
    try {
      return _placedBuildings.firstWhere((b) => b.tileX == x && b.tileY == y);
    } catch (_) {
      return null;
    }
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

  Future<void> addExp(int amount) async {
    _exp += amount;
    await _db.addExp(amount);
    final newLevel = GameConstants.playerLevelFromExp(_exp);
    if (newLevel != _playerLevel) {
      _playerLevel = newLevel;
      await _db.updatePlayerLevel(_playerLevel);
    }
    notifyListeners();
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
  }) async {
    if (_coins < coinCost || _gems < gemCost || _wood < woodCost || _metal < metalCost) return null;

    await _db.subtractResources(coins: coinCost, gems: gemCost, wood: woodCost, metal: metalCost);
    _coins -= coinCost;
    _gems -= gemCost;
    _wood -= woodCost;
    _metal -= metalCost;

    final building = PlacedBuilding(
      type: type,
      name: name,
      tileX: tileX,
      tileY: tileY,
      coinCost: coinCost,
      gemCost: gemCost,
      woodCost: woodCost,
      metalCost: metalCost,
      happinessBonus: happinessBonus,
      constructionStart: DateTime.now().toIso8601String(),
      constructionDurationMinutes: constructionMinutes,
      isConstructed: false,
      isFlipped: isFlipped,
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
        final expAmount = b.level > 1
            ? GameConstants.expPerBuildingUpgraded
            : GameConstants.expPerBuildingPlaced;
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
    if (building.level >= GameConstants.maxBuildingLevel) return false;

    final template = GameConstants.buildingTemplates.firstWhere(
      (t) => t['type'] == building.type,
    );

    final coinCost = GameConstants.upgradeCoinCost(template['coinCost'] as int, building.level);
    final woodCost = GameConstants.upgradeWoodCost(template['woodCost'] as int, building.level);
    final metalCost = GameConstants.upgradeMetalCost(template['metalCost'] as int, building.level);

    if (_coins < coinCost || _wood < woodCost || _metal < metalCost) return false;

    await _db.subtractResources(coins: coinCost, wood: woodCost, metal: metalCost);
    _coins -= coinCost;
    _wood -= woodCost;
    _metal -= metalCost;

    final newLevel = building.level + 1;
    final constructionMinutes = GameConstants.upgradeConstructionMinutes(
      template['constructionMinutes'] as int,
      building.level,
    );
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

    final expAmount = building.level > 1
        ? GameConstants.expPerBuildingUpgraded
        : GameConstants.expPerBuildingPlaced;
    building.isConstructed = true;
    building.constructionStart = DateTime.now().subtract(Duration(hours: 24)).toIso8601String();
    await _db.markBuildingConstructed(buildingId);
    await addExp(expAmount);

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
      final template = GameConstants.buildingTemplates.firstWhere(
        (t) => t['type'] == building.type,
      );
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
    if (hasBuildingAt(newTileX, newTileY)) return false;
    if (!isTileUnlocked(newTileX, newTileY)) return false;

    await _db.movePlacedBuilding(buildingId, newTileX, newTileY);
    _placedBuildings[idx].tileX = newTileX;
    _placedBuildings[idx].tileY = newTileY;
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
      final happiness = ((sum / _needTypes.length) * 100).round();
      _villagers[i].happiness = happiness;
      if (_villagers[i].id != null) {
        _db.updateVillagerHappiness(_villagers[i].id!, happiness);
      }
    }
  }
}
