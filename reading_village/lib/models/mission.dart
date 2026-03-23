/// Represents the type of mission completion check.
/// BM = Before Mission — auto-completes if conditions already met when mission activates.
/// AM = After Mission — conditions must be met AFTER the mission becomes active.
enum MissionCheckType { bm, am }

/// The branches of the mission tree.
enum MissionBranch { basicConstruction, advancedConstruction, villager, bookTracking }

/// The type of condition to check for mission completion.
enum MissionConditionType {
  buyBuilding,        // Buy (place) a building of a specific type
  upgradeBuilding,    // Upgrade a building of a specific type to a specific level
  reachBuildingCount, // Have N buildings of a type at a specific level (constructed)
  villagerHappiness,  // Have N villagers at 100% happiness
  villagerHappinessWithBook, // Use a happiness book to get a villager to 100%
  villagerHappinessNatural,  // Have N villagers at 100% happiness WITHOUT book powerup
  totalPagesRead,     // Total pages read across all books
  booksCompleted,     // Total books fully read
}

/// Reward given when a mission is claimed.
class MissionReward {
  final int exp;
  final int coins;
  final int gems;

  const MissionReward({this.exp = 0, this.coins = 0, this.gems = 0});

  @override
  String toString() {
    final parts = <String>[];
    if (exp > 0) parts.add('$exp XP');
    if (coins > 0) parts.add('$coins Coins');
    if (gems > 0) parts.add('$gems Gems');
    return parts.join(', ');
  }
}

/// A single mission definition.
class Mission {
  final String id;
  final String title;
  final String description;
  final MissionBranch branch;
  final MissionCheckType checkType;
  final MissionConditionType conditionType;
  final String? buildingType;    // For building-related missions
  final int? targetLevel;        // For upgrade missions
  final int? targetCount;        // For count-based missions (pages, books, buildings, villagers)
  final MissionReward reward;
  final int orderInBranch;       // Order within the branch (0-indexed)

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
    required this.reward,
    required this.orderInBranch,
  });
}

/// Tracks the player's progress on a specific mission.
class MissionProgress {
  final String missionId;
  bool isCompleted;
  bool isClaimed;
  String? activatedAt; // When the mission became active (for AM missions)

  MissionProgress({
    required this.missionId,
    this.isCompleted = false,
    this.isClaimed = false,
    this.activatedAt,
  });

  factory MissionProgress.fromMap(Map<String, dynamic> map) {
    return MissionProgress(
      missionId: map['mission_id'] as String,
      isCompleted: (map['is_completed'] as int) == 1,
      isClaimed: (map['is_claimed'] as int) == 1,
      activatedAt: map['activated_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mission_id': missionId,
      'is_completed': isCompleted ? 1 : 0,
      'is_claimed': isClaimed ? 1 : 0,
      'activated_at': activatedAt,
    };
  }
}

/// All mission definitions in the game.
class MissionData {
  static const List<String> buildingTypes = [
    'park', 'water_plant', 'power_plant', 'school', 'hospital',
  ];

  static const List<String> allBuildingTypes = [
    'house', 'park', 'water_plant', 'power_plant', 'school', 'hospital',
  ];

  static List<Mission> get allMissions => [
    ..._basicConstructionBranch,
    ..._advancedConstructionBranch,
    ..._villagerBranch,
    ..._bookTrackingBranch,
  ];

  // ─── Branch 1: Basic Construction (17 missions, all BM) ───

