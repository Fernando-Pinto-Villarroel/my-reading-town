import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reading_village/infrastructure/ui/config/app_theme.dart';
import 'package:reading_village/domain/rules/village_rules.dart';
import 'package:reading_village/domain/entities/placed_building.dart';
import 'package:reading_village/adapters/providers/village_provider.dart';
import 'package:reading_village/infrastructure/ui/widgets/common/resource_icon.dart';
import 'package:reading_village/infrastructure/ui/widgets/common/shared_utils.dart';
import 'package:reading_village/infrastructure/ui/localization/language_provider.dart';
import 'package:reading_village/infrastructure/ui/localization/context_ext.dart';

void showBuildingInfoSheet(
  BuildContext context, {
  required PlacedBuilding building,
  required VillageProvider village,
  required VoidCallback onSyncGameState,
}) {
  final langProvider = context.read<LanguageProvider>();
  final isDecoration = building.isDecoration;
  final atMaxLevel =
      isDecoration || building.level >= VillageRules.maxBuildingLevel;
  final template = VillageRules.findTemplate(building.type);
  if (template == null) return;

  final coinCost = atMaxLevel
      ? 0
      : VillageRules.upgradeCoinCost(
          template['coinCost'] as int, building.level);
  final woodCost = atMaxLevel
      ? 0
      : VillageRules.upgradeWoodCost(
          template['woodCost'] as int, building.level);
  final metalCost = atMaxLevel
      ? 0
      : VillageRules.upgradeMetalCost(
          template['metalCost'] as int, building.level);
  final upgradeMinutes = atMaxLevel
      ? 0
      : VillageRules.upgradeConstructionMinutes(
          template['constructionMinutes'] as int, building.level);
  final canAfford = !atMaxLevel &&
      village.coins >= coinCost &&
      village.wood >= woodCost &&
      village.metal >= metalCost &&
      village.canStartConstruction;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    isScrollControlled: true,
    constraints: sheetConstraints(context),
    builder: (sheetCtx) => Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewPadding.bottom),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dragHandle(),
              SizedBox(height: 16),
              Image.asset(
                'assets/images/${VillageRules.spriteForBuilding(building.type, building.level)}',
                width: 88,
                height: 88,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, __, ___) =>
                    Icon(Icons.park, size: 88, color: AppTheme.mint),
              ),
              SizedBox(height: 8),
              Text(
                  context.t('building_name_${building.type}',
                      fallback: building.name),
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkText)),
              if (!isDecoration)
                Text(
                    '${langProvider.translate('level_label')} ${building.level}',
                    style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.lavender,
                        fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(
                _buildingDescription(building, langProvider),
                style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.darkText.withValues(alpha: 0.6)),
              ),
              if (building.type == 'house' && building.id != null)
                _buildResidentsList(village, building, langProvider),
              SizedBox(height: 16),
              if (atMaxLevel)
                Text(
                  isDecoration
                      ? langProvider.translate('decoration_label')
                      : langProvider.translate('max_level_reached'),
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color:
                          isDecoration ? AppTheme.lavender : AppTheme.coinGold),
                )
              else ...[
                Text(
                    '${langProvider.translate('upgrade_to_level')}${building.level + 1}:',
                    style: TextStyle(fontSize: 14, color: AppTheme.darkText)),
                SizedBox(height: 4),
                _upgradeCapacityPreview(building, langProvider),
                SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  children: [
                    _costChip(ResourceIcon.coin(size: 20), coinCost),
                    if (woodCost > 0)
                      _costChip(ResourceIcon.wood(size: 20), woodCost),
                    if (metalCost > 0)
                      _costChip(ResourceIcon.metal(size: 20), metalCost),
                  ],
                ),
                SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer_outlined,
                        size: 16,
                        color: AppTheme.darkText.withValues(alpha: 0.5)),
                    SizedBox(width: 4),
                    Text(formatMinutes(upgradeMinutes),
                        style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.darkText.withValues(alpha: 0.6))),
                  ],
                ),
                SizedBox(height: 6),
                _expBadge(((template['exp'] as int? ?? 20) *
                        VillageRules.upgradeExpMultiplier)
                    .round()),
              ],
              SizedBox(height: 16),
              if (!atMaxLevel)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: canAfford
                        ? () async {
                            Navigator.pop(sheetCtx);
                            final success =
                                await village.upgradeBuilding(building.id!);
                            if (success) onSyncGameState();
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          canAfford ? AppTheme.mint : Colors.grey.shade300,
                      foregroundColor: AppTheme.darkText,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      canAfford
                          ? '${langProvider.translate('upgrade_button')} ${context.t('building_name_${building.type}', fallback: building.name)}!'
                          : !village.canStartConstruction
                              ? langProvider.translate('all_constructors_busy')
                              : langProvider.translate('not_enough_resources'),
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              SizedBox(height: 8),
            ],
          ),
        ),
      ),
    ),
  );
}

