enum ResourceType { food, play, clean }

class Resources {
  final int food;
  final int play;
  final int clean;
  final int boxPieces;

  Resources({
    required this.food,
    required this.play,
    required this.clean,
    this.boxPieces = 0,
  });

  factory Resources.fromJson(Map<String, dynamic> json) => Resources(
    food: (json['food'] as num? ?? 0).toInt(),
    play: (json['play'] as num? ?? 0).toInt(),
    clean: (json['clean'] as num? ?? 0).toInt(),
    boxPieces: (json['box_pieces'] as num? ?? 0).toInt(),
  );

  static Resources get empty => Resources(food: 0, play: 0, clean: 0);

  Resources copyWith({int? food, int? play, int? clean, int? boxPieces}) =>
      Resources(
        food: food ?? this.food,
        play: play ?? this.play,
        clean: clean ?? this.clean,
        boxPieces: boxPieces ?? this.boxPieces,
      );

  int amountFor(ResourceType type) => switch (type) {
    ResourceType.food => food,
    ResourceType.play => play,
    ResourceType.clean => clean,
  };
}

class Creature {
  final String type;
  final String name;
  final int fullness;
  final int happiness;
  final int cleanliness;
  final DateTime lastUpdatedAt;

  Creature({
    required this.type,
    required this.name,
    required this.fullness,
    required this.happiness,
    required this.cleanliness,
    DateTime? lastUpdatedAt,
  }) : lastUpdatedAt = lastUpdatedAt ?? DateTime.now().toUtc();

  factory Creature.fromJson(Map<String, dynamic> json) => Creature(
    type: json['type'] as String? ?? 'cat',
    name: json['name'] as String? ?? 'Pet',
    fullness: (json['fullness'] as num? ?? 100).toInt(),
    happiness: (json['happiness'] as num? ?? 100).toInt(),
    cleanliness: (json['cleanliness'] as num? ?? 100).toInt(),
    lastUpdatedAt: json['last_updated_at'] != null
        ? DateTime.parse(json['last_updated_at'] as String).toUtc()
        : DateTime.now().toUtc(),
  );

  Creature copyWith({
    int? fullness,
    int? happiness,
    int? cleanliness,
    DateTime? lastUpdatedAt,
  }) => Creature(
    type: type,
    name: name,
    fullness: fullness ?? this.fullness,
    happiness: happiness ?? this.happiness,
    cleanliness: cleanliness ?? this.cleanliness,
    lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
  );

  int statFor(ResourceType type) => switch (type) {
    ResourceType.food => fullness,
    ResourceType.play => happiness,
    ResourceType.clean => cleanliness,
  };
}
