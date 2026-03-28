import 'package:my_reading_town/domain/entities/placed_building.dart';
import 'package:my_reading_town/domain/entities/villager.dart';
import 'package:my_reading_town/domain/entities/inventory_item.dart';
import 'package:my_reading_town/domain/entities/mission.dart';
import 'package:my_reading_town/domain/entities/mission_data.dart';
import 'package:my_reading_town/domain/ports/inventory_repository.dart';
import 'package:my_reading_town/domain/ports/village_repository.dart';

class MissionService {
  final InventoryRepository _invRepo;
  final VillageRepository _villageRepo;
  MissionService(this._invRepo, this._villageRepo);

  Future<Map<String, MissionProgress>> loadMissionProgress() async {
    final maps = await _invRepo.getMissionProgress();
    return {
      for (final m in maps)
        m['mission_id'] as String: MissionProgress.fromMap(m),
    };
  }

  bool isBranchUnlocked(
      MissionBranch branch, Map<String, MissionProgress> progress) {
    final deps = MissionData.branchDependencies(branch);
    for (final dep in deps) {
      if (!isBranchFullyCompleted(dep, progress)) return false;
    }
    return true;
  }

  bool isBranchFullyCompleted(
      MissionBranch branch, Map<String, MissionProgress> progress) {
    final missions = MissionData.getMissionsForBranch(branch);
    return missions.every((m) {
      final p = progress[m.id];
      return p != null && p.isClaimed;
    });
  }

  Mission? getActiveMission(
      MissionBranch branch, Map<String, MissionProgress> progress) {
    if (!isBranchUnlocked(branch, progress)) return null;
    final missions = MissionData.getMissionsForBranch(branch);
    for (final mission in missions) {
      final p = progress[mission.id];
      if (p == null || !p.isClaimed) return mission;
    }
    return null;
  }

  List<Mission> getActiveMissions(Map<String, MissionProgress> progress) {
    final result = <Mission>[];
    for (final branch in MissionBranch.values) {
      final active = getActiveMission(branch, progress);
      if (active != null) result.add(active);
    }
    return result;
  }

  MissionProgress _getOrCreateProgress(
      Mission mission, Map<String, MissionProgress> progress) {
    if (!progress.containsKey(mission.id)) {
      progress[mission.id] = MissionProgress(missionId: mission.id);
    }
    return progress[mission.id]!;
  }

  Future<void> _ensureMissionActivated(
      Mission mission, Map<String, MissionProgress> progress) async {
    final p = _getOrCreateProgress(mission, progress);
    if (p.activatedAt == null) {
      p.activatedAt = DateTime.now().toIso8601String();
      await _invRepo.upsertMissionProgress(mission.id,
          activatedAt: p.activatedAt);
    }
  }

  Future<void> checkMissions({
    required Map<String, MissionProgress> progress,
    required List<PlacedBuilding> buildings,
    required List<Villager> villagers,
    required List<ActivePowerup> activePowerups,
    required bool bookItemUsedSinceActive,
    int? totalPagesRead,
    int? completedBooks,
  }) async {
    for (final branch in MissionBranch.values) {
      final mission = getActiveMission(branch, progress);
      if (mission == null) continue;

      final p = _getOrCreateProgress(mission, progress);
      if (p.isCompleted) continue;

      await _ensureMissionActivated(mission, progress);

      final isComplete = _checkMissionCondition(mission, buildings, villagers,
          activePowerups, bookItemUsedSinceActive,
          totalPagesRead: totalPagesRead, completedBooks: completedBooks);
      if (isComplete) {
        p.isCompleted = true;
        await _invRepo.upsertMissionProgress(mission.id, isCompleted: true);
      }
    }
  }

