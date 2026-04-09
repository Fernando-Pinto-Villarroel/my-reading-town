import 'package:flutter/material.dart';
import 'package:my_reading_town/infrastructure/ui/config/app_theme.dart';
import 'package:my_reading_town/domain/rules/village_rules.dart';
import 'package:my_reading_town/adapters/providers/village_provider.dart';
import 'package:my_reading_town/infrastructure/ui/widgets/common/resource_icon.dart';
import 'package:my_reading_town/infrastructure/ui/widgets/common/shared_utils.dart';
import 'package:my_reading_town/infrastructure/ui/localization/context_ext.dart';

class TemplateList extends StatefulWidget {
  final VillageProvider village;
  final bool landscape;
  final List<Map<String, dynamic>> templates;
  final bool isDecorationTab;
  final String? selectedType;
  final String? scrollToType;
  final ValueChanged<String?> onSelect;

  const TemplateList({
    super.key,
    required this.village,
    required this.landscape,
    required this.templates,
    required this.isDecorationTab,
    required this.selectedType,
    required this.onSelect,
    this.scrollToType,
  });

  @override
  State<TemplateList> createState() => _TemplateListState();
}

class _TemplateListState extends State<TemplateList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.scrollToType != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToType(widget.scrollToType!));
    }
  }

  @override
  void didUpdateWidget(TemplateList old) {
    super.didUpdateWidget(old);
    if (widget.scrollToType != null &&
        widget.scrollToType != old.scrollToType) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToType(widget.scrollToType!));
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToType(String type) {
    final index = widget.templates.indexWhere((t) => t['type'] == type);
    if (index < 0 || !_scrollController.hasClients) return;
    // Portrait: fixed card width 140 + horizontal margin 4*2 = 148px, left padding 8
    // Landscape: approximate card width 180px, left padding 8
    final itemWidth = widget.landscape ? 180.0 : 148.0;
    final offset = (8.0 + index * itemWidth)
        .clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

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
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(left: 8, right: 24),
      itemCount: widget.templates.length,
      itemBuilder: (ctx, index) {
        final template = widget.templates[index];
        final type = template['type'] as String;
        final isSelected = widget.selectedType == type;
        final isHighlighted = widget.scrollToType == type;
        final coinCost = template['coinCost'] as int;
        final gemCost = template['gemCost'] as int;
        final woodCost = template['woodCost'] as int;
        final metalCost = template['metalCost'] as int;
        final buildMinutes = template['constructionMinutes'] as int;
        final canAfford = widget.village.coins >= coinCost &&
            widget.village.gems >= gemCost &&
            widget.village.wood >= woodCost &&
            widget.village.metal >= metalCost;
        final canPlace =
            widget.isDecorationTab ? true : widget.village.canPlaceBuildingType(type);
        final currentCount = widget.village.buildingCountOfType(type);
        final maxCount = VillageRules.maxBuildingsOfTypeForPlayerLevel(
            type, widget.village.playerLevel);

        final minLevel = VillageRules.minLevelForBuilding(type);
        final isLevelLocked = minLevel > widget.village.playerLevel;
        final translatedName = isLevelLocked
            ? '??'
            : context.t(
                'building_name_$type',
                fallback: template['name'] as String,
              );
        return GestureDetector(
          onTap: (!isLevelLocked && canPlace)
              ? () => widget.onSelect(widget.selectedType == type ? null : type)
              : null,
          child: widget.landscape
              ? _landscapeCard(
                  context,
                  translatedName,
                  template,
                  type,
                  isSelected,
                  isHighlighted,
                  coinCost,
                  gemCost,
                  woodCost,
                  metalCost,
                  buildMinutes,
                  canAfford,
                  canPlace,
                  currentCount,
                  maxCount,
                  isLevelLocked,
                  minLevel)
              : _portraitCard(
                  context,
                  translatedName,
                  template,
                  type,
                  isSelected,
                  isHighlighted,
                  coinCost,
                  gemCost,
                  woodCost,
                  metalCost,
                  buildMinutes,
                  canAfford,
                  canPlace,
                  currentCount,
                  maxCount,
                  isLevelLocked,
                  minLevel),
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
      bool isHighlighted,
      int coinCost,
      int gemCost,
      int woodCost,
      int metalCost,
      int buildMinutes,
      bool canAfford,
      bool canPlace,
      int currentCount,
      int maxCount,
      bool isLevelLocked,
      int minLevel) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 3, vertical: 4),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: isLevelLocked
          ? _lockedCardDecoration()
          : _cardDecoration(isSelected, isHighlighted),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          isLevelLocked
              ? SizedBox(
                  width: 64,
                  height: 64,
                  child: Icon(Icons.lock, size: 40, color: Colors.grey.shade400),
                )
              : buildAssetPreview(type, 64, canAfford && canPlace),
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
                          color: isLevelLocked
                              ? Colors.grey.shade500
                              : AppTheme.darkText)),
                  if (isLevelLocked)
                    Text(
                      context.t('unlocks_at_level',
                          fallback: 'Unlocks at Level $minLevel').replaceAll('{level}', '$minLevel'),
                      style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600),
                    )
                  else ...[
                    _costRow(coinCost, gemCost, woodCost, metalCost, 9, 12),
                    _timeExpRow(
                        buildMinutes, template['exp'] as int? ?? 20, 9, 10),
                    if (!widget.isDecorationTab)
                      _capacityRow(type, 9, 10, context),
                    if (!widget.isDecorationTab)
                      _countRow(currentCount, maxCount, canPlace, 9, 10),
                  ],
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
      bool isHighlighted,
      int coinCost,
      int gemCost,
      int woodCost,
      int metalCost,
      int buildMinutes,
      bool canAfford,
      bool canPlace,
      int currentCount,
      int maxCount,
      bool isLevelLocked,
      int minLevel) {
    return Container(
      width: 140,
      margin: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      padding: EdgeInsets.all(6),
      decoration: isLevelLocked
          ? _lockedCardDecoration()
          : _cardDecoration(isSelected, isHighlighted),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          isLevelLocked
              ? SizedBox(
                  width: 80,
                  height: 80,
                  child: Icon(Icons.lock, size: 48, color: Colors.grey.shade400),
                )
              : buildAssetPreview(type, 80, canAfford && canPlace),
          SizedBox(height: 2),
          Text(translatedName,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isLevelLocked ? Colors.grey.shade500 : AppTheme.darkText),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          SizedBox(height: 1),
          if (isLevelLocked)
            Text(
              context.t('unlocks_at_level',
                  fallback: 'Unlocks at Level $minLevel').replaceAll('{level}', '$minLevel'),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w600),
            )
          else ...[
            FittedBox(
              fit: BoxFit.scaleDown,
              child: _costRow(coinCost, gemCost, woodCost, metalCost, 10, 14),
            ),
            _timeExpRow(buildMinutes, template['exp'] as int? ?? 20, 11, 13),
            if (!widget.isDecorationTab) _capacityRow(type, 10, 12, context),
            if (!widget.isDecorationTab)
              _countRow(currentCount, maxCount, canPlace, 10, 12),
          ],
        ],
      ),
    );
  }

  BoxDecoration _lockedCardDecoration() {
    return BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade300, width: 1),
    );
  }

  BoxDecoration _cardDecoration(bool isSelected, bool isHighlighted) {
    if (isSelected) {
      return BoxDecoration(
        color: AppTheme.mint.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.mint, width: 2),
      );
    }
    if (isHighlighted) {
      return BoxDecoration(
        color: AppTheme.pink.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.darkPink, width: 2),
      );
    }
    return BoxDecoration(
      color: AppTheme.softWhite,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade300, width: 1),
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