  static final List<Mission> _basicConstructionBranch = [
    // Buy each non-house building (5 missions)
    for (int i = 0; i < buildingTypes.length; i++)
      Mission(
        id: 'bc_buy_${buildingTypes[i]}',
        title: 'Build a ${_buildingDisplayName(buildingTypes[i])}',
        description: 'Place your first ${_buildingDisplayName(buildingTypes[i])} in the village.',
        branch: MissionBranch.basicConstruction,
        checkType: MissionCheckType.bm,
        conditionType: MissionConditionType.buyBuilding,
        buildingType: buildingTypes[i],
        reward: MissionReward(exp: 20 + i * 5),
        orderInBranch: i,
      ),

    // Upgrade each building type to level 2 (6 missions)
    for (int i = 0; i < allBuildingTypes.length; i++)
      Mission(
        id: 'bc_upgrade_${allBuildingTypes[i]}_lv2',
        title: 'Upgrade ${_buildingDisplayName(allBuildingTypes[i])} to Lv.2',
        description: 'Improve a ${_buildingDisplayName(allBuildingTypes[i])} to level 2.',
        branch: MissionBranch.basicConstruction,
        checkType: MissionCheckType.bm,
        conditionType: MissionConditionType.upgradeBuilding,
        buildingType: allBuildingTypes[i],
        targetLevel: 2,
        reward: MissionReward(exp: 40 + i * 5, coins: 30 + i * 10),
        orderInBranch: 5 + i,
      ),

    // Upgrade each building type to level 3 (6 missions)
    for (int i = 0; i < allBuildingTypes.length; i++)
      Mission(
        id: 'bc_upgrade_${allBuildingTypes[i]}_lv3',
        title: 'Upgrade ${_buildingDisplayName(allBuildingTypes[i])} to Lv.3',
        description: 'Improve a ${_buildingDisplayName(allBuildingTypes[i])} to level 3.',
        branch: MissionBranch.basicConstruction,
        checkType: MissionCheckType.bm,
        conditionType: MissionConditionType.upgradeBuilding,
        buildingType: allBuildingTypes[i],
        targetLevel: 3,
        reward: MissionReward(exp: 60 + i * 10, coins: 50 + i * 15, gems: 8 + i * 3),
        orderInBranch: 11 + i,
      ),
  ];

  // ─── Branch 2: Advanced Construction (18 missions, all BM) ───
  // Depends on full completion of basic construction branch.

  static final List<Mission> _advancedConstructionBranch = [
    // Reach count of buildings at level 1 (6 missions)
    for (int i = 0; i < allBuildingTypes.length; i++)
      Mission(
        id: 'ac_count_${allBuildingTypes[i]}_lv1',
        title: 'Reach ${_advCount(allBuildingTypes[i])} ${_buildingDisplayName(allBuildingTypes[i])}s Lv.1',
        description: 'Have ${_advCount(allBuildingTypes[i])} ${_buildingDisplayName(allBuildingTypes[i])}s at level 1 or above.',
        branch: MissionBranch.advancedConstruction,
        checkType: MissionCheckType.bm,
        conditionType: MissionConditionType.reachBuildingCount,
        buildingType: allBuildingTypes[i],
        targetLevel: 1,
        targetCount: _advCount(allBuildingTypes[i]),
        reward: MissionReward(exp: 50 + i * 10, coins: 40 + i * 10),
        orderInBranch: i,
      ),

    // Reach count of buildings at level 2 (6 missions)
    for (int i = 0; i < allBuildingTypes.length; i++)
      Mission(
        id: 'ac_count_${allBuildingTypes[i]}_lv2',
        title: 'Reach ${_advCount(allBuildingTypes[i])} ${_buildingDisplayName(allBuildingTypes[i])}s Lv.2',
        description: 'Have ${_advCount(allBuildingTypes[i])} ${_buildingDisplayName(allBuildingTypes[i])}s at level 2 or above.',
        branch: MissionBranch.advancedConstruction,
        checkType: MissionCheckType.bm,
        conditionType: MissionConditionType.reachBuildingCount,
        buildingType: allBuildingTypes[i],
        targetLevel: 2,
        targetCount: _advCount(allBuildingTypes[i]),
        reward: MissionReward(exp: 80 + i * 10, coins: 60 + i * 15, gems: 10 + i * 3),
        orderInBranch: 6 + i,
      ),

    // Reach count of buildings at level 3 (6 missions)
    for (int i = 0; i < allBuildingTypes.length; i++)
      Mission(
        id: 'ac_count_${allBuildingTypes[i]}_lv3',
        title: 'Reach ${_advCount(allBuildingTypes[i])} ${_buildingDisplayName(allBuildingTypes[i])}s Lv.3',
        description: 'Have ${_advCount(allBuildingTypes[i])} ${_buildingDisplayName(allBuildingTypes[i])}s at level 3.',
        branch: MissionBranch.advancedConstruction,
        checkType: MissionCheckType.bm,
        conditionType: MissionConditionType.reachBuildingCount,
        buildingType: allBuildingTypes[i],
        targetLevel: 3,
        targetCount: _advCount(allBuildingTypes[i]),
        reward: MissionReward(exp: 120 + i * 15, coins: 100 + i * 20, gems: 20 + i * 5),
        orderInBranch: 12 + i,
      ),
  ];

  // ─── Branch 3: Villager (6 missions, all AM) ───

