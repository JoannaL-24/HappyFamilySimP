import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/cupertino.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text('Pet Game')),
      child: GameView(),
    );
  }
}

class GameView extends StatefulWidget {
  const GameView({super.key});

  @override
  State<GameView> createState() => _GameViewState();
}

class _GameViewState extends State<GameView> {
  late FamilyPetGame game;

  @override
  void initState() {
    super.initState();
    game = FamilyPetGame();
  }

  @override
  Widget build(BuildContext context) {
    return GameWidget(game: game);
  }
}

class FamilyPetGame extends FlameGame {
  late Pet pet;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Create a simple pet at the center
    pet = Pet(position: Vector2(size.x / 2, size.y / 2));
    add(pet);
  }
}

class Pet extends PositionComponent with TapCallbacks {
  Pet({required Vector2 position})
    : super(position: position, size: Vector2(100, 100), anchor: Anchor.center);

  bool isHappy = false;

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw a simple circle pet
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      40,
      Paint()
        ..color = isHappy ? const Color(0xFF90EE90) : const Color(0xFFFFB6C1),
    );

    // Draw eyes
    const eyeRadius = 5.0;
    const eyeOffsetY = 25.0;
    canvas.drawCircle(
      Offset(size.x / 2 - 15, size.y / 2 - eyeOffsetY),
      eyeRadius,
      Paint()..color = const Color(0xFF000000),
    );
    canvas.drawCircle(
      Offset(size.x / 2 + 15, size.y / 2 - eyeOffsetY),
      eyeRadius,
      Paint()..color = const Color(0xFF000000),
    );

    // Draw mouth (happy or sad)
    if (isHappy) {
      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(size.x / 2, size.y / 2 + 10),
          radius: 10,
        ),
        0,
        3.14159,
        false,
        Paint()..color = const Color(0xFF000000),
      );
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    isHappy = !isHappy;
  }
}

