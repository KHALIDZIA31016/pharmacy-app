import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Picks a product photo (camera or gallery) and stores a permanent copy in
/// the app's documents folder, so the path saved in SQLite stays valid.
class ImageStore {
  static final _picker = ImagePicker();

  /// Returns the saved file path, or null if the user cancelled.
  static Future<String?> pick(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1024,
      imageQuality: 80,
    );
    if (picked == null) return null;

    final dir = Directory(
      p.join((await getApplicationDocumentsDirectory()).path, 'supply_images'),
    );
    await dir.create(recursive: true);
    final ext = p.extension(picked.path).isEmpty
        ? '.jpg'
        : p.extension(picked.path);
    final target = p.join(
      dir.path,
      '${DateTime.now().microsecondsSinceEpoch}$ext',
    );
    await File(picked.path).copy(target);
    return target;
  }
}
