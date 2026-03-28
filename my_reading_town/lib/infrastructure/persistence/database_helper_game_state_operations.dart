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
}
