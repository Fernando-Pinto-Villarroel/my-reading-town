import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reading_village/infrastructure/ui/config/app_theme.dart';
import 'package:reading_village/adapters/providers/village_provider.dart';

class LeftActionGrid extends StatelessWidget {
  final bool landscape;
  final bool isConstructionMode;
  final VoidCallback onConstructionTap;
  final VoidCallback onMissionsTap;
  final VoidCallback onBackpackTap;
  final VoidCallback onMinigamesTap;

  const LeftActionGrid({
    super.key,
    required this.landscape,
    required this.isConstructionMode,
    required this.onConstructionTap,
    required this.onMissionsTap,
    required this.onBackpackTap,
    required this.onMinigamesTap,
  });

  @override
  Widget build(BuildContext context) {
    final btnSize = landscape ? 42.0 : 48.0;
    const gap = 6.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                _ActionButton(
                  icon: Icons.flag,
                  color: AppTheme.gemPurple,
                  size: btnSize,
                  onTap: onMissionsTap,
                ),
                if (context
                        .watch<VillageProvider>()
                        .unclaimedCompletedMissionCount >
                    0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: gap),
            _ActionButton(
              icon: Icons.house,
              color: AppTheme.mediumOrange,
              size: btnSize,
              isActive: isConstructionMode,
              onTap: onConstructionTap,
            ),
          ],
        ),
        SizedBox(height: gap),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ActionButton(
              icon: Icons.backpack,
              color: AppTheme.mediumMint,
              size: btnSize,
              onTap: onBackpackTap,
            ),
            SizedBox(width: gap),
            _ActionButton(
              icon: Icons.sports_esports,
              color: AppTheme.darkSkyBlue,
              size: btnSize,
              onTap: onMinigamesTap,
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final bool isActive;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.size,
    this.isActive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isActive ? AppTheme.mint.withValues(alpha: 0.9) : color,
          borderRadius: BorderRadius.circular(14),
          border: isActive ? Border.all(color: Colors.white, width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 26, color: Colors.white),
      ),
    );
  }
}
