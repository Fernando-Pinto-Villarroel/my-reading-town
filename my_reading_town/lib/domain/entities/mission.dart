enum MissionCheckType { bm, am }

enum MissionBranch {
  basicConstruction,
  advancedConstruction,
  villager,
  bookTracking,
  halloween,
  christmas,
  easter,
}

enum MissionConditionType {
  buyBuilding,
  upgradeBuilding,
  reachBuildingCount,
  villagerHappiness,
  villagerHappinessWithBook,
  villagerHappinessNatural,
  totalPagesRead,
  booksCompleted,
  enterAppDuringEvent,
  villagerSpeciesHappiness,
}

class MissionReward {
  final int exp;
  final int coins;
  final int gems;
  final String? speciesId;

  const MissionReward({
    this.exp = 0,
    this.coins = 0,
    this.gems = 0,
    this.speciesId,
  });

  @override
  String toString() {
    final parts = <String>[];
    if (exp > 0) parts.add('$exp XP');
    if (coins > 0) parts.add('$coins Coins');
    if (gems > 0) parts.add('$gems Gems');
    if (speciesId != null) parts.add('New Species');
    return parts.join(', ');
  }
}

class Mission {
  final String id;
  final String title;
  final String description;
  final MissionBranch branch;
  final MissionCheckType checkType;
  final MissionConditionType conditionType;
  final String? buildingType;
  final int? targetLevel;
  final int? targetCount;
  final String? speciesType;
  final MissionReward reward;
  final int orderInBranch;

  const Mission({
    required this.id,
    required this.title,
    required this.description,
    required this.branch,
    required this.checkType,
    required this.conditionType,
    this.buildingType,
    this.targetLevel,
    this.targetCount,
    this.speciesType,
    required this.reward,
    required this.orderInBranch,
  });
}

class MissionProgress {
  final String missionId;
  bool isCompleted;
  bool isClaimed;
  String? activatedAt;
  int? pagesAtActivation;
  int? booksAtActivation;

  MissionProgress({
    required this.missionId,
    this.isCompleted = false,
    this.isClaimed = false,
    this.activatedAt,
    this.pagesAtActivation,
    this.booksAtActivation,
  });

  factory MissionProgress.fromMap(Map<String, dynamic> map) {
    return MissionProgress(
      missionId: map['mission_id'] as String,
      isCompleted: (map['is_completed'] as int) == 1,
      isClaimed: (map['is_claimed'] as int) == 1,
      activatedAt: map['activated_at'] as String?,
      pagesAtActivation: map['pages_at_activation'] as int?,
      booksAtActivation: map['books_at_activation'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mission_id': missionId,
      'is_completed': isCompleted ? 1 : 0,
      'is_claimed': isClaimed ? 1 : 0,
      'activated_at': activatedAt,
      'pages_at_activation': pagesAtActivation,
      'books_at_activation': booksAtActivation,
    };
  }
}
