part of 'database_helper.dart';

extension DatabaseHelperBackupOperations on DatabaseHelper {
  static const List<String> _allTables = [
    'books',
    'tags',
    'book_tags',
    'reading_sessions',
    'resources',
    'villagers',
    'placed_buildings',
    'road_tiles',
    'unlocked_chunks',
    'game_state',
    'inventory_items',
    'minigame_cooldowns',
    'active_powerups',
    'mission_progress',
    'species_unlocks',
  ];

  Future<Map<String, dynamic>> exportAllTables() async {
    final db = await database;
    final result = <String, dynamic>{
      'version': 3,
      'exported_at': DateTime.now().toIso8601String(),
    };
    for (final table in _allTables) {
      result[table] = await db.query(table);
    }
    return result;
  }

  Future<void> importAllTables(Map<String, dynamic> data) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final table in _allTables.reversed) {
        await txn.delete(table);
      }
      for (final table in _allTables) {
        final rows = data[table] as List<dynamic>?;
        if (rows == null) continue;
        for (final row in rows) {
          await txn.insert(
            table,
            Map<String, dynamic>.from(row as Map),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    });
  }

  Future<void> resetDatabase() async {
    final db = await database;
    await db.close();
    DatabaseHelper._database = null;
    final path = join(await getDatabasesPath(), 'my_reading_town.db');
    await deleteDatabase(path);
  }
}
