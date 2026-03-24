abstract class InventoryRepository {
  Future<List<Map<String, dynamic>>> getInventoryItems();
  Future<void> addInventoryItem(String type, {int amount = 1});
  Future<void> removeInventoryItem(String type, {int amount = 1});
  Future<List<Map<String, dynamic>>> getMinigameCooldowns();
  Future<void> setMinigameCooldown(String minigameId, String cooldownEnd);
  Future<List<Map<String, dynamic>>> getActivePowerups();
  Future<List<Map<String, dynamic>>> getExpiredSpeedupPowerups();
  Future<int> insertPowerup(Map<String, dynamic> powerup);
  Future<void> deleteExpiredPowerups();
  Future<List<Map<String, dynamic>>> getMissionProgress();
  Future<void> upsertMissionProgress(String missionId, {bool? isCompleted, bool? isClaimed, String? activatedAt});
}
