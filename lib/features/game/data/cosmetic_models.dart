class CosmeticItem {
  final int id;
  final String name;
  final int spriteIndex;
  final bool isDefault;

  CosmeticItem({
    required this.id,
    required this.name,
    required this.spriteIndex,
    required this.isDefault,
  });

  factory CosmeticItem.fromJson(Map<String, dynamic> json) => CosmeticItem(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String,
    spriteIndex: (json['sprite_index'] as num).toInt(),
    isDefault: json['is_default'] as bool? ?? false,
  );
}

class RoomPlacement {
  final String id;
  final String childId;
  final int itemId;
  final int spriteIndex; // from cosmetic_items join — used to look up the sprite
  double posX;
  double posY;
  final int priorityOffset;

  RoomPlacement({
    required this.id,
    required this.childId,
    required this.itemId,
    required this.spriteIndex,
    required this.posX,
    required this.posY,
    this.priorityOffset = 0,
  });

  /// Expects the row to include a nested `cosmetic_items` object with
  /// `sprite_index`, as returned by `.select('*, cosmetic_items(sprite_index)')`.
  factory RoomPlacement.fromJson(Map<String, dynamic> json) {
    final nested =
        json['cosmetic_items'] as Map<String, dynamic>? ?? {};
    return RoomPlacement(
      id: json['id'] as String,
      childId: json['child_id'] as String,
      itemId: (json['item_id'] as num).toInt(),
      spriteIndex: (nested['sprite_index'] as num? ?? 42).toInt(),
      posX: (json['pos_x'] as num).toDouble(),
      posY: (json['pos_y'] as num).toDouble(),
      priorityOffset: (json['priority_offset'] as num? ?? 0).toInt(),
    );
  }
}
