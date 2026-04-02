import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';

enum PetState { idle, sad, dead, eating, excited, dancing, shower }

// Thresholds used by updateMood
const int kPetDeadThreshold = 0;   // fullness <= this → dead
const int kPetSadThreshold = 30;   // happiness < this → sad
const int kPetDirtyThreshold = 50; // cleanliness < this → dirty filter starts

class Pet extends SpriteAnimationGroupComponent<PetState> with TapCallbacks {
  final Vector2 velocity = Vector2.zero();
  double speed = 100;

  bool _playingOneShot = false;
  PetState _moodState = PetState.idle; // base mood; one-shots return here

  /// 0.0 = clean, 1.0 = fully dirty. Drives the dirty overlay.
  double dirtyAmount = 0.0;

  @override
  Future<void> onLoad() async {
    anchor = Anchor.bottomCenter;
    size = Vector2(32, 32);

    final animResults = await Future.wait([
      _loadAnim('Idle.png', 10, loop: true),
      _loadAnim('Sad.png', 9, loop: true),
      _loadAnim('DeadCat.png', 1, loop: true),
      _loadAnim('Eating.png', 15, loop: false),
      _loadAnim('Excited.png', 12, loop: false),
      _loadAnim('Dance.png', 4, loop: false),
      _loadAnim('Box3.png', 4, loop: false),
    ]);

    animations = {
      PetState.idle: animResults[0],
      PetState.sad: animResults[1],
      PetState.dead: animResults[2],
      PetState.eating: animResults[3],
      PetState.excited: animResults[4],
      PetState.dancing: animResults[5],
      PetState.shower: animResults[6],
    };
    current = PetState.idle;

    return super.onLoad();
  }

  Future<SpriteAnimation> _loadAnim(
    String file,
    int amount, {
    required bool loop,
  }) {
    return SpriteAnimation.load(
      'Assets/Cats/CatSprites/Classical/Individual/$file',
      SpriteAnimationData.sequenced(
        amount: amount,
        textureSize: Vector2(32, 32),
        stepTime: 0.15,
        loop: loop,
      ),
    );
  }

  /// Updates base mood and dirty overlay from current stat values.
  void updateMood({
    required int fullness,
    required int happiness,
    required int cleanliness,
  }) {
    // Dirty overlay: ramps up as cleanliness drops below threshold
    dirtyAmount = cleanliness < kPetDirtyThreshold
        ? ((kPetDirtyThreshold - cleanliness) / kPetDirtyThreshold).clamp(0.0, 1.0)
        : 0.0;

    // Determine base mood (dead > sad > idle)
    final PetState newMood;
    if (fullness <= kPetDeadThreshold) {
      newMood = PetState.dead;
    } else if (happiness <= kPetSadThreshold) {
      newMood = PetState.sad;
    } else {
      newMood = PetState.idle;
    }

    _moodState = newMood;

    // Dead overrides everything immediately, including one-shots
    if (newMood == PetState.dead) {
      _playingOneShot = false;
      current = PetState.dead;
      return;
    }

    // Apply mood only when not mid one-shot
    if (!_playingOneShot) {
      current = _moodState;
    }
  }

  /// Plays a one-shot animation [loops] times then returns to the current mood.
  /// Ignored if dead or another one-shot is already playing.
  void playOneShot(PetState state, {int loops = 1}) {
    if (_moodState == PetState.dead) return;
    if (_playingOneShot) return;
    _playingOneShot = true;
    int remaining = loops;
    current = state;
    animationTickers?[state]?.reset();

    void onComplete() {
      remaining--;
      if (remaining > 0) {
        animationTickers?[state]?.reset();
        animationTickers?[state]?.onComplete = onComplete;
      } else {
        _playingOneShot = false;
        current = _moodState;
      }
    }

    animationTickers?[state]?.onComplete = onComplete;
  }

  // Pre-generated dirt spots with a fixed seed so they're stable each frame.
  static final List<_DirtSpot> _dirtSpots = _generateDirtSpots();

  static List<_DirtSpot> _generateDirtSpots() {
    const colors = [
      Color(0xFF5D3A1A), // dark brown
      Color(0xFF7B4F2E), // medium brown
      Color(0xFF4A5C2F), // muddy green
      Color(0xFF3D2B1F), // dark mud
      Color(0xFF6B5B3E), // tan mud
    ];
    final rng = Random(0xD1D7); // fixed seed
    const count = 28;
    return List.generate(count, (i) {
      return _DirtSpot(
        x: 2 + rng.nextDouble() * 28,
        y: 2 + rng.nextDouble() * 28,
        radius: 0.7 + rng.nextDouble() * 2.2,
        angle: rng.nextDouble() * pi,
        scaleY: 0.4 + rng.nextDouble() * 0.9,
        color: colors[rng.nextInt(colors.length)],
        // spread thresholds across 0..0.85 so last spots appear at ~85% dirty
        threshold: (i / count) * 0.85,
      );
    });
  }

  @override
  void render(Canvas canvas) {
    if (dirtyAmount <= 0) {
      super.render(canvas);
      return;
    }

    // Isolated layer: sprite first, then dirt spots with srcATop so they
    // only paint over non-transparent sprite pixels.
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.x, size.y), Paint());
    super.render(canvas);

    for (final spot in _dirtSpots) {
      if (dirtyAmount < spot.threshold) continue;
      // Fade each spot in over a short range after its threshold
      final spotAlpha =
          ((dirtyAmount - spot.threshold) / 0.15).clamp(0.0, 1.0) * 0.88;

      canvas.save();
      canvas.translate(spot.x, spot.y);
      canvas.rotate(spot.angle);
      canvas.scale(1.0, spot.scaleY);
      canvas.drawCircle(
        Offset.zero,
        spot.radius,
        Paint()
          ..color = spot.color.withValues(alpha: spotAlpha)
          ..blendMode = BlendMode.srcATop,
      );
      canvas.restore();
    }

    canvas.restore();
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.add(velocity * speed * dt);

    if (velocity.x > 0 && !isFlippedHorizontally) {
      flipHorizontallyAroundCenter();
    } else if (velocity.x < 0 && isFlippedHorizontally) {
      flipHorizontallyAroundCenter();
    }
  }
}

class _DirtSpot {
  const _DirtSpot({
    required this.x,
    required this.y,
    required this.radius,
    required this.angle,
    required this.scaleY,
    required this.color,
    required this.threshold,
  });

  final double x;
  final double y;
  final double radius;
  final double angle;
  final double scaleY;
  final Color color;
  /// dirtyAmount must exceed this (0–1) before the spot appears.
  final double threshold;
}
