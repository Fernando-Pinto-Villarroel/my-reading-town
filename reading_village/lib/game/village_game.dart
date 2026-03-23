import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Draggable, Matrix4;
import 'components/grid_component.dart';
import 'components/building_component.dart';
import 'components/villager_component.dart';
import 'components/expansion_sign_component.dart';
import '../models/placed_building.dart';
import '../models/villager.dart';
import '../config/game_constants.dart';

class VillageGame extends FlameGame {
  final Function(int tileX, int tileY)? onTileTapped;
  final Function(PlacedBuilding)? onConstructionComplete;
  final Function(Villager)? onVillagerTapped;
  final Function(int chunkX, int chunkY)? onExpansionSignTapped;

  bool isConstructionMode = false;
  bool isRoadMode = false;
  bool _isReady = false;

  late GridComponent _gridComponent;
  final Set<String> _roadTiles = {};
  final Set<String> _unlockedChunks = {};
  final Map<int, BuildingComponent> _buildingComponents = {};
  final List<VillagerComponent> _villagerComponents = [];
  final Map<String, ExpansionSignComponent> _expansionSigns = {};
  List<String> _roadTilesList = [];

  double _constructionCheckTimer = 0;
  final Map<int, PlacedBuilding> _buildingsById = {};

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
        GameConstants.defaultAreaCenterTile * GameConstants.tilePixelSize +
        GameConstants.tilePixelSize / 2;
    camera.viewfinder.position = Vector2(centerWorld, centerWorld);
    camera.viewfinder.anchor = Anchor.center;
    camera.viewfinder.zoom = GameConstants.defaultZoom;

    _gridComponent = GridComponent();
    world.add(_gridComponent);

    world.add(_WorldTapHandler(this));

    _isReady = true;
    updateGridState();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _constructionCheckTimer += dt;
    if (_constructionCheckTimer >= 1.0) {
      _constructionCheckTimer = 0;
      _checkConstructionCompletion();
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
        zoom.clamp(GameConstants.minZoom, GameConstants.maxZoom);
  }

  double get currentZoom => camera.viewfinder.zoom;

  void updateGridState() {
    if (!_isReady) return;
    _gridComponent.roadTiles = _roadTiles;
    _gridComponent.unlockedChunks = _unlockedChunks;
    _gridComponent.showGridLines = isConstructionMode || isRoadMode;
  }

  void updateRoadTiles(Set<String> roads) {
    _roadTiles.clear();
    _roadTiles.addAll(roads);
    _roadTilesList = roads.toList();
    if (_isReady) _gridComponent.roadTiles = _roadTiles;
    for (var vc in _villagerComponents) {
      vc.roadTiles = _roadTilesList;
    }
  }

  void updateUnlockedChunks(Set<String> chunks) {
    _unlockedChunks.clear();
    _unlockedChunks.addAll(chunks);
    if (_isReady) {
      _gridComponent.unlockedChunks = _unlockedChunks;
      _updateExpansionSigns();
    }
  }

  /// Sets (or clears) the highlighted chunk overlay on the grid.
  void setHighlightedChunk(int? chunkX, int? chunkY) {
    if (!_isReady) return;
    if (chunkX != null && chunkY != null) {
      _gridComponent.highlightedChunk = '$chunkX,$chunkY';
    } else {
      _gridComponent.highlightedChunk = null;
    }
  }

