import 'package:flutter/material.dart';
import 'package:reading_village/infrastructure/ui/config/app_theme.dart';
import 'package:reading_village/adapters/repositories/villager_favorites.dart';
import 'package:reading_village/domain/entities/villager.dart';
import 'package:reading_village/adapters/providers/village_provider.dart';
import 'package:reading_village/infrastructure/ui/widgets/common/shared_utils.dart';

void showVillagerInfoSheet(
  BuildContext context, {
  required Villager villager,
  required VillageProvider village,
  required VoidCallback onSyncGameState,
}) {
  final villagerIdx = villager.id ?? 0;

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
                '${villager.species.substring(0, 1).toUpperCase()}${villager.species.substring(1)} Villager',
                style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.lavender,
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(villager.moodText,
                  style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.darkText.withValues(alpha: 0.6))),
              SizedBox(height: 12),
              _happinessChip(villager),
              if (villager.id != null &&
                  village.villagerHasHappinessBoost(villager.id!)) ...[
                SizedBox(height: 8),
                _happinessBookBadge(village, villager),
              ],
              if (villager.happiness < 100) ...[
                SizedBox(height: 8),
                _missingNeedsBadges(village, villager),
              ],
              SizedBox(height: 16),
              _infoRow(Icons.auto_stories, 'Favorite Author',
                  VillagerFavorites.author(villagerIdx)),
              SizedBox(height: 10),
              _infoRow(Icons.format_quote, 'Favorite Quote',
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
  final controller = TextEditingController(text: villager.name);
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Rename Villager'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/images/${villager.spriteFile}',
              width: 64, height: 85, filterQuality: FilterQuality.medium),
          SizedBox(height: 12),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'New Name',
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
            onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            final newName = controller.text.trim();
            if (newName.isEmpty || villager.id == null) return;
            village.renameVillager(villager.id!, newName);
            Navigator.pop(ctx);
            onSyncGameState();
          },
          child: Text('Rename'),
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

Widget _happinessChip(Villager villager) {
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
        Text('Happiness: ${villager.happiness}%',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: color)),
      ],
    ),
  );
}

Widget _happinessBookBadge(VillageProvider village, Villager villager) {
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
        Text('Happiness Book active',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkText)),
        SizedBox(width: 8),
        Text(timeStr,
            style: TextStyle(
                fontSize: 12,
                color: AppTheme.darkText.withValues(alpha: 0.6))),
      ],
    ),
  );
}

Widget _missingNeedsBadges(VillageProvider village, Villager villager) {
  const needEmojis = {
    'water_plant': '💧',
    'power_plant': '⚡',
    'hospital': '🏥',
    'school': '🎒',
    'park': '🌳',
  };
  const needLabels = {
    'water_plant': 'Water',
    'power_plant': 'Power',
    'hospital': 'Hospital',
    'school': 'School',
    'park': 'Park',
  };
  final missing = village.missingNeedsForVillager(villager);
  if (missing.isEmpty) return SizedBox.shrink();
  return Wrap(
    spacing: 6,
    runSpacing: 4,
    alignment: WrapAlignment.center,
    children: missing.map((type) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade200, width: 1),
        ),
        child: Text(
          '${needEmojis[type] ?? '❓'} Needs ${needLabels[type] ?? type}',
          style: TextStyle(
              fontSize: 12,
              color: Colors.red.shade400,
              fontWeight: FontWeight.w600),
        ),
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
