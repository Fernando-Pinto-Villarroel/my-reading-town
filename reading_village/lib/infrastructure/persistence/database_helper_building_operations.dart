part of 'database_helper.dart';

extension DatabaseHelperBuildingOperations on DatabaseHelper {
  Future<int> insertPlacedBuilding(Map<String, dynamic> building) async {
    final db = await database;
    return db.insert('placed_buildings', building);
  }

  Future<List<Map<String, dynamic>>> getPlacedBuildings() async {
    final db = await database;
    return db.query('placed_buildings');
  }

  Future<void> updateConstructionStart(int buildingId, String constructionStart) async {
    final db = await database;
    await db.update('placed_buildings', {'construction_start': constructionStart},
        where: 'id = ?', whereArgs: [buildingId]);
  }

  Future<void> markBuildingConstructed(int buildingId) async {
    final db = await database;
    await db.update('placed_buildings', {'is_constructed': 1},
        where: 'id = ?', whereArgs: [buildingId]);
  }

  Future<void> upgradePlacedBuilding(int buildingId, int newLevel, String constructionStart, int constructionMinutes) async {
    final db = await database;
    await db.update('placed_buildings', {
      'level': newLevel,
      'is_constructed': 0,
      'construction_start': constructionStart,
      'construction_duration_minutes': constructionMinutes,
    }, where: 'id = ?', whereArgs: [buildingId]);
  }

  Future<void> deletePlacedBuilding(int buildingId) async {
    final db = await database;
    await db.delete('placed_buildings', where: 'id = ?', whereArgs: [buildingId]);
  }

  Future<void> revertBuildingUpgrade(int buildingId, int previousLevel, int constructionMinutes) async {
    final db = await database;
    await db.update('placed_buildings', {
      'level': previousLevel,
      'is_constructed': 1,
      'construction_start': null,
      'construction_duration_minutes': constructionMinutes,
    }, where: 'id = ?', whereArgs: [buildingId]);
  }

  Future<void> movePlacedBuilding(int buildingId, int newTileX, int newTileY) async {
    final db = await database;
    await db.update('placed_buildings', {
      'tile_x': newTileX,
      'tile_y': newTileY,
    }, where: 'id = ?', whereArgs: [buildingId]);
  }

  Future<void> flipBuilding(int buildingId, bool isFlipped) async {
    final db = await database;
    await db.update('placed_buildings', {
      'is_flipped': isFlipped ? 1 : 0,
    }, where: 'id = ?', whereArgs: [buildingId]);
  }

  Future<void> insertRoadTile(int x, int y) async {
    final db = await database;
    await db.insert('road_tiles', {'tile_x': x, 'tile_y': y},
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> deleteRoadTile(int x, int y) async {
    final db = await database;
    await db.delete('road_tiles',
        where: 'tile_x = ? AND tile_y = ?', whereArgs: [x, y]);
  }

  Future<List<Map<String, dynamic>>> getRoadTiles() async {
    final db = await database;
    return db.query('road_tiles');
  }

  Future<List<Map<String, dynamic>>> getUnlockedChunks() async {
    final db = await database;
    return db.query('unlocked_chunks');
  }

  Future<void> insertUnlockedChunk(int chunkX, int chunkY) async {
    final db = await database;
    await db.insert(
        'unlocked_chunks', {'chunk_x': chunkX, 'chunk_y': chunkY},
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }
}
