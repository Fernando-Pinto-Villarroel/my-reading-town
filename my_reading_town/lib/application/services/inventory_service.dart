import 'dart:math';
import 'package:my_reading_town/domain/entities/inventory_item.dart';
import 'package:my_reading_town/domain/ports/inventory_repository.dart';
import 'package:my_reading_town/domain/ports/village_repository.dart';
import 'package:my_reading_town/domain/rules/minigame_rules.dart';

class InventoryService {
  final InventoryRepository _invRepo;
  final VillageRepository _villageRepo;
  InventoryService(this._invRepo, this._villageRepo);

  Future<List<InventoryItem>> loadInventoryItems() async {
    final maps = await _invRepo.getInventoryItems();
    return maps.map((m) => InventoryItem.fromMap(m)).toList();
  }

  Future<List<Map<String, dynamic>>> getExpiredSpeedupPowerups() =>
      _invRepo.getExpiredSpeedupPowerups();

  Future<List<ActivePowerup>> loadActivePowerups() async {
    await _invRepo.deleteExpiredPowerups();
    final maps = await _invRepo.getActivePowerups();
    return maps.map((m) => ActivePowerup.fromMap(m)).toList();
  }

  Future<List<MinigameCooldown>> loadMinigameCooldowns() async {
    final maps = await _invRepo.getMinigameCooldowns();
    return maps.map((m) => MinigameCooldown.fromMap(m)).toList();
  }

  Future<void> addItem(String type, List<InventoryItem> items,
      {int amount = 1}) async {
    await _invRepo.addInventoryItem(type, amount: amount);
    final idx = items.indexWhere((i) => i.type == type);
    if (idx != -1) items[idx].quantity += amount;
  }

  int itemQuantity(String type, List<InventoryItem> items) {
    final item = items.where((i) => i.type == type).firstOrNull;
    return item?.quantity ?? 0;
  }

  bool isMinigameOnCooldown(
      String minigameId, List<MinigameCooldown> cooldowns) {
    final cd = cooldowns.where((c) => c.minigameId == minigameId).firstOrNull;
    if (cd == null) return false;
    return cd.isOnCooldown;
  }

  Duration minigameCooldownRemaining(
      String minigameId, List<MinigameCooldown> cooldowns) {
    final cd = cooldowns.where((c) => c.minigameId == minigameId).firstOrNull;
    if (cd == null) return Duration.zero;
    return cd.remainingCooldown;
  }

  bool villagerHasHappinessBoost(
          int villagerId, List<ActivePowerup> powerups) =>
      powerups.any((p) =>
          p.type == 'book_happiness' &&
          p.targetVillagerId == villagerId &&
          p.isActive);

  bool isSpeedBoostActive(List<ActivePowerup> powerups) =>
      powerups.any((p) => p.type == 'sandwich_speed' && p.isActive);

  bool isHammerActive(List<ActivePowerup> powerups) =>
      powerups.any((p) => p.type == 'hammer_constructor' && p.isActive);

  bool isGlassesActive(List<ActivePowerup> powerups) =>
      powerups.any((p) => p.type == 'glasses_reading' && p.isActive);

  double readingResourceMultiplier(List<ActivePowerup> powerups) =>
      isGlassesActive(powerups) ? 1.5 : 1.0;

  double constructionSpeedMultiplier(List<ActivePowerup> powerups) =>
      isSpeedBoostActive(powerups) ? 2.0 : 1.0;

  int maxConstructors(List<ActivePowerup> powerups) {
    int max = 3;
    for (final p in powerups) {
      if (p.type == 'hammer_constructor' && p.isActive) max++;
    }
    return max;
  }

  Future<bool> useBookItem(int villagerId, List<InventoryItem> items,
      List<ActivePowerup> powerups) async {
    if (itemQuantity('book', items) <= 0) return false;
    if (villagerHasHappinessBoost(villagerId, powerups)) return false;

    await _invRepo.removeInventoryItem('book');
    final idx = items.indexWhere((i) => i.type == 'book');
    if (idx != -1) items[idx].quantity--;

    final powerup = ActivePowerup(
      type: 'book_happiness',
      targetVillagerId: villagerId,
      activatedAt: DateTime.now().toIso8601String(),
      durationHours: 24,
    );
    final id = await _invRepo.insertPowerup(powerup.toMap());
    powerups.add(ActivePowerup(
      id: id,
      type: powerup.type,
      targetVillagerId: powerup.targetVillagerId,
      activatedAt: powerup.activatedAt,
      durationHours: powerup.durationHours,
    ));
    return true;
  }

