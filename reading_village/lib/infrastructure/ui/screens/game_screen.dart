import 'dart:async';
import 'package:flame/game.dart' hide Matrix4;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:reading_village/infrastructure/ui/config/app_theme.dart';
import 'package:reading_village/domain/rules/village_rules.dart';
import 'package:reading_village/infrastructure/ui/config/ui_constants.dart';
import 'package:reading_village/infrastructure/ui/game/village_game.dart';
import 'package:reading_village/domain/entities/placed_building.dart';
import 'package:reading_village/domain/entities/villager.dart';
import 'package:reading_village/adapters/providers/book_provider.dart';
import 'package:reading_village/adapters/providers/village_provider.dart';
import 'package:reading_village/infrastructure/ui/widgets/dialogs/backpack_dialog.dart';
import 'package:reading_village/infrastructure/ui/widgets/dialogs/building_dialogs.dart';
import 'package:reading_village/infrastructure/ui/widgets/sheets/building_info_sheet.dart';
import 'package:reading_village/infrastructure/ui/widgets/common/building_selector.dart';
import 'package:reading_village/infrastructure/ui/widgets/dialogs/expansion_dialog.dart';
import 'package:reading_village/infrastructure/ui/widgets/hud/constructor_counter.dart';
import 'package:reading_village/infrastructure/ui/widgets/hud/resource_hud.dart';
import 'package:reading_village/infrastructure/ui/widgets/hud/left_action_grid.dart';
import 'package:reading_village/infrastructure/ui/widgets/hud/side_menu.dart';
import 'package:reading_village/infrastructure/ui/widgets/common/happiness_indicator.dart';
import 'package:reading_village/infrastructure/ui/widgets/popups/level_up_popup.dart';
import 'package:reading_village/infrastructure/ui/widgets/dialogs/minigames_dialog.dart';
import 'package:reading_village/infrastructure/ui/widgets/dialogs/missions_modal.dart';
import 'package:reading_village/infrastructure/ui/widgets/dialogs/reading_modal.dart';
import 'package:reading_village/infrastructure/ui/widgets/dialogs/settings_dialog.dart';
import 'package:reading_village/infrastructure/ui/widgets/common/shared_utils.dart';
import 'package:reading_village/infrastructure/ui/widgets/dialogs/stats_dialog.dart';
import 'package:reading_village/infrastructure/ui/widgets/common/tap_through_interactive_viewer.dart';
import 'package:reading_village/infrastructure/ui/widgets/sheets/villager_sheets.dart';

part 'game_screen_tap_handlers.dart';

