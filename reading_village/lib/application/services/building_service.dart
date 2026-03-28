import 'package:reading_village/domain/entities/inventory_item.dart';
import 'package:reading_village/domain/entities/placed_building.dart';
import 'package:reading_village/domain/ports/village_repository.dart';
import 'package:reading_village/domain/rules/village_rules.dart';

class BuildingService {
  final VillageRepository _repo;
  BuildingService(this._repo);

  static String tileKey(int x, int y) => '$x,$y';

  static Duration effectiveRemainingTime(
      PlacedBuilding b, List<ActivePowerup> powerups) {
    if (b.isConstructed || b.constructionStart == null) return Duration.zero;
    final start = DateTime.parse(b.constructionStart!);
    final total = Duration(minutes: b.constructionDurationMinutes);
    final now = DateTime.now();
    if (!now.isAfter(start)) return total;

    double effectiveElapsedMs = 0.0;
    DateTime cursor = start;

    final boosts = powerups.where((p) => p.type == 'sandwich_speed').toList()
      ..sort((a, b) => DateTime.parse(a.activatedAt)
          .compareTo(DateTime.parse(b.activatedAt)));

    for (final boost in boosts) {
      if (!cursor.isBefore(now)) break;
      final boostStart = DateTime.parse(boost.activatedAt);
      final boostEnd = boostStart.add(Duration(hours: boost.durationHours));

      if (cursor.isBefore(boostStart)) {
        final segEnd = boostStart.isBefore(now) ? boostStart : now;
        effectiveElapsedMs +=
            segEnd.difference(cursor).inMilliseconds.toDouble();
        cursor = segEnd;
      }
      if (cursor.isBefore(boostEnd) && cursor.isBefore(now)) {
        final segEnd = boostEnd.isBefore(now) ? boostEnd : now;
        effectiveElapsedMs +=
            segEnd.difference(cursor).inMilliseconds.toDouble() * 2.0;
        cursor = segEnd;
      }
    }

    if (cursor.isBefore(now))
      effectiveElapsedMs += now.difference(cursor).inMilliseconds.toDouble();

    final remainingMs = total.inMilliseconds - effectiveElapsedMs;
    return remainingMs <= 0
        ? Duration.zero
        : Duration(milliseconds: remainingMs.round());
  }

