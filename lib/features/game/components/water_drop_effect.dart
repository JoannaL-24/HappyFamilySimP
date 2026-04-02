import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

/// A single water droplet that manages its own priority:
/// behind the pet while ascending, in front while descending.
class WaterDrop extends Component {
  WaterDrop({
    required Vector2 startPosition,
    required Vector2 velocity,
    required this.getPetPriority,
    this.lifespan = 1.1,
    this.radius = 2.0,
    this.alwaysBehind = false,
  }) : _pos = startPosition.clone(),
       _vel = velocity.clone();

  final Vector2 _pos;
  final Vector2 _vel;
  final int Function() getPetPriority;
  final double lifespan;
  final double radius;
  final bool alwaysBehind;

  double _elapsed = 0;
  static const double _gravity = 260.0;

  @override
  void update(double dt) {
    _elapsed += dt;
    if (_elapsed >= lifespan) {
      removeFromParent();
      return;
    }
    _vel.y += _gravity * dt;
    _pos.x += _vel.x * dt;
    _pos.y += _vel.y * dt;

    // Always behind, or behind only while ascending
    priority = (alwaysBehind || _vel.y < 0) ? getPetPriority() - 1 : 9999;
  }

  @override
  void render(Canvas canvas) {
    final alpha = (1.0 - (_elapsed / lifespan)).clamp(0.0, 1.0);

    canvas.save();
    canvas.translate(_pos.x, _pos.y);

    final path = Path()
      ..moveTo(0, radius * 1.4)
      ..cubicTo(-radius, radius * 0.4, -radius, -radius, 0, -radius)
      ..cubicTo(radius, -radius, radius, radius * 0.4, 0, radius * 1.4)
      ..close();

    canvas.drawPath(
      path,
      Paint()..color = Color.fromRGBO(79, 195, 247, alpha),
    );
    // glint highlight
    canvas.drawCircle(
      Offset(-radius * 0.25, -radius * 0.3),
      radius * 0.25,
      Paint()..color = Color.fromRGBO(255, 255, 255, alpha * 0.6),
    );

    canvas.restore();
  }
}

/// Spawns [dropsPerBurst] [WaterDrop] components [bursts] times at [interval]
/// seconds apart, then removes itself.
class WaterDropSpawner extends Component {
  WaterDropSpawner({
    required this.getPosition,
    required this.getPetPriority,
    this.bursts = 4,
    this.interval = 0.55,
    this.dropsPerBurst = 14,
  });

  final Vector2 Function() getPosition;
  final int Function() getPetPriority;
  final int bursts;
  final double interval;
  final int dropsPerBurst;

  int _spawned = 0;
  double _elapsed = 0;
  static final _rng = Random();

  @override
  void onMount() {
    _spawnBurst();
  }

  @override
  void update(double dt) {
    if (_spawned >= bursts) {
      removeFromParent();
      return;
    }
    _elapsed += dt;
    if (_elapsed >= interval) {
      _elapsed -= interval;
      _spawnBurst();
    }
  }

  void _spawnBurst() {
    if (_spawned >= bursts) return;
    _spawned++;
    final origin = getPosition();
    for (var i = 0; i < dropsPerBurst; i++) {
      final vx = (_rng.nextDouble() - 0.5) * 55;
      final vy = -55 - _rng.nextDouble() * 75;
      final r = 1.2 + _rng.nextDouble() * 1.2;
      parent?.add(
        WaterDrop(
          startPosition: origin.clone(),
          velocity: Vector2(vx, vy),
          getPetPriority: getPetPriority,
          radius: r,
          alwaysBehind: i < dropsPerBurst ~/ 2,
        ),
      );
    }
  }
}
