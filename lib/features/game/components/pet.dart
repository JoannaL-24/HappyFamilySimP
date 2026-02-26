import 'package:flame/components.dart';
import 'package:flame/events.dart';

enum PetState { idle, cry }

class Pet extends SpriteAnimationGroupComponent<PetState> with TapCallbacks {
  final Vector2 velocity = Vector2.zero();
  double speed = 100;

  @override
  Future<void> onLoad() async {
    anchor = Anchor.bottomCenter;
    size = Vector2(32, 32);

    final [idle, box] = await Future.wait([
      SpriteAnimation.load(
        'Assets/Cats/CatSprites/Classical/Individual/Idle.png',
        SpriteAnimationData.sequenced(
          amount: 10,
          textureSize: Vector2(32, 32),
          stepTime: 0.15,
        ),
      ),
      SpriteAnimation.load(
        'Assets/Cats/CatSprites/Classical/Individual/Cry.png',
        SpriteAnimationData.sequenced(
          amount: 4,
          textureSize: Vector2(32, 32),
          stepTime: 0.15,
        ),
      ),
    ]);

    animations = {PetState.idle: idle, PetState.cry: box};
    current = PetState.idle;

    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.add(velocity * speed * dt);

    // Flip sprite when moving left
    if (velocity.x > 0 && !isFlippedHorizontally) {
      flipHorizontallyAroundCenter();
    } else if (velocity.x < 0 && isFlippedHorizontally) {
      flipHorizontallyAroundCenter();
    }
  }

  // @override
  // void onTapDown(TapDownEvent event) {
  //   current = current == PetState.idle ? PetState.cry : PetState.idle;
  // }
}
