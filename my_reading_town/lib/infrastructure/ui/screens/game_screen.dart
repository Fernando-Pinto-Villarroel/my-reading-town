import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/game.dart' hide Matrix4;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:my_reading_town/infrastructure/ui/config/app_theme.dart';
import 'package:my_reading_town/infrastructure/ui/localization/context_ext.dart';
import 'package:my_reading_town/infrastructure/ui/localization/language_provider.dart';
import 'package:my_reading_town/domain/rules/village_rules.dart';
import 'package:my_reading_town/infrastructure/ui/config/ui_constants.dart';
import 'package:my_reading_town/infrastructure/ui/game/village_game.dart';
import 'package:my_reading_town/domain/entities/placed_building.dart';
import 'package:my_reading_town/domain/entities/villager.dart';
import 'package:my_reading_town/adapters/providers/book_provider.dart';
import 'package:my_reading_town/adapters/providers/village_provider.dart';
import 'package:my_reading_town/infrastructure/ui/widgets/dialogs/backpack_dialog.dart';
import 'package:my_reading_town/infrastructure/ui/widgets/dialogs/building_dialogs.dart';
import 'package:my_reading_town/infrastructure/ui/widgets/sheets/building_info_sheet.dart';
import 'package:my_reading_town/infrastructure/ui/widgets/common/building_selector.dart';
import 'package:my_reading_town/infrastructure/ui/widgets/dialogs/expansion_dialog.dart';
import 'package:my_reading_town/infrastructure/ui/widgets/hud/constructor_counter.dart';
import 'package:my_reading_town/infrastructure/ui/widgets/hud/resource_hud.dart';
import 'package:my_reading_town/infrastructure/ui/widgets/hud/left_action_grid.dart';
import 'package:my_reading_town/infrastructure/ui/widgets/hud/side_menu.dart';
import 'package:my_reading_town/infrastructure/ui/widgets/common/happiness_indicator.dart';
import 'package:my_reading_town/infrastructure/ui/widgets/popups/level_up_popup.dart';
import 'package:my_reading_town/infrastructure/ui/widgets/dialogs/minigames_dialog.dart';
import 'package:my_reading_town/infrastructure/ui/widgets/dialogs/missions_modal.dart';
import 'package:my_reading_town/infrastructure/ui/widgets/dialogs/reading_modal.dart';
import 'package:my_reading_town/infrastructure/ui/widgets/dialogs/settings_dialog.dart';
import 'package:my_reading_town/application/services/building_service.dart';
import 'package:my_reading_town/application/services/notification_service.dart';
import 'package:my_reading_town/infrastructure/di/service_locator.dart';
import 'package:my_reading_town/infrastructure/ui/widgets/common/shared_utils.dart';
import 'package:my_reading_town/infrastructure/ui/widgets/dialogs/stats_dialog.dart';
import 'package:my_reading_town/infrastructure/ui/widgets/common/tap_through_interactive_viewer.dart';
import 'package:my_reading_town/infrastructure/ui/widgets/dialogs/village_photo_dialog.dart';
import 'package:my_reading_town/infrastructure/ui/widgets/dialogs/roulette_dialog.dart';
import 'package:my_reading_town/infrastructure/ui/widgets/dialogs/store_dialog.dart';
import 'package:my_reading_town/infrastructure/ui/widgets/dialogs/species_book_dialog.dart';
import 'package:my_reading_town/domain/rules/species_rules.dart';
import 'package:my_reading_town/infrastructure/ui/widgets/sheets/villager_sheets.dart';
import 'package:my_reading_town/infrastructure/ui/widgets/dialogs/villager_choice_dialog.dart';
import 'package:my_reading_town/infrastructure/ui/widgets/tour/tour_overlay.dart';
import 'package:my_reading_town/app_constants.dart';
import 'package:my_reading_town/infrastructure/ui/widgets/common/app_toast.dart';

part 'game_screen_tap_handlers.dart';

