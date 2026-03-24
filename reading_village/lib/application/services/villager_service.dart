import 'dart:math';
import 'package:reading_village/domain/entities/placed_building.dart';
import 'package:reading_village/domain/entities/villager.dart';
import 'package:reading_village/domain/entities/inventory_item.dart';
import 'package:reading_village/domain/ports/village_repository.dart';
import 'package:reading_village/domain/rules/village_rules.dart';
import 'package:reading_village/application/services/building_service.dart';

class VillagerService {
  final VillageRepository _repo;
  final BuildingService _buildingService;
  VillagerService(this._repo, this._buildingService);

  static const _needTypes = ['water_plant', 'power_plant', 'hospital', 'school', 'park'];

  int villageHappiness(List<Villager> villagers) {
    if (villagers.isEmpty) return 0;
    final total = villagers.fold<int>(0, (s, v) => s + v.happiness);
    return (total / villagers.length).round();
  }

  List<String> missingBuildingTypes(List<Villager> villagers, List<PlacedBuilding> buildings, Set<String> roadTiles) {
    if (villagers.isEmpty) return [];
    final totalNeeds = villagers.length;
    final capacityByType = <String, int>{
      for (final type in _needTypes) type: 0,
    };
    for (var b in buildings) {
      if (!b.isConstructed || b.type == 'house') continue;
      if (!_buildingService.isBuildingRoadConnected(b, roadTiles)) continue;
      capacityByType[b.type] = (capacityByType[b.type] ?? 0) + VillageRules.buildingCapacity(b.type, b.level);
    }
    return capacityByType.entries
        .where((e) => e.value < totalNeeds)
        .map((e) => e.key)
        .toList();
  }

  List<String> missingNeedsForVillager(Villager villager, List<Villager> allVillagers,
      List<PlacedBuilding> buildings, Set<String> roadTiles) {
    final idx = allVillagers.indexOf(villager);
    if (idx == -1) return [];

    final capacityByType = <String, int>{};
    for (final type in _needTypes) {
      int cap = 0;
      for (var b in buildings) {
        if (!b.isConstructed || b.type != type) continue;
        if (!_buildingService.isBuildingRoadConnected(b, roadTiles)) continue;
        cap += VillageRules.buildingCapacity(b.type, b.level);
      }
      capacityByType[type] = cap;
    }

    return _needTypes.where((type) => idx >= (capacityByType[type] ?? 0)).toList();
  }

  void updateVillagerHappiness(List<Villager> villagers, List<PlacedBuilding> buildings,
      Set<String> roadTiles, List<ActivePowerup> activePowerups) {
    if (villagers.isEmpty) return;

    final capacityByType = <String, int>{};
    for (final type in _needTypes) {
      int cap = 0;
      for (var b in buildings) {
        if (!b.isConstructed || b.type != type) continue;
        if (!_buildingService.isBuildingRoadConnected(b, roadTiles)) continue;
        cap += VillageRules.buildingCapacity(b.type, b.level);
      }
      capacityByType[type] = cap;
    }

    for (int i = 0; i < villagers.length; i++) {
      double sum = 0;
      for (final type in _needTypes) {
        final cap = capacityByType[type] ?? 0;
        if (i < cap) sum += 1.0;
      }
      int happiness = ((sum / _needTypes.length) * 100).round();

      final hasBoost = villagers[i].id != null &&
          activePowerups.any((p) =>
              p.type == 'book_happiness' &&
              p.targetVillagerId == villagers[i].id &&
              p.isActive);
      if (hasBoost) happiness = 100;

      villagers[i].happiness = happiness;
      if (villagers[i].id != null) {
        _repo.updateVillagerHappiness(villagers[i].id!, happiness);
      }
    }
  }

  Future<List<Villager>> reconcileVillagers(List<Villager> villagers,
      List<PlacedBuilding> buildings, Set<String> roadTiles) async {
    final capacity = _buildingService.totalHouseCapacity(buildings, roadTiles);
    final random = Random();
    final houses = buildings
        .where((b) => b.type == 'house' && b.isConstructed && _buildingService.isBuildingRoadConnected(b, roadTiles))
        .toList();

    final newVillagers = <Villager>[];
    while (villagers.length + newVillagers.length < capacity) {
      PlacedBuilding? targetHouse;
      for (var house in houses) {
        final cap = VillageRules.villagersPerHouse(house.level);
        final current = (villagers + newVillagers).where((v) => v.houseId == house.id).length;
        if (current < cap) {
          targetHouse = house;
          break;
        }
      }
      if (targetHouse == null) break;

      final seed = random.nextInt(10000);
      final name = VillageRules.randomVillagerName(seed);
      final species = VillageRules.randomVillagerSpecies(seed ~/ 3);
      final id = await _repo.insertVillager(name, species, targetHouse.id!);
      newVillagers.add(Villager(id: id, name: name, species: species, happiness: 50, houseId: targetHouse.id!));
    }

    return [...villagers, ...newVillagers];
  }

  Future<void> renameVillager(int villagerId, String newName, List<Villager> villagers) async {
    final idx = villagers.indexWhere((v) => v.id == villagerId);
    if (idx == -1) return;
    villagers[idx].name = newName;
    await _repo.renameVillager(villagerId, newName);
  }

  List<Villager> villagersInHouse(int houseId, List<Villager> villagers) =>
      villagers.where((v) => v.houseId == houseId).toList();
}
