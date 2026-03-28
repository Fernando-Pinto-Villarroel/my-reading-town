import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:my_reading_town/domain/rules/village_rules.dart';
import 'package:my_reading_town/infrastructure/ui/config/ui_constants.dart';

class GridComponent extends Component with HasGameReference<FlameGame> {
  Set<String> roadTiles = {};
  Set<String> unlockedChunks = {};
  bool showGridLines = false;

  String? highlightedChunk;

  static const Color _highlightFill = Color(0x30FFB3BA);
  static const Color _highlightBorder = Color(0xCCFFB3BA);

  static const double _tileSize = UiConstants.tilePixelSize;
  static const int _mapSize = VillageRules.mapSize;

  static const List<Color> _grassColors = [
    Color(0xFFB8E6B8),
    Color(0xFFC2ECC2),
    Color(0xFFACDEAC),
    Color(0xFFBCE2B6),
    Color(0xFFB0E0B0),
  ];

  static const List<Color> _nightGrassColors = [
    Color(0xFF2A4A5C),
    Color(0xFF2C4E62),
    Color(0xFF264658),
    Color(0xFF2E5060),
    Color(0xFF28485A),
  ];

  static const Color _roadColor = Color(0xFFE0D8C8);
  static const Color _roadDetailColor = Color(0xFFD0C8B8);
  static const Color _nightRoadColor = Color(0xFF3A3C50);
  static const Color _nightRoadDetailColor = Color(0xFF2E3044);

  static const List<Color> _fogColors = [
    Color(0xFF8AB08A),
    Color(0xFF80A880),
    Color(0xFF90B890),
  ];
  static const List<Color> _nightFogColors = [
    Color(0xFF1A2E3C),
    Color(0xFF182A38),
    Color(0xFF1E3240),
  ];

  bool isNightMode = false;

  GridComponent() : super(priority: -10);

  bool _isChunkUnlocked(int tileX, int tileY) {
    final cx = tileX ~/ VillageRules.chunkSize;
    final cy = tileY ~/ VillageRules.chunkSize;
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
        final rect =
            Rect.fromLTWH(x * _tileSize, y * _tileSize, _tileSize, _tileSize);
        final key = '$x,$y';
        final unlocked = _isChunkUnlocked(x, y);
        final isRoad = roadTiles.contains(key);

        final grassColors = isNightMode ? _nightGrassColors : _grassColors;
        final roadColor = isNightMode ? _nightRoadColor : _roadColor;
        final roadDetailColor =
            isNightMode ? _nightRoadDetailColor : _roadDetailColor;

        if (isRoad && unlocked) {
          tilePaint.color = roadColor;
          canvas.drawRect(rect, tilePaint);
          final detailHash = (x * 11 + y * 23) % 5;
          if (detailHash == 0) {
            canvas.drawCircle(Offset(rect.left + 12, rect.top + 20), 1.5,
                Paint()..color = roadDetailColor);
          }
          if (detailHash == 2) {
            canvas.drawCircle(Offset(rect.left + 28, rect.top + 32), 1.0,
                Paint()..color = roadDetailColor);
          }
        } else if (unlocked) {
          final colorIdx = (x * 7 + y * 13) % grassColors.length;
          tilePaint.color = grassColors[colorIdx];
          canvas.drawRect(rect, tilePaint);
        } else {
          final fogColors = isNightMode ? _nightFogColors : _fogColors;
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
          final cx = x ~/ VillageRules.chunkSize;
          final cy = y ~/ VillageRules.chunkSize;
          final isUnlocked = unlockedChunks.contains('$cx,$cy');
          if (!isUnlocked) continue;

          if (x % VillageRules.chunkSize == 0) {
            canvas.drawLine(
              Offset(x * _tileSize, y * _tileSize),
              Offset(x * _tileSize, (y + 1) * _tileSize),
              chunkBorderPaint,
            );
          }
          if (y % VillageRules.chunkSize == 0) {
            canvas.drawLine(
              Offset(x * _tileSize, y * _tileSize),
              Offset((x + 1) * _tileSize, y * _tileSize),
              chunkBorderPaint,
            );
          }
        }
      }
    }

    if (highlightedChunk != null) {
      final parts = highlightedChunk!.split(',');
      if (parts.length == 2) {
        final hcx = int.tryParse(parts[0]) ?? 0;
        final hcy = int.tryParse(parts[1]) ?? 0;
        final hx = hcx * VillageRules.chunkSize;
        final hy = hcy * VillageRules.chunkSize;
        final highlightRect = Rect.fromLTWH(
          hx * _tileSize,
          hy * _tileSize,
          VillageRules.chunkSize * _tileSize,
          VillageRules.chunkSize * _tileSize,
        );

        canvas.drawRect(highlightRect, Paint()..color = _highlightFill);

        final borderPaint = Paint()
          ..color = _highlightBorder
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.0;
        canvas.drawRRect(
          RRect.fromRectAndRadius(highlightRect, const Radius.circular(8)),
          borderPaint,
        );

        final accentPaint = Paint()..color = _highlightBorder;
        final cornerSize = _tileSize * 0.15;
        for (final corner in [
          highlightRect.topLeft,
          highlightRect.topRight + Offset(-cornerSize, 0),
          highlightRect.bottomLeft + Offset(0, -cornerSize),
          highlightRect.bottomRight + Offset(-cornerSize, -cornerSize),
        ]) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(corner.dx, corner.dy, cornerSize, cornerSize),
              const Radius.circular(4),
            ),
            accentPaint,
          );
        }
      }
    }
  }
}
