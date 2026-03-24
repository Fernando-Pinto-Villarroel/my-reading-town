import 'package:flutter/material.dart';
import 'package:reading_village/infrastructure/ui/config/app_theme.dart';
import 'package:reading_village/domain/rules/village_rules.dart';
import 'package:reading_village/adapters/providers/village_provider.dart';
import 'package:reading_village/infrastructure/ui/widgets/common/template_list.dart';
import 'package:reading_village/infrastructure/ui/localization/context_ext.dart';

class BuildingSelector extends StatelessWidget {
  final VillageProvider village;
  final bool landscape;
  final TabController tabController;
  final String? selectedBuildingType;
  final int? movingBuildingId;
  final bool flipNextBuilding;
  final ValueChanged<String?> onSelectBuilding;
  final VoidCallback onToggleFlip;

  const BuildingSelector({
    super.key,
    required this.village,
    required this.landscape,
    required this.tabController,
    required this.selectedBuildingType,
    required this.movingBuildingId,
    required this.flipNextBuilding,
    required this.onSelectBuilding,
    required this.onToggleFlip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: landscape ? 180 : 310,
      margin: EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.cream.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(landscape ? 14 : 20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(8, 4, 8, 0),
            child: TabBar(
              controller: tabController,
              labelColor: AppTheme.darkText,
              unselectedLabelColor: AppTheme.darkText.withValues(alpha: 0.5),
              indicatorColor: AppTheme.pink,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: TextStyle(
                  fontSize: landscape ? 11 : 13, fontWeight: FontWeight.bold),
              unselectedLabelStyle: TextStyle(fontSize: landscape ? 11 : 13),
              tabs: [
                Tab(
                    text: context.t('buildings_tab'),
                    height: landscape ? 26 : 30),
                Tab(
                    text: context.t('decorations_tab'),
                    height: landscape ? 26 : 30),
                Tab(text: context.t('tiles_tab'), height: landscape ? 26 : 30),
              ],
            ),
          ),
          if (selectedBuildingType != null || movingBuildingId == null)
            _buildActionHints(context),
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: [
                TemplateList(
                  village: village,
                  landscape: landscape,
                  templates: VillageRules.buildingTemplates,
                  isDecorationTab: false,
                  selectedType: selectedBuildingType,
                  onSelect: onSelectBuilding,
                ),
                TemplateList(
                  village: village,
                  landscape: landscape,
                  templates: VillageRules.decorationTemplates,
                  isDecorationTab: true,
                  selectedType: selectedBuildingType,
                  onSelect: onSelectBuilding,
                ),
                _TileList(
                  village: village,
                  landscape: landscape,
                  selectedType: selectedBuildingType,
                  onSelect: onSelectBuilding,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionHints(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.symmetric(horizontal: 12, vertical: landscape ? 2 : 4),
      child: Row(
        children: [
          if (selectedBuildingType != null &&
              VillageRules.isTileType(selectedBuildingType!)) ...[
            Icon(Icons.touch_app,
                size: 14, color: AppTheme.darkText.withValues(alpha: 0.5)),
            SizedBox(width: 4),
            Text(context.t('tap_tiles_road'),
                style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.darkText.withValues(alpha: 0.6))),
          ] else if (selectedBuildingType != null) ...[
            GestureDetector(
              onTap: onToggleFlip,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: flipNextBuilding
                      ? AppTheme.mint
                      : AppTheme.darkText.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.flip,
                        size: 14,
                        color: flipNextBuilding
                            ? Colors.white
                            : AppTheme.darkText),
                    SizedBox(width: 3),
                    Text(context.t('flip'),
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: flipNextBuilding
                                ? Colors.white
                                : AppTheme.darkText)),
                  ],
                ),
              ),
            ),
            SizedBox(width: 8),
            Text(context.t('tap_tile_to_place'),
                style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.darkText.withValues(alpha: 0.6))),
          ] else if (movingBuildingId == null)
            Text(context.t('tap_tile_to_move'),
                style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.darkText.withValues(alpha: 0.6))),
        ],
      ),
    );
  }
}

class _TileList extends StatelessWidget {
  final VillageProvider village;
  final bool landscape;
  final String? selectedType;
  final ValueChanged<String?> onSelect;

  const _TileList({
    required this.village,
    required this.landscape,
    required this.selectedType,
    required this.onSelect,
  });

  Widget _buildTilePreview(String type, double size) {
    if (type == 'road') {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFFE0D8C8),
          borderRadius: BorderRadius.circular(6),
        ),
      );
    }
    return Container(width: size, height: size, color: Colors.grey.shade300);
  }

  @override
  Widget build(BuildContext context) {
    final templates = VillageRules.tileTemplates;
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 8),
      itemCount: templates.length,
      itemBuilder: (ctx, index) {
        final template = templates[index];
        final type = template['type'] as String;
        final isSelected = selectedType == type;

        return GestureDetector(
          onTap: () => onSelect(selectedType == type ? null : type),
          child: landscape
              ? _landscapeTile(ctx, template, type, isSelected)
              : _portraitTile(ctx, template, type, isSelected),
        );
      },
    );
  }

  Widget _landscapeTile(BuildContext context, Map<String, dynamic> template,
      String type, bool isSelected) {
    final translatedName = context.t(
      'building_name_$type',
      fallback: template['name'] as String,
    );
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 3, vertical: 4),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: _tileDecoration(isSelected),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTilePreview(type, 48),
          SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(translatedName,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkText)),
              Text(context.t('free'),
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkMint)),
              Text(context.t('no_build_time'),
                  style: TextStyle(
                      fontSize: 9,
                      color: AppTheme.darkText.withValues(alpha: 0.5))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _portraitTile(BuildContext context, Map<String, dynamic> template,
      String type, bool isSelected) {
    final translatedName = context.t(
      'building_name_$type',
      fallback: template['name'] as String,
    );
    return Container(
      width: 140,
      margin: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      padding: EdgeInsets.all(8),
      decoration: _tileDecoration(isSelected),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTilePreview(type, 80),
          SizedBox(height: 4),
          Text(translatedName,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkText)),
          SizedBox(height: 2),
          Text(context.t('free'),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkMint)),
          Text(context.t('no_build_time'),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.darkText.withValues(alpha: 0.5))),
        ],
      ),
    );
  }

  BoxDecoration _tileDecoration(bool isSelected) {
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
}
