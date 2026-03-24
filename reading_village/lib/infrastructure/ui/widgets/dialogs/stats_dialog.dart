import 'package:flutter/material.dart';
import 'package:reading_village/infrastructure/ui/config/app_theme.dart';
import 'package:reading_village/infrastructure/persistence/database_helper.dart';
import 'package:reading_village/adapters/providers/book_provider.dart';
import 'package:reading_village/adapters/providers/village_provider.dart';
import 'package:reading_village/infrastructure/ui/widgets/common/resource_icon.dart';
import 'package:reading_village/infrastructure/ui/widgets/common/shared_utils.dart';
import 'package:reading_village/infrastructure/ui/localization/context_ext.dart';

void showStatsDialog(
    BuildContext context, VillageProvider village, BookProvider bookProvider) {
  showDialog(
    context: context,
    builder: (ctx) {
      final landscape = isLandscape(ctx);
      return Dialog(
        insetPadding: EdgeInsets.symmetric(
            horizontal: landscape ? 60 : 36, vertical: landscape ? 16 : 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: EdgeInsets.all(20),
          constraints: BoxConstraints(maxHeight: 680),
          decoration: BoxDecoration(
            color: AppTheme.cream,
            borderRadius: BorderRadius.circular(24),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.bar_chart, size: 24, color: AppTheme.lavender),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(ctx.t('village_stats'),
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkText)),
                    ),
                    IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                SizedBox(height: 8),
                StatRow(
                    icon: ResourceIcon.coin(size: 28),
                    label: ctx.t('coins'),
                    value: '${village.coins}'),
                StatRow(
                    icon: ResourceIcon.gem(size: 28),
                    label: ctx.t('gems'),
                    value: '${village.gems}'),
                StatRow(
                    icon: ResourceIcon.wood(size: 28),
                    label: ctx.t('wood'),
                    value: '${village.wood}'),
                StatRow(
                    icon: ResourceIcon.metal(size: 28),
                    label: ctx.t('metal'),
                    value: '${village.metal}'),
                Divider(),
                FutureBuilder<Map<String, int>>(
                  future: _loadStats(),
                  builder: (ctx, snapshot) {
                    final stats = snapshot.data ??
                        {
                          'totalPages': 0,
                          'completedBooks': 0,
                          'totalSessions': 0,
                          'totalTimeMinutes': 0,
                        };
                    return Column(
                      children: [
                        StatRow(
                            icon: Icon(Icons.auto_stories,
                                size: 28, color: AppTheme.lavender),
                            label: ctx.t('pages_read'),
                            value: '${stats['totalPages']}'),
                        StatRow(
                            icon: Icon(Icons.menu_book,
                                size: 28, color: AppTheme.pink),
                            label: ctx.t('books_stat'),
                            value: '${bookProvider.books.length}'),
                        StatRow(
                            icon: Icon(Icons.star,
                                size: 28, color: AppTheme.coinGold),
                            label: ctx.t('completed'),
                            value: '${stats['completedBooks']}'),
                        StatRow(
                            icon: Icon(Icons.history,
                                size: 28, color: AppTheme.skyBlue),
                            label: ctx.t('sessions'),
                            value: '${stats['totalSessions']}'),
                        if ((stats['totalTimeMinutes'] ?? 0) > 0)
                          StatRow(
                              icon: Icon(Icons.timer,
                                  size: 28, color: AppTheme.mint),
                              label: ctx.t('reading_time'),
                              value:
                                  _formatTotalTime(stats['totalTimeMinutes']!)),
                      ],
                    );
                  },
                ),
                Divider(),
                StatRow(
                    icon: Icon(Icons.house, size: 28, color: AppTheme.mint),
                    label: ctx.t('buildings'),
                    value:
                        '${village.placedBuildings.where((b) => b.isConstructed).length}'),
                StatRow(
                    icon: Icon(Icons.favorite, size: 28, color: AppTheme.pink),
                    label: ctx.t('happiness'),
                    value: '${village.villageHappiness}%'),
                StatRow(
                    icon: Icon(Icons.pets, size: 28, color: AppTheme.peach),
                    label: ctx.t('villagers'),
                    value: '${village.villagers.length}'),
              ],
            ),
          ),
        ),
      );
    },
  );
}

String _formatTotalTime(int minutes) {
  if (minutes < 60) return '${minutes}m';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m > 0 ? '${h}h ${m}m' : '${h}h';
}

Future<Map<String, int>> _loadStats() async {
  final db = DatabaseHelper();
  return {
    'totalPages': await db.getTotalPagesRead(),
    'completedBooks': await db.getCompletedBooksCount(),
    'totalSessions': await db.getTotalSessionsCount(),
    'totalTimeMinutes': await db.getTotalTimeMinutes(),
  };
}

class StatRow extends StatelessWidget {
  final Widget icon;
  final String label;
  final String value;

  const StatRow(
      {super.key,
      required this.icon,
      required this.label,
      required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          icon,
          SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 15, color: AppTheme.darkText)),
          Spacer(),
          Text(value,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkText)),
        ],
      ),
    );
  }
}
