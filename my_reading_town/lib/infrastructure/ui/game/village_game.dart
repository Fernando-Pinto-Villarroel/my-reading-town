import 'dart:math';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Draggable, Matrix4;
import 'components/grid_component.dart';
import 'components/building_component.dart';
import 'components/villager_component.dart';
import 'components/expansion_sign_component.dart';
import 'package:my_reading_town/application/services/building_service.dart';
import 'package:my_reading_town/application/services/villager_service.dart';
import 'package:my_reading_town/domain/entities/inventory_item.dart';
import 'package:my_reading_town/domain/entities/placed_building.dart';
import 'package:my_reading_town/domain/entities/villager.dart';
import 'package:my_reading_town/domain/rules/village_rules.dart';
import 'package:my_reading_town/infrastructure/ui/config/ui_constants.dart';
import 'package:my_reading_town/app_constants.dart';

class VillageGame extends FlameGame {
  final Function(int tileX, int tileY)? onTileTapped;
  final Function(PlacedBuilding)? onConstructionComplete;
  final Function(Villager)? onVillagerTapped;
  final Function(int chunkX, int chunkY)? onExpansionSignTapped;

  bool isConstructionMode = false;
  bool isRoadMode = false;
  int playerLevel = 1;
  bool _isReady = false;

  bool _isNightMode = false;
  double _nightCheckTimer = 0;
  late NightOverlayComponent _nightOverlay;

  bool get isNightMode => _isNightMode;

  late GridComponent _gridComponent;
  final Set<String> _roadTiles = {};
  final Set<String> _walkableTiles = {};
  final Map<String, String> _specialTiles = {};
  final Set<String> _unlockedChunks = {};
  final Map<int, BuildingComponent> _buildingComponents = {};
  final List<VillagerComponent> _villagerComponents = [];
  final Map<String, ExpansionSignComponent> _expansionSigns = {};
  List<String> _walkableTilesList = [];

  double _constructionCheckTimer = 0;
  final Map<int, PlacedBuilding> _buildingsById = {};
  List<ActivePowerup> _activePowerups = [];
  VillagerService? _villagerService;

  VillageGame({
    this.onTileTapped,
    this.onConstructionComplete,
    this.onVillagerTapped,
    this.onExpansionSignTapped,
  });

  @override
  Color backgroundColor() => const Color(0xFF709070);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final centerWorld =
        VillageRules.defaultAreaCenterTile * UiConstants.tilePixelSize +
            UiConstants.tilePixelSize / 2;
    camera.viewfinder.position = Vector2(centerWorld, centerWorld);
    camera.viewfinder.anchor = Anchor.center;
    camera.viewfinder.zoom = UiConstants.defaultZoom;

    _gridComponent = GridComponent();
    world.add(_gridComponent);

    world.add(_WorldTapHandler(this));

    _nightOverlay = NightOverlayComponent();
    camera.viewport.add(_nightOverlay);

