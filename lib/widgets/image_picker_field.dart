import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/ui.dart';
import '../data/services/image_store.dart';

/// Bottom sheet to take a photo or pick from the gallery.
/// Returns the saved file path, '' when the user chose "Remove", or null if
/// cancelled / failed.
Future<String?> chooseImage(
  BuildContext context, {
  bool canRemove = false,
}) async {
  final action = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Take a photo'),
            onTap: () => Navigator.pop(ctx, 'camera'),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.pop(ctx, 'gallery'),
          ),
          if (canRemove)
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: AppColors.danger,
              ),
              title: const Text('Remove photo'),
              onTap: () => Navigator.pop(ctx, 'remove'),
            ),
        ],
      ),
    ),
  );
  if (action == null) return null;
  if (action == 'remove') return '';
  try {
    return await ImageStore.pick(
      action == 'camera' ? ImageSource.camera : ImageSource.gallery,
    );
  } catch (_) {
    if (context.mounted) {
      showSnack(context, 'Could not open the $action.', error: true);
    }
    return null;
  }
}

/// Photo box: tap to choose Camera or Gallery, with a remove option.
class ImagePickerField extends StatelessWidget {
  final String? path;
  final ValueChanged<String?> onChanged;

  const ImagePickerField({
    super.key,
    required this.path,
    required this.onChanged,
  });

  Future<void> _choose(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            if (path != null)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: AppColors.danger,
                ),
                title: const Text('Remove photo'),
                onTap: () => Navigator.pop(ctx, 'remove'),
              ),
          ],
        ),
      ),
    );
    if (action == null) return;
    if (action == 'remove') return onChanged(null);
    try {
      final saved = await ImageStore.pick(
        action == 'camera' ? ImageSource.camera : ImageSource.gallery,
      );
      if (saved != null) onChanged(saved);
    } catch (_) {
      if (context.mounted) {
        showSnack(
          context,
          'Could not open the ${action == 'camera' ? 'camera' : 'gallery'}.',
          error: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _choose(context),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 130,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
        ),
        child: path == null
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo_outlined,
                    size: 32,
                    color: AppColors.primary,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add product photo',
                    style: TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Camera or gallery',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(File(path!), fit: BoxFit.cover),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
