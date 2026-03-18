import 'dart:async';
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
import '../widgets/happiness_indicator.dart';
import '../widgets/resource_icon.dart';
import '../widgets/reward_popup.dart';
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
    );

    setState(() {
      _mode = GameMode.normal;
      _selectedBuildingType = null;
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
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
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
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.cream,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
              Icon(Icons.celebration, size: 48, color: AppTheme.coinGold),
              SizedBox(height: 12),
              Text(
                'Construction Complete!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkText,
                ),
              ),
              SizedBox(height: 12),
              Image.asset(
                'assets/images/${GameConstants.spriteForBuilding(building.type, building.level)}',
                width: 64,
                height: 64,
                filterQuality: FilterQuality.medium,
              ),
              SizedBox(height: 8),
              Text(
                '${building.name} is ready!',
                style: TextStyle(fontSize: 16, color: AppTheme.darkText),
              ),
              if (building.type == 'house')
                Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'A new villager has arrived!',
                    style: TextStyle(fontSize: 14, color: AppTheme.mint, fontWeight: FontWeight.bold),
                  ),
                ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Great!'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showConstructingBuildingSheet(PlacedBuilding building) {
    final village = _villageProvider;
    final remaining = building.remainingConstructionTime;
    final gemCost = GameConstants.gemCostToSpeedUp(remaining);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewPadding.bottom),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
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
                width: 64, height: 64,
                filterQuality: FilterQuality.medium,
              ),
              SizedBox(height: 8),
              Text(
                '${building.name} (Lv${building.level})',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.darkText),
              ),
              SizedBox(height: 4),
              Text(
                'Under construction...',
                style: TextStyle(fontSize: 14, color: AppTheme.peach, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              _buildTimeDisplay(remaining),
              SizedBox(height: 16),
              if (gemCost > 0)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: village.gems >= gemCost
                        ? () async {
                            Navigator.pop(sheetCtx);
                            final success = await village.speedUpConstruction(building.id!);
                            if (success) {
                              _syncGameState();
                              if (mounted) _checkConstructions();
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: village.gems >= gemCost ? AppTheme.gemPurple : Colors.grey.shade300,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeDisplay(Duration remaining) {
    final hours = remaining.inHours;
    final mins = remaining.inMinutes % 60;
    final secs = remaining.inSeconds % 60;
    final text = hours > 0
        ? '${hours}h ${mins}m ${secs}s remaining'
        : '${mins}m ${secs}s remaining';
    return Text(text, style: TextStyle(fontSize: 16, color: AppTheme.darkText, fontWeight: FontWeight.bold));
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
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
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
                  width: 64, height: 64,
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.4,
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
                    padding: EdgeInsets.fromLTRB(16, 12, 8, 8),
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
                          icon: Icon(Icons.add_circle, size: 32, color: AppTheme.pink),
                          onPressed: () => _showAddBookDialog(),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Consumer<BookProvider>(
                      builder: (ctx, bookProvider, _) {
                        if (bookProvider.activeBooks.isEmpty &&
                            bookProvider.completedBooks.isEmpty) {
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
                        return ListView(
                          controller: scrollController,
                          children: [
                            if (bookProvider.activeBooks.isNotEmpty) ...[
                              Padding(
                                padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                                child: Row(
                                  children: [
                                    Icon(Icons.auto_stories, size: 16, color: AppTheme.lavender),
                                    SizedBox(width: 4),
                                    Text('Currently Reading',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkText)),
                                  ],
                                ),
                              ),
                              ...bookProvider.activeBooks.map((book) => BookCard(
                                    book: book,
                                    onLogPages: () => _showLogPagesDialog(book.id!),
                                  )),
                            ],
                            if (bookProvider.completedBooks.isNotEmpty) ...[
                              Padding(
                                padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                                child: Row(
                                  children: [
                                    Icon(Icons.star, size: 16, color: AppTheme.coinGold),
                                    SizedBox(width: 4),
                                    Text('Completed',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkText)),
                                  ],
                                ),
                              ),
                              ...bookProvider.completedBooks.map((book) =>
                                  BookCard(book: book, onLogPages: () {})),
                            ],
                            SizedBox(height: 24),
                          ],
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
    final titleController = TextEditingController();
    final pagesController = TextEditingController();
    String? titleError;
    String? pagesError;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Add a New Book'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Book Title',
                  hintText: 'e.g. The Little Prince',
                  errorText: titleError,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                textCapitalization: TextCapitalization.words,
                maxLength: 100,
              ),
              SizedBox(height: 12),
              TextField(
                controller: pagesController,
                decoration: InputDecoration(
                  labelText: 'Total Pages (2–900)',
                  hintText: 'e.g. 96',
                  errorText: pagesError,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final title = titleController.text.trim();
                final pages = int.tryParse(pagesController.text.trim());
                String? tErr;
                String? pErr;

                if (title.isEmpty) {
                  tErr = 'Title is required';
                } else if (title.length < 2) {
                  tErr = 'Title must be at least 2 characters';
                }
                if (pages == null) {
                  pErr = 'Enter a valid number';
                } else if (pages < 2) {
                  pErr = 'Minimum 2 pages';
                } else if (pages > 900) {
                  pErr = 'Maximum 900 pages';
                }

                if (tErr != null || pErr != null) {
                  setDialogState(() { titleError = tErr; pagesError = pErr; });
                  return;
                }

                _bookProvider.addBook(title, pages!);
                Navigator.pop(dialogCtx);
              },
              child: Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogPagesDialog(int bookId) {
    final pagesController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Log Pages Read'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('How many pages did you read?',
                style: TextStyle(color: AppTheme.darkText.withValues(alpha: 0.7))),
            SizedBox(height: 12),
            TextField(
              controller: pagesController,
              decoration: InputDecoration(
                labelText: 'Pages Read',
                hintText: 'e.g. 15',
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
              if (pages == null || pages <= 0) return;

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

  @override
  Widget build(BuildContext context) {
    final village = context.watch<VillageProvider>();
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;
    final bottomPadding = mediaQuery.padding.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // GameWidget fills the screen; Flame camera handles rendering.
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
          // InteractiveViewer overlay captures pan/pinch gestures
          // and syncs transform to the Flame camera. Taps are forwarded
          // to the Flame game by converting screen coords to world coords.
          Positioned.fill(
            child: _TapThroughInteractiveViewer(
              transformationController: _transformController,
              minScale: GameConstants.minZoom / GameConstants.defaultZoom,
              maxScale: GameConstants.maxZoom / GameConstants.defaultZoom,
              game: _game,
            ),
          ),

          Positioned(
            top: topPadding + 10,
            left: 14,
            child: _buildResourceHud(village),
          ),

          Positioned(
            top: topPadding + 10,
            right: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                HappinessIndicator(happiness: village.villageHappiness),
                SizedBox(height: 10),
                _buildZoomControls(),
                SizedBox(height: 10),
                _buildSideMenu(),
              ],
            ),
          ),

          if (_mode == GameMode.construction)
            Positioned(
              bottom: bottomPadding + 8,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_movingBuildingId != null)
                    Container(
                      margin: EdgeInsets.only(bottom: 8),
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                            onTap: () => setState(() => _movingBuildingId = null),
                            child: Icon(Icons.close, size: 20, color: AppTheme.darkText),
                          ),
                        ],
                      ),
                    ),
                  _buildBuildingSelector(village),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResourceHud(VillageProvider village) {
    return GestureDetector(
      onTap: () => setState(() => _resourceHudExpanded = !_resourceHudExpanded),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                Icon(Icons.star, size: 32, color: AppTheme.coinGold),
                SizedBox(width: 6),
                Text(
                  'Lv${village.playerLevel}',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.black87, blurRadius: 4)],
                  ),
                ),
                SizedBox(width: 8),
                Icon(
                  _resourceHudExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 22,
                  color: Colors.white70,
                ),
              ],
            ),
            if (_resourceHudExpanded) ...[
              SizedBox(height: 5),
              _hudRow(ResourceIcon.coin(size: 32), '${village.coins}'),
              SizedBox(height: 5),
              _hudRow(ResourceIcon.gem(size: 32), '${village.gems}'),
              SizedBox(height: 5),
              _hudRow(
                Image.asset('assets/images/cat_villager.png', width: 32, height: 32, filterQuality: FilterQuality.medium),
                '${village.villagers.length}',
              ),
              SizedBox(height: 5),
              _hudRow(ResourceIcon.wood(size: 32), '${village.wood}'),
              SizedBox(height: 5),
              _hudRow(ResourceIcon.metal(size: 32), '${village.metal}'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _hudRow(Widget icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        SizedBox(width: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 19,
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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xAA000000),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ZoomButton(
            icon: Icons.remove,
            onTap: () => _applyZoomFactor(0.8),
          ),
          GestureDetector(
            onTap: () {
              _game.setZoom(GameConstants.defaultZoom);
              _game.camera.viewfinder.position = Vector2.all(
                GameConstants.defaultAreaCenterTile * GameConstants.tilePixelSize +
                    GameConstants.tilePixelSize / 2,
              );
              _syncTransformToCamera();
              setState(() {});
            },
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('Reset', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
          _ZoomButton(
            icon: Icons.add,
            onTap: () => _applyZoomFactor(1.25),
          ),
        ],
      ),
    );
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

  Widget _buildBuildingSelector(VillageProvider village) {
    return Container(
      height: 180,
      margin: EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.cream.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
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
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Text('Select Building:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.darkText)),
                Spacer(),
                if (_selectedBuildingType != null)
                  Text('Tap a tile to place',
                      style: TextStyle(fontSize: 12, color: AppTheme.darkText.withValues(alpha: 0.6)))
                else if (_movingBuildingId == null)
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

                return GestureDetector(
                  onTap: canPlace ? () => setState(() { _selectedBuildingType = type; _movingBuildingId = null; }) : null,
                  child: Container(
                    width: 100,
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
                          width: 36, height: 36,
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
                          ],
                        ),
                        if (woodCost > 0 || metalCost > 0)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (woodCost > 0) ...[
                                ResourceIcon.wood(size: 12),
                                Text(' $woodCost', style: TextStyle(fontSize: 10)),
                              ],
                              if (woodCost > 0 && metalCost > 0) SizedBox(width: 4),
                              if (metalCost > 0) ...[
                                ResourceIcon.metal(size: 12),
                                Text(' $metalCost', style: TextStyle(fontSize: 10)),
                              ],
                            ],
                          ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.timer_outlined, size: 10, color: AppTheme.darkText.withValues(alpha: 0.4)),
                            SizedBox(width: 2),
                            Text(_formatMinutes(buildMinutes), style: TextStyle(fontSize: 9, color: AppTheme.darkText.withValues(alpha: 0.5))),
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
