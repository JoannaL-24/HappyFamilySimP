import 'dart:ui';

import 'package:flame/events.dart';

import 'furniture_sprite.dart';

class PlacedItemComponent extends FurnitureSpriteComponent
    with DragCallbacks, TapCallbacks {
  PlacedItemComponent({
    required super.sprite,
    required super.size,
    required super.anchor,
    super.position,
    super.priorityOffset,
    required this.placementId,
    required this.itemId,
    required this.spriteIndex,
    this.onMoved,
    this.onSelected,
  });

  final String placementId;
  final int itemId;
  final int spriteIndex;

  bool editMode = false;
  bool isSelected = false;

  /// Called when drag ends; provides the new world position.
  final void Function(String id, double x, double y)? onMoved;

  /// Called when tapped in edit mode with the placement id,
  /// or null to deselect.
  final void Function(String? id)? onSelected;

  @override
  bool onDragUpdate(DragUpdateEvent event) {
    if (!editMode) return false;
    position.add(event.localDelta);
    return true;
  }

  @override
  bool onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (!editMode) return false;
    onMoved?.call(placementId, position.x, position.y);
    return true;
  }

  @override
  bool onTapDown(TapDownEvent event) {
    if (!editMode) return false;
    onSelected?.call(isSelected ? null : placementId);
    return true;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (!editMode) return;

    final color = isSelected
        ? const Color(0xCCEF5350) // red when selected
        : const Color(0x882196F3); // blue highlight in edit mode

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }
}
