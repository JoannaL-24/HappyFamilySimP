import 'package:flame/components.dart';
import 'package:flame/game.dart';

import 'components/pet.dart';

class FamilyPetGame extends FlameGame {
  FamilyPetGame()
    : super(
        camera: CameraComponent.withFixedResolution(width: 400, height: 800),
      );
  late Pet pet;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    pet = Pet()..position = Vector2(50, 100);
    add(pet);
  }
}
