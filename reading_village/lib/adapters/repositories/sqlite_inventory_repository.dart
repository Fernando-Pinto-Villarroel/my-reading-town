import 'package:reading_village/infrastructure/persistence/database_helper.dart';
import 'package:reading_village/domain/ports/inventory_repository.dart';

class SqliteInventoryRepository implements InventoryRepository {
  final DatabaseHelper _db;
  SqliteInventoryRepository(this._db);

  @override
  Future<List<Map<String, dynamic>>> getInventoryItems() => _db.getInventoryItems();

  @override
  Future<void> addInventoryItem(String type, {int amount = 1}) => _db.addInventoryItem(type, amount: amount);

  @override
  Future<void> removeInventoryItem(String type, {int amount = 1}) => _db.removeInventoryItem(type, amount: amount);

  @override
  Future<List<Map<String, dynamic>>> getMinigameCooldowns() => _db.getMinigameCooldowns();

  @override
  Future<void> setMinigameCooldown(String minigameId, String cooldownEnd) =>
      _db.setMinigameCooldown(minigameId, cooldownEnd);

  @override
  Future<List<Map<String, dynamic>>> getActivePowerups() => _db.getActivePowerups();

  @override
  Future<int> insertPowerup(Map<String, dynamic> powerup) => _db.insertPowerup(powerup);

  @override
  Future<void> deleteExpiredPowerups() => _db.deleteExpiredPowerups();

  @override
  Future<List<Map<String, dynamic>>> getMissionProgress() => _db.getMissionProgress();

  @override
  Future<void> upsertMissionProgress(String missionId, {bool? isCompleted, bool? isClaimed, String? activatedAt}) =>
      _db.upsertMissionProgress(missionId, isCompleted: isCompleted, isClaimed: isClaimed, activatedAt: activatedAt);
}
