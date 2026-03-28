class InventoryItem {
  final int? id;
  final String type;
  int quantity;

  InventoryItem({
    this.id,
    required this.type,
    this.quantity = 0,
  });

  String get displayName {
    switch (type) {
      case 'book':
        return 'Happiness Book';
      case 'sandwich':
        return 'Constructor Sandwich';
      case 'hammer':
        return 'Constructor Hammer';
      default:
        return type;
    }
  }

  String get description {
    switch (type) {
      case 'book':
        return 'Give to a villager to boost their happiness to 100% for 24 hours!';
      case 'sandwich':
        return 'Speed up all constructions by 2x for 1 hour!';
      case 'hammer':
        return 'Gain an extra constructor slot for 24 hours!';
      default:
        return '';
    }
  }

  String get assetName {
    switch (type) {
      case 'book':
        return 'book_item.png';
      case 'sandwich':
        return 'sandwich_item.png';
      case 'hammer':
        return 'hammer_item.png';
      default:
        return 'gem.png';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'type': type,
      'quantity': quantity,
    };
  }

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id'] as int?,
      type: map['type'] as String,
      quantity: map['quantity'] as int? ?? 0,
    );
  }
}

class ActivePowerup {
  final int? id;
  final String type;
  final int? targetVillagerId;
  final String activatedAt;
  final int durationHours;

  ActivePowerup({
    this.id,
    required this.type,
    this.targetVillagerId,
    required this.activatedAt,
    required this.durationHours,
  });

  bool get isActive {
    final start = DateTime.parse(activatedAt);
    return DateTime.now().difference(start) < Duration(hours: durationHours);
  }

  Duration get remainingTime {
    final start = DateTime.parse(activatedAt);
    final elapsed = DateTime.now().difference(start);
    final remaining = Duration(hours: durationHours) - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'type': type,
      'target_villager_id': targetVillagerId,
      'activated_at': activatedAt,
      'duration_hours': durationHours,
    };
  }

  factory ActivePowerup.fromMap(Map<String, dynamic> map) {
    return ActivePowerup(
      id: map['id'] as int?,
      type: map['type'] as String,
      targetVillagerId: map['target_villager_id'] as int?,
      activatedAt: map['activated_at'] as String,
      durationHours: map['duration_hours'] as int? ?? 24,
    );
  }
}

class MinigameCooldown {
  final String minigameId;
  final String cooldownEnd;

  MinigameCooldown({
    required this.minigameId,
    required this.cooldownEnd,
  });

  bool get isOnCooldown {
    final end = DateTime.parse(cooldownEnd);
    return DateTime.now().isBefore(end);
  }

  Duration get remainingCooldown {
    final end = DateTime.parse(cooldownEnd);
    final remaining = end.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  Map<String, dynamic> toMap() {
    return {
      'minigame_id': minigameId,
      'cooldown_end': cooldownEnd,
    };
  }

  factory MinigameCooldown.fromMap(Map<String, dynamic> map) {
    return MinigameCooldown(
      minigameId: map['minigame_id'] as String,
      cooldownEnd: map['cooldown_end'] as String,
    );
  }
}
