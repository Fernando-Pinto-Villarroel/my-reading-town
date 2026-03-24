part of 'database_helper.dart';

extension DatabaseHelperInventoryOperations on DatabaseHelper {
  Future<List<Map<String, dynamic>>> getInventoryItems() async {
    final db = await database;
    return db.query('inventory_items');
  }

  Future<void> addInventoryItem(String type, {int amount = 1}) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE inventory_items SET quantity = quantity + ? WHERE type = ?',
      [amount, type],
    );
  }

  Future<void> removeInventoryItem(String type, {int amount = 1}) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE inventory_items SET quantity = MAX(0, quantity - ?) WHERE type = ?',
      [amount, type],
    );
  }

  Future<List<Map<String, dynamic>>> getMinigameCooldowns() async {
    final db = await database;
    return db.query('minigame_cooldowns');
  }

  Future<void> setMinigameCooldown(String minigameId, String cooldownEnd) async {
    final db = await database;
    await db.insert(
      'minigame_cooldowns',
      {'minigame_id': minigameId, 'cooldown_end': cooldownEnd},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getActivePowerups() async {
    final db = await database;
    return db.query('active_powerups');
  }

  Future<int> insertPowerup(Map<String, dynamic> powerup) async {
    final db = await database;
    return db.insert('active_powerups', powerup);
  }

  Future<void> deletePowerup(int id) async {
    final db = await database;
    await db.delete('active_powerups', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteExpiredPowerups() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    await db.rawDelete('''
      DELETE FROM active_powerups
      WHERE datetime(activated_at, '+' || duration_hours || ' hours') < datetime(?)
    ''', [now]);
  }

  Future<List<Map<String, dynamic>>> getMissionProgress() async {
    final db = await database;
    return db.query('mission_progress');
  }

  Future<void> upsertMissionProgress(String missionId, {
    bool? isCompleted,
    bool? isClaimed,
    String? activatedAt,
  }) async {
    final db = await database;
    final existing = await db.query('mission_progress',
        where: 'mission_id = ?', whereArgs: [missionId]);
    if (existing.isEmpty) {
      await db.insert('mission_progress', {
        'mission_id': missionId,
        'is_completed': (isCompleted ?? false) ? 1 : 0,
        'is_claimed': (isClaimed ?? false) ? 1 : 0,
        'activated_at': activatedAt,
      });
    } else {
      final updates = <String, dynamic>{};
      if (isCompleted != null) updates['is_completed'] = isCompleted ? 1 : 0;
      if (isClaimed != null) updates['is_claimed'] = isClaimed ? 1 : 0;
      if (activatedAt != null) updates['activated_at'] = activatedAt;
      if (updates.isNotEmpty) {
        await db.update('mission_progress', updates,
            where: 'mission_id = ?', whereArgs: [missionId]);
      }
    }
  }
}
