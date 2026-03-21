import 'dart:async';
import 'dart:io' show File;
import 'package:flame/game.dart' hide Matrix4;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../config/game_constants.dart';
import '../data/database_helper.dart';
import '../game/village_game.dart';
import '../models/placed_building.dart';
import '../models/villager.dart';
import '../providers/book_provider.dart';
import '../providers/village_provider.dart';
import '../widgets/book_card.dart';
import '../widgets/skeleton.dart';
import '../widgets/book_filter_bar.dart';
import '../widgets/book_form_dialog.dart';
import '../widgets/book_search_dialog.dart';
import '../widgets/happiness_indicator.dart';
import '../widgets/resource_icon.dart';
import '../widgets/reward_popup.dart';
import '../widgets/tag_manager_dialog.dart';
import '../models/book.dart';
import '../providers/tag_provider.dart';
import '../data/villager_favorites.dart';

enum GameMode { normal, construction, road }

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late VillageGame _game;
  late VillageProvider _villageProvider;
  late BookProvider _bookProvider;
  GameMode _mode = GameMode.normal;
  String? _selectedBuildingType;
  int? _movingBuildingId;
  Timer? _constructionTimer;
  final Set<int> _notifiedCompletions = {};
  bool _menuOpen = false;
  bool _resourceHudExpanded = false;
  bool _flipNextBuilding = false;
  late final TransformationController _transformController;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ));
    _game = VillageGame(
      onTileTapped: _handleTileTap,
      onConstructionComplete: _onConstructionComplete,
      onVillagerTapped: _onVillagerTapped,
    );
    _transformController = TransformationController();
    _transformController.addListener(_onTransformChanged);
  }

  void _onTransformChanged() {
    final m = _transformController.value;
    final scale = m.getMaxScaleOnAxis();
    final translation = m.getTranslation();
    _game.applyCameraTransform(scale, translation.x, translation.y);
  }

  @override
  void dispose() {
    _constructionTimer?.cancel();
    _transformController.removeListener(_onTransformChanged);
    _transformController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _villageProvider = context.read<VillageProvider>();
    _bookProvider = context.read<BookProvider>();
    _constructionTimer ??= Timer.periodic(
      const Duration(seconds: 1),
      (_) => _checkConstructions(),
    );
    _syncGameState();
  }

  void _syncGameState() {
    final village = _villageProvider;
    _game.updateRoadTiles(village.roadTiles);
    _game.updateUnlockedChunks(village.unlockedChunks);
    _game.updatePlacedBuildings(village.placedBuildings);
    _game.updateVillagers(village.villagers, missingBuildingTypes: village.missingBuildingTypes, houseRoadTiles: village.houseAdjacentRoadTiles);
    _game.isConstructionMode = _mode == GameMode.construction;
    _game.isRoadMode = _mode == GameMode.road;
    _game.updateGridState();
  }

  void _checkConstructions() async {
    if (!mounted) return;
    final village = _villageProvider;
    final completed = await village.checkAndCompleteConstructions();
    for (var building in completed) {
      if (!_notifiedCompletions.contains(building.id)) {
        _notifiedCompletions.add(building.id!);
        if (mounted) _showConstructionCompleteDialog(building);
      }
    }
    if (completed.isNotEmpty && mounted) {
      _syncGameState();
    }
  }

  void _onConstructionComplete(PlacedBuilding building) {
    _checkConstructions();
  }

  void _handleTileTap(int tileX, int tileY) {
    final village = _villageProvider;

    if (_mode == GameMode.road) {
      if (!village.isTileUnlocked(tileX, tileY)) return;
      if (village.hasBuildingAt(tileX, tileY)) return;
      village.toggleRoad(tileX, tileY);
      _syncGameState();
      return;
    }

    if (_mode == GameMode.construction) {
      if (!village.isTileUnlocked(tileX, tileY)) {
        final chunkX = tileX ~/ GameConstants.chunkSize;
        final chunkY = tileY ~/ GameConstants.chunkSize;
        if (village.isChunkAdjacentToUnlocked(chunkX, chunkY)) {
          _showExpansionDialog(chunkX, chunkY);
        }
        return;
      }

      if (_movingBuildingId != null) {
        if (village.hasBuildingAt(tileX, tileY)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('This tile is already occupied', style: TextStyle(color: AppTheme.darkText)), backgroundColor: AppTheme.peach, behavior: SnackBarBehavior.floating),
          );
          return;
        }
        _moveBuilding(tileX, tileY);
        return;
      }

      if (_selectedBuildingType != null) {
        if (village.hasBuildingAt(tileX, tileY)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('This tile is already occupied', style: TextStyle(color: AppTheme.darkText)), backgroundColor: AppTheme.peach, behavior: SnackBarBehavior.floating),
          );
          return;
        }
        if (village.isRoadTile(tileX, tileY)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Remove the road first', style: TextStyle(color: AppTheme.darkText)), backgroundColor: AppTheme.peach, behavior: SnackBarBehavior.floating),
          );
          return;
        }
        _placeBuilding(tileX, tileY);
        return;
      }

      final building = village.getBuildingAt(tileX, tileY);
      if (building != null) {
        setState(() {
          _movingBuildingId = building.id;
          _selectedBuildingType = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tap a tile to move ${building.name}', style: TextStyle(color: AppTheme.darkText)), backgroundColor: AppTheme.mint, behavior: SnackBarBehavior.floating),
        );
        return;
      }
      return;
    }

    final building = village.getBuildingAt(tileX, tileY);
    if (building != null) {
      if (building.isConstructed) {
        _showBuildingInfoSheet(building);
      } else {
        _showConstructingBuildingSheet(building);
      }
    }
  }

  void _placeBuilding(int tileX, int tileY) async {
    final village = _villageProvider;
    final template = GameConstants.buildingTemplates.firstWhere(
      (t) => t['type'] == _selectedBuildingType,
    );

    if (!village.canPlaceBuildingType(_selectedBuildingType!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Building limit reached! Level up to unlock more.', style: TextStyle(color: AppTheme.darkText)),
          backgroundColor: AppTheme.peach,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final coinCost = template['coinCost'] as int;
    final gemCost = template['gemCost'] as int;
    final woodCost = template['woodCost'] as int;
    final metalCost = template['metalCost'] as int;

    if (village.coins < coinCost || village.gems < gemCost ||
        village.wood < woodCost || village.metal < metalCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Not enough resources! Read more to earn them.', style: TextStyle(color: AppTheme.darkText)),
          backgroundColor: AppTheme.pink,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await village.placeBuilding(
      type: _selectedBuildingType!,
      name: template['name'] as String,
      tileX: tileX,
      tileY: tileY,
      coinCost: coinCost,
      gemCost: gemCost,
      woodCost: woodCost,
      metalCost: metalCost,
      happinessBonus: template['happinessBonus'] as int,
      constructionMinutes: template['constructionMinutes'] as int,
      isFlipped: _flipNextBuilding,
    );

    setState(() {
      _mode = GameMode.normal;
      _selectedBuildingType = null;
      _flipNextBuilding = false;
    });
    _syncGameState();
  }

  void _moveBuilding(int tileX, int tileY) async {
    final village = _villageProvider;
    final messenger = ScaffoldMessenger.of(context);
    final success = await village.moveBuilding(_movingBuildingId!, tileX, tileY);
    if (!mounted) return;
    if (success) {
      messenger.clearSnackBars();
      setState(() => _movingBuildingId = null);
      _syncGameState();
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text('Cannot move here', style: TextStyle(color: AppTheme.darkText)), backgroundColor: AppTheme.peach, behavior: SnackBarBehavior.floating),
      );
    }
  }

  void _onVillagerTapped(Villager villager) {
    if (!mounted) return;
    _showVillagerInfoSheet(villager);
  }

  void _showVillagerInfoSheet(Villager villager) {
    final authorIdx = (villager.id ?? 0) % favoriteAuthors.length;
    final quoteIdx = (villager.id ?? 0) % favoriteQuotes.length;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      isScrollControlled: true,
      constraints: _sheetConstraints(context, portraitFrac: 0.68),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewPadding.bottom),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 16),
                Image.asset(
                  'assets/images/${villager.spriteFile}',
                  width: 80, height: 106,
                  filterQuality: FilterQuality.medium,
                ),
                SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    _showRenameVillagerDialog(villager);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        villager.name,
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.darkText),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.edit, size: 18, color: AppTheme.darkText.withValues(alpha: 0.5)),
                    ],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${villager.species.substring(0, 1).toUpperCase()}${villager.species.substring(1)} Villager',
                  style: TextStyle(fontSize: 14, color: AppTheme.lavender, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  villager.moodText,
                  style: TextStyle(fontSize: 13, color: AppTheme.darkText.withValues(alpha: 0.6)),
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.darkText.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        villager.happiness >= 60 ? Icons.sentiment_satisfied_alt
                            : villager.happiness >= 40 ? Icons.sentiment_neutral
                            : Icons.sentiment_dissatisfied,
                        size: 22,
                        color: villager.happiness >= 60 ? Color(0xFF2E7D32)
                            : villager.happiness >= 40 ? Color(0xFFB8860B)
                            : Color(0xFFC62828),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Happiness: ${villager.happiness}%',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: villager.happiness >= 60 ? Color(0xFF2E7D32)
                              : villager.happiness >= 40 ? Color(0xFFB8860B)
                              : Color(0xFFC62828),
                        ),
                      ),
                    ],
                  ),
                ),
                if (villager.happiness < 100) ...[
                  SizedBox(height: 8),
                  Builder(builder: (_) {
                    const needEmojis = {
                      'water_plant': '💧',
                      'power_plant': '⚡',
                      'hospital': '🏥',
                      'school': '🎒',
                      'park': '🌳',
                    };
                    final missing = _villageProvider.missingNeedsForVillager(villager);
                    if (missing.isEmpty) return SizedBox.shrink();
                    return Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      alignment: WrapAlignment.center,
                      children: missing.map((type) {
                        return Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200, width: 1),
                          ),
                          child: Text(
                            '${needEmojis[type] ?? '❓'} Needs ${_needLabel(type)}',
                            style: TextStyle(fontSize: 12, color: Colors.red.shade400, fontWeight: FontWeight.w600),
                          ),
                        );
                      }).toList(),
                    );
                  }),
                ],
                SizedBox(height: 16),
                _villagerInfoRow(Icons.auto_stories, 'Favorite Author', favoriteAuthors[authorIdx]),
                SizedBox(height: 10),
                _villagerInfoRow(Icons.format_quote, 'Favorite Quote', '"${favoriteQuotes[quoteIdx]}"'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _needLabel(String type) {
    switch (type) {
      case 'water_plant': return 'Water';
      case 'power_plant': return 'Power';
      case 'hospital': return 'Hospital';
      case 'school': return 'School';
      case 'park': return 'Park';
      default: return type;
    }
  }

  Widget _villagerInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.lavender),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: AppTheme.darkText.withValues(alpha: 0.5))),
              SizedBox(height: 2),
              Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.darkText)),
            ],
          ),
        ),
      ],
    );
  }

  void _showRenameVillagerDialog(Villager villager) {
    final controller = TextEditingController(text: villager.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Rename Villager'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/${villager.spriteFile}',
              width: 64, height: 85,
              filterQuality: FilterQuality.medium,
            ),
            SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'New Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              textCapitalization: TextCapitalization.words,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isEmpty || villager.id == null) return;
              _villageProvider.renameVillager(villager.id!, newName);
              Navigator.pop(ctx);
              _syncGameState();
            },
            child: Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showConstructionCompleteDialog(PlacedBuilding building) {
    final isUpgrade = building.level > 1;
    final expEarned = isUpgrade
        ? GameConstants.expPerBuildingUpgraded
        : GameConstants.expPerBuildingPlaced;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: EdgeInsets.fromLTRB(24, 20, 24, 20),
          decoration: BoxDecoration(
            color: AppTheme.cream,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isUpgrade ? 'Upgrade Complete!' : 'Construction Complete!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkText,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Icon(Icons.close, size: 20, color: AppTheme.darkText.withValues(alpha: 0.4)),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Image.asset(
                    'assets/images/${GameConstants.spriteForBuilding(building.type, building.level)}',
                    width: 72,
                    height: 72,
                    filterQuality: FilterQuality.medium,
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          building.name,
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.darkText),
                        ),
                        SizedBox(height: 2),
                        Text(
                          isUpgrade ? 'Upgraded to Lv${building.level}' : 'Level ${building.level}',
                          style: TextStyle(fontSize: 13, color: AppTheme.lavender, fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.coinGold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star, size: 16, color: const Color(0xFFB8860B)),
                              SizedBox(width: 4),
                              Text(
                                '+$expEarned EXP',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFFB8860B)),
                              ),
                            ],
                          ),
                        ),
                        if (building.type == 'house')
                          Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Text(
                              'A new villager has arrived!',
                              style: TextStyle(fontSize: 13, color: const Color(0xFF2E7D32), fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.mint,
                    foregroundColor: AppTheme.darkText,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Great!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showConstructingBuildingSheet(PlacedBuilding building) {
    final village = _villageProvider;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      isScrollControlled: true,
      constraints: _sheetConstraints(context, portraitFrac: 0.6),
      builder: (sheetCtx) => _ConstructionSheetContent(
        building: building,
        village: village,
        onSpeedUp: () async {
          Navigator.pop(sheetCtx);
          final success = await village.speedUpConstruction(building.id!);
          if (success) {
            _syncGameState();
            _notifiedCompletions.add(building.id!);
            if (mounted) _showConstructionCompleteDialog(building);
          }
        },
        onCancel: () async {
          Navigator.pop(sheetCtx);
          final success = await village.cancelConstruction(building.id!);
          if (success) _syncGameState();
        },
      ),
    );
  }

  void _showBuildingInfoSheet(PlacedBuilding building) {
    final village = _villageProvider;
    final atMaxLevel = building.level >= GameConstants.maxBuildingLevel;

    final template = GameConstants.buildingTemplates.firstWhere(
      (t) => t['type'] == building.type,
    );

    final coinCost = atMaxLevel ? 0 : GameConstants.upgradeCoinCost(template['coinCost'] as int, building.level);
    final woodCost = atMaxLevel ? 0 : GameConstants.upgradeWoodCost(template['woodCost'] as int, building.level);
    final metalCost = atMaxLevel ? 0 : GameConstants.upgradeMetalCost(template['metalCost'] as int, building.level);
    final upgradeMinutes = atMaxLevel ? 0 : GameConstants.upgradeConstructionMinutes(template['constructionMinutes'] as int, building.level);
    final canAfford = !atMaxLevel && village.coins >= coinCost && village.wood >= woodCost && village.metal >= metalCost;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      isScrollControlled: true,
      constraints: _sheetConstraints(context),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewPadding.bottom),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 16),
                Image.asset(
                  'assets/images/${GameConstants.spriteForBuilding(building.type, building.level)}',
                  width: 88, height: 88,
                  filterQuality: FilterQuality.medium,
                ),
                SizedBox(height: 8),
                Text(
                  building.name,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.darkText),
                ),
                Text(
                  'Level ${building.level}',
                  style: TextStyle(fontSize: 14, color: AppTheme.lavender, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  building.type == 'house'
                      ? 'Houses ${GameConstants.villagersPerHouse(building.level)} villager(s)'
                      : 'Covers ${GameConstants.buildingCapacity(building.type, building.level)} villager needs',
                  style: TextStyle(fontSize: 13, color: AppTheme.darkText.withValues(alpha: 0.6)),
                ),
                if (building.type == 'house' && building.id != null) ...[
                  SizedBox(height: 12),
                  Builder(builder: (_) {
                    final residents = village.villagersInHouse(building.id!);
                    if (residents.isEmpty) return SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text('Residents:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.darkText)),
                        SizedBox(height: 4),
                        ...residents.map((v) => Padding(
                          padding: EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset('assets/images/${v.spriteFile}', width: 20, height: 26, filterQuality: FilterQuality.medium),
                              SizedBox(width: 6),
                              Text(v.name, style: TextStyle(fontSize: 13, color: AppTheme.darkText)),
                              SizedBox(width: 4),
                              Text('(${v.moodText})', style: TextStyle(fontSize: 11, color: AppTheme.darkText.withValues(alpha: 0.5))),
                            ],
                          ),
                        )),
                      ],
                    );
                  }),
                ],
                SizedBox(height: 16),
                if (atMaxLevel)
                  Text(
                    'Max Level Reached!',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.coinGold),
                  )
                else ...[
                  Text('Upgrade to Lv${building.level + 1}:',
                      style: TextStyle(fontSize: 14, color: AppTheme.darkText)),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    children: [
                      _costChip(ResourceIcon.coin(size: 20), coinCost),
                      if (woodCost > 0) _costChip(ResourceIcon.wood(size: 20), woodCost),
                      if (metalCost > 0) _costChip(ResourceIcon.metal(size: 20), metalCost),
                    ],
                  ),
                  SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timer_outlined, size: 16, color: AppTheme.darkText.withValues(alpha: 0.5)),
                      SizedBox(width: 4),
                      Text(
                        _formatMinutes(upgradeMinutes),
                        style: TextStyle(fontSize: 13, color: AppTheme.darkText.withValues(alpha: 0.6)),
                      ),
                    ],
                  ),
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
                              final success = await village.upgradeBuilding(building.id!);
                              if (success) _syncGameState();
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canAfford ? AppTheme.mint : Colors.grey.shade300,
                        foregroundColor: AppTheme.darkText,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        canAfford ? 'Upgrade ${building.name}!' : 'Not enough resources',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

  String _formatMinutes(int minutes) {
    if (minutes >= 60) {
      final h = minutes ~/ 60;
      final m = minutes % 60;
      return m > 0 ? '${h}h ${m}m' : '${h}h';
    }
    return '${minutes}m';
  }

  Widget _costChip(Widget icon, int amount) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        SizedBox(width: 4),
        Text('$amount', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _showExpansionDialog(int chunkX, int chunkY) {
    final village = _villageProvider;
    final gemCost = GameConstants.expansionGemCost(village.expansionCount);
    final coinCost = GameConstants.expansionCoinCost(village.expansionCount);
    final canAffordGems = village.gems >= gemCost;
    final canAffordCoins = village.coins >= coinCost;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Expand Territory'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.zoom_out_map, size: 48, color: AppTheme.lavender),
            SizedBox(height: 12),
            Text('Unlock this 5x5 area:'),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: canAffordCoins
                        ? () async {
                            Navigator.pop(ctx);
                            final success = await village.expandTerritoryWithCoins(chunkX, chunkY);
                            if (success) _syncGameState();
                          }
                        : null,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Column(
                      children: [
                        ResourceIcon.coin(size: 28),
                        SizedBox(height: 4),
                        Text('$coinCost', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('OR', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.darkText)),
                ),
                Expanded(
                  child: OutlinedButton(
                    onPressed: canAffordGems
                        ? () async {
                            Navigator.pop(ctx);
                            final success = await village.expandTerritoryWithGems(chunkX, chunkY);
                            if (success) _syncGameState();
                          }
                        : null,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Column(
                      children: [
                        ResourceIcon.gem(size: 28),
                        SizedBox(height: 4),
                        Text('$gemCost', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showReadingModal() {
    final landscape = _isLandscape(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      constraints: landscape
          ? BoxConstraints(maxWidth: 480, maxHeight: MediaQuery.of(context).size.height * 0.95)
          : null,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: landscape ? 0.95 : 0.85,
        minChildSize: landscape ? 0.5 : 0.4,
        maxChildSize: 0.95,
        builder: (ctx, scrollController) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewPadding.bottom),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.cream,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  SizedBox(height: 8),
                  Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 4, 4),
                    child: Row(
                      children: [
                        Icon(Icons.menu_book, size: 24, color: AppTheme.darkText),
                        SizedBox(width: 8),
                        Text(
                          'Reading Tracker',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.darkText),
                        ),
                        Spacer(),
                        IconButton(
                          icon: Icon(Icons.label, size: 22, color: AppTheme.lavender),
                          tooltip: 'Manage Tags',
                          onPressed: () {
                            showModalBottomSheet(
                              context: ctx,
                              backgroundColor: Colors.transparent,
                              isScrollControlled: true,
                              builder: (_) => TagManagerDialog(),
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.add_circle, size: 30, color: AppTheme.pink),
                          onPressed: () => _showAddBookDialog(),
                        ),
                      ],
                    ),
                  ),
                  // Filter bar
                  Consumer2<BookProvider, TagProvider>(
                    builder: (ctx, bookProvider, tagProvider, _) {
                      return BookFilterBar(
                        filter: bookProvider.filter,
                        availableTags: tagProvider.tags,
                        onFilterChanged: (f) => bookProvider.setFilter(f),
                      );
                    },
                  ),
                  SizedBox(height: 4),
                  Expanded(
                    child: Consumer<BookProvider>(
                      builder: (ctx, bookProvider, _) {
                        final books = bookProvider.filteredBooks;
                        if (bookProvider.books.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.auto_stories, size: 60, color: AppTheme.lavender),
                                SizedBox(height: 16),
                                Text(
                                  'No books yet!\nTap + to add your first book.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 16, color: AppTheme.darkText.withValues(alpha: 0.6)),
                                ),
                              ],
                            ),
                          );
                        }
                        if (books.isEmpty) {
                          return Center(
                            child: Text('No books match your filters.',
                                style: TextStyle(fontSize: 14, color: AppTheme.darkText.withValues(alpha: 0.5))),
                          );
                        }
                        return ListView.builder(
                          controller: scrollController,
                          itemCount: books.length + 1, // +1 for bottom padding
                          itemBuilder: (ctx, i) {
                            if (i == books.length) return SizedBox(height: 24);
                            final book = books[i];
                            return BookCard(
                              book: book,
                              onLogPages: book.isCompleted ? () {} : () => _showLogPagesDialog(book.id!),
                              onTap: () => _showBookDetailSheet(book),
                              onEdit: () => _editBook(book),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddBookDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.add_circle, size: 22, color: AppTheme.pink),
            SizedBox(width: 8),
            Text('Add a Book', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('How would you like to add your book?',
                style: TextStyle(fontSize: 14, color: AppTheme.darkText.withValues(alpha: 0.7))),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  showDialog(context: context, builder: (_) => BookSearchDialog());
                },
                icon: Icon(Icons.search, size: 18),
                label: Text('Search Online'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.lavender,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  showDialog(context: context, builder: (_) => BookFormDialog());
                },
                icon: Icon(Icons.edit, size: 18),
                label: Text('Add Manually'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: AppTheme.lavender),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editBook(Book book) {
    showDialog(
      context: context,
      builder: (_) => BookFormDialog(existingBook: book),
    );
  }

  void _showBookDetailSheet(Book book) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      isScrollControlled: true,
      constraints: _sheetConstraints(context, portraitFrac: 0.5),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewPadding.bottom),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (book.coverImagePath != null && book.coverImagePath!.isNotEmpty)
                      SkeletonImage(
                        image: FileImage(File(book.coverImagePath!)),
                        width: 60, height: 86, borderRadius: 10,
                      )
                    else
                      Container(
                        width: 60, height: 86,
                        decoration: BoxDecoration(
                          color: AppTheme.lavender.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.menu_book, size: 28, color: AppTheme.lavender),
                      ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(book.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkText)),
                          if (book.author != null && book.author!.isNotEmpty) ...[
                            SizedBox(height: 2),
                            Text(book.author!, style: TextStyle(fontSize: 13, color: AppTheme.darkText.withValues(alpha: 0.6))),
                          ],
                          SizedBox(height: 4),
                          Text('${book.pagesRead} / ${book.totalPages} pages',
                              style: TextStyle(fontSize: 13, color: AppTheme.lavender, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
                if (book.tags.isNotEmpty) ...[
                  SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: book.tags.map((tag) => Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Color(tag.colorValue).withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(tag.title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.darkText)),
                    )).toList(),
                  ),
                ],
                SizedBox(height: 16),
                Row(
                  children: [
                    if (!book.isCompleted)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(sheetCtx);
                            _showLogPagesDialog(book.id!);
                          },
                          icon: Icon(Icons.menu_book, size: 16),
                          label: Text('Log Pages'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.pink),
                        ),
                      ),
                    if (!book.isCompleted) SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetCtx);
                          _editBook(book);
                        },
                        icon: Icon(Icons.edit, size: 16, color: AppTheme.lavender),
                        label: Text('Edit', style: TextStyle(color: AppTheme.lavender)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppTheme.lavender.withValues(alpha: 0.5)),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetCtx);
                          _confirmDeleteBook(book);
                        },
                        icon: Icon(Icons.delete_outline, size: 16, color: Colors.red.shade300),
                        label: Text('Delete', style: TextStyle(color: Colors.red.shade300)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.red.shade200),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDeleteBook(Book book) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Book?'),
        content: Text('Remove "${book.title}" and all its reading sessions?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade300),
            onPressed: () {
              _bookProvider.deleteBook(book.id!);
              Navigator.pop(ctx);
            },
            child: Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showLogPagesDialog(int bookId) {
    final pagesController = TextEditingController();
    final book = _bookProvider.books.firstWhere((b) => b.id == bookId);
    final remainingPages = book.totalPages - book.pagesRead;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        String? pagesError;
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Log Pages Read'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('How many pages did you read?',
                    style: TextStyle(color: AppTheme.darkText.withValues(alpha: 0.7))),
                SizedBox(height: 4),
                Text('$remainingPages pages remaining',
                    style: TextStyle(fontSize: 12, color: AppTheme.darkText.withValues(alpha: 0.5))),
                SizedBox(height: 12),
                TextField(
                  controller: pagesController,
                  decoration: InputDecoration(
                    labelText: 'Pages Read (max $remainingPages)',
                    hintText: 'e.g. 15',
                    errorText: pagesError,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.number,
                  autofocus: true,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final pages = int.tryParse(pagesController.text.trim());
                  if (pages == null || pages <= 0) {
                    setDialogState(() => pagesError = 'Enter a valid number');
                    return;
                  }
                  if (pages > remainingPages) {
                    setDialogState(() => pagesError = 'Cannot exceed $remainingPages remaining pages');
                    return;
                  }

              Navigator.pop(dialogCtx);

              final rewards = await _bookProvider.logPages(bookId, pages);
              final expEarned = rewards['exp'] as int;

              if (mounted) {
                await _villageProvider.refreshResources();
                if (expEarned > 0) {
                  await _villageProvider.addExp(expEarned);
                }
              }

              if (mounted) {
                _showRewardPopup(
                  rewards['coins'] as int,
                  rewards['gems'] as int,
                  rewards['wood'] as int,
                  rewards['metal'] as int,
                  rewards['bookCompleted'] as bool,
                );
              }
            },
            child: Text('Log!'),
          ),
        ],
      ),
        );
      },
    );
  }

  void _showRewardPopup(int coins, int gems, int wood, int metal, bool bookCompleted) {
    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => RewardPopup(
        coinsEarned: coins,
        gemsEarned: gems,
        woodEarned: wood,
        metalEarned: metal,
        bookCompleted: bookCompleted,
        onDismiss: () => overlayEntry.remove(),
      ),
    );
    Overlay.of(context).insert(overlayEntry);
  }

  void _showSettingsModal() {
    final usernameController = TextEditingController(text: _villageProvider.username);
    final townNameController = TextEditingController(text: _villageProvider.townName);

    showDialog(
      context: context,
      builder: (ctx) {
        final village = _villageProvider;
        final progress = GameConstants.expProgressToNextLevel(village.exp);
        final expToNext = GameConstants.expToNextLevel(village.exp);
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cream,
              borderRadius: BorderRadius.circular(24),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(Icons.settings, size: 24, color: AppTheme.lavender),
                      SizedBox(width: 8),
                      Text('Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.darkText)),
                      Spacer(),
                      IconButton(icon: Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.lavender.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text('Player Level ${village.playerLevel}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkText)),
                        SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.darkText.withValues(alpha: 0.3), width: 1),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 10,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation(AppTheme.lavender),
                            ),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text('${village.exp} EXP ($expToNext to next level)', style: TextStyle(fontSize: 12, color: AppTheme.darkText.withValues(alpha: 0.6))),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: townNameController,
                    decoration: InputDecoration(
                      labelText: 'Town Name',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () {
                        final username = usernameController.text.trim();
                        final townName = townNameController.text.trim();
                        if (username.isNotEmpty) _villageProvider.updateUsername(username);
                        if (townName.isNotEmpty) _villageProvider.updateTownName(townName);
                        Navigator.pop(ctx);
                      },
                      child: Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showStatsModal() {
    showDialog(
      context: context,
      builder: (ctx) {
        final village = _villageProvider;
        final bookProvider = _bookProvider;
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            padding: EdgeInsets.all(20),
            constraints: BoxConstraints(maxHeight: 600),
            decoration: BoxDecoration(
              color: AppTheme.cream,
              borderRadius: BorderRadius.circular(24),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bar_chart, size: 24, color: AppTheme.lavender),
                      SizedBox(width: 8),
                      Text('Village Stats',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.darkText)),
                      Spacer(),
                      IconButton(icon: Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  SizedBox(height: 8),
                  _StatRow(icon: Icon(Icons.stars, size: 28, color: AppTheme.coinGold), label: 'Village Level', value: '${village.villageLevel}'),
                  _StatRow(icon: ResourceIcon.coin(size: 28), label: 'Coins', value: '${village.coins}'),
                  _StatRow(icon: ResourceIcon.gem(size: 28), label: 'Gems', value: '${village.gems}'),
                  _StatRow(icon: ResourceIcon.wood(size: 28), label: 'Wood', value: '${village.wood}'),
                  _StatRow(icon: ResourceIcon.metal(size: 28), label: 'Metal', value: '${village.metal}'),
                  Divider(),
                  FutureBuilder<Map<String, int>>(
                    future: _loadStats(),
                    builder: (ctx, snapshot) {
                      final stats = snapshot.data ?? {'totalPages': 0, 'completedBooks': 0, 'totalSessions': 0};
                      return Column(
                        children: [
                          _StatRow(icon: Icon(Icons.auto_stories, size: 28, color: AppTheme.lavender), label: 'Pages Read', value: '${stats['totalPages']}'),
                          _StatRow(icon: Icon(Icons.menu_book, size: 28, color: AppTheme.pink), label: 'Books', value: '${bookProvider.books.length}'),
                          _StatRow(icon: Icon(Icons.star, size: 28, color: AppTheme.coinGold), label: 'Completed', value: '${stats['completedBooks']}'),
                        ],
                      );
                    },
                  ),
                  Divider(),
                  _StatRow(icon: Icon(Icons.house, size: 28, color: AppTheme.mint), label: 'Buildings', value: '${village.placedBuildings.where((b) => b.isConstructed).length}'),
                  _StatRow(icon: Icon(Icons.favorite, size: 28, color: AppTheme.pink), label: 'Happiness', value: '${village.villageHappiness}%'),
                  _StatRow(icon: Icon(Icons.pets, size: 28, color: AppTheme.peach), label: 'Villagers', value: '${village.villagers.length}'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, int>> _loadStats() async {
    final db = DatabaseHelper();
    return {
      'totalPages': await db.getTotalPagesRead(),
      'completedBooks': await db.getCompletedBooksCount(),
      'totalSessions': await db.getTotalSessionsCount(),
    };
  }

  bool _isLandscape(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.landscape;

  BoxConstraints _sheetConstraints(BuildContext context, {double portraitFrac = 0.75}) {
    final size = MediaQuery.of(context).size;
    final landscape = _isLandscape(context);
    return BoxConstraints(
      maxHeight: landscape ? size.height * 0.92 : size.height * portraitFrac,
      maxWidth: landscape ? 480 : double.infinity,
    );
  }

  @override
  Widget build(BuildContext context) {
    final village = context.watch<VillageProvider>();
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;
    final bottomPadding = mediaQuery.padding.bottom;
    final leftPadding = mediaQuery.padding.left;
    final rightPadding = mediaQuery.padding.right;
    final landscape = _isLandscape(context);
    final hudEdge = landscape ? 8.0 : 14.0;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: GameWidget(
              game: _game,
              loadingBuilder: (context) => Container(
                color: const Color(0xFF709070),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.house, size: 64, color: AppTheme.pink),
                      SizedBox(height: 16),
                      Text('Loading village...', style: TextStyle(fontSize: 16, color: Colors.white)),
                      SizedBox(height: 16),
                      CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppTheme.pink)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: _TapThroughInteractiveViewer(
              transformationController: _transformController,
              minScale: GameConstants.minZoom / GameConstants.defaultZoom,
              maxScale: GameConstants.maxZoom / GameConstants.defaultZoom,
              game: _game,
            ),
          ),

          Positioned(
            top: topPadding + (landscape ? 6 : 10),
            left: leftPadding + hudEdge,
            child: _buildResourceHud(village, landscape),
          ),

          Positioned(
            top: topPadding + (landscape ? 6 : 10),
            right: rightPadding + hudEdge,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                HappinessIndicator(happiness: village.villageHappiness),
                SizedBox(height: landscape ? 6 : 10),
                _buildZoomControls(),
                SizedBox(height: landscape ? 6 : 10),
                _buildSideMenu(),
              ],
            ),
          ),

          if (_mode == GameMode.construction)
            Positioned(
              bottom: bottomPadding + 8,
              left: leftPadding,
              right: rightPadding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_movingBuildingId != null)
                    Container(
                      margin: EdgeInsets.only(bottom: 8),
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: landscape ? 4 : 8),
                      decoration: BoxDecoration(
                        color: AppTheme.mint.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.open_with, size: 20, color: AppTheme.darkText),
                          SizedBox(width: 8),
                          Text('Tap a tile to move building', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.darkText)),
                          SizedBox(width: 8),
                          GestureDetector(
                            onTap: () async {
                              final village = _villageProvider;
                              await village.flipBuilding(_movingBuildingId!);
                              _syncGameState();
                            },
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppTheme.darkText.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.flip, size: 20, color: AppTheme.darkText),
                            ),
                          ),
                          SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => setState(() => _movingBuildingId = null),
                            child: Icon(Icons.close, size: 20, color: AppTheme.darkText),
                          ),
                        ],
                      ),
                    ),
                  if (landscape && _selectedBuildingType != null && _movingBuildingId == null)
                    Container(
                      margin: EdgeInsets.only(bottom: 6),
                      child: GestureDetector(
                        onTap: () => setState(() => _flipNextBuilding = !_flipNextBuilding),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: _flipNextBuilding ? AppTheme.mint : AppTheme.cream.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.flip, size: 18, color: _flipNextBuilding ? Colors.white : AppTheme.darkText),
                              SizedBox(width: 4),
                              Text('Flip', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _flipNextBuilding ? Colors.white : AppTheme.darkText)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  _buildBuildingSelector(village, landscape),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResourceHud(VillageProvider village, bool landscape) {
    final iconSize = landscape ? 28.0 : 32.0;
    final fontSize = landscape ? 17.0 : 19.0;
    final spacing = landscape ? 4.0 : 5.0;
    final padding = landscape
        ? EdgeInsets.symmetric(horizontal: 10, vertical: 8)
        : EdgeInsets.symmetric(horizontal: 12, vertical: 10);

    return GestureDetector(
      onTap: () => setState(() => _resourceHudExpanded = !_resourceHudExpanded),
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
                  _resourceHudExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: landscape ? 20 : 22,
                  color: Colors.white70,
                ),
              ],
            ),
            if (_resourceHudExpanded) ...[
              SizedBox(height: spacing),
              _hudRow(ResourceIcon.coin(size: iconSize), '${village.coins}', fontSize),
              SizedBox(height: spacing),
              _hudRow(ResourceIcon.gem(size: iconSize), '${village.gems}', fontSize),
              SizedBox(height: spacing),
              _hudRow(ResourceIcon.wood(size: iconSize), '${village.wood}', fontSize),
              SizedBox(height: spacing),
              _hudRow(ResourceIcon.metal(size: iconSize), '${village.metal}', fontSize),
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

  void _applyZoomFactor(double factor) {
    final currentZoom = _game.currentZoom;
    final newZoom = (currentZoom * factor).clamp(
      GameConstants.minZoom,
      GameConstants.maxZoom,
    );

    // Set Flame camera zoom directly.
    _game.setZoom(newZoom);

    // Reconstruct InteractiveViewer transform from actual camera state
    // so pinch gestures stay in sync.
    _syncTransformToCamera();
    setState(() {});
  }

  /// Rebuilds the InteractiveViewer transform matrix from the current Flame
  /// camera zoom & position, keeping both systems in sync.
  void _syncTransformToCamera() {
    final zoom = _game.currentZoom;
    final scale = zoom / GameConstants.defaultZoom;
    final camPos = _game.camera.viewfinder.position;
    final viewSize = _game.size;
    final centerWorld =
        GameConstants.defaultAreaCenterTile * GameConstants.tilePixelSize +
            GameConstants.tilePixelSize / 2;

    // Invert applyCameraTransform:
    //   childCenterX = viewSize.x/2 + (worldX - centerWorld) * defaultZoom
    //   tx = viewSize.x/2 - scale * childCenterX
    final childCenterX =
        viewSize.x / 2 + (camPos.x - centerWorld) * GameConstants.defaultZoom;
    final childCenterY =
        viewSize.y / 2 + (camPos.y - centerWorld) * GameConstants.defaultZoom;

    final tx = viewSize.x / 2 - scale * childCenterX;
    final ty = viewSize.y / 2 - scale * childCenterY;

    final m = Matrix4.identity();
    m.storage[0] = scale;
    m.storage[5] = scale;
    m.storage[12] = tx;
    m.storage[13] = ty;

    _transformController.removeListener(_onTransformChanged);
    _transformController.value = m;
    _transformController.addListener(_onTransformChanged);
  }

  Widget _buildZoomControls() {
    return SizedBox.shrink();
    // return Container(
    //   decoration: BoxDecoration(
    //     color: const Color(0xAA000000),
    //     borderRadius: BorderRadius.circular(14),
    //   ),
    //   child: Row(
    //     mainAxisSize: MainAxisSize.min,
    //     children: [
    //       _ZoomButton(
    //         icon: Icons.remove,
    //         onTap: () => _applyZoomFactor(0.8),
    //       ),
    //       GestureDetector(
    //         onTap: () {
    //           _game.setZoom(GameConstants.defaultZoom);
    //           _game.camera.viewfinder.position = Vector2.all(
    //             GameConstants.defaultAreaCenterTile * GameConstants.tilePixelSize +
    //                 GameConstants.tilePixelSize / 2,
    //           );
    //           _syncTransformToCamera();
    //           setState(() {});
    //         },
    //         child: Padding(
    //           padding: EdgeInsets.symmetric(horizontal: 8),
    //           child: Text('Reset', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
    //         ),
    //       ),
    //       _ZoomButton(
    //         icon: Icons.add,
    //         onTap: () => _applyZoomFactor(1.25),
    //       ),
    //     ],
    //   ),
    // );
  }

  Widget _buildSideMenu() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SideMenuButton(
              icon: Icons.menu_book,
              isActive: false,
              onTap: () => _showReadingModal(),
            ),
            SizedBox(width: 6),
            _DropdownToggleButton(
              isOpen: _menuOpen,
              onTap: () {
                setState(() {
                  _menuOpen = !_menuOpen;
                  if (!_menuOpen) {
                    _mode = GameMode.normal;
                    _selectedBuildingType = null;
                    _flipNextBuilding = false;
                    _syncGameState();
                  }
                });
              },
            ),
          ],
        ),
        if (_menuOpen) ...[
          SizedBox(height: 6),
          _SideMenuButton(
            icon: Icons.house,
            isActive: _mode == GameMode.construction,
            onTap: () {
              setState(() {
                if (_mode == GameMode.construction) {
                  _mode = GameMode.normal;
                  _selectedBuildingType = null;
                  _flipNextBuilding = false;
                } else {
                  _mode = GameMode.construction;
                }
              });
              _syncGameState();
            },
          ),
          SizedBox(height: 6),
          _SideMenuButton(
            icon: Icons.add_road,
            isActive: _mode == GameMode.road,
            onTap: () {
              setState(() {
                _mode = _mode == GameMode.road ? GameMode.normal : GameMode.road;
                _selectedBuildingType = null;
              });
              _syncGameState();
            },
          ),
          SizedBox(height: 6),
          _SideMenuButton(
            icon: Icons.bar_chart,
            isActive: false,
            onTap: () => _showStatsModal(),
          ),
          SizedBox(height: 6),
          _SideMenuButton(
            icon: Icons.settings,
            isActive: false,
            onTap: () => _showSettingsModal(),
          ),
        ],
      ],
    );
  }

  Widget _buildBuildingSelector(VillageProvider village, bool landscape) {
    return Container(
      height: landscape ? 88 : 195,
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
          if (!landscape)
            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Text('Select Building:',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.darkText)),
                  Spacer(),
                  if (_selectedBuildingType != null) ...[
                    GestureDetector(
                      onTap: () => setState(() => _flipNextBuilding = !_flipNextBuilding),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _flipNextBuilding ? AppTheme.mint : AppTheme.darkText.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.flip, size: 16, color: _flipNextBuilding ? Colors.white : AppTheme.darkText),
                            SizedBox(width: 4),
                            Text('Flip', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _flipNextBuilding ? Colors.white : AppTheme.darkText)),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text('Tap a tile to place',
                        style: TextStyle(fontSize: 12, color: AppTheme.darkText.withValues(alpha: 0.6))),
                  ] else if (_movingBuildingId == null)
                    Text('Tap building to move',
                        style: TextStyle(fontSize: 12, color: AppTheme.darkText.withValues(alpha: 0.6))),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 8),
              itemCount: GameConstants.buildingTemplates.length,
              itemBuilder: (ctx, index) {
                final template = GameConstants.buildingTemplates[index];
                final type = template['type'] as String;
                final isSelected = _selectedBuildingType == type;
                final coinCost = template['coinCost'] as int;
                final woodCost = template['woodCost'] as int;
                final metalCost = template['metalCost'] as int;
                final buildMinutes = template['constructionMinutes'] as int;
                final canAfford = village.coins >= coinCost &&
                    village.wood >= woodCost && village.metal >= metalCost;
                final canPlace = village.canPlaceBuildingType(type);

                if (landscape) {
                  return GestureDetector(
                    onTap: canPlace ? () => setState(() { _selectedBuildingType = type; _movingBuildingId = null; }) : null,
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.mint.withValues(alpha: 0.3) : AppTheme.softWhite,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? AppTheme.mint : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/images/$type.png',
                            width: 32, height: 32,
                            filterQuality: FilterQuality.medium,
                            color: (canAfford && canPlace) ? null : Colors.grey,
                            colorBlendMode: (canAfford && canPlace) ? null : BlendMode.saturation,
                          ),
                          SizedBox(width: 6),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                template['name'] as String,
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.darkText),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ResourceIcon.coin(size: 10),
                                  Text(' $coinCost', style: TextStyle(fontSize: 9)),
                                  if (woodCost > 0) ...[
                                    SizedBox(width: 2),
                                    ResourceIcon.wood(size: 10),
                                    Text(' $woodCost', style: TextStyle(fontSize: 9)),
                                  ],
                                  if (metalCost > 0) ...[
                                    SizedBox(width: 2),
                                    ResourceIcon.metal(size: 10),
                                    Text(' $metalCost', style: TextStyle(fontSize: 9)),
                                  ],
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.timer_outlined, size: 10, color: AppTheme.peach),
                                  SizedBox(width: 2),
                                  Text(_formatMinutes(buildMinutes), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppTheme.darkText.withValues(alpha: 0.7))),
                                  SizedBox(width: 6),
                                  Text(
                                    '${village.buildingCountOfType(type)}/${GameConstants.maxBuildingsOfTypeForPlayerLevel(type, village.playerLevel)}',
                                    style: TextStyle(fontSize: 9, color: canPlace ? AppTheme.darkText.withValues(alpha: 0.5) : Colors.red.shade300),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return GestureDetector(
                  onTap: canPlace ? () => setState(() { _selectedBuildingType = type; _movingBuildingId = null; }) : null,
                  child: Container(
                    width: 110,
                    margin: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.mint.withValues(alpha: 0.3) : AppTheme.softWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppTheme.mint : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/$type.png',
                          width: 44, height: 44,
                          filterQuality: FilterQuality.medium,
                          color: (canAfford && canPlace) ? null : Colors.grey,
                          colorBlendMode: (canAfford && canPlace) ? null : BlendMode.saturation,
                        ),
                        SizedBox(height: 2),
                        Text(
                          template['name'] as String,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.darkText),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 1),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ResourceIcon.coin(size: 12),
                            Text(' $coinCost', style: TextStyle(fontSize: 10)),
                            if (woodCost > 0) ...[
                              SizedBox(width: 3),
                              ResourceIcon.wood(size: 12),
                              Text(' $woodCost', style: TextStyle(fontSize: 10)),
                            ],
                            if (metalCost > 0) ...[
                              SizedBox(width: 3),
                              ResourceIcon.metal(size: 12),
                              Text(' $metalCost', style: TextStyle(fontSize: 10)),
                            ],
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.timer_outlined, size: 13, color: AppTheme.peach),
                            SizedBox(width: 3),
                            Text(_formatMinutes(buildMinutes), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.darkText.withValues(alpha: 0.7))),
                          ],
                        ),
                        Text(
                          '${village.buildingCountOfType(type)}/${GameConstants.maxBuildingsOfTypeForPlayerLevel(type, village.playerLevel)}',
                          style: TextStyle(fontSize: 9, color: canPlace ? AppTheme.darkText.withValues(alpha: 0.5) : Colors.red.shade300),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SideMenuButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _SideMenuButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isActive ? AppTheme.mint.withValues(alpha: 0.9) : const Color(0xAA000000),
          borderRadius: BorderRadius.circular(14),
          border: isActive ? Border.all(color: Colors.white, width: 2) : null,
        ),
        child: Icon(icon, size: 26, color: isActive ? AppTheme.darkText : Colors.white),
      ),
    );
  }
}