enum GameMode { normal, construction, road }

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with TickerProviderStateMixin, _GameTapHandlers {
  late VillageGame _game;
  VillageProvider? _villageProviderRef;
  @override
  VillageProvider get _villageProvider => _villageProviderRef!;
  late BookProvider _bookProvider;
  @override
  GameMode _mode = GameMode.normal;
  @override
  String? _selectedBuildingType;
  String? _scrollToBuildingType;
  @override
  int? _movingBuildingId;
  Timer? _constructionTimer;
  @override
  final Set<int> _notifiedCompletions = {};
  int _lastSandwichCount = 0;
  bool _menuOpen = false;
  bool _resourceHudExpanded = true;
  bool _villagerChoiceDialogShowing = false;
  bool _isCapturing = false;
  final GlobalKey _gameRepaintKey = GlobalKey();
  @override
  bool _flipNextBuilding = false;
  late final TransformationController _transformController;
  late final TabController _buildingTabController;
  final GlobalKey _tourMissionsKey = GlobalKey();
  final GlobalKey _tourBuildKey = GlobalKey();
  final GlobalKey _tourReadingKey = GlobalKey();
  final GlobalKey _tourResourcesKey = GlobalKey();
  final GlobalKey _tourBackpackKey = GlobalKey();
  final GlobalKey _tourMinigamesKey = GlobalKey();
  final GlobalKey _tourPhotoKey = GlobalKey();
  final GlobalKey _tourStatsKey = GlobalKey();
  final GlobalKey _tourSettingsKey = GlobalKey();
  final GlobalKey _tourRouletteKey = GlobalKey();
  final GlobalKey _tourStoreKey = GlobalKey();
  final GlobalKey _tourSpeciesKey = GlobalKey();
  int _tourStep = -1;
  bool _tourInitialized = false;

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
      // Set the VillagerService on the game so it can calculate missing needs per villager
      _game.setVillagerService(_villageProvider.villagerService);
    }
    _bookProvider = context.read<BookProvider>();
    _constructionTimer ??= Timer.periodic(
      const Duration(seconds: 1),
      (_) => _checkConstructions(),
    );
    _syncGameState();
    _villageProvider.checkMissions();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _checkPendingVillagerChoices();
    });
    if (!_tourInitialized) {
      _tourInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_villageProvider.tutorialCompleted && !AppConstants.testMode) {
          setState(() => _tourStep = 0);
        }
      });
    }
  }

  void _onVillageProviderChanged() => _checkLevelUp();

  @override
  void _syncGameState() {
    final village = _villageProvider;
    _game.updateRoadTiles(village.roadTiles);
    _game.updateSpecialTiles(village.specialTiles);
    _game.updateWalkableTiles(village.walkableTiles);
    _game.playerLevel = village.playerLevel;
    _game.updateUnlockedChunks(village.unlockedChunks);
    _game.updatePlacedBuildings(village.placedBuildings);
    _game.updateVillagers(village.villagers,
        missingBuildingTypes: village.missingBuildingTypes,
        houseRoadTiles: village.houseAdjacentRoadTiles);
    _game.updateActivePowerups(village.activePowerups);
    _game.isConstructionMode = _mode == GameMode.construction;
    _game.isRoadMode = _mode == GameMode.road ||
        (_mode == GameMode.construction &&
            _selectedBuildingType != null &&
            VillageRules.isTileType(_selectedBuildingType!));
    _game.updateGridState();

    final sandwichCount =
        village.activePowerups.where((p) => p.type == 'sandwich_speed').length;
    if (sandwichCount != _lastSandwichCount) {
      _lastSandwichCount = sandwichCount;
      _rescheduleConstructionNotifications();
    }
  }

  void _rescheduleConstructionNotifications() {
    final village = _villageProvider;
    final lang = sl<LanguageProvider>();
    final notif = sl<NotificationService>();
    for (final b in village.placedBuildings) {
      if (b.isConstructed || b.id == null) continue;
      final remaining =
          BuildingService.effectiveRemainingTime(b, village.activePowerups);
      notif.scheduleConstructionComplete(
        buildingId: b.id!,
        buildingName: b.name,
        remaining: remaining,
        title: lang.translate('notification_construction_title'),
        body: lang.translate('notification_construction_body'),
      );
    }
  }

  void _checkConstructions() async {
    if (!mounted) return;
    final village = _villageProvider;
    village.tickCooldowns();
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
    if (mounted) _checkPendingVillagerChoices();
  }

  @override
  void _checkPendingVillagerChoices() {
    if (!mounted || _villagerChoiceDialogShowing) return;
    final village = _villageProvider;
    if (village.pendingVillagerChoices.isEmpty) return;

    final choice = village.pendingVillagerChoices.first;
    final lang = sl<LanguageProvider>();

    _villagerChoiceDialogShowing = true;
    showVillagerChoiceDialog(
      context,
      choice: choice,
      village: village,
      lang: lang,
      onComplete: () {
        _villagerChoiceDialogShowing = false;
        _syncGameState();
        if (mounted) _checkPendingVillagerChoices();
      },
    );
  }

  void _checkLevelUp() {
    final newLevel = _villageProvider.consumeLevelUp();
    if (newLevel != null && mounted) {
      showDialog(
        context: context,
        barrierColor: Colors.transparent,
        barrierDismissible: true,
        builder: (ctx) => LevelUpPopup(
            newLevel: newLevel, onDismiss: () {
          Navigator.pop(ctx);
          _checkNewSpecies();
        }),
      );
    }
  }

  void _checkNewSpecies() {
    final speciesId = _villageProvider.consumePendingNewSpecies();
    if (speciesId == null || !mounted) return;
    final speciesData = SpeciesRules.findById(speciesId);
    if (speciesData == null) return;
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _NewSpeciesPopup(speciesData: speciesData, lang: lang),
    );
  }

  void _onConstructionComplete(PlacedBuilding building) =>
      _checkConstructions();

  Future<void> _captureVillagePhoto() async {
    if (_isCapturing) return;
    setState(() {
      _isCapturing = true;
      _menuOpen = false;
    });

    try {
      final boundary = _gameRepaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null || !mounted) return;

      final pixelRatio = MediaQuery.of(context).devicePixelRatio;
      final tileBounds = _game.getOccupiedBounds();

      if (tileBounds == null) {
        await Future.delayed(const Duration(milliseconds: 50));
        final fullImage = await boundary.toImage(pixelRatio: pixelRatio);
        final byteData =
            await fullImage.toByteData(format: ui.ImageByteFormat.png);
        if (!mounted) return;
        showDialog(
            context: context,
            builder: (_) =>
                VillagePhotoDialog(imageBytes: byteData!.buffer.asUint8List()));
        return;
      }

      const padTiles = 1;
      final minTileX = max(0, tileBounds.minX - padTiles);
      final minTileY = max(0, tileBounds.minY - padTiles);
      final maxTileX =
          min(VillageRules.mapSize - 1, tileBounds.maxX + padTiles);
      final maxTileY =
          min(VillageRules.mapSize - 1, tileBounds.maxY + padTiles);

      final tileSize = UiConstants.tilePixelSize;
      final contentWorldW = (maxTileX - minTileX + 1) * tileSize;
      final contentWorldH = (maxTileY - minTileY + 1) * tileSize;
      final worldCenterX =
          (minTileX * tileSize + (maxTileX + 1) * tileSize) / 2.0;
      final worldCenterY =
          (minTileY * tileSize + (maxTileY + 1) * tileSize) / 2.0;

      final screenW = boundary.size.width;
      final screenH = boundary.size.height;

      final fitZoom = min(screenW / contentWorldW, screenH / contentWorldH)
          .clamp(0.005, 10.0);

      _game.setCameraForCapture(Vector2(worldCenterX, worldCenterY), fitZoom);
      await Future.delayed(const Duration(milliseconds: 100));

      final fullImage = await boundary.toImage(pixelRatio: pixelRatio);

      _onTransformChanged();

      final visibleContentW = contentWorldW * fitZoom;
      final visibleContentH = contentWorldH * fitZoom;
      final imgW = fullImage.width.toDouble();
      final imgH = fullImage.height.toDouble();

      final cropX =
          ((screenW - visibleContentW) / 2.0 * pixelRatio).clamp(0.0, imgW);
      final cropY =
          ((screenH - visibleContentH) / 2.0 * pixelRatio).clamp(0.0, imgH);
      final cropW = (visibleContentW * pixelRatio).clamp(1.0, imgW - cropX);
      final cropH = (visibleContentH * pixelRatio).clamp(1.0, imgH - cropY);

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawImageRect(
        fullImage,
        Rect.fromLTWH(cropX, cropY, cropW, cropH),
        Rect.fromLTWH(0, 0, cropW, cropH),
        Paint(),
      );
      final picture = recorder.endRecording();
      final croppedImage = await picture.toImage(cropW.round(), cropH.round());
      final byteData =
          await croppedImage.toByteData(format: ui.ImageByteFormat.png);

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) =>
            VillagePhotoDialog(imageBytes: byteData!.buffer.asUint8List()),
      );
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  String get _tourVillagerName {
    final villagers = _villageProvider.villagers;
    return villagers.isNotEmpty ? villagers.first.name : 'Mochi';
  }

  String get _tourVillagerSpecies {
    final villagers = _villageProvider.villagers;
    return villagers.isNotEmpty ? villagers.first.species : 'cat';
  }

  void _onTourAdvance() {
    final step = _tourStep;
    if (step == 5) {
      setState(() {
        _mode = GameMode.normal;
        _selectedBuildingType = null;
        _flipNextBuilding = false;
        _tourStep = 6;
      });
      _syncGameState();
    } else if (step == 11) {
      setState(() => _menuOpen = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _tourStep = 12);
      });
    } else if (step == 17) {
      setState(() {
        _menuOpen = false;
        _tourStep = 18;
      });
    } else if (step == 21) {
      setState(() => _menuOpen = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _tourStep = 22);
      });
    } else if (step == 23) {
      setState(() {
        _menuOpen = false;
        _tourStep = 24;
      });
    } else if (step == 25) {
      _completeTour();
    } else if (step >= 0 && step < tourTotalSteps) {
      setState(() => _tourStep = step + 1);
    }
  }

  Future<void> _onTourInputSubmit(String username, String townName) async {
    if (username.isNotEmpty) await _villageProvider.updateUsername(username);
    if (townName.isNotEmpty) await _villageProvider.updateTownName(townName);
    if (mounted) setState(() => _tourStep = 25);
  }

  Future<void> _completeTour() async {
    await _villageProvider.markTutorialCompleted();
    if (mounted) setState(() => _tourStep = -1);
  }


  void _onVillagerTapped(Villager villager) {
    if (!mounted) return;
    showVillagerInfoSheet(context,
        villager: villager,
        village: _villageProvider,
        onSyncGameState: _syncGameState,
        onNeedTapped: (type) {
          setState(() {
            _mode = GameMode.construction;
            _buildingTabController.index = 0;
            _scrollToBuildingType = type;
            if (_villageProvider.canPlaceBuildingType(type)) {
              _selectedBuildingType = type;
            } else {
              _selectedBuildingType = null;
            }
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _scrollToBuildingType = null);
          });
        });
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
            child: RepaintBoundary(
              key: _gameRepaintKey,
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
                        Text(context.t('loading_village'),
                            style:
                                TextStyle(fontSize: 16, color: Colors.white)),
                        SizedBox(height: 16),
                        CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(AppTheme.pink)),
                      ],
                    ),
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
                SizedBox(
                  key: _tourResourcesKey,
                  child: ResourceHud(
                    village: village,
                    landscape: landscape,
                    expanded: _resourceHudExpanded,
                    onToggle: () => setState(
                        () => _resourceHudExpanded = !_resourceHudExpanded),
                  ),
                ),
                SizedBox(height: 6),
                LeftActionGrid(
                  landscape: landscape,
                  isConstructionMode: _mode == GameMode.construction,
                  missionsButtonKey: _tourMissionsKey,
                  buildButtonKey: _tourBuildKey,
                  backpackButtonKey: _tourBackpackKey,
                  minigamesButtonKey: _tourMinigamesKey,
                  rouletteButtonKey: _tourRouletteKey,
                  storeButtonKey: _tourStoreKey,
                  onConstructionTap: () {
                    setState(() {
                      if (_mode == GameMode.construction) {
                        _mode = GameMode.normal;
                        _selectedBuildingType = null;
                        _flipNextBuilding = false;
                      } else {
                        _mode = GameMode.construction;
                        if (_tourStep == 4) _tourStep = 5;
                      }
                    });
                    _syncGameState();
                  },
                  onMissionsTap: () {
                    if (_tourStep == 2) {
                      setState(() => _tourStep = 3);
                    } else {
                      showMissionsModal(context);
                    }
                  },
                  onBackpackTap: () {
                    if (_tourStep == 8) {
                      setState(() => _tourStep = 9);
                    } else {
                      _villageProvider.clearNewBackpackItems();
                      showBackpackDialog(context, _villageProvider);
                    }
                  },
                  onMinigamesTap: () {
                    if (_tourStep == 10) {
                      setState(() => _tourStep = 11);
                    } else {
                      showMinigamesDialog(context,
                          village: _villageProvider, onReturn: () {
                        _villageProvider.loadData();
                        _syncGameState();
                      });
                    }
                  },
                  onRouletteTap: () {
                    if (_tourStep == 18) {
                      setState(() => _tourStep = 19);
                    } else {
                      showRouletteDialog(context);
                    }
                  },
                  onStoreTap: () {
                    if (_tourStep == 20) {
                      setState(() => _tourStep = 21);
                    } else {
                      showStoreDialog(context);
                    }
                  },
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
                    happiness: village.villageHappiness, landscape: landscape),
                SizedBox(height: landscape ? 4 : 6),
                ConstructorCounter(village: village, landscape: landscape),
                SizedBox(height: landscape ? 6 : 10),
                SideMenu(
                  menuOpen: _menuOpen,
                  readingButtonKey: _tourReadingKey,
                  photoButtonKey: _tourPhotoKey,
                  statsButtonKey: _tourStatsKey,
                  settingsButtonKey: _tourSettingsKey,
                  speciesButtonKey: _tourSpeciesKey,
                  onToggleMenu: () => setState(() => _menuOpen = !_menuOpen),
                  onReadingTap: () {
                    if (_tourStep == 6) {
                      setState(() => _tourStep = 7);
                    } else {
                      showReadingModal(context);
                    }
                  },
                  onPhotoTap: () {
                    if (_tourStep == 12) {
                      setState(() => _tourStep = 13);
                    } else {
                      _captureVillagePhoto();
                    }
                  },
                  onStatsTap: () {
                    if (_tourStep == 14) {
                      setState(() => _tourStep = 15);
                    } else {
                      showStatsDialog(context, _villageProvider, _bookProvider);
                    }
                  },
                  onSettingsTap: () {
                    if (_tourStep == 16) {
                      setState(() => _tourStep = 17);
                    } else {
                      showSettingsDialog(context, _villageProvider);
                    }
                  },
                  onSpeciesBookTap: () {
                    if (_tourStep == 22) {
                      setState(() => _tourStep = 23);
                    } else {
                      showSpeciesBookDialog(context);
                    }
                  },
                ),
              ],
            ),
          ),
          if (_mode == GameMode.construction)
            Positioned(
              bottom: bottomPadding + 8,
              left: leftPadding + (landscape ? hudEdge : 0),
              right: rightPadding + (landscape ? hudEdge : 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_movingBuildingId != null) _buildMovingBanner(landscape),
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
                    scrollToType: _scrollToBuildingType,
                    onSelectBuilding: (type) => setState(() {
                      _selectedBuildingType = type;
                      _movingBuildingId = null;
                    }),
                    onToggleFlip: () =>
                        setState(() => _flipNextBuilding = !_flipNextBuilding),
                  ),
                ],
              ),
            ),
          if (_tourStep >= 0 && _tourStep < tourTotalSteps)
            TourOverlay(
              stepIndex: _tourStep,
              villagerName: _tourVillagerName,
              villagerSpecies: _tourVillagerSpecies,
              missionsButtonKey: _tourMissionsKey,
              buildButtonKey: _tourBuildKey,
              readingButtonKey: _tourReadingKey,
              backpackButtonKey: _tourBackpackKey,
              minigamesButtonKey: _tourMinigamesKey,
              photoButtonKey: _tourPhotoKey,
              statsButtonKey: _tourStatsKey,
              settingsButtonKey: _tourSettingsKey,
              rouletteButtonKey: _tourRouletteKey,
              storeButtonKey: _tourStoreKey,
              speciesButtonKey: _tourSpeciesKey,
              resourcesKey: _tourResourcesKey,
              translate: (key, {fallback}) =>
                  sl<LanguageProvider>().translate(key, fallback: fallback ?? key),
              onAdvance: _onTourAdvance,
              onInputSubmit: _onTourInputSubmit,
            ),
        ],
      ),
    );
  }

  Widget _buildMovingBanner(bool landscape) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding:
          EdgeInsets.symmetric(horizontal: 16, vertical: landscape ? 4 : 8),
      decoration: BoxDecoration(
        color: AppTheme.mint.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.open_with, size: 20, color: AppTheme.darkText),
          SizedBox(width: 8),
          Expanded(
            child: Text(context.t('tap_tile_to_move'),
                softWrap: true,
                overflow: TextOverflow.visible,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: AppTheme.darkText)),
          ),
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
                  color: _flipNextBuilding ? Colors.white : AppTheme.darkText),
              SizedBox(width: 4),
              Text(context.t('flip'),
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

class _NewSpeciesPopup extends StatelessWidget {
  final VillagerSpeciesData speciesData;
  final LanguageProvider lang;

  const _NewSpeciesPopup({required this.speciesData, required this.lang});

  Color get _rarityColor {
    switch (speciesData.rarity) {
      case VillagerRarity.common: return const Color(0xFF78909C);
      case VillagerRarity.rare: return const Color(0xFF1E88E5);
      case VillagerRarity.extraordinary: return const Color(0xFF8E24AA);
      case VillagerRarity.legendary: return const Color(0xFFEF6C00);
      case VillagerRarity.godly: return const Color(0xFFE53935);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _rarityColor;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppTheme.softWhite,
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              lang.translate('species_new'),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 16),
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2.5),
              ),
              child: Center(
                child: Image.asset(
                  'assets/images/${speciesData.id}_villager.png',
                  width: 70,
                  height: 70,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, __, ___) =>
                      Icon(Icons.pets, size: 44, color: color),
                ),
              ),
            ),
            SizedBox(height: 14),
            Text(
              lang.translate(speciesData.nameKey),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkText,
              ),
            ),
            SizedBox(height: 6),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color, width: 1.5),
              ),
              child: Text(
                lang.translate(SpeciesRules.rarityKey(speciesData.rarity)),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            SizedBox(height: 10),
            Text(
              lang.translate(speciesData.descriptionKey),
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.darkText.withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  lang.translate('done'),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