  static const List<Mission> _villagerBranch = [
    Mission(
      id: 'vl_happy_1',
      title: '1 Happy Villager',
      description: 'Get 1 villager to 100% happiness.',
      branch: MissionBranch.villager,
      checkType: MissionCheckType.am,
      conditionType: MissionConditionType.villagerHappiness,
      targetCount: 1,
      reward: MissionReward(exp: 30, coins: 20),
      orderInBranch: 0,
    ),
    Mission(
      id: 'vl_book_happy',
      title: 'Happiness Book',
      description: 'Use a Happiness Book on a villager to temporarily get 100% happiness.',
      branch: MissionBranch.villager,
      checkType: MissionCheckType.am,
      conditionType: MissionConditionType.villagerHappinessWithBook,
      targetCount: 1,
      reward: MissionReward(exp: 40, coins: 30),
      orderInBranch: 1,
    ),
    Mission(
      id: 'vl_happy_3',
      title: '3 Happy Villagers',
      description: 'Get 3 villagers to 100% happiness at the same time.',
      branch: MissionBranch.villager,
      checkType: MissionCheckType.am,
      conditionType: MissionConditionType.villagerHappiness,
      targetCount: 3,
      reward: MissionReward(exp: 60, coins: 50),
      orderInBranch: 2,
    ),
    Mission(
      id: 'vl_happy_5',
      title: '5 Happy Villagers',
      description: 'Get 5 villagers to 100% happiness at the same time.',
      branch: MissionBranch.villager,
      checkType: MissionCheckType.am,
      conditionType: MissionConditionType.villagerHappiness,
      targetCount: 5,
      reward: MissionReward(exp: 80, coins: 70, gems: 10),
      orderInBranch: 3,
    ),
    Mission(
      id: 'vl_happy_10',
      title: '10 Happy Villagers',
      description: 'Get 10 villagers to 100% happiness at the same time.',
      branch: MissionBranch.villager,
      checkType: MissionCheckType.am,
      conditionType: MissionConditionType.villagerHappiness,
      targetCount: 10,
      reward: MissionReward(exp: 120, coins: 100, gems: 20),
      orderInBranch: 4,
    ),
    Mission(
      id: 'vl_happy_12_natural',
      title: '12 Happy Villagers (Natural)',
      description: 'Get 12 villagers to 100% happiness at the same time WITHOUT any Happiness Books active.',
      branch: MissionBranch.villager,
      checkType: MissionCheckType.am,
      conditionType: MissionConditionType.villagerHappinessNatural,
      targetCount: 12,
      reward: MissionReward(exp: 200, coins: 150, gems: 50),
      orderInBranch: 5,
    ),
  ];

  // ─── Branch 4: Book Tracking (11 missions, all BM) ───

