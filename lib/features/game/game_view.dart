import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/game_repository.dart';
import 'data/models.dart';
import 'game_engine.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.gameRepository});

  final GameRepository gameRepository;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  FamilyPetGame? _game;
  Resources? _resources;
  String? _error;
  StreamSubscription<Resources>? _resourcesSub;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _resourcesSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final childId = Supabase.instance.client.auth.currentUser?.id;
    if (childId == null) {
      setState(() => _error = 'Not logged in.');
      return;
    }

    try {
      final results = await Future.wait([
        widget.gameRepository.getCreature(childId),
        widget.gameRepository.getResources(childId),
      ]);

      final creature = results[0] as Creature;
      final resources = results[1] as Resources;

      final game = FamilyPetGame(creature: creature, resources: resources);

      _resourcesSub = widget.gameRepository
          .watchResources(childId)
          .listen((updated) {
            game.resources = updated;
            if (mounted) setState(() => _resources = updated);
          });

      setState(() {
        _game = game;
        _resources = resources;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pet Game')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_game == null || _resources == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(_game!.creature?.name ?? 'Pet Game')),
      body: Stack(
        children: [
          GameWidget(game: _game!),
          _ResourceBar(resources: _resources!),
        ],
      ),
    );
  }
}

class _ResourceBar extends StatelessWidget {
  const _ResourceBar({required this.resources});

  final Resources resources;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ResourceItem(icon: '🍖', label: 'Food', amount: resources.food),
            _ResourceItem(icon: '🎾', label: 'Play', amount: resources.play),
            _ResourceItem(icon: '🛁', label: 'Clean', amount: resources.clean),
          ],
        ),
      ),
    );
  }
}

class _ResourceItem extends StatefulWidget {
  const _ResourceItem({
    required this.icon,
    required this.label,
    required this.amount,
  });

  final String icon;
  final String label;
  final int amount;

  @override
  State<_ResourceItem> createState() => _ResourceItemState();
}

class _ResourceItemState extends State<_ResourceItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _offsetY;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _offsetY = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 0.0), weight: 60),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(_ResourceItem old) {
    super.didUpdateWidget(old);
    if (old.amount != widget.amount) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _offsetY,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _offsetY.value),
        child: child,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.icon, style: const TextStyle(fontSize: 20)),
          Text(
            '${widget.amount}',
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
