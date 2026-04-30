import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart' show Vector2;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/cosmetic_models.dart';
import 'data/cosmetic_repository.dart';
import 'data/game_repository.dart';
import 'data/models.dart';
import 'game_engine.dart' show FamilyPetGame, kBoxPiecesRequired;

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.gameRepository,
    required this.cosmeticRepository,
  });

  final GameRepository gameRepository;
  final CosmeticRepository cosmeticRepository;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  FamilyPetGame? _game;
  Resources? _resources;
  Creature? _creature;
  String? _error;
  StreamSubscription<Resources>? _resourcesSub;

  // Cosmetics state
  List<CosmeticItem> _allItems = [];
  Set<int> _ownedIds = {};
  List<RoomPlacement> _placements = [];
  bool _editMode = false;
  String? _selectedPlacementId;

  ResourceType? _applyingType;
  bool _isOpeningBox = false;

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
      await widget.gameRepository.ensureDefaults(childId);

      final results = await Future.wait([
        widget.gameRepository.getCreature(childId),
        widget.gameRepository.getResources(childId),
        widget.cosmeticRepository.getItemsWithOwnership(childId),
        widget.cosmeticRepository.getPlacements(childId),
      ]);

      final creature = results[0] as Creature;
      final resources = results[1] as Resources;
      final cosmetics =
          results[2] as ({List<CosmeticItem> all, Set<int> ownedIds});
      final placements = results[3] as List<RoomPlacement>;

      final game = FamilyPetGame(
        creature: creature,
        resources: resources,
        initialPlacements: placements,
        onStatsUpdated: (fullness, happiness, cleanliness) {
          widget.gameRepository.updateCreatureStats(
            childId,
            fullness: fullness,
            happiness: happiness,
            cleanliness: cleanliness,
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _creature = _creature?.copyWith(
                  fullness: fullness,
                  happiness: happiness,
                  cleanliness: cleanliness,
                );
              });
            }
          });
        },
        onPlacementMoved: (id, x, y) {
          widget.cosmeticRepository.updatePlacement(id, x, y);
          final p = _placements.firstWhere((p) => p.id == id,
              orElse: () => RoomPlacement(
                    id: id,
                    childId: childId,
                    itemId: 0,
                    spriteIndex: 0,
                    posX: x,
                    posY: y,
                  ));
          p.posX = x;
          p.posY = y;
        },
        onPlacementSelected: (id) {
          if (mounted) setState(() => _selectedPlacementId = id);
        },
      );

      _resourcesSub = widget.gameRepository
          .watchResources(childId)
          .listen((updated) {
        game.resources = updated;
        if (mounted) setState(() => _resources = updated);
      });

      setState(() {
        _game = game;
        _resources = resources;
        _creature = creature;
        _allItems = cosmetics.all;
        _ownedIds = cosmetics.ownedIds;
        _placements = placements;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _applyResource(ResourceType type) async {
    if (_applyingType != null) return;
    final game = _game;
    final creature = _creature;
    final resources = _resources;
    if (game == null || creature == null || resources == null) return;
    if (resources.amountFor(type) <= 0) return;
    if (creature.statFor(type) >= 100) return;

    final childId = Supabase.instance.client.auth.currentUser?.id;
    if (childId == null) return;

    setState(() => _applyingType = type);
    game.triggerResourceAnimation(type);

    try {
      final updated =
          await widget.gameRepository.applyResource(childId, type);
      if (mounted) setState(() => _creature = updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _applyingType = null);
    }
  }

  Future<void> _openMysteryBox() async {
    if (_isOpeningBox) return;
    final resources = _resources;
    final game = _game;
    if (resources == null || game == null) return;
    if (resources.boxPieces < kBoxPiecesRequired) return;

    final childId = Supabase.instance.client.auth.currentUser?.id;
    if (childId == null) return;

    final unowned = _allItems.where((i) => !_ownedIds.contains(i.id)).toList();
    if (unowned.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You already own all items!')),
      );
      return;
    }

    final reward = unowned[Random().nextInt(unowned.length)];
    setState(() => _isOpeningBox = true);

    final sprite = game.sheet.createSprite(reward.spriteIndex).sprite;
    final spriteSize = game.sheet.spriteSize(reward.spriteIndex);

    if (sprite != null && spriteSize != null) {
      game.openMysteryBox(
        sprite,
        Vector2(spriteSize.width, spriteSize.height),
        onComplete: () {
          if (mounted) {
            setState(() {
              _ownedIds = {..._ownedIds, reward.id};
              _isOpeningBox = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('You got: ${reward.name}!')),
            );
          }
        },
      );
    } else {
      setState(() => _isOpeningBox = false);
    }

    await Future.wait([
      widget.gameRepository.spendBoxPieces(childId),
      widget.cosmeticRepository.grantOwnership(childId, reward.id),
    ]);
  }

  void _toggleEditMode() {
    final newMode = !_editMode;
    setState(() {
      _editMode = newMode;
      if (!newMode) _selectedPlacementId = null;
    });
    _game?.setEditMode(newMode);
  }

  Future<void> _addPlacement(CosmeticItem item) async {
    final childId = Supabase.instance.client.auth.currentUser?.id;
    if (childId == null) return;

    const defaultX = 100.0;
    const defaultY = 220.0;

    final id = await widget.cosmeticRepository.addPlacement(
      childId,
      item.id,
      defaultX,
      defaultY,
    );
    if (id == null) return;

    final placement = RoomPlacement(
      id: id,
      childId: childId,
      itemId: item.id,
      spriteIndex: item.spriteIndex,
      posX: defaultX,
      posY: defaultY,
      priorityOffset: item.priorityOffset,
    );

    setState(() => _placements.add(placement));
    _game?.addPlacement(placement);
  }

  Future<void> _removePlacement(String id) async {
    await widget.cosmeticRepository.removePlacement(id);
    setState(() {
      _placements.removeWhere((p) => p.id == id);
      if (_selectedPlacementId == id) _selectedPlacementId = null;
    });
    _game?.removePlacement(id);
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

    if (_game == null || _resources == null || _creature == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_game!.creature?.name ?? 'Pet Game'),
        actions: [
          TextButton.icon(
            onPressed: _toggleEditMode,
            icon: Icon(_editMode ? Icons.check : Icons.chair_alt),
            label: Text(_editMode ? 'Done' : 'Decorate'),
          ),
        ],
      ),
      body: Stack(
        children: [
          GameWidget(game: _game!),
          _ResourceBar(
            resources: _resources!,
            creature: _creature!,
            applyingType: _applyingType,
            onApply: _applyResource,
            isOpeningBox: _isOpeningBox,
            onOpenBox: _openMysteryBox,
          ),
          if (_editMode)
            _CosmeticsPanel(
              sheet: _game!.sheet,
              allItems: _allItems,
              ownedIds: _ownedIds,
              selectedPlacementId: _selectedPlacementId,
              onItemTap: _addPlacement,
              onDeleteSelected: _selectedPlacementId != null
                  ? () => _removePlacement(_selectedPlacementId!)
                  : null,
            ),
        ],
      ),
    );
  }
}

