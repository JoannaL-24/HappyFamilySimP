import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'game_engine.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pet Game')),
      body: GameWidget(game: FamilyPetGame()),
    );
  }
}