  /// Creates/removes expansion sign components for locked chunks adjacent to
  /// unlocked territory.
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
        if (nx < 0 || nx >= GameConstants.chunksPerSide) continue;
        if (ny < 0 || ny >= GameConstants.chunksPerSide) continue;
        adjacentLocked.add(neighbor);
      }
    }

    // Remove signs that are no longer needed
    final toRemove = _expansionSigns.keys
        .where((k) => !adjacentLocked.contains(k))
        .toList();
    for (final k in toRemove) {
      _expansionSigns[k]?.removeFromParent();
      _expansionSigns.remove(k);
    }

    // Add new signs
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
        building.tileX * GameConstants.tilePixelSize,
        building.tileY * GameConstants.tilePixelSize,
      );
      final compSize = Vector2(
        building.tileWidth * GameConstants.tilePixelSize,
        building.tileHeight * GameConstants.tilePixelSize,
      );

      if (_buildingComponents.containsKey(building.id)) {
        final comp = _buildingComponents[building.id!]!;
        comp.updateBuilding(building);
        comp.position = worldPos;
        comp.size = compSize;
      } else {
        final comp = BuildingComponent(
          building: building,
          position: worldPos,
          size: compSize,
        );
        _buildingComponents[building.id!] = comp;
        world.add(comp);
      }
    }
  }

  void updateVillagers(List<Villager> villagers, {
    List<String> missingBuildingTypes = const [],
    Map<int, String> houseRoadTiles = const {},
  }) {
    if (_roadTilesList.isEmpty) return;

    final existingById = <int, VillagerComponent>{};
    for (final comp in _villagerComponents) {
      if (comp.villager.id != null) {
        existingById[comp.villager.id!] = comp;
      }
    }

    final currentIds = villagers.where((v) => v.id != null).map((v) => v.id!).toSet();

    final toRemove = _villagerComponents.where(
      (c) => c.villager.id == null || !currentIds.contains(c.villager.id!),
    ).toList();
    for (final comp in toRemove) {
      comp.removeFromParent();
      _villagerComponents.remove(comp);
    }

    for (int i = 0; i < villagers.length; i++) {
      final v = villagers[i];
      if (v.id != null && existingById.containsKey(v.id!)) {
        existingById[v.id!]!.villager = v;
        existingById[v.id!]!.roadTiles = _roadTilesList;
        existingById[v.id!]!.missingBuildingTypes = missingBuildingTypes;
      } else {
        // Spawn at the road tile adjacent to the villager's house
        String? spawnTile;
        if (v.houseId != null) {
          spawnTile = houseRoadTiles[v.houseId];
        }
        spawnTile ??= _roadTilesList[i % _roadTilesList.length];

        final parts = spawnTile.split(',');
        final startX = int.parse(parts[0]) * GameConstants.tilePixelSize +
            GameConstants.tilePixelSize / 2;
        final startY = int.parse(parts[1]) * GameConstants.tilePixelSize +
            GameConstants.tilePixelSize / 2;

        final comp = VillagerComponent(
          villager: v,
          position: Vector2(startX, startY),
          roadTiles: _roadTilesList,
          missingBuildingTypes: missingBuildingTypes,
          onTapped: onVillagerTapped,
        );
        _villagerComponents.add(comp);
        world.add(comp);
      }
    }
  }

  /// Called by the InteractiveViewer wrapper to sync its transform to the camera.
  void applyCameraTransform(double scale, double tx, double ty) {
    final zoom = (GameConstants.defaultZoom * scale)
        .clamp(GameConstants.minZoom, GameConstants.maxZoom);
    camera.viewfinder.zoom = zoom;

    // Convert InteractiveViewer transform to world coordinates.
    // The child-space center is: (viewCenter - translation) / scale.
    // The offset from the default child center maps to world pan.
    final centerWorld =
        GameConstants.defaultAreaCenterTile * GameConstants.tilePixelSize +
        GameConstants.tilePixelSize / 2;

    final viewSize = size;
    final childCenterX = (viewSize.x / 2 - tx) / scale;
    final childCenterY = (viewSize.y / 2 - ty) / scale;

    final worldX = centerWorld + (childCenterX - viewSize.x / 2) / GameConstants.defaultZoom;
    final worldY = centerWorld + (childCenterY - viewSize.y / 2) / GameConstants.defaultZoom;

    final ws = GameConstants.worldPixelSize;
    camera.viewfinder.position = Vector2(
      worldX.clamp(0, ws),
      worldY.clamp(0, ws),
    );
  }

  void handleWorldTap(Vector2 worldPos) {
    // Check villagers first (they have higher priority)
    for (final vc in _villagerComponents) {
      final rel = worldPos - vc.position;
      if (rel.x.abs() < vc.size.x / 2 && rel.y.abs() < vc.size.y / 2) {
        onVillagerTapped?.call(vc.villager);
        return;
      }
    }

    // Check expansion signs (tappable in any mode)
    for (final sign in _expansionSigns.values) {
      if (sign.containsWorldPoint(worldPos)) {
        onExpansionSignTapped?.call(sign.chunkX, sign.chunkY);
        return;
      }
    }

    final tileX = (worldPos.x / GameConstants.tilePixelSize).floor();
    final tileY = (worldPos.y / GameConstants.tilePixelSize).floor();

    if (tileX >= 0 &&
        tileX < GameConstants.mapSize &&
        tileY >= 0 &&
        tileY < GameConstants.mapSize) {
      onTileTapped?.call(tileX, tileY);
    }
  }
}

class _WorldTapHandler extends PositionComponent with TapCallbacks {
  final VillageGame gameRef;

  _WorldTapHandler(this.gameRef)
      : super(
          size: Vector2.all(GameConstants.worldPixelSize),
          position: Vector2.zero(),
          priority: -20,
        );

  @override
  void onTapUp(TapUpEvent event) {
    gameRef.handleWorldTap(event.localPosition);
  }
}
