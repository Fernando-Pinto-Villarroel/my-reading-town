import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:my_reading_town/infrastructure/ui/config/app_theme.dart';
import 'package:my_reading_town/domain/rules/village_rules.dart';
import 'package:my_reading_town/infrastructure/ui/widgets/common/resource_icon.dart';
import 'package:my_reading_town/infrastructure/ui/localization/context_ext.dart';

class LevelUpPopup extends StatefulWidget {
  final int newLevel;
  final VoidCallback onDismiss;

  const LevelUpPopup({
    super.key,
    required this.newLevel,
    required this.onDismiss,
  });

  @override
  State<LevelUpPopup> createState() => _LevelUpPopupState();
}

class _LevelUpPopupState extends State<LevelUpPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.bounceOut,
    );
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _animController.forward();
    _confettiController.play();
  }

  @override
  void dispose() {
    _animController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final level = widget.newLevel;
    final buildingTypes = VillageRules.buildingTemplates
        .map((t) => t['type'] as String)
        .where((type) => VillageRules.minLevelForBuilding(type) <= level)
        .toList();

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: widget.onDismiss,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                particleDrag: 0.05,
                emissionFrequency: 0.04,
                numberOfParticles: 35,
                gravity: 0.15,
                colors: const [
                  AppTheme.pink,
                  AppTheme.lavender,
                  AppTheme.mint,
                  AppTheme.coinGold,
                  AppTheme.peach,
                  AppTheme.skyBlue,
                ],
              ),
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 16),
                  constraints: const BoxConstraints(maxWidth: 360),
                  decoration: BoxDecoration(
                    color: AppTheme.cream,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.lavender.withAlpha(100),
                        blurRadius: 24,
                        spreadRadius: 6,
                      ),
                    ],
                    border: Border.all(
                        color: AppTheme.lavender.withAlpha(120), width: 2),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: GestureDetector(
                          onTap: widget.onDismiss,
                          child:
                              Icon(Icons.close, size: 20, color: Colors.grey),
                        ),
                      ),
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [AppTheme.lavender, AppTheme.pink],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Icon(Icons.star_rounded,
                            size: 36, color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          context.t('level_up_title'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.lavender,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${context.t('level_label')} $level',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.darkText,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.gemPurple.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppTheme.gemPurple.withAlpha(60)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ResourceIcon.gem(size: 24),
                            const SizedBox(width: 8),
                            Text(
                              context.t('plus_gems_reward'),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.gemPurple,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        context.t('building_limits'),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.darkText.withAlpha(180),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        alignment: WrapAlignment.center,
                        children: buildingTypes.map((type) {
                          final max =
                              VillageRules.maxBuildingsOfTypeForPlayerLevel(
                                  type, level);
                          final prevMax =
                              VillageRules.maxBuildingsOfTypeForPlayerLevel(
                                  type, level - 1);
                          final increased = max > prevMax;
                          final template = VillageRules.findTemplate(type);
                          final name = context.t('building_name_$type',
                              fallback: template?['name'] as String? ?? type);
                          return Container(
                            width: 95,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 6),
                            decoration: BoxDecoration(
                              color: increased
                                  ? AppTheme.mint.withAlpha(40)
                                  : AppTheme.softWhite,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: increased
                                    ? AppTheme.darkMint.withAlpha(100)
                                    : Colors.grey.shade200,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/images/$type.png',
                                  width: 32,
                                  height: 32,
                                  filterQuality: FilterQuality.medium,
                                  errorBuilder: (_, __, ___) => Icon(Icons.home,
                                      size: 32, color: AppTheme.mint),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  name,
                                  style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.darkText),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                increased
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text('$prevMax ',
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.darkMint)),
                                          Icon(Icons.arrow_forward_rounded,
                                              size: 12,
                                              color: AppTheme.darkMint),
                                          Text(' $max',
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.darkMint)),
                                        ],
                                      )
                                    : Text(
                                        '${context.t('max_label')} $max',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              AppTheme.darkText.withAlpha(140),
                                        ),
                                      ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        context.t('tap_anywhere'),
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }
}
