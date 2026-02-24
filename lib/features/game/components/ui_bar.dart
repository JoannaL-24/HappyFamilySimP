import 'dart:ui';

import 'package:flame/components.dart';

class StatBar extends PositionComponent {
  StatBar({
    required this.label,
    required this.barColor,
    this.value = 100,
    super.position,
  });

  final String label;
  final Color barColor;
  int value;

  static const double barWidth = 60;
  static const double barHeight = 8;
  static const double labelWidth = 30;

  @override
  void render(Canvas canvas) {
    // Draw label
    final paragraphBuilder =
        ParagraphBuilder(ParagraphStyle(fontSize: 6, fontFamily: 'monospace'))
          ..pushStyle(TextStyle(color: const Color(0xFFFFFFFF)))
          ..addText(label);

    final paragraph = paragraphBuilder.build()
      ..layout(const ParagraphConstraints(width: labelWidth));
    canvas.drawParagraph(paragraph, const Offset(0, 1));

    // Background (empty bar)
    canvas.drawRect(
      const Rect.fromLTWH(labelWidth, 0, barWidth, barHeight),
      Paint()..color = const Color(0xFF222222),
    );

    // Filled portion
    final fillWidth = barWidth * (value.clamp(0, 100) / 100);
    canvas.drawRect(
      Rect.fromLTWH(labelWidth, 0, fillWidth, barHeight),
      Paint()..color = barColor,
    );

    // Border
    canvas.drawRect(
      const Rect.fromLTWH(labelWidth, 0, barWidth, barHeight),
      Paint()
        ..color = const Color(0xFF888888)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }
}

class UiBar extends PositionComponent {
  late final StatBar fullnessBar;
  late final StatBar happinessBar;
  late final StatBar cleanlinessBar;

  int get fullness => fullnessBar.value;
  set fullness(int v) => fullnessBar.value = v.clamp(0, 100);

  int get happiness => happinessBar.value;
  set happiness(int v) => happinessBar.value = v.clamp(0, 100);

  int get cleanliness => cleanlinessBar.value;
  set cleanliness(int v) => cleanlinessBar.value = v.clamp(0, 100);

  @override
  Future<void> onLoad() async {
    position = Vector2(4, 10);

    const spacing = 10.0;

    fullnessBar = StatBar(
      label: 'FULL',
      barColor: const Color(0xFF4CAF50),
      position: Vector2(0, 0),
    );

    happinessBar = StatBar(
      label: 'HAPP',
      barColor: const Color(0xFF2196F3),
      position: Vector2(0, spacing),
    );

    cleanlinessBar = StatBar(
      label: 'CLEN',
      barColor: const Color(0xFFFF9800),
      position: Vector2(0, spacing * 2),
    );

    addAll([fullnessBar, happinessBar, cleanlinessBar]);

    return super.onLoad();
  }
}
