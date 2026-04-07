import 'package:flutter/material.dart';
import 'package:my_reading_town/domain/entities/placed_building.dart';
import 'package:my_reading_town/domain/entities/villager.dart';
import 'package:my_reading_town/domain/entities/inventory_item.dart';
import 'package:my_reading_town/domain/entities/mission.dart';
import 'package:my_reading_town/domain/entities/mission_data.dart';
import 'package:my_reading_town/domain/ports/village_repository.dart';
import 'package:my_reading_town/application/services/building_service.dart';
import 'package:my_reading_town/application/services/villager_service.dart';
import 'package:my_reading_town/application/services/inventory_service.dart';
import 'package:my_reading_town/application/services/mission_service.dart';
import 'package:my_reading_town/application/services/player_service.dart';
import 'package:my_reading_town/domain/rules/roulette_rules.dart';
import 'package:my_reading_town/domain/rules/minigame_rules.dart';

class VillageProvider extends ChangeNotifier {
  final VillageRepository _repo;
  final BuildingService _buildingSvc;
  final VillagerService _villagerSvc;
  final InventoryService _inventorySvc;
  final MissionService _missionSvc;
  final PlayerService _playerSvc;

  VillageProvider(this._repo, this._buildingSvc, this._villagerSvc,
      this._inventorySvc, this._missionSvc, this._playerSvc);

  VillagerService get villagerService => _villagerSvc;

  List<PlacedBuilding> _placedBuildings = [];
  List<Villager> _villagers = [];
  int _coins = 0;
  int _gems = 0;
  int _wood = 0;
  int _metal = 0;
  Set<String> _roadTiles = {};
  Set<String> _unlockedChunks = {};
  int _expansionCount = 0;
  int _exp = 0;
  int _playerLevel = 1;
  String _username = '';
  String _townName = 'My Village';

  List<InventoryItem> _inventoryItems = [];
  List<ActivePowerup> _activePowerups = [];
  List<MinigameCooldown> _minigameCooldowns = [];

  Map<String, MissionProgress> _missionProgress = {};
  bool _bookItemUsedSinceActive = false;
  int? _pendingLevelUp;
  String _language = 'en';
  bool _tutorialCompleted = false;
  String? _rouletteLastFreeSpin;
  bool _hasNewBackpackItems = false;

  List<PlacedBuilding> get placedBuildings => _placedBuildings;
  List<Villager> get villagers => _villagers;
  int get coins => _coins;
  int get gems => _gems;
  int get wood => _wood;
  int get metal => _metal;
  Set<String> get roadTiles => _roadTiles;
  Set<String> get unlockedChunks => _unlockedChunks;
  int get expansionCount => _expansionCount;
  int get exp => _exp;
  int get playerLevel => _playerLevel;
  int? get pendingLevelUp => _pendingLevelUp;
  String get username => _username;
  String get townName => _townName;
  String get language => _language;
  bool get tutorialCompleted => _tutorialCompleted;
  String? get rouletteLastFreeSpin => _rouletteLastFreeSpin;

  bool get canSpinRouletteForFree {
    if (_rouletteLastFreeSpin == null) return true;
    final last = DateTime.parse(_rouletteLastFreeSpin!);
    final now = DateTime.now();
    return !(last.year == now.year && last.month == now.month && last.day == now.day);
  }

