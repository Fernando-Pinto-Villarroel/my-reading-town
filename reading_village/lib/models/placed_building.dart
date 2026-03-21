class PlacedBuilding {
  final int? id;
  final String type;
  final String name;
  int tileX;
  int tileY;
  int level;
  final int coinCost;
  final int gemCost;
  final int woodCost;
  final int metalCost;
  final int happinessBonus;
  String? constructionStart;
  int constructionDurationMinutes;
  bool isConstructed;
  bool isFlipped;

  PlacedBuilding({
    this.id,
    required this.type,
    required this.name,
    required this.tileX,
    required this.tileY,
    this.level = 1,
    required this.coinCost,
    this.gemCost = 0,
    this.woodCost = 0,
    this.metalCost = 0,
    required this.happinessBonus,
    this.constructionStart,
    this.constructionDurationMinutes = 60,
    this.isConstructed = false,
    this.isFlipped = false,
  });

  bool get isBuilt => isConstructed && level > 0;
  int get totalHappiness => isConstructed ? happinessBonus * level : 0;

  bool get isConstructionComplete {
    if (isConstructed) return true;
    if (constructionStart == null) return false;
    final start = DateTime.parse(constructionStart!);
    return DateTime.now().difference(start) >=
        Duration(minutes: constructionDurationMinutes);
  }

  Duration get remainingConstructionTime {
    if (isConstructed || constructionStart == null) return Duration.zero;
    final start = DateTime.parse(constructionStart!);
    final elapsed = DateTime.now().difference(start);
    final remaining = Duration(minutes: constructionDurationMinutes) - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'type': type,
      'name': name,
      'tile_x': tileX,
      'tile_y': tileY,
      'level': level,
      'coin_cost': coinCost,
      'gem_cost': gemCost,
      'wood_cost': woodCost,
      'metal_cost': metalCost,
      'happiness_bonus': happinessBonus,
      'construction_start': constructionStart,
      'construction_duration_minutes': constructionDurationMinutes,
      'is_constructed': isConstructed ? 1 : 0,
      'is_flipped': isFlipped ? 1 : 0,
    };
  }

  factory PlacedBuilding.fromMap(Map<String, dynamic> map) {
    return PlacedBuilding(
      id: map['id'] as int?,
      type: map['type'] as String,
      name: map['name'] as String,
      tileX: map['tile_x'] as int,
      tileY: map['tile_y'] as int,
      level: map['level'] as int? ?? 1,
      coinCost: map['coin_cost'] as int,
      gemCost: map['gem_cost'] as int? ?? 0,
      woodCost: map['wood_cost'] as int? ?? 0,
      metalCost: map['metal_cost'] as int? ?? 0,
      happinessBonus: map['happiness_bonus'] as int? ?? 0,
      constructionStart: map['construction_start'] as String?,
      constructionDurationMinutes:
          map['construction_duration_minutes'] as int? ?? 60,
      isConstructed: (map['is_constructed'] as int? ?? 0) == 1,
      isFlipped: (map['is_flipped'] as int? ?? 0) == 1,
    );
  }

  PlacedBuilding copyWith({
    int? id,
    int? level,
    bool? isConstructed,
    String? constructionStart,
    int? constructionDurationMinutes,
    bool? isFlipped,
  }) {
    return PlacedBuilding(
      id: id ?? this.id,
      type: type,
      name: name,
      tileX: tileX,
      tileY: tileY,
      level: level ?? this.level,
      coinCost: coinCost,
      gemCost: gemCost,
      woodCost: woodCost,
      metalCost: metalCost,
      happinessBonus: happinessBonus,
      constructionStart: constructionStart ?? this.constructionStart,
      constructionDurationMinutes:
          constructionDurationMinutes ?? this.constructionDurationMinutes,
      isConstructed: isConstructed ?? this.isConstructed,
      isFlipped: isFlipped ?? this.isFlipped,
    );
  }
}
