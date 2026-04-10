import 'package:flutter/material.dart';
import 'package:my_reading_town/infrastructure/ui/config/app_theme.dart';
import 'package:my_reading_town/domain/rules/village_rules.dart';
import 'package:my_reading_town/adapters/providers/village_provider.dart';
import 'package:my_reading_town/infrastructure/ui/widgets/common/template_list.dart';
import 'package:my_reading_town/infrastructure/ui/localization/context_ext.dart';

class BuildingSelector extends StatelessWidget {
  final VillageProvider village;
  final bool landscape;
  final TabController tabController;
  final String? selectedBuildingType;
  final int? movingBuildingId;
  final bool flipNextBuilding;
  final ValueChanged<String?> onSelectBuilding;
  final VoidCallback onToggleFlip;
  final String? scrollToType;

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
    this.scrollToType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: landscape ? 180 : 310,
      margin: EdgeInsets.symmetric(horizontal: 8),
      clipBehavior: Clip.hardEdge,
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
                  scrollToType: scrollToType,
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

  static const _tileColors = {
    'grass': Color(0xFF90C96B),
    'road': Color(0xFFE0D8C8),
    'sea': Color(0xFF7EC8E3),
    'sand': Color(0xFFE8D89A),
    'rock': Color(0xFFB0A898),
  };

  static const _tileWalkable = {
    'grass': false,
    'road': true,
    'sea': false,
    'sand': true,
    'rock': false,
  };

  static const _tileBuildable = {
    'grass': true,
    'road': false,
    'sea': false,
    'sand': true,
    'rock': false,
  };

  Widget _buildTilePreview(String type, double size) {
    final color = _tileColors[type] ?? Colors.grey.shade300;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }

  Widget _tileInfoRow(BuildContext context, String labelKey, bool valid, double fontSize) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          valid ? Icons.check_circle : Icons.cancel,
          size: fontSize + 3,
          color: valid ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
        ),
        SizedBox(width: 3),
        Text(
          context.t(labelKey),
          style: TextStyle(
            fontSize: fontSize,
            color: AppTheme.darkText.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _timerRow(double fontSize) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.timer_outlined,
            size: fontSize + 2,
            color: AppTheme.darkOrange),
        SizedBox(width: 2),
        Text(
          '0s',
          style: TextStyle(
              fontSize: fontSize,
              color: AppTheme.darkOrange),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final templates = VillageRules.tileTemplates;
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(left: 8, right: 24),
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
    final walkable = _tileWalkable[type] ?? false;
    final buildable = _tileBuildable[type] ?? false;
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(translatedName,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkText)),
                  if (type == 'grass') ...[
                    SizedBox(width: 4),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppTheme.mint.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        context.t('tile_default_label'),
                        style: TextStyle(
                            fontSize: 7,
                            color: AppTheme.darkMint,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ],
              ),
              Text(context.t('free'),
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkMint)),
              _timerRow(9),
              _tileInfoRow(context, 'tile_walking', walkable, 9),
              _tileInfoRow(context, 'tile_building', buildable, 9),
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
    final walkable = _tileWalkable[type] ?? false;
    final buildable = _tileBuildable[type] ?? false;
    return Container(
      width: 140,
      margin: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      padding: EdgeInsets.all(8),
      decoration: _tileDecoration(isSelected),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTilePreview(type, 64),
          SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(translatedName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkText)),
              if (type == 'grass') ...[
                SizedBox(width: 4),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppTheme.mint.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    context.t('tile_default_label'),
                    style: TextStyle(
                        fontSize: 7,
                        color: AppTheme.darkMint,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 2),
          Text(context.t('free'),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkMint)),
          _timerRow(9),
          SizedBox(height: 2),
          _tileInfoRow(context, 'tile_walking', walkable, 9),
          _tileInfoRow(context, 'tile_building', buildable, 9),
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
