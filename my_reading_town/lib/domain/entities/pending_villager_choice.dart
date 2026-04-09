class PendingVillagerChoice {
  final int id;
  final int houseId;
  final String species1;
  final String species2;
  final String species3;
  final String name1;
  final String name2;
  final String name3;

  const PendingVillagerChoice({
    required this.id,
    required this.houseId,
    required this.species1,
    required this.species2,
    required this.species3,
    required this.name1,
    required this.name2,
    required this.name3,
  });

  List<String> get speciesOptions => [species1, species2, species3];
  List<String> get nameOptions => [name1, name2, name3];

  factory PendingVillagerChoice.fromMap(Map<String, dynamic> map) {
    return PendingVillagerChoice(
      id: map['id'] as int,
      houseId: map['house_id'] as int,
      species1: map['species1'] as String,
      species2: map['species2'] as String,
      species3: map['species3'] as String,
      name1: map['name1'] as String,
      name2: map['name2'] as String,
      name3: map['name3'] as String,
    );
  }
}
