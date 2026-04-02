import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'components/background.dart';
import 'components/furniture_sprite.dart';
import 'components/pet.dart';
import 'components/placed_item_component.dart';
import 'components/ui_bar.dart';
import 'components/water_drop_effect.dart' show WaterDropSpawner;
import 'data/cosmetic_models.dart';
import 'data/models.dart';

const int kStatIncrement = 10;

class FamilyPetGame extends FlameGame with KeyboardEvents {
  FamilyPetGame({
    this.creature,
    this.resources,
    this.initialPlacements,
    this.onStatsUpdated,
    this.onPlacementMoved,
    this.onPlacementSelected,
  });

  Creature? creature;
  Resources? resources;
  final List<RoomPlacement>? initialPlacements;

  /// (fullness, happiness, cleanliness) — called after debug key changes.
  final void Function(int, int, int)? onStatsUpdated;

  /// Called when a placed item finishes dragging.
  final void Function(String id, double x, double y)? onPlacementMoved;

  /// Called when a placed item is tapped in edit mode (null = deselect).
  final void Function(String? id)? onPlacementSelected;

  late UiBar uiBar;
  late Background background;
  late Pet pet;
  late FurnitureSpriteSheet sheet;

  bool _editMode = false;
  String? _selectedPlacementId;
  final Map<String, PlacedItemComponent> _placedComponents = {};

  @override
  Color backgroundColor() => const Color(0xFFf2e9e1);

  @override
  Future<void> onLoad() async {
    camera = CameraComponent.withFixedResolution(width: 200, height: 400)
      ..viewfinder.anchor = Anchor.topLeft;

    uiBar = UiBar(position: Vector2(10, 9));
    camera.viewport.add(uiBar);

    final c = creature;
    if (c != null) {
      uiBar.fullness = c.fullness;
      uiBar.happiness = c.happiness;
      uiBar.cleanliness = c.cleanliness;
    }

    background = Background(theme: 'Classic', index: 1)
      ..position = Vector2(100, 45);
    world.add(background);

    pet = Pet()..position = Vector2(100, 320);
    world.add(pet);

    sheet = await FurnitureSpriteSheet.load();

    // Load DB placements; fall back to defaults if none exist yet.
    final placements = initialPlacements;
    if (placements != null && placements.isNotEmpty) {
      for (final p in placements) {
        _addPlacedComponent(p);
      }
    } else {
      // Default room layout until the child decorates
      // _addDefaultFurniture();
    }

    return super.onLoad();
  }

  @override
  void onMount() {
    super.onMount();
    _updatePetMood();
  }

  void _addDefaultFurniture() {
    world.addAll([
      sheet.createSprite(42, position: Vector2(80, 200)),
      sheet.createSprite(340, position: Vector2(150, 330), priorityOffset: -17),
      sheet.createSprite(50, position: Vector2(60, 330), priorityOffset: -15),
    ]);
  }

  // ── Edit mode ─────────────────────────────────────────────────────────────

  bool get editMode => _editMode;

  void setEditMode(bool value) {
    _editMode = value;
    for (final comp in _placedComponents.values) {
      comp.editMode = value;
    }
    if (!value) {
      _selectPlacement(null);
    }
  }

  void _selectPlacement(String? id) {
    for (final comp in _placedComponents.values) {
      comp.isSelected = comp.placementId == id;
    }
    _selectedPlacementId = id;
    onPlacementSelected?.call(id);
  }

  // ── Placement management ──────────────────────────────────────────────────

  void addPlacement(RoomPlacement placement) {
    _addPlacedComponent(placement);
  }

  void removePlacement(String id) {
    final comp = _placedComponents.remove(id);
    comp?.removeFromParent();
    if (_selectedPlacementId == id) {
      _selectedPlacementId = null;
      onPlacementSelected?.call(null);
    }
  }

