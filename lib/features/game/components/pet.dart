import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';

enum PetState {
  // mood states
  idle, sad, dead,
  // triggered one-shots (from outside)
  eating, excited, dancing, shower, box2,
  // autonomous behaviour
  idle2, waiting, layDown, sleepy, sleep, surprised,
}

// Thresholds used by updateMood
const int kPetDeadThreshold = 0;   // fullness <= this → dead
const int kPetSadThreshold = 30;   // happiness <= this → sad
const int kPetDirtyThreshold = 50; // cleanliness < this → dirty filter starts

// Wander Y bounds (world coordinates); X is computed per-Y via _wallMarginAt.
const double _kMinY = 295.0;
const double _kMaxY = 365.0;

// Autonomous states that the behaviour system "owns" — updateMood won't
// clobber current while one of these is active (except for dead).
const Set<PetState> _kAutonomousStates = {
  PetState.idle2, PetState.waiting, PetState.layDown,
  PetState.sleepy, PetState.sleep, PetState.surprised,
};

class Pet extends SpriteAnimationGroupComponent<PetState> with TapCallbacks {
  final Vector2 velocity = Vector2.zero();
  double speed = 30;
  double debugSpeedMultiplier = 1.0;

  bool _playingOneShot = false;
  PetState _moodState = PetState.idle;

  /// 0.0 = clean, 1.0 = fully dirty. Drives the dirty overlay.
  double dirtyAmount = 0.0;

  // ── Autonomous behaviour ──────────────────────────────────────────────────

  static final _rng = Random();

  double _behaviorTimer = 1.0; // initial pause before first behaviour pick
  bool _wandering = false;
  double _wanderTargetX = 100;
  double _wanderTargetY = 320;
  VoidCallback? _onTimerExpired; // overrides _pickBehavior when set

  /// World positions of placed beds — updated by the game engine.
  List<Vector2> bedPositions = [];

  /// World positions of placed toys — updated by the game engine.
  List<Vector2> toyPositions = [];

  @override
  Future<void> onLoad() async {
    anchor = Anchor.bottomCenter;
    size = Vector2(32, 32);

    final animResults = await Future.wait([
      _loadAnim('Idle.png',     10, loop: true),
      _loadAnim('Sad.png',       9, loop: true),
      _loadAnim('DeadCat.png',   1, loop: true),
      _loadAnim('Eating.png',   15, loop: false),
      _loadAnim('Excited.png',  12, loop: false),
      _loadAnim('Dance.png',     4, loop: false),
      _loadAnim('Box3.png',      4, loop: false),
      _loadAnim('Box2.png',     12, loop: false, stepTime: 0.25),
      _loadAnim('Idle2.png',    10, loop: true),
      _loadAnim('Waiting.png',   6, loop: true),
      _loadAnim('LayDown.png',  12, loop: true),
      _loadAnim('Sleepy.png',    8, loop: false),
      _loadAnim('Sleep.png',     4, loop: true),
      _loadAnim('Surprised.png',12, loop: false),
    ]);

    animations = {
      PetState.idle:      animResults[0],
      PetState.sad:       animResults[1],
      PetState.dead:      animResults[2],
      PetState.eating:    animResults[3],
      PetState.excited:   animResults[4],
      PetState.dancing:   animResults[5],
      PetState.shower:    animResults[6],
      PetState.box2:      animResults[7],
      PetState.idle2:     animResults[8],
      PetState.waiting:   animResults[9],
      PetState.layDown:   animResults[10],
      PetState.sleepy:    animResults[11],
      PetState.sleep:     animResults[12],
      PetState.surprised: animResults[13],
    };
    current = PetState.idle;

    // Nearest-neighbour filtering prevents frame-edge bleeding on pixel art.
    paint.filterQuality = FilterQuality.none;

    return super.onLoad();
  }

  Future<SpriteAnimation> _loadAnim(
    String file,
    int amount, {
    required bool loop,
    double stepTime = 0.15,
  }) {
    return SpriteAnimation.load(
      'Assets/Cats/CatSprites/Classical/Individual/$file',
      SpriteAnimationData.sequenced(
        amount: amount,
        textureSize: Vector2(32, 32),
        stepTime: stepTime,
        loop: loop,
      ),
    );
  }

  // ── Mood ──────────────────────────────────────────────────────────────────