class _DropdownToggleButton extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onTap;

  const _DropdownToggleButton({required this.isOpen, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(isOpen ? Icons.close : Icons.apps, size: 26, color: Colors.white),
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ZoomButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Icon(icon, size: 26, color: Colors.white),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final Widget icon;
  final String label;
  final String value;

  const _StatRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          icon,
          SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 15, color: AppTheme.darkText)),
          Spacer(),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkText)),
        ],
      ),
    );
  }
}

class _ConstructionSheetContent extends StatefulWidget {
  final PlacedBuilding building;
  final VillageProvider village;
  final VoidCallback onSpeedUp;
  final VoidCallback onCancel;

  const _ConstructionSheetContent({
    required this.building,
    required this.village,
    required this.onSpeedUp,
    required this.onCancel,
  });

  @override
  State<_ConstructionSheetContent> createState() => _ConstructionSheetContentState();
}

class _ConstructionSheetContentState extends State<_ConstructionSheetContent> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.building.remainingConstructionTime;
    final gemCost = GameConstants.gemCostToSpeedUp(remaining);
    final hours = remaining.inHours;
    final mins = remaining.inMinutes % 60;
    final secs = remaining.inSeconds % 60;
    final timeText = hours > 0
        ? '${hours}h ${mins}m ${secs}s remaining'
        : '${mins}m ${secs}s remaining';

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewPadding.bottom),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 16),
            Image.asset(
              'assets/images/building_construction.png',
              width: 88, height: 88,
              filterQuality: FilterQuality.medium,
            ),
            SizedBox(height: 8),
            Text(
              '${widget.building.name} (Lv${widget.building.level})',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.darkText),
            ),
            SizedBox(height: 4),
            Text(
              'Under construction...',
              style: TextStyle(fontSize: 14, color: AppTheme.darkOrange, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(timeText, style: TextStyle(fontSize: 16, color: AppTheme.darkText, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            if (gemCost > 0)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: widget.village.gems >= gemCost ? widget.onSpeedUp : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.village.gems >= gemCost ? AppTheme.gemPurple : Colors.grey.shade300,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.flash_on, size: 20),
                      SizedBox(width: 8),
                      Text('Speed up', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(width: 8),
                      ResourceIcon.gem(size: 20),
                      SizedBox(width: 4),
                      Text('$gemCost', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                onPressed: widget.onCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade400,
                  side: BorderSide(color: Colors.red.shade300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  widget.building.level > 1 ? 'Cancel Upgrade' : 'Cancel Construction',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Full resource refund',
              style: TextStyle(fontSize: 11, color: AppTheme.darkText.withValues(alpha: 0.5)),
            ),
            SizedBox(height: 8),
          ],
        ),
        ),
      ),
    );
  }
}

/// Combines InteractiveViewer for pan/zoom with tap forwarding to Flame.
/// InteractiveViewer handles all drag/pinch gestures natively.
/// Taps are detected separately and converted to world coordinates.
class _TapThroughInteractiveViewer extends StatelessWidget {
  final TransformationController transformationController;
  final double minScale;
  final double maxScale;
  final VillageGame game;

  const _TapThroughInteractiveViewer({
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
        // Convert screen tap position to Flame world coordinates
        final zoom = game.currentZoom;
        final camPos = game.camera.viewfinder.position;
        final screenSize = game.size;
        final worldX = camPos.x + (details.localPosition.dx - screenSize.x / 2) / zoom;
        final worldY = camPos.y + (details.localPosition.dy - screenSize.y / 2) / zoom;
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
