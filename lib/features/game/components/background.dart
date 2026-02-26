import 'package:flame/components.dart';

/// Renders a background image from the Backgrounds asset folder.
/// Anchored at center and sized to fill the camera resolution.
class Background extends SpriteComponent {
  Background({
    this.theme = 'Classic',
    this.index = 1,
  }) : super(anchor: Anchor.topCenter, priority: -1);

  final String theme;
  final int index;

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('Assets/Backgrounds/$theme/$index.png');
    size = sprite!.originalSize;
  }
}