  static const List<Mission> _bookTrackingBranch = [
    Mission(
      id: 'bt_pages_100',
      title: 'Read 100 Pages',
      description: 'Log 100 pages read in total.',
      branch: MissionBranch.bookTracking,
      checkType: MissionCheckType.bm,
      conditionType: MissionConditionType.totalPagesRead,
      targetCount: 100,
      reward: MissionReward(exp: 25, gems: 5),
      orderInBranch: 0,
    ),
    Mission(
      id: 'bt_pages_300',
      title: 'Read 300 Pages',
      description: 'Log 300 pages read in total.',
      branch: MissionBranch.bookTracking,
      checkType: MissionCheckType.bm,
      conditionType: MissionConditionType.totalPagesRead,
      targetCount: 300,
      reward: MissionReward(exp: 40, coins: 20, gems: 10),
      orderInBranch: 1,
    ),
    Mission(
      id: 'bt_books_1',
      title: 'Finish 1 Book',
      description: 'Finish reading 1 book completely.',
      branch: MissionBranch.bookTracking,
      checkType: MissionCheckType.bm,
      conditionType: MissionConditionType.booksCompleted,
      targetCount: 1,
      reward: MissionReward(exp: 50, coins: 30, gems: 15),
      orderInBranch: 2,
    ),
    Mission(
      id: 'bt_pages_500',
      title: 'Read 500 Pages',
      description: 'Log 500 pages read in total.',
      branch: MissionBranch.bookTracking,
      checkType: MissionCheckType.bm,
      conditionType: MissionConditionType.totalPagesRead,
      targetCount: 500,
      reward: MissionReward(exp: 60, coins: 40, gems: 20),
      orderInBranch: 3,
    ),
    Mission(
      id: 'bt_pages_750',
      title: 'Read 750 Pages',
      description: 'Log 750 pages read in total.',
      branch: MissionBranch.bookTracking,
      checkType: MissionCheckType.bm,
      conditionType: MissionConditionType.totalPagesRead,
      targetCount: 750,
      reward: MissionReward(exp: 70, coins: 50, gems: 25),
      orderInBranch: 4,
    ),
    Mission(
      id: 'bt_books_2',
      title: 'Finish 2 Books',
      description: 'Finish reading 2 books completely.',
      branch: MissionBranch.bookTracking,
      checkType: MissionCheckType.bm,
      conditionType: MissionConditionType.booksCompleted,
      targetCount: 2,
      reward: MissionReward(exp: 80, coins: 60, gems: 30),
      orderInBranch: 5,
    ),
    Mission(
      id: 'bt_pages_1000',
      title: 'Read 1,000 Pages',
      description: 'Log 1,000 pages read in total.',
      branch: MissionBranch.bookTracking,
      checkType: MissionCheckType.bm,
      conditionType: MissionConditionType.totalPagesRead,
      targetCount: 1000,
      reward: MissionReward(exp: 100, coins: 80, gems: 35),
      orderInBranch: 6,
    ),
    Mission(
      id: 'bt_pages_1500',
      title: 'Read 1,500 Pages',
      description: 'Log 1,500 pages read in total.',
      branch: MissionBranch.bookTracking,
      checkType: MissionCheckType.bm,
      conditionType: MissionConditionType.totalPagesRead,
      targetCount: 1500,
      reward: MissionReward(exp: 120, coins: 100, gems: 40),
      orderInBranch: 7,
    ),
    Mission(
      id: 'bt_books_4',
      title: 'Finish 4 Books',
      description: 'Finish reading 4 books completely.',
      branch: MissionBranch.bookTracking,
      checkType: MissionCheckType.bm,
      conditionType: MissionConditionType.booksCompleted,
      targetCount: 4,
      reward: MissionReward(exp: 140, coins: 120, gems: 45),
      orderInBranch: 8,
    ),
    Mission(
      id: 'bt_pages_2500',
      title: 'Read 2,500 Pages',
      description: 'Log 2,500 pages read in total.',
      branch: MissionBranch.bookTracking,
      checkType: MissionCheckType.bm,
      conditionType: MissionConditionType.totalPagesRead,
      targetCount: 2500,
      reward: MissionReward(exp: 180, coins: 150, gems: 50),
      orderInBranch: 9,
    ),
    Mission(
      id: 'bt_books_8',
      title: 'Finish 8 Books',
      description: 'Finish reading 8 books completely.',
      branch: MissionBranch.bookTracking,
      checkType: MissionCheckType.bm,
      conditionType: MissionConditionType.booksCompleted,
      targetCount: 8,
      reward: MissionReward(exp: 250, coins: 200, gems: 60),
      orderInBranch: 10,
    ),
  ];

  // ─── Helpers ───

  static String _buildingDisplayName(String type) {
    switch (type) {
      case 'house': return 'House';
      case 'park': return 'Park';
      case 'water_plant': return 'Water Tower';
      case 'power_plant': return 'Power Station';
      case 'school': return 'School';
      case 'hospital': return 'Clinic';
      default: return type;
    }
  }

  /// Houses need 5, other buildings need 3.
  static int _advCount(String type) => type == 'house' ? 5 : 3;

  static Mission? getMissionById(String id) {
    try {
      return allMissions.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  static List<Mission> getMissionsForBranch(MissionBranch branch) {
    return allMissions.where((m) => m.branch == branch).toList()
      ..sort((a, b) => a.orderInBranch.compareTo(b.orderInBranch));
  }

  static String branchDisplayName(MissionBranch branch) {
    switch (branch) {
      case MissionBranch.basicConstruction: return 'Basic Construction';
      case MissionBranch.advancedConstruction: return 'Advanced Construction';
      case MissionBranch.villager: return 'Villager';
      case MissionBranch.bookTracking: return 'Book Tracking';
    }
  }

  static String branchDescription(MissionBranch branch) {
    switch (branch) {
      case MissionBranch.basicConstruction: return 'Build and upgrade all building types';
      case MissionBranch.advancedConstruction: return 'Expand your village with multiple buildings';
      case MissionBranch.villager: return 'Keep your villagers happy';
      case MissionBranch.bookTracking: return 'Track your reading journey';
    }
  }

  /// Returns branches that must be fully completed before this branch unlocks.
  static List<MissionBranch> branchDependencies(MissionBranch branch) {
    switch (branch) {
      case MissionBranch.advancedConstruction:
        return [MissionBranch.basicConstruction];
      default:
        return [];
    }
  }
}