  bool _checkMissionCondition(
      Mission mission,
      List<PlacedBuilding> buildings,
      List<Villager> villagers,
      List<ActivePowerup> activePowerups,
      bool bookItemUsedSinceActive,
      {int? totalPagesRead,
      int? completedBooks}) {
    switch (mission.conditionType) {
      case MissionConditionType.buyBuilding:
        return buildings
            .any((b) => b.type == mission.buildingType && b.isConstructed);

      case MissionConditionType.upgradeBuilding:
        return buildings.any((b) =>
            b.type == mission.buildingType &&
            b.level >= (mission.targetLevel ?? 1) &&
            b.isConstructed);

      case MissionConditionType.reachBuildingCount:
        final count = buildings
            .where((b) =>
                b.type == mission.buildingType &&
                b.level >= (mission.targetLevel ?? 1) &&
                b.isConstructed)
            .length;
        return count >= (mission.targetCount ?? 1);

      case MissionConditionType.villagerHappiness:
        final happyCount = villagers.where((v) => v.happiness >= 100).length;
        return happyCount >= (mission.targetCount ?? 1);

      case MissionConditionType.villagerHappinessWithBook:
        return bookItemUsedSinceActive;

      case MissionConditionType.villagerHappinessNatural:
        final hasAnyBookPowerup =
            activePowerups.any((p) => p.type == 'book_happiness' && p.isActive);
        if (hasAnyBookPowerup) return false;
        final happyCount = villagers.where((v) => v.happiness >= 100).length;
        return happyCount >= (mission.targetCount ?? 1);

      case MissionConditionType.totalPagesRead:
        return (totalPagesRead ?? 0) >= (mission.targetCount ?? 1);

      case MissionConditionType.booksCompleted:
        return (completedBooks ?? 0) >= (mission.targetCount ?? 1);
    }
  }

  ({int current, int target}) getMissionProgressValues(
      Mission mission,
      List<PlacedBuilding> buildings,
      List<Villager> villagers,
      List<ActivePowerup> activePowerups,
      bool bookItemUsedSinceActive,
      {int? totalPagesRead,
      int? completedBooks}) {
    final target = mission.targetCount ?? 1;
    int current = 0;

    switch (mission.conditionType) {
      case MissionConditionType.buyBuilding:
        current = buildings
            .where((b) => b.type == mission.buildingType && b.isConstructed)
            .length;
        return (current: current.clamp(0, 1), target: 1);

      case MissionConditionType.upgradeBuilding:
        final maxLevel = buildings
            .where((b) => b.type == mission.buildingType && b.isConstructed)
            .fold<int>(0, (max, b) => b.level > max ? b.level : max);
        current = maxLevel;
        return (
          current: current.clamp(0, mission.targetLevel ?? 1),
          target: mission.targetLevel ?? 1
        );

      case MissionConditionType.reachBuildingCount:
        current = buildings
            .where((b) =>
                b.type == mission.buildingType &&
                b.level >= (mission.targetLevel ?? 1) &&
                b.isConstructed)
            .length;
        return (current: current.clamp(0, target), target: target);

      case MissionConditionType.villagerHappiness:
        current = villagers.where((v) => v.happiness >= 100).length;
        return (current: current.clamp(0, target), target: target);

      case MissionConditionType.villagerHappinessWithBook:
        current = bookItemUsedSinceActive ? 1 : 0;
        return (current: current, target: 1);

      case MissionConditionType.villagerHappinessNatural:
        final hasAnyBookPowerup =
            activePowerups.any((p) => p.type == 'book_happiness' && p.isActive);
        if (hasAnyBookPowerup) {
          current = 0;
        } else {
          current = villagers.where((v) => v.happiness >= 100).length;
        }
        return (current: current.clamp(0, target), target: target);

      case MissionConditionType.totalPagesRead:
        current = totalPagesRead ?? 0;
        return (current: current.clamp(0, target), target: target);

      case MissionConditionType.booksCompleted:
        current = completedBooks ?? 0;
        return (current: current.clamp(0, target), target: target);
    }
  }

  Future<bool> claimMissionReward(
      String missionId, Map<String, MissionProgress> progress) async {
    final mission = MissionData.getMissionById(missionId);
    if (mission == null) return false;

    final p = progress[missionId];
    if (p == null || !p.isCompleted || p.isClaimed) return false;

    final reward = mission.reward;
    if (reward.coins > 0 || reward.gems > 0) {
      await _villageRepo.addResources(coins: reward.coins, gems: reward.gems);
    }

    p.isClaimed = true;
    await _invRepo.upsertMissionProgress(missionId, isClaimed: true);

    final nextMission = getActiveMission(mission.branch, progress);
    if (nextMission != null) {
      await _ensureMissionActivated(nextMission, progress);
    }

    return true;
  }

  int unclaimedCompletedMissionCount(Map<String, MissionProgress> progress) {
    int count = 0;
    for (final branch in MissionBranch.values) {
      final mission = getActiveMission(branch, progress);
      if (mission != null) {
        final p = progress[mission.id];
        if (p != null && p.isCompleted && !p.isClaimed) count++;
      }
    }
    return count;
  }
}