  Duration get rouletteNextFreeSpinIn {
    if (canSpinRouletteForFree) return Duration.zero;
    final last = DateTime.parse(_rouletteLastFreeSpin!);
    final nextDay = DateTime(last.year, last.month, last.day + 1);
    final remaining = nextDay.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool get hasNewBackpackItems => _hasNewBackpackItems;

  void clearNewBackpackItems() {
    if (!_hasNewBackpackItems) return;
    _hasNewBackpackItems = false;
    notifyListeners();
  }

  List<InventoryItem> get inventoryItems => _inventoryItems;
  List<ActivePowerup> get activePowerups => _activePowerups;
  List<MinigameCooldown> get minigameCooldowns => _minigameCooldowns;
  Map<String, MissionProgress> get missionProgress => _missionProgress;

  int? consumeLevelUp() {
    final level = _pendingLevelUp;
    _pendingLevelUp = null;
    return level;
  }

  int get maxConstructors => _inventorySvc.maxConstructors(_activePowerups);
  int get busyConstructors =>
      _placedBuildings.where((b) => !b.isConstructed).length;
  bool get canStartConstruction => busyConstructors < maxConstructors;
  bool get isSpeedBoostActive =>
      _inventorySvc.isSpeedBoostActive(_activePowerups);
  double get constructionSpeedMultiplier =>
      _inventorySvc.constructionSpeedMultiplier(_activePowerups);
  bool get isHammerActive => _inventorySvc.isHammerActive(_activePowerups);
  bool get isGlassesActive => _inventorySvc.isGlassesActive(_activePowerups);
  double get readingResourceMultiplier =>
      _inventorySvc.readingResourceMultiplier(_activePowerups);
  int get villageHappiness => _villagerSvc.villageHappiness(_villagers);

  bool villagerHasHappinessBoost(int villagerId) =>
      _inventorySvc.villagerHasHappinessBoost(villagerId, _activePowerups);

  int itemQuantity(String type) =>
      _inventorySvc.itemQuantity(type, _inventoryItems);

  bool isMinigameOnCooldown(String minigameId) =>
      _inventorySvc.isMinigameOnCooldown(minigameId, _minigameCooldowns);

  Duration minigameCooldownRemaining(String minigameId) =>
      _inventorySvc.minigameCooldownRemaining(minigameId, _minigameCooldowns);

  bool get hasAnyMinigameAvailable => MinigameRules.configs.keys
      .any((id) => !isMinigameOnCooldown(id));

  bool _prevMinigameAvailable = false;

  void tickCooldowns() {
    final current = hasAnyMinigameAvailable;
    if (current != _prevMinigameAvailable) {
      _prevMinigameAvailable = current;
      notifyListeners();
    }
  }

  List<String> get missingBuildingTypes => _villagerSvc.missingBuildingTypes(
      _villagers, _placedBuildings, _roadTiles);

  bool isBuildingRoadConnected(PlacedBuilding b) =>
      _buildingSvc.isBuildingRoadConnected(b, _roadTiles);

  bool isTileUnlocked(int tileX, int tileY) =>
      _buildingSvc.isTileUnlocked(tileX, tileY, _unlockedChunks);

  bool isRoadTile(int x, int y) => _buildingSvc.isRoadTile(x, y, _roadTiles);

  bool hasBuildingAt(int x, int y) =>
      _buildingSvc.hasBuildingAt(x, y, _placedBuildings);

  PlacedBuilding? getBuildingAt(int x, int y) =>
      _buildingSvc.getBuildingAt(x, y, _placedBuildings);

  bool canPlaceBuildingAtArea(int x, int y, int width, int height) =>
      _buildingSvc.canPlaceBuildingAtArea(
          x, y, width, height, _placedBuildings, _roadTiles, _unlockedChunks);

  ({int x, int y})? findValidPlacement(
          int tapX, int tapY, int width, int height) =>
      _buildingSvc.findValidPlacement(tapX, tapY, width, height,
          _placedBuildings, _roadTiles, _unlockedChunks);

  bool isChunkAdjacentToUnlocked(int chunkX, int chunkY) =>
      _buildingSvc.isChunkAdjacentToUnlocked(chunkX, chunkY, _unlockedChunks);

  int buildingCountOfType(String type) =>
      _buildingSvc.buildingCountOfType(type, _placedBuildings);

  bool canPlaceBuildingType(String type) =>
      _buildingSvc.canPlaceBuildingType(type, _playerLevel, _placedBuildings);

  List<Villager> villagersInHouse(int houseId) =>
      _villagerSvc.villagersInHouse(houseId, _villagers);

  Map<int, String> get houseAdjacentRoadTiles =>
      _buildingSvc.houseAdjacentRoadTiles(_placedBuildings, _roadTiles);

  String? adjacentRoadTile(PlacedBuilding b) =>
      _buildingSvc.adjacentRoadTile(b, _roadTiles);

  static String tileKey(int x, int y) => BuildingService.tileKey(x, y);

  List<String> missingNeedsForVillager(Villager villager) =>
      _villagerSvc.missingNeedsForVillager(
          villager, _villagers, _placedBuildings, _roadTiles);

  // --- Branch / Mission delegation ---

  bool isBranchUnlocked(MissionBranch branch) =>
      _missionSvc.isBranchUnlocked(branch, _missionProgress);
  bool isBranchFullyCompleted(MissionBranch branch) =>
      _missionSvc.isBranchFullyCompleted(branch, _missionProgress);
  Mission? getActiveMission(MissionBranch branch) =>
      _missionSvc.getActiveMission(branch, _missionProgress);
  List<Mission> getActiveMissions() =>
      _missionSvc.getActiveMissions(_missionProgress);

  int get unclaimedCompletedMissionCount =>
      _missionSvc.unclaimedCompletedMissionCount(_missionProgress);

  ({int current, int target}) getMissionProgressValues(Mission mission,
      {int? totalPagesRead, int? completedBooks}) {
    return _missionSvc.getMissionProgressValues(
      mission,
      _placedBuildings,
      _villagers,
      _activePowerups,
      _bookItemUsedSinceActive,
      totalPagesRead: totalPagesRead,
      completedBooks: completedBooks,
    );
  }

  Future<void> _crystallizeExpiredSpeedups() async {
    final expiredMaps = await _inventorySvc.getExpiredSpeedupPowerups();
    if (expiredMaps.isEmpty) return;
    for (final row in expiredMaps) {
      final boostStart = DateTime.parse(row['activated_at'] as String);
      final boostDurationHours = row['duration_hours'] as int;
      final boostEnd = boostStart.add(Duration(hours: boostDurationHours));
      for (final b in _placedBuildings) {
        if (b.isConstructed || b.constructionStart == null || b.id == null) {
          continue;
        }
        final constructStart = DateTime.parse(b.constructionStart!);
        final overlapStart =
            constructStart.isAfter(boostStart) ? constructStart : boostStart;
        if (!boostEnd.isAfter(overlapStart)) continue;
        final bonus = boostEnd.difference(overlapStart);
        final newStart = constructStart.subtract(bonus);
        b.constructionStart = newStart.toIso8601String();
        await _repo.updateConstructionStart(b.id!, b.constructionStart!);
      }
    }
  }

  // --- Data loading ---

  Future<void> loadData() async {
    final placedMaps = await _repo.getPlacedBuildings();
    _placedBuildings =
        placedMaps.map((m) => PlacedBuilding.fromMap(m)).toList();

    final villagerMaps = await _repo.getVillagers();
    _villagers = villagerMaps.map((m) => Villager.fromMap(m)).toList();

    final resources = await _repo.getResources();
    _coins = resources['coins'] as int? ?? 0;
    _gems = resources['gems'] as int? ?? 0;
    _wood = resources['wood'] as int? ?? 0;
    _metal = resources['metal'] as int? ?? 0;

    final roadMaps = await _repo.getRoadTiles();
    _roadTiles = roadMaps
        .map((m) => tileKey(m['tile_x'] as int, m['tile_y'] as int))
        .toSet();

    final chunkMaps = await _repo.getUnlockedChunks();
    _unlockedChunks = chunkMaps
        .map((m) => tileKey(m['chunk_x'] as int, m['chunk_y'] as int))
        .toSet();

    final gameState = await _repo.getGameState();
    _expansionCount = gameState['expansion_count'] as int;
    _exp = gameState['exp'] as int;
    _playerLevel = gameState['player_level'] as int;
    _username = gameState['username'] as String;
    _townName = gameState['town_name'] as String;
    _language = gameState['language'] as String? ?? 'en';
    _tutorialCompleted = (gameState['tutorial_completed'] as int? ?? 0) == 1;
    _rouletteLastFreeSpin = gameState['roulette_last_free_spin'] as String?;

    _inventoryItems = await _inventorySvc.loadInventoryItems();
    await _crystallizeExpiredSpeedups();
    _activePowerups = await _inventorySvc.loadActivePowerups();
    _minigameCooldowns = await _inventorySvc.loadMinigameCooldowns();
    _missionProgress = await _missionSvc.loadMissionProgress();

    _villagers = await _villagerSvc.reconcileVillagers(
        _villagers, _placedBuildings, _roadTiles);
    _villagerSvc.updateVillagerHappiness(
        _villagers, _placedBuildings, _roadTiles, _activePowerups);
    notifyListeners();
  }

  Future<void> markTutorialCompleted() async {
    await _repo.setTutorialCompleted();
    _tutorialCompleted = true;
    notifyListeners();
  }

  static int get rouletteGemCost => RouletteRules.gemCostPerSpin;

  Future<bool> spinRoulette() async {
    final isFree = canSpinRouletteForFree;
    if (!isFree && _gems < rouletteGemCost) return false;
    if (!isFree) {
      await _repo.subtractResources(gems: rouletteGemCost);
      _gems -= rouletteGemCost;
    }
    if (isFree) {
      final now = DateTime.now().toIso8601String();
      await _repo.setRouletteLastFreeSpin(now);
      _rouletteLastFreeSpin = now;
    }
    notifyListeners();
    return true;
  }

  Future<void> applyRouletteReward(Map<String, dynamic> reward) async {
    final type = reward['type'] as String;
    switch (type) {
      case 'coins':
        await addResources(coins: reward['amount'] as int);
        break;
      case 'gems':
        await addResources(gems: reward['amount'] as int);
        break;
      case 'wood':
        await addResources(wood: reward['amount'] as int);
        break;
      case 'metal':
        await addResources(metal: reward['amount'] as int);
        break;
      case 'book':
      case 'sandwich':
      case 'hammer':
      case 'glasses':
        await addItemToInventory(type);
        _hasNewBackpackItems = true;
        break;
    }
  }

  Future<void> addResources(
      {int coins = 0, int gems = 0, int wood = 0, int metal = 0}) async {
    await _repo.addResources(
        coins: coins, gems: gems, wood: wood, metal: metal);
    _coins += coins;
    _gems += gems;
    _wood += wood;
    _metal += metal;
    notifyListeners();
  }

  Future<void> refreshResources() async {
    final resources = await _repo.getResources();
    _coins = resources['coins'] as int? ?? 0;
    _gems = resources['gems'] as int? ?? 0;
    _wood = resources['wood'] as int? ?? 0;
    _metal = resources['metal'] as int? ?? 0;
    notifyListeners();
  }

  // --- Building operations ---

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
    if (_coins < coinCost ||
        _gems < gemCost ||
        _wood < woodCost ||
        _metal < metalCost) {
      return null;
    }
    if (!canStartConstruction) return null;

    final saved = await _buildingSvc.placeBuilding(
      type: type,
      name: name,
      tileX: tileX,
      tileY: tileY,
      coinCost: coinCost,
      gemCost: gemCost,
      woodCost: woodCost,
      metalCost: metalCost,
      happinessBonus: happinessBonus,
      constructionMinutes: constructionMinutes,
      isFlipped: isFlipped,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      isDecoration: isDecoration,
    );
    if (saved == null) return null;

    _coins -= coinCost;
    _gems -= gemCost;
    _wood -= woodCost;
    _metal -= metalCost;
    _placedBuildings.add(saved);
    notifyListeners();
    return saved;
  }

