import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:reading_village/infrastructure/ui/config/app_theme.dart';

class VillagePhotoDialog extends StatefulWidget {
  final Uint8List imageBytes;

  const VillagePhotoDialog({super.key, required this.imageBytes});

  @override
  State<VillagePhotoDialog> createState() => _VillagePhotoDialogState();
}

class _VillagePhotoDialogState extends State<VillagePhotoDialog> {
  bool _saving = false;
  bool _saved = false;
  bool _sharing = false;

  Future<void> _saveToGallery() async {
    if (_saving || _saved) return;
    setState(() => _saving = true);
    try {
      if (!await Gal.hasAccess()) {
        await Gal.requestAccess();
      }
      await Gal.putImageBytes(
        widget.imageBytes,
        album: 'My Reading Town',
        name: 'village_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      if (mounted) setState(() { _saving = false; _saved = true; });
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/my_reading_village.png');
      await file.writeAsBytes(widget.imageBytes);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        text: 'My Reading Village! 📚🏡✨',
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final maxImageHeight = screenSize.height * 0.45;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cream,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            _buildImage(maxImageHeight),
            _buildCongrats(),
            _buildButtons(),
            _buildCloseButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.pink, AppTheme.lavender],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('✨', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Text(
            'Your Village!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkText,
            ),
          ),
          const SizedBox(width: 8),
          const Text('✨', style: TextStyle(fontSize: 22)),
        ],
      ),
    );
  }

  Widget _buildImage(double maxHeight) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Image.memory(
            widget.imageBytes,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildCongrats() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Text(
        'Amazing work! Keep reading to grow your village! 📚',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          color: AppTheme.darkText.withValues(alpha: 0.75),
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          Expanded(child: _buildSaveButton()),
          const SizedBox(width: 10),
          Expanded(child: _buildShareButton()),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _saveToGallery,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: _saved ? AppTheme.mint : AppTheme.skyBlue,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (_saved ? AppTheme.mint : AppTheme.skyBlue)
                  .withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_saving)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            else
              Icon(
                _saved ? Icons.check_circle : Icons.download_rounded,
                size: 20,
                color: AppTheme.darkText,
              ),
            const SizedBox(width: 6),
            Text(
              _saving ? 'Saving...' : (_saved ? 'Saved!' : 'Save'),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppTheme.darkText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareButton() {
    return GestureDetector(
      onTap: _share,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: AppTheme.pink,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.pink.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_sharing)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            else
              Icon(Icons.share_rounded, size: 20, color: AppTheme.darkText),
            const SizedBox(width: 6),
            Text(
              _sharing ? 'Sharing...' : 'Share',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppTheme.darkText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCloseButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
      child: TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(
          'Close',
          style: TextStyle(
            color: AppTheme.darkText.withValues(alpha: 0.5),
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