    _isReady = true;
    _updateNightMode();
    updateGridState();
  }

  void updateActivePowerups(List<ActivePowerup> powerups) {
    _activePowerups = powerups;
  }

  void setVillagerService(VillagerService service) {
    _villagerService = service;
  }

  void _updateNightMode() {
    final isNight = AppConstants.testMode
        ? AppConstants.isNightTime
        : (() {
            final hour = DateTime.now().hour;
            return hour >= 19 || hour < 5;
          })();
    final wasNight = _isNightMode;
    _isNightMode = isNight;
    _nightOverlay.isNight = isNight;
    if (_isReady) _gridComponent.isNightMode = isNight;
    if (isNight && !wasNight) {
      _repositionVillagersForNight();
      for (final comp in _villagerComponents) {
        comp.randomizeFacing();
      }
    }
  }

  void _repositionVillagersForNight() {
    final perHouseSlot = <int, int>{};
    for (final comp in _villagerComponents) {
      final v = comp.villager;
      if (v.houseId != null && _buildingsById.containsKey(v.houseId)) {
        final house = _buildingsById[v.houseId!]!;
        final slot = perHouseSlot[v.houseId!] ?? 0;
        perHouseSlot[v.houseId!] = slot + 1;
        final x = (house.tileX + 0.55 + slot * 0.5) * UiConstants.tilePixelSize;
        final y =
            (house.tileY + house.tileHeight - 0.5) * UiConstants.tilePixelSize;
        comp.position = Vector2(x, y);
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _constructionCheckTimer += dt;
    if (_constructionCheckTimer >= 1.0) {
      _constructionCheckTimer = 0;
      _checkConstructionCompletion();
    }
    _nightCheckTimer += dt;
    if (_nightCheckTimer >= 60.0) {
      _nightCheckTimer = 0;
      _updateNightMode();
    }
    for (final entry in _buildingComponents.entries) {
      final b = _buildingsById[entry.key];
      if (b != null && !b.isConstructed) {
        entry.value.effectiveRemaining =
            BuildingService.effectiveRemainingTime(b, _activePowerups);
      }
    }
  }

  void _checkConstructionCompletion() {
    for (var building in _buildingsById.values) {
      if (!building.isConstructed && building.isConstructionComplete) {
        onConstructionComplete?.call(building);
      }
    }
  }

  void setZoom(double zoom) {
    camera.viewfinder.zoom =
        zoom.clamp(UiConstants.minZoom, UiConstants.maxZoom);
  }

  double get currentZoom => camera.viewfinder.zoom;

  void updateGridState() {
    if (!_isReady) return;
    _gridComponent.roadTiles = _roadTiles;
    _gridComponent.specialTiles = _specialTiles;
    _gridComponent.unlockedChunks = _unlockedChunks;
    _gridComponent.showGridLines = isConstructionMode || isRoadMode;
  }

  void updateSpecialTiles(Map<String, String> tiles) {
    _specialTiles.clear();
    _specialTiles.addAll(tiles);
    if (_isReady) _gridComponent.specialTiles = _specialTiles;
  }

  void updateWalkableTiles(Set<String> tiles) {
    _walkableTiles.clear();
    _walkableTiles.addAll(tiles);
    _walkableTilesList = tiles.toList();
    for (var vc in _villagerComponents) {
      vc.roadTiles = _walkableTilesList;
    }
    for (final entry in _buildingComponents.entries) {
      final b = _buildingsById[entry.key];
      if (b != null) {
        entry.value.isRoadConnected = _isBuildingRoadConnected(b, _walkableTiles);
      }
    }
  }

  void updateRoadTiles(Set<String> roads) {
    _roadTiles.clear();
    _roadTiles.addAll(roads);
    if (_isReady) _gridComponent.roadTiles = _roadTiles;
  }

  void updateUnlockedChunks(Set<String> chunks) {
    _unlockedChunks.clear();
    _unlockedChunks.addAll(chunks);
    if (_isReady) {
      _gridComponent.unlockedChunks = _unlockedChunks;
      _updateExpansionSigns();
    }
  }

  void setHighlightedChunk(int? chunkX, int? chunkY) {
    if (!_isReady) return;
    if (chunkX != null && chunkY != null) {
      _gridComponent.highlightedChunk = '$chunkX,$chunkY';
    } else {
      _gridComponent.highlightedChunk = null;
    }
  }

  void _updateExpansionSigns() {
    final adjacentLocked = <String>{};

    for (final key in _unlockedChunks) {
      final parts = key.split(',');
      final cx = int.parse(parts[0]);
      final cy = int.parse(parts[1]);

      for (final neighbor in [
        '${cx - 1},$cy',
        '${cx + 1},$cy',
        '$cx,${cy - 1}',
        '$cx,${cy + 1}',
      ]) {
        if (_unlockedChunks.contains(neighbor)) continue;
        final np = neighbor.split(',');
        final nx = int.parse(np[0]);
        final ny = int.parse(np[1]);
        if (nx < 0 || nx >= VillageRules.chunksPerSide) continue;
        if (ny < 0 || ny >= VillageRules.chunksPerSide) continue;
        adjacentLocked.add(neighbor);
      }
    }

    final toRemove =
        _expansionSigns.keys.where((k) => !adjacentLocked.contains(k)).toList();
    for (final k in toRemove) {
      _expansionSigns[k]?.removeFromParent();
      _expansionSigns.remove(k);
    }

    for (final key in adjacentLocked) {
      if (_expansionSigns.containsKey(key)) continue;
      final parts = key.split(',');
      final cx = int.parse(parts[0]);
      final cy = int.parse(parts[1]);
      final sign = ExpansionSignComponent(
        chunkX: cx,
        chunkY: cy,
      );
      _expansionSigns[key] = sign;
      world.add(sign);
    }
  }

  bool _isBuildingRoadConnected(PlacedBuilding b, Set<String> roads) {
    for (int dx = 0; dx < b.tileWidth; dx++) {
      for (int dy = 0; dy < b.tileHeight; dy++) {
        final tx = b.tileX + dx;
        final ty = b.tileY + dy;
        for (final d in [
          [-1, 0],
          [1, 0],
          [0, -1],
          [0, 1]
        ]) {
          final nx = tx + d[0];
          final ny = ty + d[1];
          if (nx >= b.tileX &&
              nx < b.tileX + b.tileWidth &&
              ny >= b.tileY &&
              ny < b.tileY + b.tileHeight) {
            continue;
          }
          if (roads.contains('$nx,$ny')) return true;
        }
      }
    }
    return false;
  }

  void updatePlacedBuildings(List<PlacedBuilding> buildings) {
    final currentIds =
        buildings.where((b) => b.id != null).map((b) => b.id!).toSet();

    final toRemove = _buildingComponents.keys
        .where((id) => !currentIds.contains(id))
        .toList();
    for (var id in toRemove) {
      _buildingComponents[id]?.removeFromParent();
      _buildingComponents.remove(id);
    }

    _buildingsById.clear();
    for (var building in buildings) {
      if (building.id == null) continue;
      _buildingsById[building.id!] = building;

      final worldPos = Vector2(
        building.tileX * UiConstants.tilePixelSize,
        building.tileY * UiConstants.tilePixelSize,
      );
      final compSize = Vector2(
        building.tileWidth * UiConstants.tilePixelSize,
        building.tileHeight * UiConstants.tilePixelSize,
      );

      if (_buildingComponents.containsKey(building.id)) {
        final comp = _buildingComponents[building.id!]!;
        comp.updateBuilding(building);
        comp.position = worldPos;
        comp.size = compSize;
        comp.isRoadConnected = _isBuildingRoadConnected(building, _walkableTiles);
      } else {
        final comp = BuildingComponent(
          building: building,
          position: worldPos,
          size: compSize,
        );
        comp.isRoadConnected = _isBuildingRoadConnected(building, _walkableTiles);
        _buildingComponents[building.id!] = comp;
        world.add(comp);
      }
    }
  }

  void updateVillagers(
    List<Villager> villagers, {
    List<String> missingBuildingTypes = const [],
    Map<int, String> houseRoadTiles = const {},
  }) {
    if (_walkableTilesList.isEmpty) return;

    final existingById = <int, VillagerComponent>{};
    for (final comp in _villagerComponents) {
      if (comp.villager.id != null) {
        existingById[comp.villager.id!] = comp;
      }
    }

    final currentIds =
        villagers.where((v) => v.id != null).map((v) => v.id!).toSet();

    final toRemove = _villagerComponents
        .where(
          (c) => c.villager.id == null || !currentIds.contains(c.villager.id!),
        )
        .toList();
    for (final comp in toRemove) {
      comp.removeFromParent();
      _villagerComponents.remove(comp);
    }

    for (int i = 0; i < villagers.length; i++) {
      final v = villagers[i];
      // Calculate missing needs for this specific villager
      final villagerMissingNeeds = _villagerService != null
          ? _villagerService!.missingNeedsForVillager(
              v, villagers, _buildingsById.values.toList(), _walkableTiles, playerLevel)
          : missingBuildingTypes;

      if (v.id != null && existingById.containsKey(v.id!)) {
        existingById[v.id!]!.villager = v;
        existingById[v.id!]!.roadTiles = _walkableTilesList;
        existingById[v.id!]!.missingBuildingTypes = villagerMissingNeeds;
      } else {
        Vector2 spawnPos;
        if (_isNightMode &&
            v.houseId != null &&
            _buildingsById.containsKey(v.houseId)) {
          final house = _buildingsById[v.houseId!]!;
          final slot = _villagerComponents
              .where((c) => c.villager.houseId == v.houseId)
              .length;
          final x =
              (house.tileX + 0.55 + slot * 0.5) * UiConstants.tilePixelSize;
          final y = (house.tileY + house.tileHeight - 0.5) *
              UiConstants.tilePixelSize;
          spawnPos = Vector2(x, y);
        } else {
          String? spawnTile;
          if (v.houseId != null) {
            spawnTile = houseRoadTiles[v.houseId];
          }
          if (spawnTile != null) {
            final parts = spawnTile.split(',');
            spawnPos = Vector2(
              int.parse(parts[0]) * UiConstants.tilePixelSize +
                  UiConstants.tilePixelSize / 2,
              int.parse(parts[1]) * UiConstants.tilePixelSize +
                  UiConstants.tilePixelSize / 2,
            );
          } else if (v.houseId != null &&
              _buildingsById.containsKey(v.houseId)) {
            final house = _buildingsById[v.houseId!]!;
            final slot = _villagerComponents
                .where((c) => c.villager.houseId == v.houseId)
                .length;
            spawnPos = Vector2(
              (house.tileX + 0.5 + slot * 0.5) * UiConstants.tilePixelSize,
              (house.tileY + house.tileHeight) * UiConstants.tilePixelSize,
            );
          } else {
            spawnPos = Vector2(
              int.parse(_walkableTilesList[i % _walkableTilesList.length].split(',')[0]) *
                      UiConstants.tilePixelSize +
                  UiConstants.tilePixelSize / 2,
              int.parse(_walkableTilesList[i % _walkableTilesList.length].split(',')[1]) *
                      UiConstants.tilePixelSize +
                  UiConstants.tilePixelSize / 2,
            );
          }
        }

        final comp = VillagerComponent(
          villager: v,
          position: spawnPos,
          roadTiles: _walkableTilesList,
          missingBuildingTypes: villagerMissingNeeds,
          onTapped: onVillagerTapped,
        );
        _villagerComponents.add(comp);
        world.add(comp);
      }
    }
  }

  Vector2 get cameraPosition => camera.viewfinder.position;
  double get cameraZoom => camera.viewfinder.zoom;

  void setCameraForCapture(Vector2 position, double zoom) {
    camera.viewfinder.position = position;
    camera.viewfinder.zoom = zoom.clamp(0.005, 10.0);
  }

  ({int minX, int minY, int maxX, int maxY})? getOccupiedBounds() {
    int? minX, minY, maxX, maxY;

    for (final key in _roadTiles) {
      final parts = key.split(',');
      final tx = int.parse(parts[0]);
      final ty = int.parse(parts[1]);
      minX = minX == null ? tx : min(minX, tx);
      minY = minY == null ? ty : min(minY, ty);
      maxX = maxX == null ? tx : max(maxX, tx);
      maxY = maxY == null ? ty : max(maxY, ty);
    }

    for (final b in _buildingsById.values) {
      final bMinX = b.tileX;
      final bMinY = b.tileY;
      final bMaxX = b.tileX + b.tileWidth - 1;
      final bMaxY = b.tileY + b.tileHeight - 1;
      minX = minX == null ? bMinX : min(minX, bMinX);
      minY = minY == null ? bMinY : min(minY, bMinY);
      maxX = maxX == null ? bMaxX : max(maxX, bMaxX);
      maxY = maxY == null ? bMaxY : max(maxY, bMaxY);
    }

    if (minX == null) return null;
    return (minX: minX, minY: minY!, maxX: maxX!, maxY: maxY!);
  }

  void applyCameraTransform(double scale, double tx, double ty) {
    final zoom = (UiConstants.defaultZoom * scale)
        .clamp(UiConstants.minZoom, UiConstants.maxZoom);
    camera.viewfinder.zoom = zoom;

    final centerWorld =
        VillageRules.defaultAreaCenterTile * UiConstants.tilePixelSize +
            UiConstants.tilePixelSize / 2;

    final viewSize = size;
    final childCenterX = (viewSize.x / 2 - tx) / scale;
    final childCenterY = (viewSize.y / 2 - ty) / scale;

    final worldX =
        centerWorld + (childCenterX - viewSize.x / 2) / UiConstants.defaultZoom;
    final worldY =
        centerWorld + (childCenterY - viewSize.y / 2) / UiConstants.defaultZoom;

    final ws = UiConstants.worldPixelSize;
    camera.viewfinder.position = Vector2(
      worldX.clamp(0, ws),
      worldY.clamp(0, ws),
    );
  }

  void handleWorldTap(Vector2 worldPos) {
    VillagerComponent? topmost;
    for (final vc in _villagerComponents) {
      final rel = worldPos - vc.position;
      if (rel.x.abs() < vc.size.x / 2 && rel.y.abs() < vc.size.y / 2) {
        if (topmost == null || vc.priority > topmost.priority) {
          topmost = vc;
        }
      }
    }
    if (topmost != null) {
      onVillagerTapped?.call(topmost.villager);
      return;
    }

    for (final sign in _expansionSigns.values) {
      if (sign.containsWorldPoint(worldPos)) {
        onExpansionSignTapped?.call(sign.chunkX, sign.chunkY);
        return;
      }
    }

    final tileX = (worldPos.x / UiConstants.tilePixelSize).floor();
    final tileY = (worldPos.y / UiConstants.tilePixelSize).floor();

    if (tileX >= 0 &&
        tileX < VillageRules.mapSize &&
        tileY >= 0 &&
        tileY < VillageRules.mapSize) {
      onTileTapped?.call(tileX, tileY);
    }
  }
}

class NightOverlayComponent extends PositionComponent
    with HasGameReference<FlameGame> {
  static const Color _overlayColor = Color(0x40102040);

  bool isNight = false;

  NightOverlayComponent() : super(priority: 500);

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }

  @override
  void render(Canvas canvas) {
    if (!isNight) return;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = _overlayColor,
    );
  }
}

class _WorldTapHandler extends PositionComponent with TapCallbacks {
  final VillageGame gameRef;

  _WorldTapHandler(this.gameRef)
      : super(
          size: Vector2.all(UiConstants.worldPixelSize),
          position: Vector2.zero(),
          priority: -20,
        );

  @override
  void onTapUp(TapUpEvent event) {
    gameRef.handleWorldTap(event.localPosition);
  }
}
