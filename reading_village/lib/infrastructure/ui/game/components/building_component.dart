import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:reading_village/domain/entities/placed_building.dart';
import 'package:reading_village/domain/rules/village_rules.dart';
import '../village_game.dart';

class BuildingComponent extends PositionComponent {
  PlacedBuilding building;

  Sprite? _builtSprite;
  Sprite? _constructionSprite;
  int _loadedLevel = 0;

  double _pulseTimer = 0;
  double _pulseScale = 1.0;
  bool _justUpgraded = false;
  Duration effectiveRemaining = Duration.zero;

  BuildingComponent({
    required this.building,
    required Vector2 position,
    required Vector2 size,
  }) : super(position: position, size: size, priority: 10 + building.tileY);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _constructionSprite = await Sprite.load('building_construction.png');
    await _loadLevelSprite();
  }

  Future<void> _loadLevelSprite() async {
    final filename =
        VillageRules.spriteForBuilding(building.type, building.level);
    _builtSprite = await Sprite.load(filename);
    _loadedLevel = building.level;
  }

  void updateBuilding(PlacedBuilding updated) {
    if (updated.level > building.level) {
      _justUpgraded = true;
      _pulseTimer = 0;
    }
    if (updated.isConstructed) effectiveRemaining = Duration.zero;
    building = updated;
    priority = 10 + building.tileY;
    if (building.level != _loadedLevel && building.isConstructed) {
      _loadLevelSprite();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_justUpgraded) {
      _pulseTimer += dt;
      _pulseScale = 1.0 + 0.2 * (1.0 - _pulseTimer / 0.5).clamp(0.0, 1.0);
      if (_pulseTimer > 0.5) {
        _justUpgraded = false;
        _pulseScale = 1.0;
      }
    } else if (building.isConstructed) {
      _pulseTimer += dt;
      _pulseScale = 1.0 + 0.01 * sin(_pulseTimer * 2);
    }
  }

  static const _glowTypes = {
    'house',
    'hospital',
    'park',
    'power_plant',
    'lamp_post'
  };

  void _renderNightGlow(Canvas canvas, double offsetX, double offsetY,
      double spriteW, double spriteH) {
    if (!_glowTypes.contains(building.type)) return;

    if (building.type == 'lamp_post') {
      final bulbX = offsetX + spriteW / 2;
      final bulbY = offsetY + spriteH * 0.20;
      final glowRadius = spriteH * 0.9;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFE57A),
            const Color.fromARGB(105, 255, 107, 2),
            const Color(0x00FF8C00),
          ],
          stops: const [0.0, 0.25, 1.0],
        ).createShader(
            Rect.fromCircle(center: Offset(bulbX, bulbY), radius: glowRadius));
      canvas.drawCircle(Offset(bulbX, bulbY), glowRadius, paint);
    } else {
      final centerX = offsetX + spriteW / 2;
      final centerY = offsetY + spriteH / 2;
      final glowRadius = (spriteW + spriteH) * 0.6;
      final glowColor = const Color(0x77FF6D00);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [glowColor, glowColor.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(
            center: Offset(centerX, centerY), radius: glowRadius));
      canvas.drawCircle(Offset(centerX, centerY), glowRadius, paint);
    }
  }

  @override
  void render(Canvas canvas) {
    final sprite = building.isConstructed ? _builtSprite : _constructionSprite;
    if (sprite == null) return;

    final imgW = sprite.image.width.toDouble();
    final imgH = sprite.image.height.toDouble();
    final aspect = imgW / imgH;

    double spriteW = size.x * 0.95;
    double spriteH = spriteW / aspect;

    if (spriteH > size.y * 0.95) {
      spriteH = size.y * 0.95;
      spriteW = spriteH * aspect;
    }

    final offsetX = (size.x - spriteW) / 2;
    final offsetY = size.y - spriteH;

    final isNight = (findGame() as VillageGame?)?.isNightMode ?? false;
    if (isNight && building.isConstructed) {
      _renderNightGlow(canvas, offsetX, offsetY, spriteW, spriteH);
    }

    canvas.save();

    final cx = offsetX + spriteW / 2;
    final cy = offsetY + spriteH / 2;
    canvas.translate(cx, cy);
    if (building.isFlipped) {
      canvas.scale(-_pulseScale, _pulseScale);
    } else {
      canvas.scale(_pulseScale, _pulseScale);
    }
    canvas.translate(-cx, -cy);

    sprite.render(canvas,
        position: Vector2(offsetX, offsetY), size: Vector2(spriteW, spriteH));

    canvas.restore();

    if (!building.isConstructed && building.constructionStart != null) {
      final zoom = (findGame() as VillageGame?)?.currentZoom ?? 1.0;
      final uiScale = 1.0 / zoom.clamp(0.3, 2.0);

      final remaining = effectiveRemaining;
      final hours = remaining.inHours;
      final mins = remaining.inMinutes % 60;
      final secs = remaining.inSeconds % 60;
      final timerText = hours > 0
          ? '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}'
          : '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

      final fontSize = 11.0 * uiScale;
      final timerPainter = TextPainter(
        text: TextSpan(
          text: timerText,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFFFFFFF),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final pillPadH = 8.0 * uiScale;
      final pillH = 18.0 * uiScale;
      final pillRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          (size.x - timerPainter.width) / 2 - pillPadH,
          offsetY - pillH - 2 * uiScale,
          timerPainter.width + pillPadH * 2,
          pillH,
        ),
        Radius.circular(9.0 * uiScale),
      );
      canvas.drawRRect(pillRect, Paint()..color = const Color(0xCC000000));
      timerPainter.paint(
          canvas,
          Offset(
              (size.x - timerPainter.width) / 2, pillRect.top + 1 * uiScale));

      final total = building.constructionDurationMinutes * 60;
      final elapsed = total - remaining.inSeconds;
      final progress = (elapsed / total).clamp(0.0, 1.0);
      final barWidth = timerPainter.width + pillPadH * 2;
      final barX = (size.x - barWidth) / 2;
      final barY = pillRect.bottom + 2 * uiScale;
      final barH = 5.0 * uiScale;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(barX, barY, barWidth, barH),
            Radius.circular(barH / 2)),
        Paint()..color = const Color(0x40000000),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(barX, barY, barWidth * progress, barH),
            Radius.circular(barH / 2)),
        Paint()..color = const Color(0xFFFFB3BA),
      );
    }
  }
}
