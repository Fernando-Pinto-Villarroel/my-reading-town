import 'package:my_reading_town/domain/ports/village_repository.dart';
import 'package:my_reading_town/domain/rules/village_rules.dart';
import 'package:my_reading_town/domain/rules/species_rules.dart';

class PlayerService {
  final VillageRepository _repo;
  PlayerService(this._repo);

  Future<({int newExp, int? leveledUpTo, int gemReward, String? newSpeciesId})>
      addExp(int amount, int currentExp, int currentLevel) async {
    final newExp = currentExp + amount;
    await _repo.addExp(amount);
    final newLevel = VillageRules.playerLevelFromExp(newExp);
    int? leveledUpTo;
    int gemReward = 0;
    String? newSpeciesId;

    if (newLevel != currentLevel) {
      final levelsGained = newLevel - currentLevel;
      gemReward = 3 * levelsGained;
      await _repo.updatePlayerLevel(newLevel);
      await _repo.addResources(gems: gemReward);
      leveledUpTo = newLevel;

      for (int lvl = currentLevel + 1; lvl <= newLevel; lvl++) {
        final speciesId = SpeciesRules.speciesUnlockedAtLevel(lvl);
        if (speciesId != null) {
          await _repo.unlockSpecies(speciesId);
          newSpeciesId = speciesId;
        }
      }
    }
    return (
      newExp: newExp,
      leveledUpTo: leveledUpTo,
      gemReward: gemReward,
      newSpeciesId: newSpeciesId,
    );
  }

  Future<void> updateUsername(String name) async {
    await _repo.updateUsername(name);
  }

  Future<void> updateTownName(String name) async {
    await _repo.updateTownName(name);
  }
}
