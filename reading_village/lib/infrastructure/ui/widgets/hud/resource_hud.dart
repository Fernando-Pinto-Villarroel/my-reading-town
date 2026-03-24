import 'package:flutter/material.dart';
import 'package:reading_village/infrastructure/ui/config/app_theme.dart';
import 'package:reading_village/adapters/providers/village_provider.dart';
import 'package:reading_village/infrastructure/ui/widgets/common/resource_icon.dart';

class ResourceHud extends StatelessWidget {
  final VillageProvider village;
  final bool landscape;
  final bool expanded;
  final VoidCallback onToggle;

  const ResourceHud({
    super.key,
    required this.village,
    required this.landscape,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = landscape ? 28.0 : 32.0;
    final fontSize = landscape ? 17.0 : 19.0;
    final spacing = landscape ? 4.0 : 5.0;
    final padding = landscape
        ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 10);

    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: const Color(0xAA000000),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, size: iconSize, color: AppTheme.coinGold),
                SizedBox(width: 6),
                Text(
                  'Lv${village.playerLevel}',
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.black87, blurRadius: 4)],
                  ),
                ),
                SizedBox(width: 8),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: landscape ? 20 : 22,
                  color: Colors.white70,
                ),
              ],
            ),
            if (expanded) ...[
              SizedBox(height: spacing),
              _hudRow(ResourceIcon.coin(size: iconSize), '${village.coins}',
                  fontSize),
              SizedBox(height: spacing),
              _hudRow(ResourceIcon.gem(size: iconSize), '${village.gems}',
                  fontSize),
              SizedBox(height: spacing),
              _hudRow(ResourceIcon.wood(size: iconSize), '${village.wood}',
                  fontSize),
              SizedBox(height: spacing),
              _hudRow(ResourceIcon.metal(size: iconSize), '${village.metal}',
                  fontSize),
            ],
          ],
        ),
      ),
    );
  }

  Widget _hudRow(Widget icon, String value, [double fontSize = 19]) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        SizedBox(width: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [Shadow(color: Colors.black87, blurRadius: 4)],
          ),
        ),
      ],
    );
  }
}
