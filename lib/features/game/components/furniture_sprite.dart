import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/flame.dart';

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

class FurnitureSpriteSheet {
  FurnitureSpriteSheet._(this._sprites, this._image);

  final Map<int, _SpriteData> _sprites;
  final Image _image;

  static FurnitureSpriteSheet? _instance;

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

  int get count => _sprites.length;

  Iterable<int> get ids => _sprites.keys;

  /// The raw texture atlas image — usable in Flutter CustomPainters.
  Image get atlasImage => _image;

  /// Source rect of [id] inside the atlas, or null if not found.
  Rect? spriteSourceRect(int id) {
    final d = _sprites[id];
    if (d == null) return null;
    return Rect.fromLTWH(d.x, d.y, d.width, d.height);
  }

  /// Pixel size of [id], or null if not found.
  Size? spriteSize(int id) {
    final d = _sprites[id];
    if (d == null) return null;
    return Size(d.width, d.height);
  }

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

  static bool debugPriority = false;

  /// Effective y for priority sorting (used by game_engine update loop).
  int get effectivePriority => position.y.toInt() + priorityOffset;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (!debugPriority) return;

    // Draw a line at the priority-offset y (local canvas coords).
    // Anchor is bottomCenter so bottom edge is at canvas y = size.y.
    final lineY = size.y + priorityOffset;
    final paint = Paint()
      ..color = const Color(0xFFFF00FF)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, lineY), Offset(size.x, lineY), paint);
    canvas.drawCircle(Offset(size.x / 2, lineY), 2, paint);
  }
}

