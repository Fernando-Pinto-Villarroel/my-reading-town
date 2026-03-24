import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reading_village/infrastructure/ui/config/app_theme.dart';
import 'package:reading_village/infrastructure/persistence/database_helper.dart';
import 'package:reading_village/adapters/providers/book_provider.dart';
import 'package:reading_village/adapters/providers/village_provider.dart';
import 'package:reading_village/infrastructure/ui/widgets/popups/reward_popup.dart';
import 'package:reading_village/infrastructure/ui/localization/language_provider.dart';

void showLogPagesDialog(BuildContext context, int bookId) {
  final bookProvider = context.read<BookProvider>();
  final villageProvider = context.read<VillageProvider>();
  final langProvider = context.read<LanguageProvider>();
  final pagesController = TextEditingController();
  final timeController = TextEditingController();
  final book = bookProvider.books.firstWhere((b) => b.id == bookId);
  final remainingPages = book.totalPages - book.pagesRead;

  showDialog(
    context: context,
    builder: (dialogCtx) {
      String? pagesError;
      String? timeError;
      return StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(langProvider.translate('log_reading_session')),
          content: SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(langProvider.translate('how_many_pages'),
                  style: TextStyle(
                      color: AppTheme.darkText.withValues(alpha: 0.7))),
              SizedBox(height: 4),
              Text('$remainingPages ${langProvider.translate('pages_remaining')}',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.darkText.withValues(alpha: 0.5))),
              SizedBox(height: 12),
              TextField(
                controller: pagesController,
                decoration: InputDecoration(
                  labelText: '${langProvider.translate('pages_read_label')} $remainingPages)',
                  hintText: langProvider.translate('pages_read_hint'),
                  errorText: pagesError,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.number,
                autofocus: true,
              ),
              SizedBox(height: 12),
              TextField(
                controller: timeController,
                decoration: InputDecoration(
                  labelText: langProvider.translate('time_minutes_label'),
                  hintText: langProvider.translate('time_minutes_hint'),
                  errorText: timeError,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  suffixText: langProvider.translate('time_unit'),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          )),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(langProvider.translate('cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                final pages = int.tryParse(pagesController.text.trim());
                if (pages == null || pages <= 0) {
                  setDialogState(
                      () => pagesError = langProvider.translate('enter_valid_number'));
                  return;
                }
                if (pages > remainingPages) {
                  setDialogState(() => pagesError =
                      '${langProvider.translate('cannot_exceed')} $remainingPages ${langProvider.translate('remaining_pages_suffix')}');
                  return;
                }

                int? timeMins;
                final timeText = timeController.text.trim();
                if (timeText.isNotEmpty) {
                  timeMins = int.tryParse(timeText);
                  if (timeMins == null || timeMins <= 0) {
                    setDialogState(() => timeError = langProvider.translate('enter_valid_minutes'));
                    return;
                  }
                }
                setDialogState(() => timeError = null);

                Navigator.pop(dialogCtx);

                final rewards =
                    await bookProvider.logPages(bookId, pages, timeTakenMinutes: timeMins);
                final coinsEarned = rewards['coins'] as int;
                final gemsEarned = rewards['gems'] as int;
                final woodEarned = rewards['wood'] as int;
                final metalEarned = rewards['metal'] as int;
                final expEarned = rewards['exp'] as int;

                if (context.mounted) {
                  await villageProvider.addResources(
                    coins: coinsEarned,
                    gems: gemsEarned,
                    wood: woodEarned,
                    metal: metalEarned,
                  );
                  if (expEarned > 0) {
                    await villageProvider.addExp(expEarned);
                  }
                  final db = DatabaseHelper();
                  final totalPages = await db.getTotalPagesRead();
                  final completedBooksCount =
                      await db.getCompletedBooksCount();
                  await villageProvider.checkMissions(
                      totalPagesRead: totalPages,
                      completedBooks: completedBooksCount);
                }

                if (context.mounted) {
                  _showRewardPopup(
                    context,
                    rewards['coins'] as int,
                    rewards['gems'] as int,
                    rewards['wood'] as int,
                    rewards['metal'] as int,
                    rewards['bookCompleted'] as bool,
                  );
                }
              },
              child: Text(langProvider.translate('log_button')),
            ),
          ],
        ),
      );
    },
  );
}

void _showRewardPopup(BuildContext context, int coins, int gems, int wood,
    int metal, bool bookCompleted) {
  late OverlayEntry overlayEntry;
  overlayEntry = OverlayEntry(
    builder: (context) => RewardPopup(
      coinsEarned: coins,
      gemsEarned: gems,
      woodEarned: wood,
      metalEarned: metal,
      bookCompleted: bookCompleted,
      onDismiss: () => overlayEntry.remove(),
    ),
  );
  Overlay.of(context).insert(overlayEntry);
}
