import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart' hide Image;
import '../../models/villager.dart';
import '../../config/game_constants.dart';
import '../../data/villager_favorites.dart' show VillagerFavorites;

class VillagerComponent extends PositionComponent with TapCallbacks {
  Villager villager;
  List<String> roadTiles;
  List<String> missingBuildingTypes;
  final void Function(Villager)? onTapped;

  Sprite? _sprite;
  String _currentSpriteFile = '';

  late Vector2 _targetPosition;
  double _waitTimer = 0;
  bool _isWaiting = true;
  bool _facingRight = true;
  final double _speed = 120.0;
  final Random _random = Random();

  double _bobTimer = 0;
  double _bobOffset = 0;

  double _bubbleTimer = 0;
  bool _showBubble = false;
  int _bubbleIconIndex = 0;

  double _happyBubbleTimer = 0;
  bool _showHappyBubble = false;

  VillagerComponent({
    required this.villager,
    required Vector2 position,
    required this.roadTiles,
    this.missingBuildingTypes = const [],
    this.onTapped,
  }) : super(
          position: position,
          size: Vector2(GameConstants.tilePixelSize * 0.38, GameConstants.tilePixelSize * 0.50),
          anchor: Anchor.center,
          priority: 200,
        ) {
    _targetPosition = position.clone();
    _waitTimer = _random.nextDouble() * 2;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _currentSpriteFile = villager.spriteFile;
    _sprite = await Sprite.load(_currentSpriteFile);
  }

  @override
  void onTapUp(TapUpEvent event) {
    onTapped?.call(villager);
  }

