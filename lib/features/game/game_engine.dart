import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'components/pet.dart';
import 'components/ui_bar.dart';

class FamilyPetGame extends FlameGame with KeyboardEvents {
  late Pet pet;
  late UiBar uiBar;

  @override
  Future<void> onLoad() async {
    camera = CameraComponent.withFixedResolution(width: 200, height: 400);

    pet = Pet()..position = Vector2(0, 0);
    world.add(pet);

    uiBar = UiBar();
    camera.viewport.add(uiBar);

    return super.onLoad();
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.digit1) {
        uiBar.fullness -= 10;
      } else if (event.logicalKey == LogicalKeyboardKey.digit2) {
        uiBar.hydration -= 10;
      } else if (event.logicalKey == LogicalKeyboardKey.digit3) {
        uiBar.cleanliness -= 10;
      }
    }
    return KeyEventResult.handled;
  }
}