  void _addPlacedComponent(RoomPlacement p) {
    final comp = PlacedItemComponent(
      sprite: sheet.createSprite(p.spriteIndex).sprite!,
      size: sheet.spriteSize(p.spriteIndex)?.toVector2() ?? Vector2(32, 32),
      anchor: Anchor.bottomCenter,
      position: Vector2(p.posX, p.posY),
      priorityOffset: p.priorityOffset,
      placementId: p.id,
      itemId: p.itemId,
      onMoved: (id, x, y) {
        p.posX = x;
        p.posY = y;
        onPlacementMoved?.call(id, x, y);
      },
      onSelected: _selectPlacement,
    );
    comp.editMode = _editMode;
    _placedComponents[p.id] = comp;
    world.add(comp);
  }

  // ── Stat/mood helpers ─────────────────────────────────────────────────────

  bool canApplyResource(ResourceType type) {
    final res = resources;
    if (res == null) return false;
    return res.amountFor(type) > 0 && _statFor(type) < 100;
  }

  void triggerResourceAnimation(ResourceType type) {
    switch (type) {
      case ResourceType.food:
        pet.playOneShot(PetState.eating, loops: 2);
        uiBar.fullness = uiBar.fullness + kStatIncrement;
      case ResourceType.play:
        pet.playOneShot(PetState.dancing, loops: 3);
        uiBar.happiness = uiBar.happiness + kStatIncrement;
      case ResourceType.clean:
        uiBar.cleanliness = uiBar.cleanliness + kStatIncrement;
        world.add(
          WaterDropSpawner(
            getPosition: () => pet.position.clone()..y -= 12,
            getPetPriority: () => pet.priority,
            bursts: 4,
            interval: 0.55,
          ),
        );
    }
    _updatePetMood();
  }

  void _updatePetMood() {
    pet.updateMood(
      fullness: uiBar.fullness,
      happiness: uiBar.happiness,
      cleanliness: uiBar.cleanliness,
    );
  }

  int _statFor(ResourceType type) => switch (type) {
    ResourceType.food => uiBar.fullness,
    ResourceType.play => uiBar.happiness,
    ResourceType.clean => uiBar.cleanliness,
  };

  // ── Update loop ───────────────────────────────────────────────────────────

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

  // ── Keyboard (debug) ──────────────────────────────────────────────────────

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    final direction = Vector2.zero();
    if (keysPressed.contains(LogicalKeyboardKey.keyW)) direction.y -= 1;
    if (keysPressed.contains(LogicalKeyboardKey.keyS)) direction.y += 1;
    if (keysPressed.contains(LogicalKeyboardKey.keyA)) direction.x -= 1;
    if (keysPressed.contains(LogicalKeyboardKey.keyD)) direction.x += 1;
    if (direction.length > 0) direction.normalize();
    pet.velocity.setFrom(direction);

    if (event is KeyDownEvent) {
      bool changed = true;
      if (event.logicalKey == LogicalKeyboardKey.digit1) {
        uiBar.fullness -= 10;
      } else if (event.logicalKey == LogicalKeyboardKey.digit2) {
        uiBar.fullness += 10;
      } else if (event.logicalKey == LogicalKeyboardKey.digit3) {
        uiBar.happiness -= 10;
      } else if (event.logicalKey == LogicalKeyboardKey.digit4) {
        uiBar.happiness += 10;
      } else if (event.logicalKey == LogicalKeyboardKey.digit5) {
        uiBar.cleanliness -= 10;
      } else if (event.logicalKey == LogicalKeyboardKey.digit6) {
        uiBar.cleanliness += 10;
      } else {
        changed = false;
      }
      if (changed) {
        _updatePetMood();
        onStatsUpdated?.call(uiBar.fullness, uiBar.happiness, uiBar.cleanliness);
      }
    }
    return KeyEventResult.handled;
  }
}

extension on Size {
  Vector2 toVector2() => Vector2(width, height);
}
