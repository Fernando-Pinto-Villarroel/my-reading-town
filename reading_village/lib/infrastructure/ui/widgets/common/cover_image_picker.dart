import 'dart:io';
import 'package:flutter/material.dart';
import 'package:reading_village/infrastructure/ui/config/app_theme.dart';
import 'package:reading_village/adapters/services/image_service_adapter.dart';
import 'package:reading_village/infrastructure/ui/widgets/common/skeleton.dart';

final _imageAdapter = ImageServiceAdapter();

class CoverImagePicker extends StatelessWidget {
  final String? imagePath;
  final ValueChanged<String?> onChanged;
  final bool loading;

  const CoverImagePicker({
    super.key,
    this.imagePath,
    required this.onChanged,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return GestureDetector(
        onTap: () => _showOptions(context),
        child: Stack(
          children: [
            Skeleton(width: 90, height: 130, borderRadius: 12),
            Positioned(
              top: 2,
              right: 2,
              child: GestureDetector(
                onTap: () => onChanged(null),
                child: Container(
                  padding: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => _showOptions(context),
      child: imagePath != null && imagePath!.isNotEmpty
          ? Stack(
              children: [
                SkeletonImage(
                  image: FileImage(File(imagePath!)),
                  width: 90,
                  height: 130,
                  borderRadius: 12,
                ),
                Positioned(
                  top: 2,
                  right: 2,
                  child: GestureDetector(
                    onTap: () => onChanged(null),
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            )
          : _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 90,
      height: 130,
      decoration: BoxDecoration(
        color: AppTheme.lavender.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.lavender.withValues(alpha: 0.4), width: 1.5, strokeAlign: BorderSide.strokeAlignInside),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_outlined, size: 28, color: AppTheme.lavender),
          SizedBox(height: 4),
          Text('Cover', style: TextStyle(fontSize: 11, color: AppTheme.lavender, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewPadding.bottom),
        child: Container(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
        decoration: BoxDecoration(
          color: AppTheme.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_library, color: AppTheme.lavender),
              title: Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(ctx);
                final path = await _imageAdapter.pickFromGallery();
                if (path != null) onChanged(path);
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt, color: AppTheme.pink),
              title: Text('Take a Photo'),
              onTap: () async {
                Navigator.pop(ctx);
                final path = await _imageAdapter.pickFromCamera();
                if (path != null) onChanged(path);
              },
            ),
            if (imagePath != null && imagePath!.isNotEmpty)
              ListTile(
                leading: Icon(Icons.delete_outline, color: Colors.red.shade300),
                title: Text('Remove Cover'),
                onTap: () {
                  Navigator.pop(ctx);
                  onChanged(null);
                },
              ),
          ],
        ),
      ),
      ),
    );
  }
}