  Future<List<PlacedBuilding>> checkAndCompleteConstructions() async {
    final completed = await _buildingSvc.checkAndCompleteConstructions(
        _placedBuildings, _activePowerups);
    if (completed.isNotEmpty) {
      for (final b in completed) {
        await addExp(_buildingSvc.getExpForConstruction(b));
      }
      _villagers = await _villagerSvc.reconcileVillagers(
          _villagers, _placedBuildings, _roadTiles);
      _villagerSvc.updateVillagerHappiness(
          _villagers, _placedBuildings, _roadTiles, _activePowerups);
      notifyListeners();
    }
    return completed;
  }

  Future<bool> upgradeBuilding(int buildingId) async {
    if (!canStartConstruction) return false;
    final result = await _buildingSvc.upgradeBuilding(
      buildingId,
      _placedBuildings,
      coins: _coins,
      wood: _wood,
      metal: _metal,
    );
    if (result) {
      await refreshResources();
      final placedMaps = await _repo.getPlacedBuildings();
      _placedBuildings =
          placedMaps.map((m) => PlacedBuilding.fromMap(m)).toList();
      notifyListeners();
    }
    return result;
  }

  Future<bool> speedUpConstruction(int buildingId) async {
    final idx = _placedBuildings.indexWhere((b) => b.id == buildingId);
    if (idx == -1) return false;
    final building = _placedBuildings[idx];

    final result = await _buildingSvc.speedUpConstruction(
        buildingId, _placedBuildings, _gems, _activePowerups);
    if (!result) return false;

    final expAmount = _buildingSvc.getExpForConstruction(building);
    building.isConstructed = true;
    building.constructionStart =
        DateTime.now().subtract(Duration(hours: 24)).toIso8601String();
    await addExp(expAmount);

    final placedMaps = await _repo.getPlacedBuildings();
    _placedBuildings =
        placedMaps.map((m) => PlacedBuilding.fromMap(m)).toList();
    final villagerMaps = await _repo.getVillagers();
    _villagers = villagerMaps.map((m) => Villager.fromMap(m)).toList();

    _villagers = await _villagerSvc.reconcileVillagers(
        _villagers, _placedBuildings, _roadTiles);
    _villagerSvc.updateVillagerHappiness(
        _villagers, _placedBuildings, _roadTiles, _activePowerups);
    await refreshResources();
    notifyListeners();
    return true;
  }

