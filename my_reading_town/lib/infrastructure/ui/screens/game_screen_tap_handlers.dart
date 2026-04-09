part of 'game_screen.dart';

mixin _GameTapHandlers on State<GameScreen> {
  VillageProvider get _villageProvider;
  GameMode get _mode;
  set _mode(GameMode v);
  String? get _selectedBuildingType;
  set _selectedBuildingType(String? v);
  int? get _movingBuildingId;
  set _movingBuildingId(int? v);
  bool get _flipNextBuilding;
  set _flipNextBuilding(bool v);
  Set<int> get _notifiedCompletions;
  void _syncGameState();
  void _onExpansionSignTapped(int chunkX, int chunkY);
  void _checkPendingVillagerChoices();

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
      _handleConstructionTap(tileX, tileY, village);
      return;
    }

    final building = village.getBuildingAt(tileX, tileY);
    if (building != null) {
      if (building.isConstructed) {
        if (!building.isDecoration &&
            building.type != 'house' &&
            !village.isBuildingRoadConnected(building)) {
          _showBuildingNotConnectedWarning();
        } else {
          showBuildingInfoSheet(context,
              building: building,
              village: village,
              onSyncGameState: _syncGameState);
        }
      } else {
        showConstructingBuildingSheet(context,
            building: building, village: village, onSpeedUp: () async {
          Navigator.pop(context);
          final success = await village.speedUpConstruction(building.id!);
          if (success) {
            sl<NotificationService>()
                .cancelConstructionNotification(building.id!);
            _syncGameState();
            _notifiedCompletions.add(building.id!);
            if (mounted) showConstructionCompleteDialog(context, building);
            if (mounted) _checkPendingVillagerChoices();
          }
        }, onCancel: () async {
          Navigator.pop(context);
          final success = await village.cancelConstruction(building.id!);
          if (success) {
            sl<NotificationService>()
                .cancelConstructionNotification(building.id!);
            _syncGameState();
          }
        });
      }
    }
  }

  void _handleConstructionTap(int tileX, int tileY, VillageProvider village) {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);

    if (!village.isTileUnlocked(tileX, tileY)) {
      final chunkX = tileX ~/ VillageRules.chunkSize;
      final chunkY = tileY ~/ VillageRules.chunkSize;
      if (village.isChunkAdjacentToUnlocked(chunkX, chunkY)) {
        _onExpansionSignTapped(chunkX, chunkY);
      }
      return;
    }

    if (_movingBuildingId != null) {
      final existingBuilding = village.getBuildingAt(tileX, tileY);
      if (existingBuilding != null &&
          existingBuilding.id != _movingBuildingId) {
        showWarningToast(context, langProvider.translate('tile_already_occupied'));
        return;
      }
      _moveBuilding(tileX, tileY);
      return;
    }

    if (_selectedBuildingType != null &&
        VillageRules.isTileType(_selectedBuildingType!)) {
      if (!village.isTileUnlocked(tileX, tileY)) return;
      if (village.hasBuildingAt(tileX, tileY)) return;
      village.toggleRoad(tileX, tileY);
      _syncGameState();
      return;
    }

    if (_selectedBuildingType != null) {
      final tw = VillageRules.buildingTileWidth(_selectedBuildingType!);
      final th = VillageRules.buildingTileHeight(_selectedBuildingType!);
      final placement = village.findValidPlacement(tileX, tileY, tw, th);
      if (placement == null) {
        showWarningToast(context, langProvider.translate('cannot_place_here'));
        return;
      }
      _placeBuilding(placement.x, placement.y);
      return;
    }

    final building = village.getBuildingAt(tileX, tileY);
    if (building != null) {
      setState(() {
        _movingBuildingId = building.id;
        _selectedBuildingType = null;
      });
      showInfoToast(context, '${langProvider.translate('tap_tile_to_move_prefix')} ${building.name}');
    }
  }

  void _placeBuilding(int tileX, int tileY) async {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final notif = sl<NotificationService>();
    final village = _villageProvider;
    final template = VillageRules.findTemplate(_selectedBuildingType!);
    if (template == null) return;
    final isDecoration = VillageRules.isDecorationType(_selectedBuildingType!);

    if (!isDecoration &&
        !village.canPlaceBuildingType(_selectedBuildingType!)) {
      showWarningToast(context, langProvider.translate('building_limit_reached'));
      return;
    }

    if (!village.canStartConstruction) {
      showWarningToast(context, '${langProvider.translate('all_constructors_busy')} (${village.busyConstructors}/${village.maxConstructors})');
      return;
    }

    final coinCost = template['coinCost'] as int;
    final gemCost = template['gemCost'] as int;
    final woodCost = template['woodCost'] as int;
    final metalCost = template['metalCost'] as int;

    if (village.coins < coinCost ||
        village.gems < gemCost ||
        village.wood < woodCost ||
        village.metal < metalCost) {
      showWarningToast(context, langProvider.translate('not_enough_resources_read_more'));
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
      tileWidth: VillageRules.buildingTileWidth(_selectedBuildingType!),
      tileHeight: VillageRules.buildingTileHeight(_selectedBuildingType!),
      isDecoration: isDecoration,
    );

    if (!isDecoration) {
      final placed = village.getBuildingAt(tileX, tileY);
      if (placed != null && placed.id != null) {
        final remaining = BuildingService.effectiveRemainingTime(
            placed, village.activePowerups);
        if (remaining > Duration.zero) {
          notif.scheduleConstructionComplete(
            buildingId: placed.id!,
            buildingName: placed.name,
            remaining: remaining,
            title: langProvider.translate('notification_construction_title'),
            body: langProvider.translate('notification_construction_body'),
          );
        }
      }
    }

    setState(() {
      _mode = GameMode.normal;
      _selectedBuildingType = null;
      _flipNextBuilding = false;
    });
    _syncGameState();
  }

  void _showBuildingNotConnectedWarning() {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          decoration: BoxDecoration(
            color: AppTheme.cream,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEB3B).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  size: 40,
                  color: Color(0xFFE6AC00),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                langProvider.translate('building_no_road_title',
                    fallback: 'Not Connected!'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                langProvider.translate('building_no_road_message',
                    fallback:
                        'Connect this building to a road so your villagers can visit and use it!'),
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.darkText.withValues(alpha: 0.7),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFEB3B),
                    foregroundColor: const Color(0xFF4A3800),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    langProvider.translate('done', fallback: 'Got it!'),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _moveBuilding(int tileX, int tileY) async {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final village = _villageProvider;
    final success =
        await village.moveBuilding(_movingBuildingId!, tileX, tileY);
    if (!mounted) return;
    if (success) {
      setState(() => _movingBuildingId = null);
      _syncGameState();
    } else {
      showWarningToast(context, langProvider.translate('cannot_move_here'));
    }
  }
}
