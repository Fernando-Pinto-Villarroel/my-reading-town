import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:my_reading_town/domain/entities/book.dart';
import 'package:my_reading_town/domain/entities/reading_session.dart';
import 'package:my_reading_town/adapters/providers/book_provider.dart';
import 'package:my_reading_town/infrastructure/ui/config/app_theme.dart';
import 'package:my_reading_town/infrastructure/ui/widgets/common/skeleton.dart';
import 'package:my_reading_town/infrastructure/ui/localization/context_ext.dart';
import 'package:my_reading_town/infrastructure/ui/localization/language_provider.dart';

class BookCard extends StatefulWidget {
  final Book book;
  final VoidCallback onLogPages;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  const BookCard({
    super.key,
    required this.book,
    required this.onLogPages,
    this.onTap,
    this.onEdit,
  });

  @override
  State<BookCard> createState() => _BookCardState();
}

class _BookCardState extends State<BookCard> {
  bool _sessionsExpanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCover(),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.book.title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.darkText,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (widget.book.isCompleted)
                              Container(
                                margin: EdgeInsets.only(left: 6),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color:
                                      AppTheme.coinGold.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.star,
                                        size: 12, color: AppTheme.coinGold),
                                    SizedBox(width: 2),
                                    Text(context.t('done'),
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.darkText)),
                                  ],
                                ),
                              ),
                            if (widget.onEdit != null)
                              GestureDetector(
                                onTap: widget.onEdit,
                                child: Padding(
                                  padding: EdgeInsets.only(left: 6),
                                  child: Icon(Icons.edit,
                                      size: 18, color: AppTheme.lavender),
                                ),
                              ),
                          ],
                        ),
                        if (widget.book.author != null &&
                            widget.book.author!.isNotEmpty) ...[
                          SizedBox(height: 2),
                          Text(
                            widget.book.author!,
                            style: TextStyle(
                                fontSize: 12,
                                color:
                                    AppTheme.darkText.withValues(alpha: 0.6)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (widget.book.tags.isNotEmpty) ...[
                          SizedBox(height: 4),
                          Wrap(
                            spacing: 4,
                            runSpacing: 2,
                            children: widget.book.tags.map((tag) {
                              return Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Color(tag.colorValue)
                                      .withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  tag.title,
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.darkText),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                        SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: widget.book.progress,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              widget.book.isCompleted
                                  ? AppTheme.coinGold
                                  : AppTheme.lavender,
                            ),
                            minHeight: 8,
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${widget.book.pagesRead} / ${widget.book.totalPages} ${context.t('pages_label')}',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.darkText
                                        .withValues(alpha: 0.7)),
                              ),
                            ),
                            if (!widget.book.isCompleted)
                              SizedBox(
                                height: 28,
                                child: ElevatedButton.icon(
                                  onPressed: widget.onLogPages,
                                  icon: Icon(Icons.menu_book, size: 14),
                                  label: Text(context.t('log_pages'),
                                      style: TextStyle(fontSize: 12)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.pink,
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 10),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Consumer<BookProvider>(
                          builder: (ctx, bp, _) {
                            final total = bp
                                .sessionsForBook(widget.book.id!)
                                .where((s) => s.timeTakenMinutes != null)
                                .fold(0, (sum, s) => sum + s.timeTakenMinutes!);
                            if (total == 0) return SizedBox.shrink();
                            final display = total >= 60
                                ? '${total ~/ 60}h ${total % 60 > 0 ? '${total % 60}m' : ''}'
                                    .trim()
                                : '${total}m';
                            return Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Row(
                                children: [
                                  Icon(Icons.timer,
                                      size: 12, color: AppTheme.darkMint),
                                  SizedBox(width: 3),
                                  Text(
                                    '${context.t('total_time_label')} $display',
                                    style: TextStyle(
                                        fontSize: 11, color: AppTheme.darkMint),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              _buildSessionsSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionsSection(BuildContext context) {
    return Consumer<BookProvider>(
      builder: (ctx, bookProvider, _) {
        final sessions = bookProvider.sessionsForBook(widget.book.id!);
        if (sessions.isEmpty) return SizedBox.shrink();

        final sessionLabel = sessions.length == 1
            ? context.t('reading_session_singular')
            : context.t('reading_sessions_plural');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8),
            Divider(height: 1, color: Colors.grey.shade200),
            GestureDetector(
              onTap: () =>
                  setState(() => _sessionsExpanded = !_sessionsExpanded),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(Icons.history, size: 16, color: AppTheme.lavender),
                    SizedBox(width: 4),
                    Text(
                      '${sessions.length} $sessionLabel',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.lavender,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Spacer(),
                    Icon(
                      _sessionsExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 24,
                      color: AppTheme.lavender,
                    ),
                  ],
                ),
              ),
            ),
            if (_sessionsExpanded)
              SizedBox(
                height: 220,
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: sessions.length,
                  itemBuilder: (ctx, i) => _SessionRow(
                    session: sessions[i],
                    bookId: widget.book.id!,
                    totalPages: widget.book.totalPages,
                    otherSessionsPages: sessions
                        .where((s) => s.id != sessions[i].id)
                        .fold(0, (sum, s) => sum + s.pagesRead),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCover() {
    if (widget.book.coverImagePath != null &&
        widget.book.coverImagePath!.isNotEmpty) {
      return SkeletonImage(
        image: FileImage(File(widget.book.coverImagePath!)),
        width: 48,
        height: 68,
        borderRadius: 8,
      );
    }
    return _placeholderCover();
  }

  Widget _placeholderCover() {
    return Container(
      width: 48,
      height: 68,
      decoration: BoxDecoration(
        color: AppTheme.lavender.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.menu_book, size: 24, color: AppTheme.lavender),
    );
  }
}

class _SessionRow extends StatelessWidget {
  final ReadingSession session;
  final int bookId;
  final int totalPages;
  final int otherSessionsPages;

  const _SessionRow({
    required this.session,
    required this.bookId,
    required this.totalPages,
    required this.otherSessionsPages,
  });

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      return DateFormat('MMM d, yyyy').format(dt);
    } catch (_) {
      return isoDate;
    }
  }

  String _formatTime(int minutes) {
    if (minutes >= 60) {
      final h = minutes ~/ 60;
      final m = minutes % 60;
      return m > 0 ? '${h}h ${m}m' : '${h}h';
    }
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final bookProvider = context.read<BookProvider>();

    return Container(
      margin: EdgeInsets.only(bottom: 6),
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.lavender.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(session.date),
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.darkText.withValues(alpha: 0.5),
                  ),
                ),
                SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.menu_book, size: 12, color: AppTheme.lavender),
                    SizedBox(width: 3),
                    Text(
                      '${session.pagesRead} ${context.t('pages_label')}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkText,
                      ),
                    ),
                    if (session.timeTakenMinutes != null) ...[
                      SizedBox(width: 8),
                      Icon(Icons.timer,
                          size: 12,
                          color: AppTheme.mint.withValues(alpha: 0.8)),
                      SizedBox(width: 3),
                      Text(
                        _formatTime(session.timeTakenMinutes!),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.darkMint,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit_outlined, size: 20, color: AppTheme.lavender),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () => _showEditDialog(context, bookProvider),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline,
                size: 20, color: Colors.red.shade300),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () => _confirmDelete(context, bookProvider),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, BookProvider bookProvider) {
    final langProvider = context.read<LanguageProvider>();
    final pagesController = TextEditingController(text: '${session.pagesRead}');
    final timeController = TextEditingController(
        text: session.timeTakenMinutes != null
            ? '${session.timeTakenMinutes}'
            : '');
    final maxPages = otherSessionsPages + session.pagesRead > totalPages
        ? totalPages - otherSessionsPages
        : totalPages - otherSessionsPages;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        String? pagesError;
        String? timeError;
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(langProvider.translate('edit_session')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: pagesController,
                  decoration: InputDecoration(
                    labelText:
                        '${langProvider.translate('pages_read_label')} $maxPages)',
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
                    hintText: langProvider.translate('leave_empty_to_clear'),
                    errorText: timeError,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    suffixText: langProvider.translate('time_unit'),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
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
                  if (pages > maxPages) {
                    setDialogState(() => pagesError =
                        '${langProvider.translate('cannot_exceed')} $maxPages ${langProvider.translate('pages_label')}');
                    return;
                  }

                  int? timeMins;
                  final timeText = timeController.text.trim();
                  if (timeText.isNotEmpty) {
                    timeMins = int.tryParse(timeText);
                    if (timeMins == null || timeMins <= 0) {
                      setDialogState(() => timeError =
                          langProvider.translate('enter_valid_number'));
                      return;
                    }
                  }
                  setDialogState(() => timeError = null);

                  Navigator.pop(dialogCtx);
                  try {
                    await bookProvider.editSession(
                        session.id!, bookId, pages, timeMins);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                '${langProvider.translate('error_prefix')}${e.toString()}')),
                      );
                    }
                  }
                },
                child: Text(langProvider.translate('save')),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, BookProvider bookProvider) {
    final langProvider = context.read<LanguageProvider>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(langProvider.translate('delete_session_title')),
        content: Text(
            '${langProvider.translate('delete_session_confirm_prefix')} ${session.pagesRead} ${langProvider.translate('delete_session_confirm_suffix')}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(langProvider.translate('cancel')),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red.shade300),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await bookProvider.deleteSession(session.id!, bookId);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            '${langProvider.translate('error_prefix')}${e.toString()}')),
                  );
                }
              }
            },
            child: Text(langProvider.translate('delete'),
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