  Future<void> _refreshSprite() async {
    final newFile = villager.spriteFile;
    if (newFile != _currentSpriteFile) {
      _currentSpriteFile = newFile;
      _sprite = await Sprite.load(_currentSpriteFile);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _refreshSprite();

    if (_isWaiting) {
      _waitTimer -= dt;
      if (_waitTimer <= 0) {
        _pickNewTarget();
        _isWaiting = false;
      }
    } else {
      final direction = _targetPosition - position;
      final distance = direction.length;

      if (distance < 3) {
        _isWaiting = true;
        _waitTimer = 0.5 + _random.nextDouble() * 2.0;
      } else {
        final normalized = direction.normalized();
        position += normalized * _speed * dt;
        _facingRight = normalized.x > 0;
      }
    }

    _bobTimer += dt;
    if (!_isWaiting) {
      _bobOffset = sin(_bobTimer * 8) * 3;
    } else {
      _bobOffset = sin(_bobTimer * 2) * 1;
    }

    if (villager.isSad && missingBuildingTypes.isNotEmpty) {
      _bubbleTimer += dt;
      if (_bubbleTimer > 3.0) {
        _bubbleTimer = 0;
        _showBubble = !_showBubble;
        if (_showBubble) {
          _bubbleIconIndex = _random.nextInt(missingBuildingTypes.length);
        }
      }
      _showHappyBubble = false;
      _happyBubbleTimer = 0;
    } else {
      _showBubble = false;
      _bubbleTimer = 0;

      // Happy villagers occasionally show a quote bubble
      if (villager.happiness >= 60) {
        _happyBubbleTimer += dt;
        if (_happyBubbleTimer > 8.0) {
          _happyBubbleTimer = 0;
          _showHappyBubble = !_showHappyBubble;
        }
      } else {
        _showHappyBubble = false;
        _happyBubbleTimer = 0;
      }
    }
  }

  void _pickNewTarget() {
    final currentTileX =
        (position.x / GameConstants.tilePixelSize).floor();
    final currentTileY =
        (position.y / GameConstants.tilePixelSize).floor();

    final neighbors = [
      (currentTileX + 1, currentTileY),
      (currentTileX - 1, currentTileY),
      (currentTileX, currentTileY + 1),
      (currentTileX, currentTileY - 1),
    ];

    final validNeighbors = neighbors
        .where((n) => roadTiles.contains('${n.$1},${n.$2}'))
        .toList();

    if (validNeighbors.isEmpty) {
      if (roadTiles.isNotEmpty) {
        final randomRoad = roadTiles[_random.nextInt(roadTiles.length)];
        final parts = randomRoad.split(',');
        _targetPosition = Vector2(
          int.parse(parts[0]) * GameConstants.tilePixelSize +
              GameConstants.tilePixelSize / 2,
          int.parse(parts[1]) * GameConstants.tilePixelSize +
              GameConstants.tilePixelSize / 2,
        );
      }
      return;
    }

    final target = validNeighbors[_random.nextInt(validNeighbors.length)];
    _targetPosition = Vector2(
      target.$1 * GameConstants.tilePixelSize +
          GameConstants.tilePixelSize / 2,
      target.$2 * GameConstants.tilePixelSize +
          GameConstants.tilePixelSize / 2,
    );
  }

  void _renderThoughtBubble(Canvas canvas) {
    if (!_showBubble || missingBuildingTypes.isEmpty) return;

    final type = missingBuildingTypes[_bubbleIconIndex % missingBuildingTypes.length];

    final bubbleX = size.x * 0.7;
    final bubbleY = -40.0;
    final bubbleR = 34.0;

    canvas.drawCircle(
      Offset(bubbleX, bubbleY),
      bubbleR,
      Paint()..color = const Color(0xF0FFFFFF),
    );
    canvas.drawCircle(
      Offset(bubbleX, bubbleY),
      bubbleR,
      Paint()
        ..color = const Color(0x50000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    canvas.drawCircle(Offset(bubbleX - 16, bubbleY + bubbleR + 6), 7, Paint()..color = const Color(0xDDFFFFFF));
    canvas.drawCircle(Offset(bubbleX - 10, bubbleY + bubbleR + 16), 4, Paint()..color = const Color(0xBBFFFFFF));

    _drawNeedIcon(canvas, type, bubbleX, bubbleY);
  }

  static const _needEmojis = {
    'water_plant': '💧',
    'power_plant': '⚡',
    'hospital': '🏥',
    'school': '🎒',
    'park': '🌳',
  };

  void _drawNeedIcon(Canvas canvas, String type, double cx, double cy) {
    final emoji = _needEmojis[type] ?? '❓';
    final painter = TextPainter(
      text: TextSpan(
        text: emoji,
        style: const TextStyle(fontSize: 28),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset(cx - painter.width / 2, cy - painter.height / 2));
  }

  void _renderHappyBubble(Canvas canvas) {
    if (!_showHappyBubble) return;

    final idx = villager.id ?? 0;
    final text = '❤️ ${VillagerFavorites.author(idx)}';

    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(fontSize: 10, color: Color(0xFF4A4A4A)),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: 140);

    final padH = 8.0;
    final padV = 5.0;
    final bubbleW = painter.width + padH * 2;
    final bubbleH = painter.height + padV * 2;
    final bubbleX = size.x * 0.5 - bubbleW / 2;
    final bubbleY = -bubbleH - 14;

    // Rounded bubble
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(bubbleX, bubbleY, bubbleW, bubbleH),
      const Radius.circular(10),
    );
    canvas.drawRRect(rrect, Paint()..color = const Color(0xF0FFFFFF));
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = const Color(0x30000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Small tail
    canvas.drawCircle(
      Offset(size.x * 0.5 - 6, bubbleY + bubbleH + 4), 4,
      Paint()..color = const Color(0xDDFFFFFF),
    );
    canvas.drawCircle(
      Offset(size.x * 0.5 - 2, bubbleY + bubbleH + 10), 2.5,
      Paint()..color = const Color(0xBBFFFFFF),
    );

    painter.paint(canvas, Offset(bubbleX + padH, bubbleY + padV));
  }

  @override
  void render(Canvas canvas) {
    if (_sprite == null) return;

    canvas.save();
    canvas.translate(0, _bobOffset);

    if (!_facingRight) {
      canvas.translate(size.x, 0);
      canvas.scale(-1, 1);
    }

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.x / 2, size.y - 3),
        width: size.x * 0.6,
        height: 12,
      ),
      Paint()..color = const Color(0x30000000),
    );

    _sprite!.render(canvas, size: size);

    if (!_facingRight) {
      canvas.scale(-1, 1);
      canvas.translate(-size.x, 0);
    }

    _renderThoughtBubble(canvas);
    _renderHappyBubble(canvas);

    final namePainter = TextPainter(
      text: TextSpan(
        text: villager.name,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF4A4A4A),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          (size.x - namePainter.width) / 2 - 5,
          size.y + 2,
          namePainter.width + 10,
          16,
        ),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xCCFFFFFF),
    );
    namePainter.paint(
        canvas, Offset((size.x - namePainter.width) / 2, size.y + 3));

    canvas.restore();
  }
}
