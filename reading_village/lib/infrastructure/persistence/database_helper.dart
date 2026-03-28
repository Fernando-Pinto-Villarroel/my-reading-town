import 'dart:math';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:reading_village/domain/rules/village_rules.dart';

part 'database_helper_book_operations.dart';
part 'database_helper_building_operations.dart';
part 'database_helper_game_state_operations.dart';
part 'database_helper_inventory_operations.dart';

class DatabaseHelper {
  static const bool test = true;

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
    await deleteDatabase(path); // DEBUG: uncomment to reset DB on each launch
    return await openDatabase(
      path,
      version: 3,
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await db.execute(
          'ALTER TABLE books ADD COLUMN max_rewarded_pages INTEGER NOT NULL DEFAULT 0');
    }
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
        max_rewarded_pages INTEGER NOT NULL DEFAULT 0,
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
        time_taken_minutes INTEGER,
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
        tile_width INTEGER NOT NULL DEFAULT 1,
        tile_height INTEGER NOT NULL DEFAULT 1,
        level INTEGER NOT NULL DEFAULT 1,
        coin_cost INTEGER NOT NULL,
        gem_cost INTEGER NOT NULL DEFAULT 0,
        wood_cost INTEGER NOT NULL DEFAULT 0,
        metal_cost INTEGER NOT NULL DEFAULT 0,
        happiness_bonus INTEGER NOT NULL DEFAULT 0,
        construction_start TEXT,
        construction_duration_minutes INTEGER NOT NULL DEFAULT 60,
        is_constructed INTEGER NOT NULL DEFAULT 0,
        is_flipped INTEGER NOT NULL DEFAULT 0,
        is_decoration INTEGER NOT NULL DEFAULT 0
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
        exp INTEGER NOT NULL DEFAULT 0,
        player_level INTEGER NOT NULL DEFAULT 1,
        username TEXT NOT NULL DEFAULT '',
        town_name TEXT NOT NULL DEFAULT 'My Village',
        language TEXT NOT NULL DEFAULT 'en'
      )
    ''');

    await db.execute('''
      CREATE TABLE inventory_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL UNIQUE,
        quantity INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE minigame_cooldowns (
        minigame_id TEXT PRIMARY KEY,
        cooldown_end TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE active_powerups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        target_villager_id INTEGER,
        activated_at TEXT NOT NULL,
        duration_hours INTEGER NOT NULL DEFAULT 24
      )
    ''');

    await db.execute('''
      CREATE TABLE mission_progress (
        mission_id TEXT PRIMARY KEY,
        is_completed INTEGER NOT NULL DEFAULT 0,
        is_claimed INTEGER NOT NULL DEFAULT 0,
        activated_at TEXT
      )
    ''');

    for (final type in ['book', 'sandwich', 'hammer']) {
      await db.insert('inventory_items', {'type': type, 'quantity': 0});
    }

    await db.insert('resources', {
      'id': 1,
      'coins': test ? 9999 : VillageRules.startingCoins,
      'gems': test ? 9999 : VillageRules.startingGems,
      'wood': test ? 9999 : VillageRules.startingWood,
      'metal': test ? 9999 : VillageRules.startingMetal,
    });

    await db.insert('game_state', {
      'id': 1,
      'expansion_count': 0,
      'exp': 0,
      'player_level': 1,
      'username': '',
      'town_name': 'My Village',
      'language': 'en',
    });

    final defaultStart = VillageRules.defaultChunkStart;
    final defaultEnd = VillageRules.defaultChunkEnd;
    for (int cx = defaultStart; cx <= defaultEnd; cx++) {
      for (int cy = defaultStart; cy <= defaultEnd; cy++) {
        await db.insert('unlocked_chunks', {'chunk_x': cx, 'chunk_y': cy},
            conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }

    final centerTile = VillageRules.defaultAreaCenterTile;
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
      'tile_y': centerTile - 2,
      'tile_width': VillageRules.buildingTileWidth('house'),
      'tile_height': VillageRules.buildingTileHeight('house'),
      'level': 1,
      'coin_cost': 0,
      'gem_cost': 0,
      'wood_cost': 0,
      'metal_cost': 0,
      'happiness_bonus': 10,
      'construction_start':
          DateTime.now().subtract(Duration(hours: 1)).toIso8601String(),
      'construction_duration_minutes': 1,
      'is_constructed': 1,
    });

    final random = Random();
    final species = VillageRules.villagerSpecies[random.nextInt(3)];
    final name = VillageRules
        .villagerNames[random.nextInt(VillageRules.villagerNames.length)];
    await db.insert('villagers', {
      'name': name,
      'species': species,
      'happiness': 50,
      'house_id': houseId
    });
  }
}