String _buildingDescription(
    PlacedBuilding building, LanguageProvider langProvider) {
  if (building.isDecoration) {
    return langProvider.translate('decorative_desc');
  }
  if (building.type == 'house') {
    return '${langProvider.translate('houses_label')} ${VillageRules.villagersPerHouse(building.level)} ${langProvider.translate('villager_singular')}(s)';
  }
  return '${langProvider.translate('covers_label')} ${VillageRules.buildingCapacity(building.type, building.level)} ${langProvider.translate('villager_needs_label')}';
}

Widget _buildResidentsList(VillageProvider village, PlacedBuilding building,
    LanguageProvider langProvider) {
  final residents = village.villagersInHouse(building.id!);
  if (residents.isEmpty) return SizedBox.shrink();
  return Column(
    children: [
      SizedBox(height: 12),
      Text(langProvider.translate('resident_list'),
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkText)),
      SizedBox(height: 4),
      ...residents.map((v) => Padding(
            padding: EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/${v.spriteFile}',
                    width: 20, height: 26, filterQuality: FilterQuality.medium),
                SizedBox(width: 6),
                Text(v.name,
                    style: TextStyle(fontSize: 13, color: AppTheme.darkText)),
                SizedBox(width: 4),
                Text('(${v.moodText})',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.darkText.withValues(alpha: 0.5))),
              ],
            ),
          )),
    ],
  );
}

Widget _upgradeCapacityPreview(
    PlacedBuilding building, LanguageProvider langProvider) {
  final currentCap = building.type == 'house'
      ? VillageRules.villagersPerHouse(building.level)
      : VillageRules.buildingCapacity(building.type, building.level);
  final nextCap = building.type == 'house'
      ? VillageRules.villagersPerHouse(building.level + 1)
      : VillageRules.buildingCapacity(building.type, building.level + 1);
  final diff = nextCap - currentCap;
  final label = building.type == 'house'
      ? langProvider.translate('villager_capacity')
      : langProvider.translate('villager_needs_covered');
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.people, size: 14, color: AppTheme.lavender),
      SizedBox(width: 4),
      Text('$currentCap',
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.lavender)),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 4),
        child: Icon(Icons.arrow_forward, size: 14, color: AppTheme.lavender),
      ),
      Text('$nextCap $label (+$diff)',
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.lavender)),
    ],
  );
}

Widget _dragHandle() {
  return Container(
    width: 40,
    height: 4,
    decoration: BoxDecoration(
      color: Colors.grey.shade300,
      borderRadius: BorderRadius.circular(2),
    ),
  );
}

Widget _expBadge(int exp) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: AppTheme.coinGold.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star, size: 14, color: const Color(0xFFB8860B)),
        SizedBox(width: 4),
        Text('+$exp EXP',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFB8860B))),
      ],
    ),
  );
}

Widget _costChip(Widget icon, int amount) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      icon,
      SizedBox(width: 4),
      Text('$amount',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    ],
  );
}