// ── Cosmetics Panel ────────────────────────────────────────────────────────

class _CosmeticsPanel extends StatefulWidget {
  const _CosmeticsPanel({
    required this.sheet,
    required this.allItems,
    required this.ownedIds,
    required this.selectedPlacementId,
    required this.onItemTap,
    required this.onDeleteSelected,
  });

  final dynamic sheet; // FurnitureSpriteSheet
  final List<CosmeticItem> allItems;
  final Set<int> ownedIds;
  final String? selectedPlacementId;
  final void Function(CosmeticItem) onItemTap;
  final VoidCallback? onDeleteSelected;

  @override
  State<_CosmeticsPanel> createState() => _CosmeticsPanelState();
}

class _CosmeticsPanelState extends State<_CosmeticsPanel> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.chair_alt, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'Decorations',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  if (widget.selectedPlacementId != null)
                    TextButton.icon(
                      onPressed: widget.onDeleteSelected,
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.red, size: 18),
                      label: const Text('Remove',
                          style: TextStyle(color: Colors.red)),
                      style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8)),
                    ),
                  IconButton(
                    icon: Icon(
                      _expanded
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_up,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => setState(() => _expanded = !_expanded),
                  ),
                ],
              ),
            ),
            // Item grid
            if (_expanded)
              SizedBox(
                height: 280,
                child: Builder(builder: (context) {
                  // Owned items first, then locked
                  final sorted = [
                    ...widget.allItems.where((it) => widget.ownedIds.contains(it.id)),
                    ...widget.allItems.where((it) => !widget.ownedIds.contains(it.id)),
                  ];
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: sorted.length,
                    itemBuilder: (context, i) {
                      final item = sorted[i];
                      final owned = widget.ownedIds.contains(item.id);
                      return _CosmeticItemCard(
                        item: item,
                        sheet: widget.sheet,
                        owned: owned,
                        onTap: owned ? () => widget.onItemTap(item) : null,
                      );
                    },
                  );
                }),
              ),
          ],
        ),
      ),
    );
  }
}