  Future<bool> cancelConstruction(int buildingId) async {
    final idx = _placedBuildings.indexWhere((b) => b.id == buildingId);
    if (idx == -1) return false;
    final building = _placedBuildings[idx];
    final isUpgrade = building.level > 1;

    final result =
        await _buildingSvc.cancelConstruction(buildingId, _placedBuildings);
    if (!result) return false;

    if (!isUpgrade) {
      _placedBuildings.removeAt(idx);
    }

    await refreshResources();
    if (isUpgrade) {
      final placedMaps = await _repo.getPlacedBuildings();
      _placedBuildings =
          placedMaps.map((m) => PlacedBuilding.fromMap(m)).toList();
    }
    _villagers = await _villagerSvc.reconcileVillagers(
        _villagers, _placedBuildings, _roadTiles);
    _villagerSvc.updateVillagerHappiness(
        _villagers, _placedBuildings, _roadTiles, _activePowerups);
    notifyListeners();
    return true;
  }

  Future<bool> moveBuilding(int buildingId, int newTileX, int newTileY) async {
    final result = await _buildingSvc.moveBuilding(buildingId, newTileX,
        newTileY, _placedBuildings, _roadTiles, _unlockedChunks);
    if (result) notifyListeners();
    return result;
  }

  Future<void> flipBuilding(int buildingId) async {
    await _buildingSvc.flipBuilding(buildingId, _placedBuildings);
    notifyListeners();
  }

