import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_reading_town/infrastructure/ui/config/app_theme.dart';
import 'package:my_reading_town/infrastructure/persistence/database_helper.dart';
import 'package:my_reading_town/adapters/providers/book_provider.dart';
import 'package:my_reading_town/adapters/providers/village_provider.dart';
import 'package:my_reading_town/infrastructure/ui/widgets/popups/reward_popup.dart';
import 'package:my_reading_town/infrastructure/ui/localization/language_provider.dart';
import 'package:my_reading_town/domain/rules/reading_rules.dart';
import 'package:intl/intl.dart';

void showLogPagesDialog(BuildContext context, int bookId) {
  final bookProvider = context.read<BookProvider>();
  final villageProvider = context.read<VillageProvider>();
  final langProvider = context.read<LanguageProvider>();
  final pagesController = TextEditingController();
  final timeController = TextEditingController();
  final book = bookProvider.books.firstWhere((b) => b.id == bookId);
  final remainingPages = book.totalPages - book.pagesRead;
  DateTime selectedDate = DateTime.now();

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
              Text(
                  '$remainingPages ${langProvider.translate('pages_remaining')}',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.darkText.withValues(alpha: 0.5))),
              SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: pagesController,
                      decoration: InputDecoration(
                        labelText:
                            '${langProvider.translate('pages_read_label')} $remainingPages)',
                        hintText: langProvider.translate('pages_read_hint'),
                        errorText: pagesError,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      keyboardType: TextInputType.number,
                      autofocus: true,
                    ),
                  ),
                  SizedBox(width: 8),
                  Tooltip(
                    message: langProvider.translate('calculator_tooltip'),
                    child: InkWell(
                      onTap: () async {
                        final result = await _showPageCalculatorModal(
                          dialogCtx,
                          langProvider,
                          book.pagesRead,
                          book.totalPages,
                        );
                        if (result != null) {
                          pagesController.text = result.toString();
                          setDialogState(() => pagesError = null);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 50,
                        height: 58,
                        decoration: BoxDecoration(
                          color: AppTheme.lavender.withValues(alpha: 0.15),
                          border: Border.all(
                              color: AppTheme.lavender.withValues(alpha: 0.5)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.calculate_rounded,
                            color: AppTheme.lavender, size: 26),
                      ),
                    ),
                  ),
                ],
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
              SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final now = DateTime.now();
                  final earliest = now.subtract(const Duration(days: 6));
                  final picked = await showDatePicker(
                    context: dialogCtx,
                    initialDate: selectedDate,
                    firstDate: DateTime(earliest.year, earliest.month, earliest.day),
                    lastDate: DateTime(now.year, now.month, now.day),
                    builder: (ctx, child) => Theme(
                      data: Theme.of(ctx).copyWith(
                        colorScheme: Theme.of(ctx).colorScheme.copyWith(
                          primary: AppTheme.lavender,
                          onPrimary: AppTheme.darkText,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) {
                    setDialogState(() => selectedDate = picked);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.lavender.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 18, color: AppTheme.lavender),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${langProvider.translate('session_date_label')}: ${selectedDate.year.toString().padLeft(4, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                          style: TextStyle(color: AppTheme.darkText, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
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
                  setDialogState(() => pagesError =
                      langProvider.translate('enter_valid_number'));
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
                    setDialogState(() => timeError =
                        langProvider.translate('enter_valid_minutes'));
                    return;
                  }
                }
                setDialogState(() => timeError = null);

                const int dailyPageLimit = ReadingRules.dailyPageLimit;
                final db = DatabaseHelper();
                final todayPages = await db.getPagesReadForDate(selectedDate);
                final formattedDate = DateFormat('MMM d, yyyy').format(selectedDate);
                if (todayPages >= dailyPageLimit) {
                  if (dialogCtx.mounted) {
                    showDialog(
                      context: dialogCtx,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        title: Text(langProvider.translate('daily_limit_title'),
                            textAlign: TextAlign.center),
                        content: Text(
                            langProvider
                                .translate('daily_limit_reached_message')
                                .replaceAll('{date}', formattedDate),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color:
                                    AppTheme.darkText.withValues(alpha: 0.8))),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(langProvider.translate('close')),
                          ),
                        ],
                      ),
                    );
                  }
                  return;
                }
                final allowedPages =
                    (dailyPageLimit - todayPages).clamp(0, pages);
                if (allowedPages < pages && dialogCtx.mounted) {
                  final confirmed = await showDialog<bool>(
                    context: dialogCtx,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      title: Text(langProvider.translate('daily_limit_title'),
                          textAlign: TextAlign.center),
                      content: Text(
                          langProvider
                              .translate('daily_limit_partial_message')
                              .replaceAll('{date}', formattedDate)
                              .replaceAll('{allowed}', '$allowedPages')
                              .replaceAll('{limit}', '$dailyPageLimit'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: AppTheme.darkText.withValues(alpha: 0.8))),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(langProvider.translate('cancel')),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(langProvider
                              .translate('log_partial_button')
                              .replaceAll('{pages}', '$allowedPages')),
                        ),
                      ],
                    ),
                  );
                  if (confirmed != true) return;
                }
                final pagesToLog = allowedPages < pages ? allowedPages : pages;
                if (pagesToLog <= 0) return;

                if (!dialogCtx.mounted) return;
                Navigator.pop(dialogCtx);

                final rewards = await bookProvider.logPages(bookId, pagesToLog,
                    timeTakenMinutes: timeMins, sessionDate: selectedDate,
                    resourceMultiplier: villageProvider.readingResourceMultiplier);
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
                  final totalPages = await db.getTotalPagesRead();
                  final completedBooksCount = await db.getCompletedBooksCount();
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
                    rewards['rewardablePages'] as int,
                    bookId: bookId,
                    bookProvider: bookProvider,
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