class _CosmeticItemCard extends StatelessWidget {
  const _CosmeticItemCard({
    required this.item,
    required this.sheet,
    required this.owned,
    required this.onTap,
  });

  final CosmeticItem item;
  final dynamic sheet; // FurnitureSpriteSheet
  final bool owned;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: owned ? Colors.amber.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: owned ? Colors.amber.shade300 : Colors.grey.shade300,
          ),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                    child: _SpritePreview(
                      sheet: sheet,
                      spriteIndex: item.spriteIndex,
                      greyed: !owned,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(3, 2, 3, 3),
                  child: Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 8,
                      color: owned ? Colors.black87 : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            if (!owned)
              const Positioned(
                top: 2,
                right: 2,
                child: Icon(Icons.lock, size: 11, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}

/// Renders one sprite from the furniture atlas inside a Flutter widget.
class _SpritePreview extends StatelessWidget {
  const _SpritePreview({
    required this.sheet,
    required this.spriteIndex,
    this.greyed = false,
  });

  final dynamic sheet; // FurnitureSpriteSheet
  final int spriteIndex;
  final bool greyed;

  @override
  Widget build(BuildContext context) {
    final srcRect = sheet.spriteSourceRect(spriteIndex) as Rect?;
    final image = sheet.atlasImage as ui.Image?;

    if (srcRect == null || image == null) {
      return const Icon(Icons.chair_alt, color: Colors.grey);
    }

    return ColorFiltered(
      colorFilter: greyed
          ? const ColorFilter.matrix([
              0.2126, 0.7152, 0.0722, 0, 0,
              0.2126, 0.7152, 0.0722, 0, 0,
              0.2126, 0.7152, 0.0722, 0, 0,
              0,      0,      0,      0.5, 0,
            ])
          : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
      child: CustomPaint(
        painter: _AtlasSpritePainter(image: image, src: srcRect),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _AtlasSpritePainter extends CustomPainter {
  const _AtlasSpritePainter({required this.image, required this.src});

  final ui.Image image;
  final Rect src;

  @override
  void paint(Canvas canvas, Size size) {
    // Fit the sprite inside the widget, preserving aspect ratio
    final spriteAspect = src.width / src.height;
    final widgetAspect = size.width / size.height;
    late final Rect dst;
    if (spriteAspect > widgetAspect) {
      final h = size.width / spriteAspect;
      dst = Rect.fromLTWH(0, (size.height - h) / 2, size.width, h);
    } else {
      final w = size.height * spriteAspect;
      dst = Rect.fromLTWH((size.width - w) / 2, 0, w, size.height);
    }
    canvas.drawImageRect(image, src, dst, Paint()..filterQuality = FilterQuality.none);
  }

  @override
  bool shouldRepaint(_AtlasSpritePainter old) =>
      old.image != image || old.src != src;
}

// ── Resource Bar (unchanged from before) ──────────────────────────────────

class _ResourceBar extends StatelessWidget {
  const _ResourceBar({
    required this.resources,
    required this.creature,
    required this.applyingType,
    required this.onApply,
    required this.isOpeningBox,
    required this.onOpenBox,
  });

  final Resources resources;
  final Creature creature;
  final ResourceType? applyingType;
  final void Function(ResourceType) onApply;
  final bool isOpeningBox;
  final VoidCallback onOpenBox;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ResourceButton(
              icon: '🍖',
              label: 'Food',
              amount: resources.food,
              stat: creature.fullness,
              type: ResourceType.food,
              isLoading: applyingType == ResourceType.food,
              disabled:
                  applyingType != null && applyingType != ResourceType.food,
              onTap: onApply,
            ),
            _ResourceButton(
              icon: '🎾',
              label: 'Play',
              amount: resources.play,
              stat: creature.happiness,
              type: ResourceType.play,
              isLoading: applyingType == ResourceType.play,
              disabled:
                  applyingType != null && applyingType != ResourceType.play,
              onTap: onApply,
            ),
            _ResourceButton(
              icon: '🛁',
              label: 'Clean',
              amount: resources.clean,
              stat: creature.cleanliness,
              type: ResourceType.clean,
              isLoading: applyingType == ResourceType.clean,
              disabled:
                  applyingType != null && applyingType != ResourceType.clean,
              onTap: onApply,
            ),
            _BoxButton(
              pieces: resources.boxPieces,
              isOpening: isOpeningBox,
              disabled: applyingType != null,
              onTap: onOpenBox,
            ),
          ],
        ),
      ),
    );
  }
}

class _BoxButton extends StatelessWidget {
  const _BoxButton({
    required this.pieces,
    required this.isOpening,
    required this.disabled,
    required this.onTap,
  });

  final int pieces;
  final bool isOpening;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final canOpen = pieces >= kBoxPiecesRequired && !isOpening && !disabled;
    return GestureDetector(
      onTap: canOpen ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: canOpen
              ? Colors.white.withValues(alpha: 0.85)
              : Colors.grey.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: canOpen ? Colors.purple.shade300 : Colors.grey.shade400,
            width: 1.5,
          ),
          boxShadow: canOpen
              ? [
                  BoxShadow(
                    color: Colors.purple.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            isOpening
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    '🎁',
                    style: TextStyle(
                      fontSize: 20,
                      color: canOpen ? null : Colors.grey,
                    ),
                  ),
            Text(
              '$pieces/$kBoxPiecesRequired',
              style: TextStyle(
                color: canOpen ? Colors.black : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            if (!canOpen && !isOpening)
              Text(
                pieces >= kBoxPiecesRequired ? '' : 'Pieces',
                style: const TextStyle(fontSize: 9, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}

class _ResourceButton extends StatefulWidget {
  const _ResourceButton({
    required this.icon,
    required this.label,
    required this.amount,
    required this.stat,
    required this.type,
    required this.isLoading,
    required this.disabled,
    required this.onTap,
  });

  final String icon;
  final String label;
  final int amount;
  final int stat;
  final ResourceType type;
  final bool isLoading;
  final bool disabled;
  final void Function(ResourceType) onTap;

  @override
  State<_ResourceButton> createState() => _ResourceButtonState();
}

class _ResourceButtonState extends State<_ResourceButton>
    with TickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final Animation<double> _offsetY;
  late final AnimationController _flashController;
  late final Animation<double> _flashOpacity;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _offsetY = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 0.0), weight: 60),
    ]).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _flashOpacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.4), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.4, end: 0.0), weight: 70),
    ]).animate(
      CurvedAnimation(parent: _flashController, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(_ResourceButton old) {
    super.didUpdateWidget(old);
    if (old.amount != widget.amount) _bounceController.forward(from: 0);
    if (old.isLoading && !widget.isLoading) _flashController.forward(from: 0);
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _flashController.dispose();
    super.dispose();
  }

  bool get _canApply =>
      !widget.disabled &&
      !widget.isLoading &&
      widget.amount > 0 &&
      widget.stat < 100;

  String get _disabledReason {
    if (widget.stat >= 100) return 'Full!';
    if (widget.amount <= 0) return 'None left';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _canApply ? () => widget.onTap(widget.type) : null,
      child: AnimatedBuilder(
        animation: Listenable.merge([_offsetY, _flashOpacity]),
        builder: (context, child) => Transform.translate(
          offset: Offset(0, _offsetY.value),
          child: Stack(
            alignment: Alignment.center,
            children: [
              child!,
              if (_flashOpacity.value > 0)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.yellow
                          .withValues(alpha: _flashOpacity.value),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
            ],
          ),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _canApply
                ? Colors.white.withValues(alpha: 0.85)
                : Colors.grey.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  _canApply ? Colors.amber.shade400 : Colors.grey.shade400,
              width: 1.5,
            ),
            boxShadow: _canApply
                ? [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              widget.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      widget.icon,
                      style: TextStyle(
                        fontSize: 20,
                        color: _canApply ? null : Colors.grey,
                      ),
                    ),
              Text(
                '${widget.amount}',
                style: TextStyle(
                  color: _canApply ? Colors.black : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              if (!_canApply && _disabledReason.isNotEmpty)
                Text(
                  _disabledReason,
                  style: const TextStyle(fontSize: 9, color: Colors.grey),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
