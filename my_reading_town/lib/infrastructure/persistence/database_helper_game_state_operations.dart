part of 'database_helper.dart';

extension DatabaseHelperGameStateOperations on DatabaseHelper {
  Future<Map<String, dynamic>> getResources() async {
    final db = await database;
    final results = await db.query('resources', where: 'id = 1');
    if (results.isEmpty) return {'coins': 0, 'gems': 0, 'wood': 0, 'metal': 0};
    return results.first;
  }

  Future<void> addResources({int coins = 0, int gems = 0, int wood = 0, int metal = 0}) async {
    final db = await database;
    await db.rawUpdate(
        'UPDATE resources SET coins = coins + ?, gems = gems + ?, wood = wood + ?, metal = metal + ? WHERE id = 1',
        [coins, gems, wood, metal]);
  }

  Future<void> subtractResources({int coins = 0, int gems = 0, int wood = 0, int metal = 0}) async {
    final db = await database;
    await db.rawUpdate(
        'UPDATE resources SET coins = coins - ?, gems = gems - ?, wood = wood - ?, metal = metal - ? WHERE id = 1',
        [coins, gems, wood, metal]);
  }

  Future<List<Map<String, dynamic>>> getVillagers() async {
    final db = await database;
    return db.query('villagers');
  }

  Future<int> insertVillager(String name, String species, int houseId) async {
    final db = await database;
    return db.insert('villagers', {'name': name, 'species': species, 'happiness': 50, 'house_id': houseId});
  }

  Future<void> updateVillagerHappiness(int villagerId, int happiness) async {
    final db = await database;
    await db.update('villagers', {'happiness': happiness},
        where: 'id = ?', whereArgs: [villagerId]);
  }

  Future<void> renameVillager(int villagerId, String newName) async {
    final db = await database;
    await db.update('villagers', {'name': newName},
        where: 'id = ?', whereArgs: [villagerId]);
  }

  Future<Map<String, dynamic>> getGameState() async {
    final db = await database;
    final result = await db.query('game_state', where: 'id = 1');
    if (result.isEmpty) {
      return {'expansion_count': 0, 'exp': 0, 'player_level': 1, 'username': '', 'town_name': 'My Village', 'language': 'en'};
    }
    return result.first;
  }

  Future<int> getExpansionCount() async {
    final state = await getGameState();
    return state['expansion_count'] as int;
  }

  Future<void> incrementExpansionCount() async {
    final db = await database;
    await db.rawUpdate(
        'UPDATE game_state SET expansion_count = expansion_count + 1 WHERE id = 1');
  }

  Future<void> addExp(int amount) async {
    final db = await database;
    await db.rawUpdate(
        'UPDATE game_state SET exp = exp + ? WHERE id = 1', [amount]);
  }

  Future<void> updatePlayerLevel(int level) async {
    final db = await database;
    await db.update('game_state', {'player_level': level}, where: 'id = 1');
  }

  Future<void> updateUsername(String username) async {
    final db = await database;
    await db.update('game_state', {'username': username}, where: 'id = 1');
  }

  Future<void> updateTownName(String townName) async {
    final db = await database;
    await db.update('game_state', {'town_name': townName}, where: 'id = 1');
  }

  Future<void> updateLanguage(String language) async {
    final db = await database;
    await db.update('game_state', {'language': language}, where: 'id = 1');
  }

  Future<bool> getTutorialCompleted() async {
    final state = await getGameState();
    return (state['tutorial_completed'] as int? ?? 0) == 1;
  }

  Future<void> setTutorialCompleted() async {
    final db = await database;
    await db.update('game_state', {'tutorial_completed': 1}, where: 'id = 1');
  }

  Future<String?> getRouletteLastFreeSpin() async {
    final state = await getGameState();
    return state['roulette_last_free_spin'] as String?;
  }

  Future<void> setRouletteLastFreeSpin(String isoDate) async {
    final db = await database;
    await db.update('game_state', {'roulette_last_free_spin': isoDate}, where: 'id = 1');
  }

  Future<Map<String, dynamic>> getNotificationSettings() async {
    final state = await getGameState();
    return {
      'days_enabled': state['notif_days_enabled'] as String? ?? '1111111',
      'start_hour': state['notif_start_hour'] as int? ?? 8,
      'end_hour': state['notif_end_hour'] as int? ?? 22,
      'per_day': state['notif_per_day'] as int? ?? 2,
    };
  }

  Future<void> saveNotificationSettings({
    required String daysEnabled,
    required int startHour,
    required int endHour,
    required int perDay,
  }) async {
    final db = await database;
    await db.update(
      'game_state',
      {
        'notif_days_enabled': daysEnabled,
        'notif_start_hour': startHour,
        'notif_end_hour': endHour,
        'notif_per_day': perDay,
      },
      where: 'id = 1',
    );
  }

  Future<List<String>> getUnlockedSpeciesIds() async {
    final db = await database;
    final rows = await db.query('species_unlocks');
    return rows.map((r) => r['species_id'] as String).toList();
  }

  Future<void> unlockSpecies(String speciesId) async {
    final db = await database;
    await db.insert(
      'species_unlocks',
      {'species_id': speciesId, 'unlocked_at': DateTime.now().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<bool> isSpeciesUnlocked(String speciesId) async {
    final db = await database;
    final rows = await db.query('species_unlocks',
        where: 'species_id = ?', whereArgs: [speciesId]);
    return rows.isNotEmpty;
  }
}