enum GameMode { normal, construction, road }

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin, _GameTapHandlers {
  late VillageGame _game;
  VillageProvider? _villageProviderRef;
  @override
  VillageProvider get _villageProvider => _villageProviderRef!;
  late BookProvider _bookProvider;
  @override
  GameMode _mode = GameMode.normal;
  @override
  String? _selectedBuildingType;
  @override
  int? _movingBuildingId;
  Timer? _constructionTimer;
  @override
  final Set<int> _notifiedCompletions = {};
  bool _menuOpen = false;
  bool _resourceHudExpanded = false;
  @override
  bool _flipNextBuilding = false;
  late final TransformationController _transformController;
  late final TabController _buildingTabController;

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
      onExpansionSignTapped: _onExpansionSignTapped,
    );
    _transformController = TransformationController();
    _transformController.addListener(_onTransformChanged);
    _buildingTabController = TabController(length: 3, vsync: this);
  }

  void _onTransformChanged() {
    final m = _transformController.value;
    final scale = m.getMaxScaleOnAxis();
    final translation = m.getTranslation();
    _game.applyCameraTransform(scale, translation.x, translation.y);
  }

  @override
  void dispose() {
    _villageProviderRef?.removeListener(_onVillageProviderChanged);
    _constructionTimer?.cancel();
    _transformController.removeListener(_onTransformChanged);
    _transformController.dispose();
    _buildingTabController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newProvider = context.read<VillageProvider>();
    if (newProvider != _villageProviderRef) {
      _villageProviderRef?.removeListener(_onVillageProviderChanged);
      _villageProviderRef = newProvider;
      _villageProvider.addListener(_onVillageProviderChanged);
    }
    _bookProvider = context.read<BookProvider>();
    _constructionTimer ??= Timer.periodic(
      const Duration(seconds: 1),
      (_) => _checkConstructions(),
    );
    _syncGameState();
    _villageProvider.checkMissions();
  }

  void _onVillageProviderChanged() => _checkLevelUp();

  @override
  void _syncGameState() {
    final village = _villageProvider;
    _game.updateRoadTiles(village.roadTiles);
    _game.updateUnlockedChunks(village.unlockedChunks);
    _game.updatePlacedBuildings(village.placedBuildings);
    _game.updateVillagers(village.villagers,
        missingBuildingTypes: village.missingBuildingTypes,
        houseRoadTiles: village.houseAdjacentRoadTiles);
    _game.isConstructionMode = _mode == GameMode.construction;
    _game.isRoadMode = _mode == GameMode.road ||
        (_mode == GameMode.construction &&
            _selectedBuildingType != null &&
            VillageRules.isTileType(_selectedBuildingType!));
    _game.updateGridState();
  }

  void _checkConstructions() async {
    if (!mounted) return;
    final village = _villageProvider;
    final completed = await village.checkAndCompleteConstructions();
    for (var building in completed) {
      if (!_notifiedCompletions.contains(building.id)) {
        _notifiedCompletions.add(building.id!);
        if (mounted) showConstructionCompleteDialog(context, building);
      }
    }
    if (completed.isNotEmpty && mounted) {
      _syncGameState();
      await village.checkMissions();
    }
  }

  void _checkLevelUp() {
    final newLevel = _villageProvider.consumeLevelUp();
    if (newLevel != null && mounted) {
      showDialog(
        context: context,
        barrierColor: Colors.transparent,
        barrierDismissible: true,
        builder: (ctx) =>
            LevelUpPopup(newLevel: newLevel, onDismiss: () => Navigator.pop(ctx)),
      );
    }
  }

  void _onConstructionComplete(PlacedBuilding building) => _checkConstructions();

  void _onVillagerTapped(Villager villager) {
    if (!mounted) return;
    showVillagerInfoSheet(context,
        villager: villager,
        village: _villageProvider,
        onSyncGameState: _syncGameState);
  }

  @override
  void _onExpansionSignTapped(int chunkX, int chunkY) {
    showExpansionDialog(context,
        chunkX: chunkX,
        chunkY: chunkY,
        village: _villageProvider,
        game: _game,
        onSyncGameState: _syncGameState);
  }

  @override
  Widget build(BuildContext context) {
    final village = context.watch<VillageProvider>();
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;
    final bottomPadding = mediaQuery.padding.bottom;
    final leftPadding = mediaQuery.padding.left;
    final rightPadding = mediaQuery.padding.right;
    final landscape = isLandscape(context);
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
                      Text('Loading village...',
                          style:
                              TextStyle(fontSize: 16, color: Colors.white)),
                      SizedBox(height: 16),
                      CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation(AppTheme.pink)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: TapThroughInteractiveViewer(
              transformationController: _transformController,
              minScale: UiConstants.minZoom / UiConstants.defaultZoom,
              maxScale: UiConstants.maxZoom / UiConstants.defaultZoom,
              game: _game,
            ),
          ),
          Positioned(
            top: topPadding + (landscape ? 6 : 10),
            left: leftPadding + hudEdge,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResourceHud(
                  village: village,
                  landscape: landscape,
                  expanded: _resourceHudExpanded,
                  onToggle: () =>
                      setState(() => _resourceHudExpanded = !_resourceHudExpanded),
                ),
                SizedBox(height: 6),
                LeftActionGrid(
                  landscape: landscape,
                  isConstructionMode: _mode == GameMode.construction,
                  onConstructionTap: () {
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
                  onReadingTap: () => showReadingModal(context),
                  onMissionsTap: () => showMissionsModal(context),
                  onMinigamesTap: () => showMinigamesDialog(context,
                      village: _villageProvider,
                      onReturn: () {
                        _villageProvider.loadData();
                        _syncGameState();
                      }),
                ),
              ],
            ),
          ),
          Positioned(
            top: topPadding + (landscape ? 6 : 10),
            right: rightPadding + hudEdge,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                HappinessIndicator(
                    happiness: village.villageHappiness,
                    landscape: landscape),
                SizedBox(height: landscape ? 4 : 6),
                ConstructorCounter(
                    village: village, landscape: landscape),
                SizedBox(height: landscape ? 6 : 10),
                SideMenu(
                  menuOpen: _menuOpen,
                  onToggleMenu: () =>
                      setState(() => _menuOpen = !_menuOpen),
                  onBackpackTap: () =>
                      showBackpackDialog(context, _villageProvider),
                  onStatsTap: () => showStatsDialog(
                      context, _villageProvider, _bookProvider),
                  onSettingsTap: () =>
                      showSettingsDialog(context, _villageProvider),
                ),
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
                    _buildMovingBanner(landscape),
                  if (landscape &&
                      _selectedBuildingType != null &&
                      _movingBuildingId == null)
                    _buildFlipToggle(),
                  BuildingSelector(
                    village: village,
                    landscape: landscape,
                    tabController: _buildingTabController,
                    selectedBuildingType: _selectedBuildingType,
                    movingBuildingId: _movingBuildingId,
                    flipNextBuilding: _flipNextBuilding,
                    onSelectBuilding: (type) => setState(() {
                      _selectedBuildingType = type;
                      _movingBuildingId = null;
                    }),
                    onToggleFlip: () => setState(
                        () => _flipNextBuilding = !_flipNextBuilding),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMovingBanner(bool landscape) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.symmetric(
          horizontal: 16, vertical: landscape ? 4 : 8),
      decoration: BoxDecoration(
        color: AppTheme.mint.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.open_with, size: 20, color: AppTheme.darkText),
          SizedBox(width: 8),
          Text('Tap a tile to move building',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: AppTheme.darkText)),
          SizedBox(width: 8),
          GestureDetector(
            onTap: () async {
              await _villageProvider.flipBuilding(_movingBuildingId!);
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
    );
  }

  Widget _buildFlipToggle() {
    return Container(
      margin: EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: () => setState(() => _flipNextBuilding = !_flipNextBuilding),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _flipNextBuilding
                ? AppTheme.mint
                : AppTheme.cream.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.flip,
                  size: 18,
                  color:
                      _flipNextBuilding ? Colors.white : AppTheme.darkText),
              SizedBox(width: 4),
              Text('Flip',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _flipNextBuilding
                          ? Colors.white
                          : AppTheme.darkText)),
            ],
          ),
        ),
      ),
    );
  }
}