  bool isBuildingRoadConnected(PlacedBuilding b, Set<String> roadTiles) {
    for (int dx = 0; dx < b.tileWidth; dx++) {
      for (int dy = 0; dy < b.tileHeight; dy++) {
        final tx = b.tileX + dx;
        final ty = b.tileY + dy;
        for (final d in [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
          final nx = tx + d.$1;
          final ny = ty + d.$2;
          if (nx >= b.tileX &&
              nx < b.tileX + b.tileWidth &&
              ny >= b.tileY &&
              ny < b.tileY + b.tileHeight) {
            continue;
          }
          if (roadTiles.contains(tileKey(nx, ny))) return true;
        }
      }
    }
    return false;
  }

  String? adjacentRoadTile(PlacedBuilding b, Set<String> roadTiles) {
    for (int dx = 0; dx < b.tileWidth; dx++) {
      for (int dy = 0; dy < b.tileHeight; dy++) {
        final tx = b.tileX + dx;
        final ty = b.tileY + dy;
        for (final d in [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
          final nx = tx + d.$1;
          final ny = ty + d.$2;
          if (nx >= b.tileX &&
              nx < b.tileX + b.tileWidth &&
              ny >= b.tileY &&
              ny < b.tileY + b.tileHeight) {
            continue;
          }
          final key = tileKey(nx, ny);
          if (roadTiles.contains(key)) return key;
        }
      }
    }
    return null;
  }

  Map<int, String> houseAdjacentRoadTiles(
      List<PlacedBuilding> buildings, Set<String> roadTiles) {
    final result = <int, String>{};
    for (var b in buildings) {
      if (b.type == 'house' && b.isConstructed && b.id != null) {
        final road = adjacentRoadTile(b, roadTiles);
        if (road != null) result[b.id!] = road;
      }
    }
    return result;
  }

  bool isTileUnlocked(int tileX, int tileY, Set<String> unlockedChunks) {
    final chunkX = tileX ~/ VillageRules.chunkSize;
    final chunkY = tileY ~/ VillageRules.chunkSize;
    return unlockedChunks.contains(tileKey(chunkX, chunkY));
  }

  bool hasBuildingAt(int x, int y, List<PlacedBuilding> buildings) =>
      buildings.any((b) => b.occupiesTile(x, y));

  bool isRoadTile(int x, int y, Set<String> roadTiles) =>
      roadTiles.contains(tileKey(x, y));

  PlacedBuilding? getBuildingAt(int x, int y, List<PlacedBuilding> buildings) {
    try {
      return buildings.firstWhere((b) => b.occupiesTile(x, y));
    } catch (_) {
      return null;
    }
  }

  bool canPlaceBuildingAtArea(
      int x,
      int y,
      int width,
      int height,
      List<PlacedBuilding> buildings,
      Set<String> roadTiles,
      Set<String> unlockedChunks) {
    for (int dx = 0; dx < width; dx++) {
      for (int dy = 0; dy < height; dy++) {
        if (hasBuildingAt(x + dx, y + dy, buildings)) return false;
        if (isRoadTile(x + dx, y + dy, roadTiles)) return false;
        if (!isTileUnlocked(x + dx, y + dy, unlockedChunks)) return false;
      }
    }
    return true;
  }

  ({int x, int y})? findValidPlacement(
      int tapX,
      int tapY,
      int width,
      int height,
      List<PlacedBuilding> buildings,
      Set<String> roadTiles,
      Set<String> unlockedChunks) {
    for (int dy = 0; dy < height; dy++) {
      for (int dx = 0; dx < width; dx++) {
        final originX = tapX - dx;
        final originY = tapY - dy;
        if (canPlaceBuildingAtArea(originX, originY, width, height, buildings,
            roadTiles, unlockedChunks)) {
          return (x: originX, y: originY);
        }
      }
    }
    return null;
  }

  bool isChunkAdjacentToUnlocked(
      int chunkX, int chunkY, Set<String> unlockedChunks) {
    if (unlockedChunks.contains(tileKey(chunkX, chunkY))) return false;
    if (chunkX < 0 || chunkX >= VillageRules.chunksPerSide) return false;
    if (chunkY < 0 || chunkY >= VillageRules.chunksPerSide) return false;
    return unlockedChunks.contains(tileKey(chunkX - 1, chunkY)) ||
        unlockedChunks.contains(tileKey(chunkX + 1, chunkY)) ||
        unlockedChunks.contains(tileKey(chunkX, chunkY - 1)) ||
        unlockedChunks.contains(tileKey(chunkX, chunkY + 1));
  }

  int totalHouseCapacity(
      List<PlacedBuilding> buildings, Set<String> roadTiles) {
    int total = 0;
    for (var b in buildings) {
      if (b.type == 'house' && isBuildingRoadConnected(b, roadTiles)) {
        final effectiveLevel = effectiveBuildingLevel(b);
        if (effectiveLevel > 0) {
          total += VillageRules.villagersPerHouse(effectiveLevel);
        }
      }
    }
    return total;
  }

  int effectiveBuildingLevel(PlacedBuilding b) {
    if (!b.isConstructed) {
      if (b.level <= 1) return 0;
      return b.level - 1;
    }
    return b.level;
  }

  int buildingCountOfType(String type, List<PlacedBuilding> buildings) =>
      buildings.where((b) => b.type == type).length;

  bool canPlaceBuildingType(
      String type, int playerLevel, List<PlacedBuilding> buildings) {
    final maxAllowed =
        VillageRules.maxBuildingsOfTypeForPlayerLevel(type, playerLevel);
    return buildingCountOfType(type, buildings) < maxAllowed;
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
    await _repo.subtractResources(
        coins: coinCost, gems: gemCost, wood: woodCost, metal: metalCost);

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
      constructionDurationMinutes: constructionMinutes,
      isConstructed: false,
      isFlipped: isFlipped,
      isDecoration: isDecoration,
    );

    final id = await _repo.insertPlacedBuilding(building.toMap());
    return building.copyWith(id: id);
  }

  Future<List<PlacedBuilding>> checkAndCompleteConstructions(
      List<PlacedBuilding> buildings, List<ActivePowerup> powerups) async {
    List<PlacedBuilding> completed = [];
    for (int i = 0; i < buildings.length; i++) {
      final b = buildings[i];
      if (!b.isConstructed &&
          effectiveRemainingTime(b, powerups) == Duration.zero) {
        b.isConstructed = true;
        await _repo.markBuildingConstructed(b.id!);
        completed.add(b);
      }
    }
    return completed;
  }

  int getExpForConstruction(PlacedBuilding b) {
    final template = VillageRules.findTemplate(b.type);
    final baseExp = template?['exp'] as int? ?? 20;
    return b.level > 1
        ? (baseExp * VillageRules.upgradeExpMultiplier).round()
        : baseExp;
  }

  Future<bool> upgradeBuilding(int buildingId, List<PlacedBuilding> buildings,
      {required int coins, required int wood, required int metal}) async {
    final idx = buildings.indexWhere((b) => b.id == buildingId);
    if (idx == -1) return false;

    final building = buildings[idx];
    if (!building.isConstructed) return false;
    if (building.isDecoration) return false;
    if (building.level >= VillageRules.maxBuildingLevel) return false;

    final template = VillageRules.findTemplate(building.type);
    if (template == null) return false;

    final coinCost = VillageRules.upgradeCoinCost(
        template['coinCost'] as int, building.level);
    final woodCost = VillageRules.upgradeWoodCost(
        template['woodCost'] as int, building.level);
    final metalCost = VillageRules.upgradeMetalCost(
        template['metalCost'] as int, building.level);

    if (coins < coinCost || wood < woodCost || metal < metalCost) return false;

    await _repo.subtractResources(
        coins: coinCost, wood: woodCost, metal: metalCost);

    final newLevel = building.level + 1;
    final constructionMinutes = VillageRules.upgradeConstructionMinutes(
      template['constructionMinutes'] as int,
      building.level,
    );
    final constructionStart = DateTime.now().toIso8601String();

    await _repo.upgradePlacedBuilding(
        buildingId, newLevel, constructionStart, constructionMinutes);
    return true;
  }

  ({int coinCost, int woodCost, int metalCost})? getUpgradeCost(
      PlacedBuilding building) {
    final template = VillageRules.findTemplate(building.type);
    if (template == null) return null;
    return (
      coinCost: VillageRules.upgradeCoinCost(
          template['coinCost'] as int, building.level),
      woodCost: VillageRules.upgradeWoodCost(
          template['woodCost'] as int, building.level),
      metalCost: VillageRules.upgradeMetalCost(
          template['metalCost'] as int, building.level),
    );
  }

  Future<bool> speedUpConstruction(
      int buildingId,
      List<PlacedBuilding> buildings,
      int currentGems,
      List<ActivePowerup> powerups) async {
    final idx = buildings.indexWhere((b) => b.id == buildingId);
    if (idx == -1) return false;

    final building = buildings[idx];
    if (building.isConstructed) return false;

    final remaining = effectiveRemainingTime(building, powerups);
    final gemCost = VillageRules.gemCostToSpeedUp(remaining);
    if (gemCost <= 0) return false;
    if (currentGems < gemCost) return false;

    await _repo.subtractResources(gems: gemCost);
    await _repo.markBuildingConstructed(buildingId);
    return true;
  }

  int gemCostToSpeedUp(PlacedBuilding building, List<ActivePowerup> powerups) {
    return VillageRules.gemCostToSpeedUp(
        effectiveRemainingTime(building, powerups));
  }

  Future<bool> cancelConstruction(
      int buildingId, List<PlacedBuilding> buildings) async {
    final idx = buildings.indexWhere((b) => b.id == buildingId);
    if (idx == -1) return false;

    final building = buildings[idx];
    if (building.isConstructed) return false;

    final isUpgrade = building.level > 1;

    if (isUpgrade) {
      final previousLevel = building.level - 1;
      final template = VillageRules.findTemplate(building.type);
      if (template == null) return false;
      final refundCoins = VillageRules.upgradeCoinCost(
          template['coinCost'] as int, previousLevel);
      final refundWood = VillageRules.upgradeWoodCost(
          template['woodCost'] as int, previousLevel);
      final refundMetal = VillageRules.upgradeMetalCost(
          template['metalCost'] as int, previousLevel);

      await _repo.addResources(
          coins: refundCoins, wood: refundWood, metal: refundMetal);
      final baseMinutes = template['constructionMinutes'] as int;
      await _repo.revertBuildingUpgrade(buildingId, previousLevel, baseMinutes);
    } else {
      await _repo.addResources(
        coins: building.coinCost,
        gems: building.gemCost,
        wood: building.woodCost,
        metal: building.metalCost,
      );
      await _repo.deletePlacedBuilding(buildingId);
    }
    return true;
  }

  Future<bool> moveBuilding(
      int buildingId,
      int newTileX,
      int newTileY,
      List<PlacedBuilding> buildings,
      Set<String> roadTiles,
      Set<String> unlockedChunks) async {
    final idx = buildings.indexWhere((b) => b.id == buildingId);
    if (idx == -1) return false;
    final building = buildings[idx];

    final oldX = building.tileX;
    final oldY = building.tileY;
    building.tileX = -999;
    building.tileY = -999;

    final placement = findValidPlacement(newTileX, newTileY, building.tileWidth,
        building.tileHeight, buildings, roadTiles, unlockedChunks);

    if (placement == null) {
      building.tileX = oldX;
      building.tileY = oldY;
      return false;
    }

    building.tileX = placement.x;
    building.tileY = placement.y;
    await _repo.movePlacedBuilding(buildingId, placement.x, placement.y);
    return true;
  }

  Future<void> flipBuilding(
      int buildingId, List<PlacedBuilding> buildings) async {
    final idx = buildings.indexWhere((b) => b.id == buildingId);
    if (idx == -1) return;
    buildings[idx].isFlipped = !buildings[idx].isFlipped;
    await _repo.flipBuilding(buildingId, buildings[idx].isFlipped);
  }

  Future<void> toggleRoad(int x, int y, Set<String> roadTiles) async {
    final key = tileKey(x, y);
    if (roadTiles.contains(key)) {
      roadTiles.remove(key);
      await _repo.deleteRoadTile(x, y);
    } else {
      roadTiles.add(key);
      await _repo.insertRoadTile(x, y);
    }
  }

  Future<bool> expandTerritoryWithGems(int chunkX, int chunkY, int currentGems,
      int expansionCount, Set<String> unlockedChunks) async {
    if (!isChunkAdjacentToUnlocked(chunkX, chunkY, unlockedChunks))
      return false;
    final cost = VillageRules.expansionGemCost(expansionCount);
    if (currentGems < cost) return false;
    await _repo.subtractResources(gems: cost);
    await _repo.insertUnlockedChunk(chunkX, chunkY);
    await _repo.incrementExpansionCount();
    return true;
  }

  Future<bool> expandTerritoryWithCoins(int chunkX, int chunkY,
      int currentCoins, int expansionCount, Set<String> unlockedChunks) async {
    if (!isChunkAdjacentToUnlocked(chunkX, chunkY, unlockedChunks))
      return false;
    final cost = VillageRules.expansionCoinCost(expansionCount);
    if (currentCoins < cost) return false;
    await _repo.subtractResources(coins: cost);
    await _repo.insertUnlockedChunk(chunkX, chunkY);
    await _repo.incrementExpansionCount();
    return true;
  }
}