  Future<bool> useSandwichItem(
      List<InventoryItem> items, List<ActivePowerup> powerups) async {
    if (itemQuantity('sandwich', items) <= 0) return false;
    if (isSpeedBoostActive(powerups)) return false;

    await _invRepo.removeInventoryItem('sandwich');
    final idx = items.indexWhere((i) => i.type == 'sandwich');
    if (idx != -1) items[idx].quantity--;

    final powerup = ActivePowerup(
      type: 'sandwich_speed',
      activatedAt: DateTime.now().toIso8601String(),
      durationHours: 1,
    );
    final id = await _invRepo.insertPowerup(powerup.toMap());
    powerups.add(ActivePowerup(
      id: id,
      type: powerup.type,
      activatedAt: powerup.activatedAt,
      durationHours: powerup.durationHours,
    ));
    return true;
  }

  Future<bool> useHammerItem(
      List<InventoryItem> items, List<ActivePowerup> powerups) async {
    if (itemQuantity('hammer', items) <= 0) return false;
    if (isHammerActive(powerups)) return false;

    await _invRepo.removeInventoryItem('hammer');
    final idx = items.indexWhere((i) => i.type == 'hammer');
    if (idx != -1) items[idx].quantity--;

    final powerup = ActivePowerup(
      type: 'hammer_constructor',
      activatedAt: DateTime.now().toIso8601String(),
      durationHours: 24,
    );
    final id = await _invRepo.insertPowerup(powerup.toMap());
    powerups.add(ActivePowerup(
      id: id,
      type: powerup.type,
      activatedAt: powerup.activatedAt,
      durationHours: powerup.durationHours,
    ));
    return true;
  }

  Future<bool> useGlassesItem(
      List<InventoryItem> items, List<ActivePowerup> powerups) async {
    if (itemQuantity('glasses', items) <= 0) return false;
    if (isGlassesActive(powerups)) return false;

    await _invRepo.removeInventoryItem('glasses');
    final idx = items.indexWhere((i) => i.type == 'glasses');
    if (idx != -1) items[idx].quantity--;

    final powerup = ActivePowerup(
      type: 'glasses_reading',
      activatedAt: DateTime.now().toIso8601String(),
      durationHours: 1,
    );
    final id = await _invRepo.insertPowerup(powerup.toMap());
    powerups.add(ActivePowerup(
      id: id,
      type: powerup.type,
      activatedAt: powerup.activatedAt,
      durationHours: powerup.durationHours,
    ));
    return true;
  }

  Future<void> setMinigameCooldown(String minigameId, int cooldownHours,
      List<MinigameCooldown> cooldowns) async {
    final cooldownEnd =
        DateTime.now().add(Duration(hours: cooldownHours)).toIso8601String();
    await _invRepo.setMinigameCooldown(minigameId, cooldownEnd);
    final existing = cooldowns.indexWhere((c) => c.minigameId == minigameId);
    final cd =
        MinigameCooldown(minigameId: minigameId, cooldownEnd: cooldownEnd);
    if (existing != -1) {
      cooldowns[existing] = cd;
    } else {
      cooldowns.add(cd);
    }
  }

  Future<String> grantMinigameReward(List<InventoryItem> items) async {
    final rewardType = MinigameRules.pickRewardType(Random());
    if (rewardType == 'gems') {
      await _villageRepo.addResources(gems: MinigameRules.gemsRewardAmount);
    } else {
      await addItem(rewardType, items);
    }
    return rewardType;
  }

  Future<void> cleanupExpiredPowerups(List<ActivePowerup> powerups) async {
    await _invRepo.deleteExpiredPowerups();
    powerups.removeWhere((p) => !p.isActive);
  }
}
