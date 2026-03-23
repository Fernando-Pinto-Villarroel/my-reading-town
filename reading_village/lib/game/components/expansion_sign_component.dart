import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;
import '../../config/game_constants.dart';
import '../../config/app_theme.dart';

class ExpansionSignComponent extends PositionComponent {
  final int chunkX;
  final int chunkY;

  Sprite? _sprite;
  double _bobTimer = 0;
  double _bobOffset = 0;

  ExpansionSignComponent({
    required this.chunkX,
    required this.chunkY,
  }) : super(
          // Top-left corner of the center tile (index 2) in the 5×5 chunk
          position: Vector2(
            (chunkX * GameConstants.chunkSize + 2) * GameConstants.tilePixelSize,
            (chunkY * GameConstants.chunkSize + 2) * GameConstants.tilePixelSize,
          ),
          // Exactly 1×1 tile
          size: Vector2.all(GameConstants.tilePixelSize),
          anchor: Anchor.topLeft,
          priority: 5,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    try {
      _sprite = await Sprite.load('expansion_sign.png');
    } catch (_) {
      // Fallback: will draw procedurally if sprite not found
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _bobTimer += dt;
    _bobOffset = sin(_bobTimer * 2.0) * 3.0;
  }

  /// Check if a world position hits this sign.
  bool containsWorldPoint(Vector2 worldPos) {
    final rel = worldPos - position;
    return rel.x >= 0 && rel.x < size.x && rel.y >= 0 && rel.y < size.y;
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(0, _bobOffset);

    if (_sprite != null) {
      final imgW = _sprite!.image.width.toDouble();
      final imgH = _sprite!.image.height.toDouble();
      final aspect = imgW / imgH;
      // Fit height to tile, preserve aspect ratio
      final drawH = size.y;
      final drawW = drawH * aspect;
      final offsetX = (size.x - drawW) / 2;
      _sprite!.render(
        canvas,
        position: Vector2(offsetX, 0),
        size: Vector2(drawW, drawH),
      );
    } else {
      // Fallback draws relative to tile center
      canvas.translate(size.x / 2, size.y / 2);
      _renderFallbackSign(canvas);
    }

    canvas.restore();
  }

  void _renderFallbackSign(Canvas canvas) {
    final s = size.x;

    // Post
    final postPaint = Paint()..color = const Color(0xFFC4935A);
    final postW = s * 0.12;
    final postH = s * 0.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(0, s * 0.1), width: postW, height: postH),
        Radius.circular(postW / 3),
      ),
      postPaint,
    );

    // Sign board (chubby)
    final boardPaint = Paint()..color = const Color(0xFFDEB887);
    final boardW = s * 0.55;
    final boardH = s * 0.35;
    final boardRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(0, -s * 0.12), width: boardW, height: boardH),
      const Radius.circular(10),
    );
    canvas.drawRRect(boardRect, boardPaint);
    canvas.drawRRect(
      boardRect,
      Paint()
        ..color = const Color(0xFFA0784A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Happy face on board
    final facePaint = Paint()..color = const Color(0xFF6B4226);
    // Eyes
    canvas.drawCircle(Offset(-s * 0.07, -s * 0.14), s * 0.025, facePaint);
    canvas.drawCircle(Offset(s * 0.07, -s * 0.14), s * 0.025, facePaint);
    // Smile
    canvas.drawArc(
      Rect.fromCenter(center: Offset(0, -s * 0.09), width: s * 0.12, height: s * 0.08),
      0,
      pi,
      false,
      facePaint..style = PaintingStyle.stroke..strokeWidth = 1.5,
    );

    // Gold coins at base
    final coinPaint = Paint()..color = AppTheme.coinGold;
    canvas.drawCircle(Offset(-s * 0.12, s * 0.3), s * 0.04, coinPaint);
    canvas.drawCircle(Offset(-s * 0.06, s * 0.33), s * 0.035, coinPaint);

    // Green gems at base
    final gemPaint = Paint()..color = const Color(0xFF4CAF50);
    canvas.drawCircle(Offset(s * 0.10, s * 0.31), s * 0.035, gemPaint);
    canvas.drawCircle(Offset(s * 0.15, s * 0.28), s * 0.03, gemPaint);

    // Grass at base
    final grassPaint = Paint()..color = const Color(0xFF90C890);
    for (int i = -2; i <= 2; i++) {
      final gx = i * s * 0.07;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(gx, s * 0.36), width: s * 0.06, height: s * 0.1),
        grassPaint,
      );
    }
  }
}
