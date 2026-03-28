import 'package:flutter/material.dart';
import 'package:my_reading_town/infrastructure/ui/config/app_theme.dart';

class SideMenu extends StatelessWidget {
  final bool menuOpen;
  final VoidCallback onToggleMenu;
  final VoidCallback onReadingTap;
  final VoidCallback onStatsTap;
  final VoidCallback onSettingsTap;
  final VoidCallback onPhotoTap;
  final GlobalKey? readingButtonKey;
  final GlobalKey? photoButtonKey;
  final GlobalKey? statsButtonKey;
  final GlobalKey? settingsButtonKey;

  const SideMenu({
    super.key,
    required this.menuOpen,
    required this.onToggleMenu,
    required this.onReadingTap,
    required this.onStatsTap,
    required this.onSettingsTap,
    required this.onPhotoTap,
    this.readingButtonKey,
    this.photoButtonKey,
    this.statsButtonKey,
    this.settingsButtonKey,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(key: readingButtonKey, child: _ReadingButton(onTap: onReadingTap)),
            SizedBox(width: 6),
            DropdownToggleButton(isOpen: menuOpen, onTap: onToggleMenu),
          ],
        ),
        if (menuOpen) ...[
          SizedBox(height: 6),
          SizedBox(
            key: photoButtonKey,
            child: SideMenuButton(
              icon: Icons.camera_alt,
              isActive: false,
              onTap: onPhotoTap,
            ),
          ),
          SizedBox(height: 6),
          SizedBox(
            key: statsButtonKey,
            child: SideMenuButton(
              icon: Icons.bar_chart,
              isActive: false,
              onTap: onStatsTap,
            ),
          ),
          SizedBox(height: 6),
          SizedBox(
            key: settingsButtonKey,
            child: SideMenuButton(
              icon: Icons.settings,
              isActive: false,
              onTap: onSettingsTap,
            ),
          ),
        ],
      ],
    );
  }
}

class SideMenuButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const SideMenuButton({
    super.key,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.mint.withValues(alpha: 0.9)
              : const Color(0xAA000000),
          borderRadius: BorderRadius.circular(14),
          border: isActive ? Border.all(color: Colors.white, width: 2) : null,
        ),
        child: Icon(icon,
            size: 26, color: isActive ? AppTheme.darkText : Colors.white),
      ),
    );
  }
}

class _ReadingButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ReadingButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(Icons.menu_book, size: 26, color: Colors.white),
      ),
    );
  }
}

class DropdownToggleButton extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onTap;

  const DropdownToggleButton(
      {super.key, required this.isOpen, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(isOpen ? Icons.close : Icons.apps,
            size: 26, color: Colors.white),
      ),
    );
  }
}
