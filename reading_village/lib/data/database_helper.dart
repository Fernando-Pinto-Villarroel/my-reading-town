import 'dart:math';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../config/game_constants.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'reading_village.db');
    await deleteDatabase(path);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE books (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        author TEXT,
        total_pages INTEGER NOT NULL,
        pages_read INTEGER NOT NULL DEFAULT 0,
        is_completed INTEGER NOT NULL DEFAULT 0,
        cover_image_path TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        color_value INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE book_tags (
        book_id INTEGER NOT NULL,
        tag_id INTEGER NOT NULL,
        PRIMARY KEY (book_id, tag_id),
        FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE reading_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        book_id INTEGER NOT NULL,
        pages_read INTEGER NOT NULL,
        coins_earned INTEGER NOT NULL,
        gems_earned INTEGER NOT NULL,
        wood_earned INTEGER NOT NULL DEFAULT 0,
        metal_earned INTEGER NOT NULL DEFAULT 0,
        date TEXT NOT NULL,
        FOREIGN KEY (book_id) REFERENCES books(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE resources (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        coins INTEGER NOT NULL DEFAULT 0,
        gems INTEGER NOT NULL DEFAULT 0,
        wood INTEGER NOT NULL DEFAULT 0,
        metal INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE villagers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        species TEXT NOT NULL,
        happiness INTEGER NOT NULL DEFAULT 50,
        house_id INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE placed_buildings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        name TEXT NOT NULL,
        tile_x INTEGER NOT NULL,
        tile_y INTEGER NOT NULL,
        level INTEGER NOT NULL DEFAULT 1,
        coin_cost INTEGER NOT NULL,
        gem_cost INTEGER NOT NULL DEFAULT 0,
        wood_cost INTEGER NOT NULL DEFAULT 0,
        metal_cost INTEGER NOT NULL DEFAULT 0,
        happiness_bonus INTEGER NOT NULL DEFAULT 0,
        construction_start TEXT,
        construction_duration_minutes INTEGER NOT NULL DEFAULT 60,
        is_constructed INTEGER NOT NULL DEFAULT 0,
        is_flipped INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE road_tiles (
        tile_x INTEGER NOT NULL,
        tile_y INTEGER NOT NULL,
        PRIMARY KEY (tile_x, tile_y)
      )
    ''');

    await db.execute('''
      CREATE TABLE unlocked_chunks (
        chunk_x INTEGER NOT NULL,
        chunk_y INTEGER NOT NULL,
        PRIMARY KEY (chunk_x, chunk_y)
      )
    ''');

    await db.execute('''
      CREATE TABLE game_state (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        expansion_count INTEGER NOT NULL DEFAULT 0,
        village_level INTEGER NOT NULL DEFAULT 1,
        exp INTEGER NOT NULL DEFAULT 0,
        player_level INTEGER NOT NULL DEFAULT 1,
        username TEXT NOT NULL DEFAULT '',
        town_name TEXT NOT NULL DEFAULT 'My Village'
      )
    ''');

    await db.insert('resources', {
      'id': 1,
      'coins': GameConstants.startingCoins,
      'gems': GameConstants.startingGems,
      'wood': GameConstants.startingWood,
      'metal': GameConstants.startingMetal,
    });

    await db.insert('game_state', {
      'id': 1,
      'expansion_count': 0,
      'village_level': 1,
      'exp': 0,
      'player_level': 1,
      'username': '',
      'town_name': 'My Village',
    });

    final defaultStart = GameConstants.defaultChunkStart;
    final defaultEnd = GameConstants.defaultChunkEnd;
    for (int cx = defaultStart; cx <= defaultEnd; cx++) {
      for (int cy = defaultStart; cy <= defaultEnd; cy++) {
        await db.insert('unlocked_chunks', {'chunk_x': cx, 'chunk_y': cy},
            conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }

    final centerTile = GameConstants.defaultAreaCenterTile;
    for (int dx = -3; dx <= 3; dx++) {
      await db.insert(
          'road_tiles', {'tile_x': centerTile + dx, 'tile_y': centerTile},
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    for (int dy = -3; dy <= 3; dy++) {
      if (dy == 0) continue;
      await db.insert(
          'road_tiles', {'tile_x': centerTile, 'tile_y': centerTile + dy},
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    final houseId = await db.insert('placed_buildings', {
      'type': 'house',
      'name': 'Home',
      'tile_x': centerTile + 1,
      'tile_y': centerTile - 1,
      'level': 1,
      'coin_cost': 0,
      'gem_cost': 0,
      'wood_cost': 0,
      'metal_cost': 0,
      'happiness_bonus': 10,
      'construction_start': DateTime.now().subtract(Duration(hours: 1)).toIso8601String(),
      'construction_duration_minutes': 1,
      'is_constructed': 1,
    });

    final random = Random();
    final species = GameConstants.villagerSpecies[random.nextInt(3)];
    final name = GameConstants.villagerNames[random.nextInt(GameConstants.villagerNames.length)];
    await db.insert('villagers', {'name': name, 'species': species, 'happiness': 50, 'house_id': houseId});
  }

  Future<List<Map<String, dynamic>>> getBooks() async {
    final db = await database;
    return db.query('books', orderBy: 'created_at DESC');
  }

  Future<int> insertBook(Map<String, dynamic> book) async {
    final db = await database;
    return db.insert('books', book);
  }

  Future<void> updateBookPages(int bookId, int newPagesRead, bool isCompleted) async {
    final db = await database;
    await db.update('books',
        {'pages_read': newPagesRead, 'is_completed': isCompleted ? 1 : 0},
        where: 'id = ?', whereArgs: [bookId]);
  }

  Future<int> insertReadingSession(Map<String, dynamic> session) async {
    final db = await database;
    return db.insert('reading_sessions', session);
  }

  Future<List<Map<String, dynamic>>> getReadingSessions() async {
    final db = await database;
    return db.query('reading_sessions', orderBy: 'date DESC');
  }

  Future<int> getTotalPagesRead() async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT COALESCE(SUM(pages_read), 0) as total FROM reading_sessions');
    return result.first['total'] as int;
  }

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

  Future<int> getCompletedBooksCount() async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM books WHERE is_completed = 1');
    return result.first['count'] as int;
  }

  Future<int> getTotalSessionsCount() async {
    final db = await database;
    final result = await db
        .rawQuery('SELECT COUNT(*) as count FROM reading_sessions');
    return result.first['count'] as int;
  }

  Future<int> insertPlacedBuilding(Map<String, dynamic> building) async {
    final db = await database;
    return db.insert('placed_buildings', building);
  }

  Future<List<Map<String, dynamic>>> getPlacedBuildings() async {
    final db = await database;
    return db.query('placed_buildings');
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

  Future<Map<String, dynamic>> getGameState() async {
    final db = await database;
    final result = await db.query('game_state', where: 'id = 1');
    if (result.isEmpty) {
      return {'expansion_count': 0, 'village_level': 1, 'exp': 0, 'player_level': 1, 'username': '', 'town_name': 'My Village'};
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

  Future<int> getVillageLevel() async {
    final state = await getGameState();
    return state['village_level'] as int;
  }

  Future<void> updateVillageLevel(int level) async {
    final db = await database;
    await db.update('game_state', {'village_level': level}, where: 'id = 1');
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

  // --- Tags ---

  Future<List<Map<String, dynamic>>> getTags() async {
    final db = await database;
    return db.query('tags', orderBy: 'title ASC');
  }

  Future<int> insertTag(Map<String, dynamic> tag) async {
    final db = await database;
    return db.insert('tags', tag);
  }

  Future<void> updateTag(int tagId, Map<String, dynamic> values) async {
    final db = await database;
    await db.update('tags', values, where: 'id = ?', whereArgs: [tagId]);
  }

  Future<void> deleteTag(int tagId) async {
    final db = await database;
    await db.delete('book_tags', where: 'tag_id = ?', whereArgs: [tagId]);
    await db.delete('tags', where: 'id = ?', whereArgs: [tagId]);
  }

  // --- Book Tags ---

  Future<List<Map<String, dynamic>>> getBookTags(int bookId) async {
    final db = await database;
    return db.rawQuery('''
      SELECT t.* FROM tags t
      INNER JOIN book_tags bt ON bt.tag_id = t.id
      WHERE bt.book_id = ?
      ORDER BY t.title ASC
    ''', [bookId]);
  }

  Future<void> setBookTags(int bookId, List<int> tagIds) async {
    final db = await database;
    await db.delete('book_tags', where: 'book_id = ?', whereArgs: [bookId]);
    for (final tagId in tagIds) {
      await db.insert('book_tags', {'book_id': bookId, 'tag_id': tagId},
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  // --- Books (extended) ---

  Future<void> updateBook(int bookId, Map<String, dynamic> values) async {
    final db = await database;
    await db.update('books', values, where: 'id = ?', whereArgs: [bookId]);
  }

  Future<void> deleteBook(int bookId) async {
    final db = await database;
    await db.delete('book_tags', where: 'book_id = ?', whereArgs: [bookId]);
    await db.delete('reading_sessions', where: 'book_id = ?', whereArgs: [bookId]);
    await db.delete('books', where: 'id = ?', whereArgs: [bookId]);
  }
}
