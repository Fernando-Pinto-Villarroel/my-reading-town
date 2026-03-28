import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_reading_town/infrastructure/ui/config/app_theme.dart';
import 'package:my_reading_town/domain/rules/village_rules.dart';
import 'package:my_reading_town/adapters/providers/village_provider.dart';
import 'package:my_reading_town/infrastructure/ui/screens/guess_author_screen.dart';
import 'package:my_reading_town/infrastructure/ui/screens/match_character_role_screen.dart';
import 'package:my_reading_town/infrastructure/ui/widgets/common/shared_utils.dart';
import 'package:my_reading_town/infrastructure/ui/localization/language_provider.dart';

void showMinigamesDialog(
  BuildContext context, {
  required VillageProvider village,
  required VoidCallback onReturn,
}) {
  final langProvider = context.read<LanguageProvider>();

  showDialog(
    context: context,
    builder: (ctx) {
      final landscape = isLandscape(ctx);
      return Dialog(
        insetPadding: EdgeInsets.symmetric(
            horizontal: landscape ? 24 : 6, vertical: landscape ? 16 : 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cream,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.sports_esports,
                      size: 24, color: AppTheme.lavender),
                  const SizedBox(width: 8),
                  Text(langProvider.translate('minigames'),
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkText)),
                  const Spacer(),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 16),
              MinigameCard(
                icon: Icons.auto_stories,
                title: langProvider.translate('guess_the_author'),
                subtitle: langProvider.translate('guess_author_desc'),
                color: AppTheme.mint,
                darkColor: AppTheme.darkMint,
                minigameId: 'guess_author',
                village: village,
                onPlay: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const GuessAuthorScreen()),
                  ).then((_) => onReturn());
                },
              ),
              const SizedBox(height: 12),
              MinigameCard(
                icon: Icons.person_search,
                title: langProvider.translate('match_character_role'),
                subtitle: langProvider.translate('match_role_desc'),
                color: AppTheme.skyBlue,
                darkColor: AppTheme.darkSkyBlue,
                minigameId: 'match_character_role',
                village: village,
                onPlay: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MatchCharacterRoleScreen()),
                  ).then((_) => onReturn());
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

class MinigameCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color darkColor;
  final String minigameId;
  final VillageProvider village;
  final VoidCallback onPlay;

  const MinigameCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.darkColor,
    required this.minigameId,
    required this.village,
    required this.onPlay,
  });

  int get winsNeeded => VillageRules.minigames[minigameId]!.winsNeeded;

  @override
  Widget build(BuildContext context) {
    final langProvider = context.read<LanguageProvider>();
    final isOnCooldown = village.isMinigameOnCooldown(minigameId);
    final remaining = village.minigameCooldownRemaining(minigameId);

    return GestureDetector(
      onTap: isOnCooldown ? null : onPlay,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isOnCooldown
              ? Colors.grey.shade200
              : color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isOnCooldown
                ? Colors.grey.shade300
                : color.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isOnCooldown
                    ? Colors.grey.shade300
                    : color.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon,
                  size: 28,
                  color: isOnCooldown ? Colors.grey : AppTheme.darkText),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color:
                              isOnCooldown ? Colors.grey : AppTheme.darkText)),
                  Text(
                    isOnCooldown
                        ? '${langProvider.translate('cooldown_label')} ${formatDuration(remaining)}'
                        : subtitle,
                    style: TextStyle(
                        fontSize: 12,
                        color: isOnCooldown
                            ? Colors.grey
                            : AppTheme.darkText.withValues(alpha: 0.6)),
                  ),
                  Text(
                      '${langProvider.translate('win_in_row_prefix')} $winsNeeded ${langProvider.translate('win_in_row_suffix')}',
                      style: TextStyle(
                          fontSize: 11,
                          color:
                              isOnCooldown ? Colors.grey.shade400 : darkColor,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            if (isOnCooldown)
              Icon(Icons.lock, size: 24, color: Colors.grey.shade400)
            else
              Icon(Icons.play_circle_fill, size: 32, color: darkColor),
          ],
        ),
      ),
    );
  }
}
