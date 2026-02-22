import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/flame.dart';

/// Sprite data for a single furniture item from the sprite sheet.
class _SpriteData {
  final int id;
  final double x, y, width, height;

  _SpriteData({
    required this.id,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  factory _SpriteData.fromJson(Map<String, dynamic> json) {
    return _SpriteData(
      id: json['id'] as int,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
    );
  }
}

/// Loads and caches the furniture sprite sheet + JSON coordinate map.
/// Call [FurnitureSpriteSheet.load] once, then use [createSprite] to
/// build sprites by ID.
class FurnitureSpriteSheet {
  FurnitureSpriteSheet._(this._sprites, this._image);

  final Map<int, _SpriteData> _sprites;
  final Image _image;

  static FurnitureSpriteSheet? _instance;

  /// Load the sprite sheet and JSON. Safe to call multiple times (cached).
  static Future<FurnitureSpriteSheet> load() async {
    if (_instance != null) return _instance!;

    final data =
        await Flame.assets.readJson('images/Assets/furnitures_sprites.json');
    final spriteList = (data['sprites'] as List)
        .map((e) => _SpriteData.fromJson(e as Map<String, dynamic>))
        .toList();

    final sprites = {for (final s in spriteList) s.id: s};
    final image = await Flame.images.load('Assets/Furnitures,Playgrounds,Toys.png');

    _instance = FurnitureSpriteSheet._(sprites, image);
    return _instance!;
  }

  /// Number of sprites available.
  int get count => _sprites.length;

  /// All available sprite IDs.
  Iterable<int> get ids => _sprites.keys;

  /// Create a [SpriteComponent] for the given furniture ID.
  /// Anchored at bottom-center with the sprite's original pixel size.
  ///
  /// [priorityOffset] shifts the y value used for priority sorting.
  /// Negative values make it sort earlier (behind other objects).
  /// e.g. a flat mat with priorityOffset: -100 will render behind
  /// a cat standing on it at the same y position.
  SpriteComponent createSprite(int id, {Vector2? position, int priorityOffset = 0}) {
    final data = _sprites[id];
    if (data == null) {
      throw ArgumentError('No furniture sprite with id $id');
    }
    return FurnitureSpriteComponent(
      sprite: Sprite(
        _image,
        srcPosition: Vector2(data.x, data.y),
        srcSize: Vector2(data.width, data.height),
      ),
      size: Vector2(data.width, data.height),
      position: position,
      anchor: Anchor.bottomCenter,
      priorityOffset: priorityOffset,
    );
  }
}

class FurnitureSpriteComponent extends SpriteComponent {
  FurnitureSpriteComponent({
    required super.sprite,
    required super.size,
    required super.anchor,
    super.position,
    this.priorityOffset = 0,
  });

  final int priorityOffset;

  /// Effective y for priority sorting (used by game_engine update loop).
  int get effectivePriority => position.y.toInt() + priorityOffset;
}

