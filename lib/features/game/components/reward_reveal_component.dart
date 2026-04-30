import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/foundation.dart';

class RewardRevealComponent extends Component {
  RewardRevealComponent({
    required this.origin,
    required this.sprite,
    required this.spriteSize,
    required this.onComplete,
  });

  final Vector2 origin;
  final Sprite sprite;
  final Vector2 spriteSize;
  final VoidCallback onComplete;

  static const double _riseDuration = 1.6;
  static const double _fadeDuration = 0.6;
  static const double _riseDistance = 60.0;

  double _elapsed = 0;
  bool _done = false;
  late final List<_Sparkle> _sparkles;

  static const _sparkleColors = [
    Color(0xFFFFD700),
    Color(0xFFFF6B6B),
    Color(0xFF7ED6DF),
    Color(0xFF6AB04C),
    Color(0xFFFF9FF3),
    Color(0xFFF9CA24),
    Color(0xFFE056FD),
    Color(0xFF00CEC9),
  ];

  @override
  void onLoad() {
    priority = 9998;
    final rng = Random();
    _sparkles = List.generate(8, (i) => _Sparkle(
      angle: (i / 8) * pi * 2 + rng.nextDouble() * 0.4,
      maxDist: 20 + rng.nextDouble() * 14,
      color: _sparkleColors[i],
      size: 2.2 + rng.nextDouble() * 1.6,
    ));
  }

  @override
  void update(double dt) {
    if (_done) return;
    _elapsed += dt;
    if (_elapsed >= _riseDuration + _fadeDuration) {
      _done = true;
      removeFromParent();
      onComplete();
    }
  }

  @override
  void render(Canvas canvas) {
    final riseT = (_elapsed / _riseDuration).clamp(0.0, 1.0);
    final fadeAlpha = _elapsed > _riseDuration
        ? 1.0 - ((_elapsed - _riseDuration) / _fadeDuration).clamp(0.0, 1.0)
        : 1.0;

    // Sparkles start after a short delay (box opens first)
    final sparkleT = ((_elapsed - 0.3) / 1.0).clamp(0.0, 1.0);
    if (sparkleT > 0) {
      for (final s in _sparkles) {
        s.render(canvas, t: sparkleT, alpha: fadeAlpha, origin: origin);
      }
    }

    // Sprite floats upward with ease-out
    final yOffset = _easeOut(riseT) * _riseDistance;
    final spriteX = origin.x - spriteSize.x / 2;
    final spriteY = origin.y - spriteSize.y - yOffset;

    canvas.saveLayer(
      Rect.fromLTWH(spriteX - 2, spriteY - 2, spriteSize.x + 4, spriteSize.y + 4),
      Paint()..color = Color.fromRGBO(255, 255, 255, fadeAlpha),
    );
    sprite.render(canvas, position: Vector2(spriteX, spriteY), size: spriteSize);
    canvas.restore();
  }

  double _easeOut(double t) => 1 - pow(1 - t, 3).toDouble();
}

class _Sparkle {
  const _Sparkle({
    required this.angle,
    required this.maxDist,
    required this.color,
    required this.size,
  });

  final double angle;
  final double maxDist;
  final Color color;
  final double size;

  void render(Canvas canvas, {
    required double t,
    required double alpha,
    required Vector2 origin,
  }) {
    final dist = t * maxDist;
    final x = origin.x + cos(angle) * dist;
    final y = (origin.y - 18) + sin(angle) * dist;
    final effectiveAlpha = (alpha * (1 - t * 0.6)).clamp(0.0, 1.0);

    final paint = Paint()
      ..color = color.withValues(alpha: effectiveAlpha)
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(t * pi * 2);
    _drawStar(canvas, size * (1 + t * 0.4), paint);
    canvas.restore();
  }

  void _drawStar(Canvas canvas, double r, Paint paint) {
    const points = 4;
    final path = Path();
    for (int i = 0; i < points * 2; i++) {
      final a = (i * pi) / points - pi / 2;
      final radius = i.isEven ? r : r * 0.35;
      final x = cos(a) * radius;
      final y = sin(a) * radius;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }
}
