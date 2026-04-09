import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_reading_town/infrastructure/ui/config/app_theme.dart';
import 'package:my_reading_town/adapters/repositories/villager_favorites.dart';
import 'package:my_reading_town/domain/entities/villager.dart';
import 'package:my_reading_town/adapters/providers/village_provider.dart';
import 'package:my_reading_town/infrastructure/ui/widgets/common/shared_utils.dart';
import 'package:my_reading_town/infrastructure/ui/localization/language_provider.dart';

void showVillagerInfoSheet(
  BuildContext context, {
  required Villager villager,
  required VillageProvider village,
  required VoidCallback onSyncGameState,
  void Function(String buildingType)? onNeedTapped,
}) {
  final villagerIdx = villager.id ?? 0;
  final langProvider = context.read<LanguageProvider>();

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    isScrollControlled: true,
    constraints: sheetConstraints(context, portraitFrac: 0.68),
    builder: (sheetCtx) => Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewPadding.bottom),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dragHandle(),
              SizedBox(height: 16),
              Image.asset(
                'assets/images/${villager.spriteFile}',
                width: 80,
                height: 106,
                filterQuality: FilterQuality.medium,
              ),
              SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  Navigator.pop(sheetCtx);
                  showRenameVillagerDialog(context,
                      villager: villager,
                      village: village,
                      onSyncGameState: onSyncGameState);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(villager.name,
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkText)),
                    SizedBox(width: 6),
                    Icon(Icons.edit,
                        size: 18,
                        color: AppTheme.darkText.withValues(alpha: 0.5)),
                  ],
                ),
              ),
              SizedBox(height: 4),
              Text(
                '${langProvider.translate('species_${villager.species}')} ${langProvider.translate('villager_label')}',
                style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.lavender,
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                  langProvider
                      .translate('mood_${villager.moodText.toLowerCase()}'),
                  style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.darkText.withValues(alpha: 0.6))),
              SizedBox(height: 12),
              _happinessChip(villager, langProvider),
              if (villager.id != null &&
                  village.villagerHasHappinessBoost(villager.id!)) ...[
                SizedBox(height: 8),
                _happinessBookBadge(village, villager, langProvider),
              ],
              if (villager.happiness < 100) ...[
                SizedBox(height: 8),
                _missingNeedsBadges(village, villager, langProvider, sheetCtx, onNeedTapped),
              ],
              SizedBox(height: 16),
              _infoRow(
                  Icons.auto_stories,
                  langProvider.translate('favorite_author_label'),
                  VillagerFavorites.author(villagerIdx)),
              SizedBox(height: 10),
              _infoRow(
                  Icons.format_quote,
                  langProvider.translate('favorite_quote_label'),
                  '"${VillagerFavorites.quote(villagerIdx)}"'),
            ],
          ),
        ),
      ),
    ),
  );
}

void showRenameVillagerDialog(
  BuildContext context, {
  required Villager villager,
  required VillageProvider village,
  required VoidCallback onSyncGameState,
}) {
  final langProvider = context.read<LanguageProvider>();
  final controller = TextEditingController(text: villager.name);
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(langProvider.translate('rename_villager')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/images/${villager.spriteFile}',
              width: 64, height: 85, filterQuality: FilterQuality.medium),
          SizedBox(height: 12),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: langProvider.translate('new_name_label'),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            textCapitalization: TextCapitalization.words,
            autofocus: true,
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(langProvider.translate('cancel'))),
        ElevatedButton(
          onPressed: () {
            final newName = controller.text.trim();
            if (newName.isEmpty || villager.id == null) return;
            village.renameVillager(villager.id!, newName);
            Navigator.pop(ctx);
            onSyncGameState();
          },
          child: Text(langProvider.translate('rename')),
        ),
      ],
    ),
  );
}

Widget _dragHandle() {
  return Container(
    width: 40,
    height: 4,
    decoration: BoxDecoration(
      color: Colors.grey.shade300,
      borderRadius: BorderRadius.circular(2),
    ),
  );
}

Widget _happinessChip(Villager villager, LanguageProvider langProvider) {
  final color = villager.happiness >= 60
      ? Color(0xFF2E7D32)
      : villager.happiness >= 40
          ? Color(0xFFB8860B)
          : Color(0xFFC62828);
  final icon = villager.happiness >= 60
      ? Icons.sentiment_satisfied_alt
      : villager.happiness >= 40
          ? Icons.sentiment_neutral
          : Icons.sentiment_dissatisfied;

  return Container(
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      color: AppTheme.darkText.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 22, color: color),
        SizedBox(width: 8),
        Text('${langProvider.translate('happiness')}: ${villager.happiness}%',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: color)),
      ],
    ),
  );
}

Widget _happinessBookBadge(
    VillageProvider village, Villager villager, LanguageProvider langProvider) {
  final powerup = village.activePowerups.firstWhere(
    (p) =>
        p.type == 'book_happiness' &&
        p.targetVillagerId == villager.id &&
        p.isActive,
  );
  final remaining = powerup.remainingTime;
  final timeStr = formatDuration(remaining);
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: AppTheme.pink.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppTheme.pink.withValues(alpha: 0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset('assets/images/book_item.png', width: 22, height: 22),
        SizedBox(width: 8),
        Text(langProvider.translate('happiness_book_active'),
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkText)),
        SizedBox(width: 8),
        Text(timeStr,
            style: TextStyle(
                fontSize: 12, color: AppTheme.darkText.withValues(alpha: 0.6))),
      ],
    ),
  );
}

Widget _missingNeedsBadges(
    VillageProvider village,
    Villager villager,
    LanguageProvider langProvider,
    BuildContext sheetCtx,
    void Function(String buildingType)? onNeedTapped) {
  const needEmojis = {
    'water_plant': '💧',
    'power_plant': '⚡',
    'hospital': '🏥',
    'school': '🎒',
    'park': '🌳',
    'restaurant': '🍽️',
    'library': '📚',
  };
  final needLabelKeys = {
    'water_plant': 'need_water',
    'power_plant': 'need_power',
    'hospital': 'need_hospital',
    'school': 'need_school',
    'park': 'need_park',
    'restaurant': 'need_restaurant',
    'library': 'need_library',
  };
  final missing = village.missingNeedsForVillager(villager);
  if (missing.isEmpty) return SizedBox.shrink();
  return Wrap(
    spacing: 6,
    runSpacing: 4,
    alignment: WrapAlignment.center,
    children: missing.map((type) {
      final labelKey = needLabelKeys[type];
      final label = labelKey != null ? langProvider.translate(labelKey) : type;
      final tappable = onNeedTapped != null;
      final badge = Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: tappable ? Colors.red.shade100 : Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade300, width: tappable ? 1.5 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${needEmojis[type] ?? '❓'} ${langProvider.translate('needs_label')} $label',
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.red.shade400,
                  fontWeight: FontWeight.w600),
            ),
            if (tappable) ...[
              SizedBox(width: 4),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 10, color: Colors.red.shade400),
            ],
          ],
        ),
      );
      if (!tappable) return badge;
      return GestureDetector(
        onTap: () {
          Navigator.pop(sheetCtx);
          onNeedTapped(type);
        },
        child: badge,
      );
    }).toList(),
  );
}

Widget _infoRow(IconData icon, String label, String value) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 20, color: AppTheme.lavender),
      SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.darkText.withValues(alpha: 0.5))),
            SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkText)),
          ],
        ),
      ),
    ],
  );
}
