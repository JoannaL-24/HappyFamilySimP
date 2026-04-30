/// Sprite indices that represent pet beds / sleeping surfaces.
const Set<int> kBedSpriteIndices = {
  340, 341, 342, 343, 344, 345, 346, 347,
};

/// Sprite indices that represent cat-friendly toys / play structures.
const Set<int> kToySpriteIndices = {
  // Cat trees
  39, 40, 41,
  // Cat playgrounds
  50, 51, 52, 53,
  80, 81, 82, 83, 84, 85,
  106, 107, 108, 109, 110, 111, 112, 113, 114, 115,
  // Balls
  175, 176, 177, 178, 179, 180, 181, 182,
  183, 184, 185, 186,
  193, 194, 195, 196, 197, 198, 199,
  200, 201, 202, 203, 204,
  // Yarn balls
  376, 377, 378, 379, 380, 381, 382, 383, 384,
  // Cat toys (fish)
  334, 335, 336,
  // Mouse toys
  348, 350, 351, 352, 353, 354, 355, 356, 357,
  402, 403, 404,
  // Toys
  397, 398, 399, 400, 401,
};

class CosmeticItem {
  final int id;
  final String name;
  final int spriteIndex;
  final bool isDefault;
  final int priorityOffset;

  CosmeticItem({
    required this.id,
    required this.name,
    required this.spriteIndex,
    required this.isDefault,
    this.priorityOffset = 0,
  });

  factory CosmeticItem.fromJson(Map<String, dynamic> json) => CosmeticItem(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String,
    spriteIndex: (json['sprite_index'] as num).toInt(),
    isDefault: json['is_default'] as bool? ?? false,
    priorityOffset: (json['priority_offset'] as num? ?? 0).toInt(),
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
      priorityOffset: (nested['priority_offset'] as num? ?? 0).toInt(),
      posX: (json['pos_x'] as num).toDouble(),
      posY: (json['pos_y'] as num).toDouble(),
    );
  }
}