  Future<void> toggleRoad(int x, int y) async {
    await _buildingSvc.toggleRoad(x, y, _roadTiles);
    notifyListeners();
  }

  Future<bool> expandTerritoryWithGems(int chunkX, int chunkY) async {
    final result = await _buildingSvc.expandTerritoryWithGems(
        chunkX, chunkY, _gems, _expansionCount, _unlockedChunks);
    if (result) {
      _unlockedChunks.add(tileKey(chunkX, chunkY));
      _expansionCount++;
      await refreshResources();
      notifyListeners();
    }
    return result;
  }

  Future<bool> expandTerritoryWithCoins(int chunkX, int chunkY) async {
    final result = await _buildingSvc.expandTerritoryWithCoins(
        chunkX, chunkY, _coins, _expansionCount, _unlockedChunks);
    if (result) {
      _unlockedChunks.add(tileKey(chunkX, chunkY));
      _expansionCount++;
      await refreshResources();
      notifyListeners();
    }
    return result;
  }

  // --- Player operations ---

  Future<int?> addExp(int amount) async {
    final result = await _playerSvc.addExp(amount, _exp, _playerLevel);
    _exp = result.newExp;
    if (result.leveledUpTo != null) {
      _playerLevel = result.leveledUpTo!;
      _gems += result.gemReward;
      _pendingLevelUp = result.leveledUpTo;
    }
    notifyListeners();
    return result.leveledUpTo;
  }

