import 'dart:math';
import 'package:my_reading_town/domain/entities/placed_building.dart';
import 'package:my_reading_town/domain/entities/villager.dart';
import 'package:my_reading_town/domain/entities/inventory_item.dart';
import 'package:my_reading_town/domain/ports/village_repository.dart';
import 'package:my_reading_town/domain/rules/village_rules.dart';
import 'package:my_reading_town/application/services/building_service.dart';

class VillagerService {
  final VillageRepository _repo;
  final BuildingService _buildingService;
  VillagerService(this._repo, this._buildingService);


  int villageHappiness(List<Villager> villagers) {
    if (villagers.isEmpty) return 0;
    final total = villagers.fold<int>(0, (s, v) => s + v.happiness);
    return (total / villagers.length).round();
  }

  List<String> _needsForVillager(Villager villager, int playerLevel) {
    final id = villager.id ?? 0;
    final rotational = VillageRules.rotationalNeedForVillager(id, playerLevel);
    return [...VillageRules.fixedNeedTypes, rotational];
  }

  int _buildingCapacity(String type, List<PlacedBuilding> buildings, Set<String> roadTiles) {
    int cap = 0;
    for (final b in buildings) {
      if (b.type != type) continue;
      if (!_buildingService.isBuildingRoadConnected(b, roadTiles, buildings)) continue;
      final effectiveLevel = _buildingService.effectiveBuildingLevel(b);
      if (effectiveLevel <= 0) continue;
      cap += VillageRules.buildingCapacity(b.type, effectiveLevel);
    }
    return cap;
  }

  List<String> missingBuildingTypes(List<Villager> villagers,
      List<PlacedBuilding> buildings, Set<String> roadTiles, int playerLevel) {
    if (villagers.isEmpty) return [];
    final demandByType = <String, int>{};
    for (final v in villagers) {
      for (final type in _needsForVillager(v, playerLevel)) {
        demandByType[type] = (demandByType[type] ?? 0) + 1;
      }
    }
    final missing = <String>[];
    for (final entry in demandByType.entries) {
      if (_buildingCapacity(entry.key, buildings, roadTiles) < entry.value) {
        missing.add(entry.key);
      }
    }
    return missing;
  }

  int _rankForNeed(
      int globalIndex,
      String needType,
      List<Villager> villagers,
      int playerLevel) {
    if (VillageRules.fixedNeedTypes.contains(needType)) return globalIndex;
    int rank = 0;
    for (int j = 0; j < globalIndex; j++) {
      final vId = villagers[j].id ?? 0;
      if (VillageRules.rotationalNeedForVillager(vId, playerLevel) == needType) {
        rank++;
      }
    }
    return rank;
  }

  List<String> missingNeedsForVillager(
      Villager villager,
      List<Villager> allVillagers,
      List<PlacedBuilding> buildings,
      Set<String> roadTiles,
      int playerLevel) {
    final idx = allVillagers.indexOf(villager);
    if (idx == -1) return [];

    final needs = _needsForVillager(villager, playerLevel);
    return needs.where((type) {
      final rank = _rankForNeed(idx, type, allVillagers, playerLevel);
      return rank >= _buildingCapacity(type, buildings, roadTiles);
    }).toList();
  }

  void updateVillagerHappiness(
      List<Villager> villagers,
      List<PlacedBuilding> buildings,
      Set<String> roadTiles,
      List<ActivePowerup> activePowerups,
      int playerLevel) {
    if (villagers.isEmpty) return;

    for (int i = 0; i < villagers.length; i++) {
      final needs = _needsForVillager(villagers[i], playerLevel);
      double sum = 0;
      for (final type in needs) {
        final rank = _rankForNeed(i, type, villagers, playerLevel);
        if (rank < _buildingCapacity(type, buildings, roadTiles)) sum += 1.0;
      }
      int happiness = ((sum / VillageRules.totalNeedCount) * 100).round();

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

  List<String> generateSpeciesOptions(List<String> availableSpecies,
      {int seed = 0}) {
    final random = Random(seed);
    final pool = availableSpecies.isNotEmpty
        ? availableSpecies
        : VillageRules.villagerSpecies;
    if (pool.length <= 3) {
      final result = List<String>.from(pool);
      while (result.length < 3) {
        result.add(pool[random.nextInt(pool.length)]);
      }
      result.shuffle(random);
      return result;
    }
    final shuffled = List<String>.from(pool)..shuffle(random);
    return shuffled.take(3).toList();
  }

  Future<List<Villager>> reconcileVillagers(List<Villager> villagers,
      List<PlacedBuilding> buildings, Set<String> roadTiles,
      {List<String>? unlockedSpeciesIds,
      Map<int, int>? pendingChoiceCountByHouse}) async {
    final houses = buildings
        .where((b) =>
            b.type == 'house' &&
            _buildingService.effectiveBuildingLevel(b) > 0)
        .toList();

    final availableSpecies =
        (unlockedSpeciesIds != null && unlockedSpeciesIds.isNotEmpty)
            ? unlockedSpeciesIds
            : VillageRules.villagerSpecies;

    final totalCapacity = houses.fold<int>(
        0,
        (sum, h) => sum +
            VillageRules.villagersPerHouse(
                _buildingService.effectiveBuildingLevel(h)));

    final random = Random();
    final newVillagers = <Villager>[];
    while (villagers.length + newVillagers.length < totalCapacity) {
      PlacedBuilding? targetHouse;
      for (var house in houses) {
        final cap = VillageRules.villagersPerHouse(
            _buildingService.effectiveBuildingLevel(house));
        final current = (villagers + newVillagers)
            .where((v) => v.houseId == house.id)
            .length;
        final pendingCount = pendingChoiceCountByHouse?[house.id!] ?? 0;
        if (current + pendingCount < cap) {
          targetHouse = house;
          break;
        }
      }
      if (targetHouse == null) break;

      final seed = random.nextInt(10000);
      final name = VillageRules.randomVillagerName(seed);
      final species = availableSpecies[seed % availableSpecies.length];
      final id = await _repo.insertVillager(name, species, targetHouse.id!);
      newVillagers.add(Villager(
          id: id,
          name: name,
          species: species,
          happiness: 50,
          houseId: targetHouse.id!));
    }

    return [...villagers, ...newVillagers];
  }

  Future<void> renameVillager(
      int villagerId, String newName, List<Villager> villagers) async {
    final idx = villagers.indexWhere((v) => v.id == villagerId);
    if (idx == -1) return;
    villagers[idx].name = newName;
    await _repo.renameVillager(villagerId, newName);
  }

  List<Villager> villagersInHouse(int houseId, List<Villager> villagers) =>
      villagers.where((v) => v.houseId == houseId).toList();
}