  /// Updates base mood and dirty overlay from current stat values.
  void updateMood({
    required int fullness,
    required int happiness,
    required int cleanliness,
  }) {
    dirtyAmount = cleanliness < kPetDirtyThreshold
        ? ((kPetDirtyThreshold - cleanliness) / kPetDirtyThreshold).clamp(0.0, 1.0)
        : 0.0;

    final PetState newMood;
    if (fullness <= kPetDeadThreshold) {
      newMood = PetState.dead;
    } else if (happiness <= kPetSadThreshold) {
      newMood = PetState.sad;
    } else {
      newMood = PetState.idle;
    }

    _moodState = newMood;

    // Dead overrides everything — stop one-shots and autonomous behaviour.
    if (newMood == PetState.dead) {
      _playingOneShot = false;
      _wandering = false;
      _behaviorTimer = 0;
      current = PetState.dead;
      return;
    }

    // Only snap back to mood state if the behaviour system isn't mid-animation
    // and no one-shot is playing.
    if (!_playingOneShot && !_kAutonomousStates.contains(current)) {
      current = _moodState;
    }
  }

  // ── Tap reaction ─────────────────────────────────────────────────────────

  @override
  void onTapDown(TapDownEvent event) {
    if (_moodState == PetState.dead) return;
    if (_playingOneShot) return; // don't interrupt eating/dancing/etc.

    if (current == PetState.sleep || current == PetState.sleepy) {
      // Stir into layDown briefly, then drift back to sleep.
      current = PetState.layDown;
      _behaviorTimer = 1.5 + _rng.nextDouble() * 2.0;
      _onTimerExpired = () {
        current = PetState.sleep;
        _behaviorTimer = 6 + _rng.nextDouble() * 10;
      };
      return;
    }

    final layingDown = current == PetState.layDown;
    playOneShot(layingDown ? PetState.surprised : PetState.excited);
  }

  // ── One-shots (externally triggered) ─────────────────────────────────────

