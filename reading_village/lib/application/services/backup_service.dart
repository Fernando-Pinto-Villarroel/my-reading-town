import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:reading_village/infrastructure/persistence/database_helper.dart';

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
    final file = File('${tempDir.path}/reading_village_backup_$timestamp.json');
    await file.writeAsString(jsonString);
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Reading Village Backup',
    );
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
    final data = json.decode(jsonString) as Map<String, dynamic>;
    if (!data.containsKey('version') || !data.containsKey('books')) {
      throw const FormatException('Invalid backup file format');
    }
    await _db.importAllTables(data);
    return true;
  }

  Future<void> resetData() async {
    await _db.resetDatabase();
  }
}