Future<int?> _showPageCalculatorModal(
  BuildContext context,
  LanguageProvider langProvider,
  int pagesAlreadyRead,
  int totalPages,
) {
  final currentPageController = TextEditingController();
  return showDialog<int>(
    context: context,
    builder: (ctx) {
      String? calcError;
      return StatefulBuilder(
        builder: (ctx, setCalcState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: AppTheme.cream,
          title: Row(
            children: [
              Icon(Icons.calculate_rounded, color: AppTheme.lavender, size: 24),
              SizedBox(width: 8),
              Text(
                langProvider.translate('calculator_title'),
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkText),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                langProvider.translate('calculator_subtitle')
                    .replaceAll('{read}', '$pagesAlreadyRead')
                    .replaceAll('{total}', '$totalPages'),
                style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.darkText.withValues(alpha: 0.65)),
              ),
              SizedBox(height: 14),
              TextField(
                controller: currentPageController,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: langProvider.translate('calculator_page_label'),
                  hintText: '${pagesAlreadyRead + 1}',
                  errorText: calcError,
                  border:
                      OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: AppTheme.lavender.withValues(alpha: 0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.lavender),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(langProvider.translate('cancel'),
                  style: TextStyle(color: AppTheme.darkText.withValues(alpha: 0.6))),
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.check_rounded, size: 18),
              label: Text(langProvider.translate('calculator_calculate')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.lavender,
                foregroundColor: AppTheme.darkText,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final currentPage =
                    int.tryParse(currentPageController.text.trim());
                if (currentPage == null || currentPage <= 0) {
                  setCalcState(() => calcError =
                      langProvider.translate('calculator_error_invalid'));
                  return;
                }
                if (currentPage <= pagesAlreadyRead) {
                  setCalcState(() => calcError =
                      langProvider.translate('calculator_error_already_read'));
                  return;
                }
                if (currentPage > totalPages) {
                  setCalcState(() => calcError =
                      langProvider.translate('calculator_error_exceeds_total'));
                  return;
                }
                Navigator.pop(ctx, currentPage - pagesAlreadyRead);
              },
            ),
          ],
        ),
      );
    },
  );
}

void _showRewardPopup(BuildContext context, int coins, int gems, int wood,
    int metal, bool bookCompleted, int rewardablePages,
    {int? bookId, BookProvider? bookProvider}) {
  late OverlayEntry overlayEntry;
  overlayEntry = OverlayEntry(
    builder: (context) => RewardPopup(
      coinsEarned: coins,
      gemsEarned: gems,
      woodEarned: wood,
      metalEarned: metal,
      bookCompleted: bookCompleted,
      rewardablePages: rewardablePages,
      onDismiss: () {
        overlayEntry.remove();
        if (bookCompleted && bookId != null && bookProvider != null && context.mounted) {
          _showRatingDialog(context, bookId, bookProvider);
        }
      },
    ),
  );
  Overlay.of(context).insert(overlayEntry);
}

void _showRatingDialog(BuildContext context, int bookId, BookProvider bookProvider) {
  int selectedRating = 0;
  final langProvider = context.read<LanguageProvider>();

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppTheme.cream,
        title: Column(
          children: [
            Text(
              langProvider.translate('rate_your_book'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkText,
              ),
            ),
            SizedBox(height: 4),
            Text(
              langProvider.translate('rate_book_subtitle'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.darkText.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final starValue = i + 1;
            return GestureDetector(
              onTap: () => setState(() => selectedRating = starValue),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  selectedRating >= starValue ? Icons.star : Icons.star_border,
                  size: 40,
                  color: AppTheme.coinGold,
                ),
              ),
            );
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              langProvider.translate('skip_rating'),
              style: TextStyle(color: AppTheme.darkText.withValues(alpha: 0.6)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (selectedRating > 0) {
                await bookProvider.rateBook(bookId, selectedRating);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.coinGold,
              foregroundColor: AppTheme.darkText,
            ),
            child: Text(langProvider.translate('save_rating')),
          ),
        ],
      ),
    ),
  );
}
