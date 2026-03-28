import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:my_reading_town/infrastructure/ui/game/village_game.dart';

class TapThroughInteractiveViewer extends StatelessWidget {
  final TransformationController transformationController;
  final double minScale;
  final double maxScale;
  final VillageGame game;

  const TapThroughInteractiveViewer({
    super.key,
    required this.transformationController,
    required this.minScale,
    required this.maxScale,
    required this.game,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapUp: (details) {
        final zoom = game.currentZoom;
        final camPos = game.camera.viewfinder.position;
        final screenSize = game.size;
        final worldX =
            camPos.x + (details.localPosition.dx - screenSize.x / 2) / zoom;
        final worldY =
            camPos.y + (details.localPosition.dy - screenSize.y / 2) / zoom;
        game.handleWorldTap(Vector2(worldX, worldY));
      },
      child: InteractiveViewer(
        transformationController: transformationController,
        minScale: minScale,
        maxScale: maxScale,
        panEnabled: true,
        scaleEnabled: true,
        boundaryMargin: const EdgeInsets.all(double.infinity),
        child: SizedBox.expand(),
      ),
    );
  }
}
