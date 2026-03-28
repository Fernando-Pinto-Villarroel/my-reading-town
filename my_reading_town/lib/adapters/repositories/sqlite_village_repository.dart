import 'package:my_reading_town/infrastructure/persistence/database_helper.dart';
import 'package:my_reading_town/domain/ports/village_repository.dart';

class SqliteVillageRepository implements VillageRepository {
  final DatabaseHelper _db;
  SqliteVillageRepository(this._db);

  @override
  Future<List<Map<String, dynamic>>> getPlacedBuildings() =>
      _db.getPlacedBuildings();

  @override
  Future<int> insertPlacedBuilding(Map<String, dynamic> building) =>
      _db.insertPlacedBuilding(building);

  @override
  Future<void> updateConstructionStart(
          int buildingId, String constructionStart) =>
      _db.updateConstructionStart(buildingId, constructionStart);

  @override
  Future<void> markBuildingConstructed(int buildingId) =>
      _db.markBuildingConstructed(buildingId);

  @override
  Future<void> upgradePlacedBuilding(int id, int newLevel,
          String constructionStart, int constructionMinutes) =>
      _db.upgradePlacedBuilding(
          id, newLevel, constructionStart, constructionMinutes);

  @override
  Future<void> deletePlacedBuilding(int buildingId) =>
      _db.deletePlacedBuilding(buildingId);

  @override
  Future<void> revertBuildingUpgrade(
          int id, int previousLevel, int previousMinutes) =>
      _db.revertBuildingUpgrade(id, previousLevel, previousMinutes);

  @override
  Future<void> movePlacedBuilding(int id, int tileX, int tileY) =>
      _db.movePlacedBuilding(id, tileX, tileY);

  @override
  Future<void> flipBuilding(int id, bool isFlipped) =>
      _db.flipBuilding(id, isFlipped);

  @override
  Future<void> insertRoadTile(int x, int y) => _db.insertRoadTile(x, y);

  @override
  Future<void> deleteRoadTile(int x, int y) => _db.deleteRoadTile(x, y);

  @override
  Future<List<Map<String, dynamic>>> getRoadTiles() => _db.getRoadTiles();

  @override
  Future<List<Map<String, dynamic>>> getUnlockedChunks() =>
      _db.getUnlockedChunks();

  @override
  Future<void> insertUnlockedChunk(int chunkX, int chunkY) =>
      _db.insertUnlockedChunk(chunkX, chunkY);

  @override
  Future<Map<String, dynamic>> getResources() => _db.getResources();

  @override
  Future<void> addResources(
          {int coins = 0, int gems = 0, int wood = 0, int metal = 0}) =>
      _db.addResources(coins: coins, gems: gems, wood: wood, metal: metal);

  @override
  Future<void> subtractResources(
          {int coins = 0, int gems = 0, int wood = 0, int metal = 0}) =>
      _db.subtractResources(coins: coins, gems: gems, wood: wood, metal: metal);

  @override
  Future<List<Map<String, dynamic>>> getVillagers() => _db.getVillagers();

  @override
  Future<int> insertVillager(String name, String species, int houseId) =>
      _db.insertVillager(name, species, houseId);

  @override
  Future<void> updateVillagerHappiness(int villagerId, int happiness) =>
      _db.updateVillagerHappiness(villagerId, happiness);

  @override
  Future<void> renameVillager(int villagerId, String newName) =>
      _db.renameVillager(villagerId, newName);

  @override
  Future<Map<String, dynamic>> getGameState() => _db.getGameState();

  @override
  Future<void> incrementExpansionCount() => _db.incrementExpansionCount();

  @override
  Future<void> addExp(int amount) => _db.addExp(amount);

  @override
  Future<void> updatePlayerLevel(int level) => _db.updatePlayerLevel(level);

  @override
  Future<void> updateUsername(String username) => _db.updateUsername(username);

  @override
  Future<void> updateTownName(String townName) => _db.updateTownName(townName);
}
