import 'package:flame/components.dart';
import 'package:flame/events.dart';

enum PetState { idle, box }

class Pet extends SpriteAnimationGroupComponent<PetState> with TapCallbacks {
  @override
  Future<void> onLoad() async {
    anchor = Anchor.bottomCenter;
    size = Vector2(32, 32);

    final [idle, box] = await Future.wait([
      SpriteAnimation.load(
        'Idle.png',
        SpriteAnimationData.sequenced(
          amount: 10,
          textureSize: Vector2(32, 32),
          stepTime: 0.15,
        ),
      ),
      SpriteAnimation.load(
        'Box3.png',
        SpriteAnimationData.sequenced(
          amount: 4,
          textureSize: Vector2(32, 32),
          stepTime: 0.15,
        ),
      ),
    ]);

    animations = {PetState.idle: idle, PetState.box: box};
    current = PetState.idle;

    return super.onLoad();
  }

  @override
  void onTapDown(TapDownEvent event) {
    current = current == PetState.idle ? PetState.box : PetState.idle;
  }
}