  Future<void> renameVillager(int villagerId, String newName) async {
    await _villagerSvc.renameVillager(villagerId, newName, _villagers);
    notifyListeners();
  }

  Future<void> updateUsername(String name) async {
    _username = name;
    await _playerSvc.updateUsername(name);
    notifyListeners();
  }

  Future<void> updateTownName(String name) async {
    _townName = name;
    await _playerSvc.updateTownName(name);
    notifyListeners();
  }

  // --- Inventory operations ---

  Future<void> addItemToInventory(String type, {int amount = 1}) async {
    await _inventorySvc.addItem(type, _inventoryItems, amount: amount);
    notifyListeners();
  }

  Future<bool> useBookItem(int villagerId) async {
    final result = await _inventorySvc.useBookItem(
        villagerId, _inventoryItems, _activePowerups);
    if (result) {
      _villagerSvc.updateVillagerHappiness(
          _villagers, _placedBuildings, _roadTiles, _activePowerups);
      _notifyBookItemUsed();
      notifyListeners();
    }
    return result;
  }

  Future<bool> useSandwichItem() async {
    final result =
        await _inventorySvc.useSandwichItem(_inventoryItems, _activePowerups);
    if (result) notifyListeners();
    return result;
  }

  Future<bool> useHammerItem() async {
    final result =
        await _inventorySvc.useHammerItem(_inventoryItems, _activePowerups);
    if (result) notifyListeners();
    return result;
  }

  Future<bool> useGlassesItem() async {
    final result =
        await _inventorySvc.useGlassesItem(_inventoryItems, _activePowerups);
    if (result) notifyListeners();
    return result;
  }

  Future<void> setMinigameCooldown(String minigameId, int cooldownHours) async {
    await _inventorySvc.setMinigameCooldown(
        minigameId, cooldownHours, _minigameCooldowns);
    notifyListeners();
  }

  Future<String> grantMinigameReward() async {
    final rewardType = await _inventorySvc.grantMinigameReward(_inventoryItems);
    if (rewardType == 'gems') {
      _gems += 5;
    } else {
      _hasNewBackpackItems = true;
    }
    notifyListeners();
    return rewardType;
  }

  Future<void> cleanupExpiredPowerups() async {
    await _inventorySvc.cleanupExpiredPowerups(_activePowerups);
    _villagerSvc.updateVillagerHappiness(
        _villagers, _placedBuildings, _roadTiles, _activePowerups);
    notifyListeners();
  }

  // --- Mission operations ---

  Future<void> checkMissions({int? totalPagesRead, int? completedBooks}) async {
    await _missionSvc.checkMissions(
      progress: _missionProgress,
      buildings: _placedBuildings,
      villagers: _villagers,
      activePowerups: _activePowerups,
      bookItemUsedSinceActive: _bookItemUsedSinceActive,
      totalPagesRead: totalPagesRead,
      completedBooks: completedBooks,
    );
    notifyListeners();
  }

  Future<bool> claimMissionReward(String missionId) async {
    final mission = MissionData.getMissionById(missionId);
    if (mission == null) return false;

    final reward = mission.reward;
    final result =
        await _missionSvc.claimMissionReward(missionId, _missionProgress);
    if (!result) return false;

    if (reward.exp > 0) await addExp(reward.exp);
    if (reward.coins > 0) _coins += reward.coins;
    if (reward.gems > 0) _gems += reward.gems;

    if (missionId == 'vl_book_happy') _bookItemUsedSinceActive = false;

    notifyListeners();
    return true;
  }

  void _notifyBookItemUsed() {
    final activeMission = getActiveMission(MissionBranch.villager);
    if (activeMission != null &&
        activeMission.conditionType ==
            MissionConditionType.villagerHappinessWithBook) {
      _bookItemUsedSinceActive = true;
    }
  }
}
