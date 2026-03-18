import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart' hide Image;
import '../../config/game_constants.dart';

class GridComponent extends Component with HasGameReference<FlameGame> {
  Set<String> roadTiles = {};
  Set<String> unlockedChunks = {};
  bool showGridLines = false;

  static const double _tileSize = GameConstants.tilePixelSize;
  static const int _mapSize = GameConstants.mapSize;

  static const List<Color> _grassColors = [
    Color(0xFFB8E6B8),
    Color(0xFFC2ECC2),
    Color(0xFFACDEAC),
    Color(0xFFBCE2B6),
    Color(0xFFB0E0B0),
  ];

  static const Color _roadColor = Color(0xFFE0D8C8);
  static const Color _roadDetailColor = Color(0xFFD0C8B8);

  GridComponent() : super(priority: -10);

  bool _isChunkUnlocked(int tileX, int tileY) {
    final cx = tileX ~/ GameConstants.chunkSize;
    final cy = tileY ~/ GameConstants.chunkSize;
    return unlockedChunks.contains('$cx,$cy');
  }

  @override
  void render(Canvas canvas) {
    final camPos = game.camera.viewfinder.position;
    final zoom = game.camera.viewfinder.zoom;
    final screenSize = game.size;

    final visibleW = screenSize.x / zoom;
    final visibleH = screenSize.y / zoom;

    final left = camPos.x - visibleW / 2;
    final top = camPos.y - visibleH / 2;
    final right = camPos.x + visibleW / 2;
    final bottom = camPos.y + visibleH / 2;

    final startX = ((left / _tileSize).floor() - 1).clamp(0, _mapSize - 1);
    final startY = ((top / _tileSize).floor() - 1).clamp(0, _mapSize - 1);
    final endX = ((right / _tileSize).ceil() + 1).clamp(0, _mapSize);
    final endY = ((bottom / _tileSize).ceil() + 1).clamp(0, _mapSize);

    final tilePaint = Paint();
    final gridPaint = Paint()
      ..color = const Color(0x30000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    final chunkBorderPaint = Paint()
      ..color = const Color(0x60FFB3BA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int y = startY; y < endY; y++) {
      for (int x = startX; x < endX; x++) {
        final rect = Rect.fromLTWH(
            x * _tileSize, y * _tileSize, _tileSize, _tileSize);
        final key = '$x,$y';
        final unlocked = _isChunkUnlocked(x, y);
        final isRoad = roadTiles.contains(key);

        if (isRoad && unlocked) {
          tilePaint.color = _roadColor;
          canvas.drawRect(rect, tilePaint);
          final detailHash = (x * 11 + y * 23) % 5;
          if (detailHash == 0) {
            canvas.drawCircle(
                Offset(rect.left + 12, rect.top + 20), 1.5,
                Paint()..color = _roadDetailColor);
          }
          if (detailHash == 2) {
            canvas.drawCircle(
                Offset(rect.left + 28, rect.top + 32), 1.0,
                Paint()..color = _roadDetailColor);
          }
        } else if (unlocked) {
          final colorIdx = (x * 7 + y * 13) % _grassColors.length;
          tilePaint.color = _grassColors[colorIdx];
          canvas.drawRect(rect, tilePaint);
        } else {
          const fogColors = [
            Color(0xFF8AB08A),
            Color(0xFF80A880),
            Color(0xFF90B890),
          ];
          tilePaint.color = fogColors[(x * 7 + y * 13) % 3];
          canvas.drawRect(rect, tilePaint);
          canvas.drawRect(rect, Paint()..color = const Color(0x40606060));
        }

        if (showGridLines && unlocked) {
          canvas.drawRect(rect, gridPaint);
        }
      }
    }

    if (showGridLines) {
      for (int y = startY; y < endY; y++) {
        for (int x = startX; x < endX; x++) {
          final cx = x ~/ GameConstants.chunkSize;
          final cy = y ~/ GameConstants.chunkSize;
          final isUnlocked = unlockedChunks.contains('$cx,$cy');
          if (!isUnlocked) continue;

          if (x % GameConstants.chunkSize == 0) {
            canvas.drawLine(
              Offset(x * _tileSize, y * _tileSize),
              Offset(x * _tileSize, (y + 1) * _tileSize),
              chunkBorderPaint,
            );
          }
          if (y % GameConstants.chunkSize == 0) {
            canvas.drawLine(
              Offset(x * _tileSize, y * _tileSize),
              Offset((x + 1) * _tileSize, y * _tileSize),
              chunkBorderPaint,
            );
          }
        }
      }
    }
  }
}
