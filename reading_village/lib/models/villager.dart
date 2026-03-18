import '../config/game_constants.dart';

class Villager {
  final int? id;
  String name;
  final String species;
  int happiness;
  final int? houseId;

  Villager({
    this.id,
    required this.name,
    required this.species,
    this.happiness = 50,
    this.houseId,
  });

  bool get isSad => happiness < GameConstants.sadHappinessThreshold;

  String get spriteFile =>
      isSad ? '${species}_villager_sad.png' : '${species}_villager.png';

  String get assetPath => 'assets/images/$spriteFile';

  String get moodText {
    if (happiness >= 80) return 'Ecstatic';
    if (happiness >= 60) return 'Happy';
    if (happiness >= 40) return 'Okay';
    if (happiness >= 20) return 'Unhappy';
    return 'Sad';
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'species': species,
      'happiness': happiness,
      'house_id': houseId,
    };
  }

  factory Villager.fromMap(Map<String, dynamic> map) {
    return Villager(
      id: map['id'] as int?,
      name: map['name'] as String,
      species: map['species'] as String,
      happiness: map['happiness'] as int? ?? 50,
      houseId: map['house_id'] as int?,
    );
  }
}
