import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:my_reading_town/infrastructure/persistence/database_helper.dart';

class BackupService {
  final DatabaseHelper _db;

  BackupService(this._db);

  Future<void> exportData() async {
    final data = await _db.exportAllTables();
    final jsonString = const JsonEncoder.withIndent('  ').convert(data);
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final file = File('${tempDir.path}/my_reading_town_backup_$timestamp.json');
    await file.writeAsString(jsonString);
    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path)],
      text: 'My Reading Town Backup',
    ));
  }

  static const List<String> _requiredTables = [
    'books',
    'villagers',
    'placed_buildings',
    'game_state',
    'resources',
  ];

  static const List<String> _allTables = [
    'books',
    'tags',
    'book_tags',
    'reading_sessions',
    'resources',
    'villagers',
    'placed_buildings',
    'road_tiles',
    'unlocked_chunks',
    'game_state',
    'inventory_items',
    'minigame_cooldowns',
    'active_powerups',
    'mission_progress',
  ];

  String? _validateBackup(Map<String, dynamic> data) {
    if (!data.containsKey('version')) return 'missing_version';
    final version = data['version'];
    if (version is! int || version < 1) return 'invalid_version';
    for (final table in _requiredTables) {
      if (!data.containsKey(table)) return 'missing_table';
      if (data[table] is! List) return 'invalid_table_format';
    }
    for (final key in data.keys) {
      if (key == 'version' || key == 'exported_at') continue;
      if (!_allTables.contains(key)) return 'unknown_table';
      if (data[key] is! List) return 'invalid_table_format';
    }
    return null;
  }

  Future<bool> importData() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) return false;
    final filePath = result.files.single.path;
    if (filePath == null) return false;
    final jsonString = await File(filePath).readAsString();
    late Map<String, dynamic> data;
    try {
      data = json.decode(jsonString) as Map<String, dynamic>;
    } catch (_) {
      throw const FormatException('invalid_backup_not_json');
    }
    final error = _validateBackup(data);
    if (error != null) throw FormatException(error);
    await _db.importAllTables(data);
    return true;
  }

  Future<void> resetData() async {
    await _db.resetDatabase();
  }
}
