import 'package:flutter/material.dart';
import 'package:my_reading_town/infrastructure/ui/config/app_theme.dart';
import 'package:my_reading_town/domain/rules/village_rules.dart';
import 'package:my_reading_town/adapters/providers/village_provider.dart';
import 'package:my_reading_town/infrastructure/ui/widgets/common/resource_icon.dart';
import 'package:my_reading_town/infrastructure/ui/widgets/common/shared_utils.dart';
import 'package:my_reading_town/infrastructure/ui/localization/context_ext.dart';

class TemplateList extends StatelessWidget {
  final VillageProvider village;
  final bool landscape;
  final List<Map<String, dynamic>> templates;
  final bool isDecorationTab;
  final String? selectedType;
  final ValueChanged<String?> onSelect;

  const TemplateList({
    super.key,
    required this.village,
    required this.landscape,
    required this.templates,
    required this.isDecorationTab,
    required this.selectedType,
    required this.onSelect,
  });

  String _capacityText(String type, int level, BuildContext context) {
    if (VillageRules.isDecorationType(type)) return '';
    if (type == 'house') {
      final cap = VillageRules.villagersPerHouse(level);
      final unit = cap == 1
          ? context.t('villager_one', fallback: 'villager')
          : context.t('villager_many', fallback: 'villagers');
      return '${context.t('capacity_houses', fallback: 'Houses')} $cap $unit';
    }
    final cap = VillageRules.buildingCapacity(type, level);
    return '${context.t('capacity_covers', fallback: 'Covers')} $cap ${context.t('villager_many', fallback: 'villagers')}';
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(left: 8, right: 24),
      itemCount: templates.length,
      itemBuilder: (ctx, index) {
        final template = templates[index];
        final type = template['type'] as String;
        final isSelected = selectedType == type;
        final coinCost = template['coinCost'] as int;
        final gemCost = template['gemCost'] as int;
        final woodCost = template['woodCost'] as int;
        final metalCost = template['metalCost'] as int;
        final buildMinutes = template['constructionMinutes'] as int;
        final canAfford = village.coins >= coinCost &&
            village.gems >= gemCost &&
            village.wood >= woodCost &&
            village.metal >= metalCost;
        final canPlace =
            isDecorationTab ? true : village.canPlaceBuildingType(type);
        final currentCount = village.buildingCountOfType(type);
        final maxCount = VillageRules.maxBuildingsOfTypeForPlayerLevel(
            type, village.playerLevel);

        final translatedName = context.t(
          'building_name_$type',
          fallback: template['name'] as String,
        );
        return GestureDetector(
          onTap: canPlace
              ? () => onSelect(selectedType == type ? null : type)
              : null,
          child: landscape
              ? _landscapeCard(
                  context,
                  translatedName,
                  template,
                  type,
                  isSelected,
                  coinCost,
                  gemCost,
                  woodCost,
                  metalCost,
                  buildMinutes,
                  canAfford,
                  canPlace,
                  currentCount,
                  maxCount)
              : _portraitCard(
                  context,
                  translatedName,
                  template,
                  type,
                  isSelected,
                  coinCost,
                  gemCost,
                  woodCost,
                  metalCost,
                  buildMinutes,
                  canAfford,
                  canPlace,
                  currentCount,
                  maxCount),
        );
      },
    );
  }

  Widget _landscapeCard(
      BuildContext context,
      String translatedName,
      Map<String, dynamic> template,
      String type,
      bool isSelected,
      int coinCost,
      int gemCost,
      int woodCost,
      int metalCost,
      int buildMinutes,
      bool canAfford,
      bool canPlace,
      int currentCount,
      int maxCount) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 3, vertical: 4),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: _cardDecoration(isSelected),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildAssetPreview(type, 64, canAfford && canPlace),
          SizedBox(width: 6),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(translatedName,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkText)),
                  _costRow(coinCost, gemCost, woodCost, metalCost, 9, 12),
                  _timeExpRow(
                      buildMinutes, template['exp'] as int? ?? 20, 9, 10),
                  if (!isDecorationTab) _capacityRow(type, 9, 10, context),
                  if (!isDecorationTab)
                    _countRow(currentCount, maxCount, canPlace, 9, 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _portraitCard(
      BuildContext context,
      String translatedName,
      Map<String, dynamic> template,
      String type,
      bool isSelected,
      int coinCost,
      int gemCost,
      int woodCost,
      int metalCost,
      int buildMinutes,
      bool canAfford,
      bool canPlace,
      int currentCount,
      int maxCount) {
    return Container(
      width: 140,
      margin: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      padding: EdgeInsets.all(6),
      decoration: _cardDecoration(isSelected),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          buildAssetPreview(type, 80, canAfford && canPlace),
          SizedBox(height: 2),
          Text(translatedName,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkText),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          SizedBox(height: 1),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: _costRow(coinCost, gemCost, woodCost, metalCost, 10, 14),
          ),
          _timeExpRow(buildMinutes, template['exp'] as int? ?? 20, 11, 13),
          if (!isDecorationTab) _capacityRow(type, 10, 12, context),
          if (!isDecorationTab)
            _countRow(currentCount, maxCount, canPlace, 10, 12),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration(bool isSelected) {
    return BoxDecoration(
      color: isSelected
          ? AppTheme.mint.withValues(alpha: 0.3)
          : AppTheme.softWhite,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isSelected ? AppTheme.mint : Colors.grey.shade300,
        width: isSelected ? 2 : 1,
      ),
    );
  }

  Widget _costRow(int coinCost, int gemCost, int woodCost, int metalCost,
      double fontSize, double iconSize) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ResourceIcon.coin(size: iconSize),
        Text(' $coinCost', style: TextStyle(fontSize: fontSize)),
        if (woodCost > 0) ...[
          SizedBox(width: 3),
          ResourceIcon.wood(size: iconSize),
          Text(' $woodCost', style: TextStyle(fontSize: fontSize)),
        ],
        if (metalCost > 0) ...[
          SizedBox(width: 3),
          ResourceIcon.metal(size: iconSize),
          Text(' $metalCost', style: TextStyle(fontSize: fontSize)),
        ],
        if (gemCost > 0) ...[
          SizedBox(width: 3),
          ResourceIcon.gem(size: iconSize),
          Text(' $gemCost', style: TextStyle(fontSize: fontSize)),
        ],
      ],
    );
  }

  Widget _timeExpRow(
      int buildMinutes, int exp, double fontSize, double iconSize) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_outlined,
                size: iconSize, color: AppTheme.darkOrange),
            SizedBox(width: 3),
            Text(formatMinutes(buildMinutes),
                style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkText.withValues(alpha: 0.7))),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, size: iconSize, color: const Color(0xFFB8860B)),
            SizedBox(width: 2),
            Text('+$exp EXP',
                style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFB8860B))),
          ],
        ),
      ],
    );
  }

  Widget _capacityRow(
      String type, double fontSize, double iconSize, BuildContext context) {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 2,
        children: [
          Icon(Icons.people, size: iconSize, color: AppTheme.lavender),
          Text(_capacityText(type, 1, context),
              style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lavender),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _countRow(int currentCount, int maxCount, bool canPlace,
      double fontSize, double iconSize) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.home_work,
            size: iconSize,
            color: canPlace ? AppTheme.darkMint : Colors.red.shade300),
        SizedBox(width: 3),
        Text(
          '$currentCount / $maxCount',
          style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: canPlace ? AppTheme.darkMint : Colors.red.shade300),
        ),
      ],
    );
  }
}
