import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;
import 'package:my_reading_town/domain/ports/image_port.dart';

class ImageServiceAdapter implements ImagePort {
  final ImagePicker _picker = ImagePicker();

  @override
  Future<String?> pickFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
      maxHeight: 900,
      imageQuality: 85,
    );
    if (image == null) return null;
    return _saveToAppDir(File(image.path));
  }

  @override
  Future<String?> pickFromCamera() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 600,
      maxHeight: 900,
      imageQuality: 85,
    );
    if (image == null) return null;
    return _saveToAppDir(File(image.path));
  }

  @override
  Future<String?> saveImageFromUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return null;
      final dir = await getApplicationDocumentsDirectory();
      final coverDir = Directory(p.join(dir.path, 'book_covers'));
      if (!coverDir.existsSync()) coverDir.createSync(recursive: true);
      final filename = 'cover_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File(p.join(coverDir.path, filename));
      await file.writeAsBytes(response.bodyBytes);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> deleteImage(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  Future<String> _saveToAppDir(File source) async {
    final dir = await getApplicationDocumentsDirectory();
    final coverDir = Directory(p.join(dir.path, 'book_covers'));
    if (!coverDir.existsSync()) coverDir.createSync(recursive: true);
    final ext =
        p.extension(source.path).isNotEmpty ? p.extension(source.path) : '.jpg';
    final filename = 'cover_${DateTime.now().millisecondsSinceEpoch}$ext';
    final dest = File(p.join(coverDir.path, filename));
    await source.copy(dest.path);
    return dest.path;
  }
}
