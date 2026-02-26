import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'components/background.dart';
import 'components/furniture_sprite.dart';
import 'components/pet.dart';
import 'components/ui_bar.dart';
import 'data/models.dart';

class FamilyPetGame extends FlameGame with KeyboardEvents {
  FamilyPetGame({this.creature, this.resources});

  Creature? creature;
  Resources? resources;

  late UiBar uiBar;
  late Background background;
  late Pet pet;
  late FurnitureSpriteSheet sheet;

  @override
  Color backgroundColor() => const Color(0xFFf2e9e1);

  @override
  Future<void> onLoad() async {
    camera = CameraComponent.withFixedResolution(width: 200, height: 400)
      ..viewfinder.anchor = Anchor.topLeft;

    uiBar = UiBar(position: Vector2(10, 9));
    camera.viewport.add(uiBar);

    // Initialize stat bars from DB creature data if available
    final c = creature;
    if (c != null) {
      uiBar.fullness = c.fullness;
      uiBar.happiness = c.happiness;
      uiBar.cleanliness = c.cleanliness;
    }

    // background
    background = Background(theme: 'Classic', index: 1)..position = Vector2(100, 45);
    world.add(background);

    // in game things
    pet = Pet()..position = Vector2(100, 320);
    world.add(pet);

    sheet = await FurnitureSpriteSheet.load();                                                                                                                 
                                                                                                                                                                    
    world.addAll([
      sheet.createSprite(42, position: Vector2(80, 200)),
      sheet.createSprite(315, position: Vector2(150, 330), priorityOffset: -17),
      sheet.createSprite(50, position: Vector2(60, 330), priorityOffset: -15),
    ]);

    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    for (final child in world.children) {
      if (child is FurnitureSpriteComponent) {
        child.priority = child.effectivePriority;
      } else if (child is PositionComponent) {
        child.priority = child.position.y.toInt();
      }
    }
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    // WASD movement
    final direction = Vector2.zero();
    if (keysPressed.contains(LogicalKeyboardKey.keyW)) direction.y -= 1;
    if (keysPressed.contains(LogicalKeyboardKey.keyS)) direction.y += 1;
    if (keysPressed.contains(LogicalKeyboardKey.keyA)) direction.x -= 1;
    if (keysPressed.contains(LogicalKeyboardKey.keyD)) direction.x += 1;
    if (direction.length > 0) direction.normalize();
    pet.velocity.setFrom(direction);

    // Debug stat controls
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.digit1) {
        uiBar.happiness -= 10;
        if (uiBar.happiness < 50) {
          pet.current = PetState.cry;
        }
      } else if (event.logicalKey == LogicalKeyboardKey.digit2) {
        uiBar.happiness += 10;
        if (uiBar.happiness >= 50) {
          pet.current = PetState.idle;
        }
      }
    }
    return KeyEventResult.handled;
  }
}