  /// Plays a one-shot animation [loops] times then resumes autonomous behaviour.
  /// Ignored if dead or another one-shot is already playing.
  void playOneShot(PetState state, {int loops = 1, VoidCallback? afterComplete}) {
    if (_moodState == PetState.dead) return;
    if (_playingOneShot) return;
    _playingOneShot = true;
    _wandering = false;
    velocity.setZero();

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
        _behaviorTimer = 0; // let behaviour system pick immediately
        afterComplete?.call();
      }
    }

    animationTickers?[state]?.onComplete = onComplete;
  }

  // ── Autonomous behaviour system ───────────────────────────────────────────

  void _tickBehavior(double dt) {
    if (_moodState == PetState.dead) return;
    if (_playingOneShot) return;

    _behaviorTimer -= dt;

    if (_wandering) {
      final dx = _wanderTargetX - position.x;
      final dy = _wanderTargetY - position.y;
      if (dx.abs() < 2 && dy.abs() < 2) {
        // Arrived — brief pause then pick next behaviour
        position.x = _wanderTargetX;
        position.y = _wanderTargetY;
        velocity.setZero();
        _wandering = false;
        _behaviorTimer = 0.5 + _rng.nextDouble() * 1.0;
        current = _moodState == PetState.sad ? PetState.sad : PetState.idle;
      } else {
        // Normalise so diagonal speed equals straight speed
        final dir = Vector2(dx, dy);
        if (dir.length > 0) dir.normalize();
        velocity.setFrom(dir);
        if (current != PetState.idle && current != PetState.idle2) {
          current = PetState.idle;
        }
      }
      return;
    }

    if (_behaviorTimer <= 0) {
      final cb = _onTimerExpired;
      _onTimerExpired = null;
      if (cb != null) {
        cb();
      } else {
        _pickBehavior();
      }
    }
  }

  void _pickBehavior() {
    if (_moodState == PetState.sad) {
      // Sad pet: wanders less, mostly sits or waits, can fall asleep
      final r = _rng.nextDouble();
      if (r < 0.30) {
        _startWander();
      } else if (r < 0.60) {
        _startLoopAnim(PetState.idle,    3 + _rng.nextDouble() * 5);
      } else if (r < 0.80) {
        _startLoopAnim(PetState.waiting, 3 + _rng.nextDouble() * 4);
      } else {
        _startSleepChain();
      }
      return;
    }

    // Happy/idle pet: full range of behaviours
    final r = _rng.nextDouble();
    if (r < 0.30) {
      _startWander();
    } else if (r < 0.44) {
      _startLoopAnim(PetState.idle,    3 + _rng.nextDouble() * 5);
    } else if (r < 0.56) {
      _startLoopAnim(PetState.idle2,   2 + _rng.nextDouble() * 4);
    } else if (r < 0.68) {
      _startLoopAnim(PetState.waiting, 2 + _rng.nextDouble() * 4);
    } else if (r < 0.78) {
      _startLoopAnim(PetState.layDown, 4 + _rng.nextDouble() * 7);
    } else if (r < 0.90) {
      _startSleepChain();
    } else if (r < 0.96) {
      _startToyPlay();
    } else {
      _startSurprised();
    }
  }

  void _startWander() {
    _wanderTargetY = _kMinY + _rng.nextDouble() * (_kMaxY - _kMinY);
    final margin = _wallMarginAt(_wanderTargetY);
    _wanderTargetX = (10 + margin) + _rng.nextDouble() * (180 - 2 * margin);
    _wandering = true;
    current = PetState.idle;
  }

  // Returns the x wall margin (in world coords) at a given world y.
  // The perspective side walls taper from ~22px wide at the top of the floor
  // area down to ~2px at the front floor line.
  double _wallMarginAt(double worldY) {
    const double floorY = 290.0;
    const double topMargin = 22.0;
    if (worldY >= floorY) return 18.0;
    final t = ((floorY - worldY) / (floorY - _kMinY)).clamp(0.0, 1.0);
    return 18.0 + topMargin * t;
  }

  /// Plays a looping animation for [duration] seconds, then picks the next behaviour.
  void _startLoopAnim(PetState state, double duration) {
    current = state;
    _behaviorTimer = duration;
  }

  /// Walks to a bed if one is placed, then does Sleepy → Sleep for 8–20 s.
  void _startSleepChain() {
    if (bedPositions.isNotEmpty) {
      final target = bedPositions[_rng.nextInt(bedPositions.length)];
      _wanderTargetX = target.x;
      _wanderTargetY = target.y;
      _wandering = true;
      current = PetState.idle;
      _onTimerExpired = _doSleepChain;
    } else {
      _doSleepChain();
    }
  }

  void _doSleepChain() {
    current = PetState.sleepy;
    animationTickers?[PetState.sleepy]?.reset();
    animationTickers?[PetState.sleepy]?.onComplete = () {
      if (_moodState == PetState.dead || _playingOneShot) return;
      current = PetState.sleep;
      _behaviorTimer = 8 + _rng.nextDouble() * 12;
    };
    _behaviorTimer = 99;
  }

  /// Walks to a toy if one is placed, then plays near it for a few seconds.
  /// Falls back to idle2 in place if no toys are placed.
  void _startToyPlay() {
    if (toyPositions.isNotEmpty) {
      final target = toyPositions[_rng.nextInt(toyPositions.length)];
      _wanderTargetX = target.x;
      _wanderTargetY = target.y + 10;
      _wandering = true;
      current = PetState.idle;
      _onTimerExpired = () {
        _startLoopAnim(PetState.idle2, 3 + _rng.nextDouble() * 4);
      };
    } else {
      _startLoopAnim(PetState.idle2, 3 + _rng.nextDouble() * 4);
    }
  }

  /// Plays Surprised once, then immediately picks the next behaviour.
  void _startSurprised() {
    current = PetState.surprised;
    animationTickers?[PetState.surprised]?.reset();
    animationTickers?[PetState.surprised]?.onComplete = () {
      if (_moodState == PetState.dead || _playingOneShot) return;
      _behaviorTimer = 0;
    };
    _behaviorTimer = 99;
  }

  // ── Dirt overlay (pre-generated spots) ───────────────────────────────────

  static final List<_DirtSpot> _dirtSpots = _generateDirtSpots();

  static List<_DirtSpot> _generateDirtSpots() {
    const colors = [
      Color(0xFF5D3A1A),
      Color(0xFF7B4F2E),
      Color(0xFF4A5C2F),
      Color(0xFF3D2B1F),
      Color(0xFF6B5B3E),
    ];
    final rng = Random(0xD1D7);
    const count = 28;
    return List.generate(count, (i) {
      return _DirtSpot(
        x: 2 + rng.nextDouble() * 28,
        y: 2 + rng.nextDouble() * 28,
        radius: 0.7 + rng.nextDouble() * 2.2,
        angle: rng.nextDouble() * pi,
        scaleY: 0.4 + rng.nextDouble() * 0.9,
        color: colors[rng.nextInt(colors.length)],
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

    canvas.saveLayer(Rect.fromLTWH(0, 0, size.x, size.y), Paint());
    super.render(canvas);

    for (final spot in _dirtSpots) {
      if (dirtyAmount < spot.threshold) continue;
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
    final scaledDt = dt * debugSpeedMultiplier;
    _tickBehavior(scaledDt);
    position.add(velocity * speed * scaledDt);

    // Clamp to perspective-aware floor bounds
    final margin = _wallMarginAt(position.y);
    position.x = position.x.clamp(10 + margin, 190 - margin);
    position.y = position.y.clamp(_kMinY, _kMaxY);

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
  final double threshold;
}
