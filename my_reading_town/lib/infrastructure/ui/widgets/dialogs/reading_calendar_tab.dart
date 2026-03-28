import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_reading_town/adapters/providers/book_provider.dart';
import 'package:my_reading_town/domain/entities/book.dart';
import 'package:my_reading_town/domain/entities/book_filter.dart';
import 'package:my_reading_town/domain/entities/reading_session.dart';
import 'package:my_reading_town/infrastructure/ui/config/app_theme.dart';
import 'package:my_reading_town/infrastructure/ui/localization/context_ext.dart';

class ReadingCalendarTab extends StatefulWidget {
  final ScrollController scrollController;

  const ReadingCalendarTab({super.key, required this.scrollController});

  @override
  State<ReadingCalendarTab> createState() => _ReadingCalendarTabState();
}

class _ReadingCalendarTabState extends State<ReadingCalendarTab> {
  int _year = DateTime.now().year;

  Map<int, List<Book>> _buildMonthBookMap(
      List<ReadingSession> sessions, List<Book> books) {
    final bookById = {for (final b in books) b.id: b};
    final result = <int, Set<int>>{};

    for (final session in sessions) {
      try {
        final dt = DateTime.parse(session.date);
        if (dt.year != _year) continue;
        final month = dt.month;
        result.putIfAbsent(month, () => <int>{}).add(session.bookId);
      } catch (_) {}
    }

    return {
      for (final entry in result.entries)
        entry.key:
            entry.value.map((id) => bookById[id]).whereType<Book>().toList(),
    };
  }

  void _onBookTapped(BuildContext context, Book book) {
    context.read<BookProvider>().setFilter(BookFilter(searchQuery: book.title));
    DefaultTabController.of(context).animateTo(0);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookProvider>(
      builder: (ctx, bookProvider, _) {
        final monthBookMap =
            _buildMonthBookMap(bookProvider.sessions, bookProvider.books);
        final hasAnyData = monthBookMap.isNotEmpty;

        return Column(
          children: [
            _buildYearNavigator(),
            Expanded(
              child: !hasAnyData && bookProvider.sessions.isEmpty
                  ? _buildEmptyState()
                  : ListView(
                      controller: widget.scrollController,
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      children: [
                        GridView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 0.70,
                          ),
                          itemCount: 12,
                          itemBuilder: (ctx, i) {
                            final month = i + 1;
                            final booksThisMonth = monthBookMap[month] ?? [];
                            final monthKeys = [
                              'january',
                              'february',
                              'march',
                              'april',
                              'may',
                              'june',
                              'july',
                              'august',
                              'september',
                              'october',
                              'november',
                              'december',
                            ];
                            return _MonthCell(
                              month: month,
                              monthName: context.t(monthKeys[i]),
                              books: booksThisMonth,
                              onBookTap: (book) => _onBookTapped(context, book),
                            );
                          },
                        ),
                        SizedBox(height: 24),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildYearNavigator() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left, color: AppTheme.darkText),
            onPressed: () => setState(() => _year--),
          ),
          Text(
            '$_year',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkText,
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right, color: AppTheme.darkText),
            onPressed: () => setState(() => _year++),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_month, size: 60, color: AppTheme.lavender),
          SizedBox(height: 16),
          Text(
            context.t('no_reading_sessions'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: AppTheme.darkText.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthCell extends StatelessWidget {
  final int month;
  final String monthName;
  final List<Book> books;
  final void Function(Book) onBookTap;

  const _MonthCell({
    required this.month,
    required this.monthName,
    required this.books,
    required this.onBookTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasBooks = books.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: hasBooks
            ? AppTheme.lavender.withValues(alpha: 0.12)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasBooks
              ? AppTheme.lavender.withValues(alpha: 0.4)
              : Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: hasBooks
                  ? AppTheme.lavender.withValues(alpha: 0.25)
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Text(
              monthName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: hasBooks ? AppTheme.lavender : Colors.grey.shade400,
              ),
            ),
          ),
          Expanded(
            child: hasBooks
                ? _buildBookCovers()
                : Center(
                    child: Icon(Icons.auto_stories,
                        size: 24, color: Colors.grey.shade300),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookCovers() {
    return Padding(
      padding: EdgeInsets.all(5),
      child: SingleChildScrollView(
        child: Wrap(
          spacing: 4,
          runSpacing: 4,
          children: books
              .map((b) =>
                  _BookCoverThumbnail(book: b, onTap: () => onBookTap(b)))
              .toList(),
        ),
      ),
    );
  }
}

class _BookCoverThumbnail extends StatelessWidget {
  static const double _w = 36.0;
  static const double _h = 50.0;

  final Book book;
  final VoidCallback onTap;

  const _BookCoverThumbnail({required this.book, required this.onTap});

  String _titleAbbrev(String title) {
    final t = title.trim();
    if (t.isEmpty) return '?';
    return t.length > 4 ? '${t.substring(0, 4)}...' : t;
  }

  @override
  Widget build(BuildContext context) {
    final hasCover =
        book.coverImagePath != null && book.coverImagePath!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: hasCover
          ? ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Image.file(
                File(book.coverImagePath!),
                fit: BoxFit.cover,
                width: _w,
                height: _h,
                errorBuilder: (_, __, ___) => _placeholder(),
              ),
            )
          : _placeholder(),
    );
  }

  Widget _placeholder() {
    final colors = [
      AppTheme.pink,
      AppTheme.lavender,
      AppTheme.mint,
      AppTheme.peach,
      AppTheme.skyBlue,
    ];
    final colorIndex = book.title.codeUnitAt(0) % colors.length;
    final bg = colors[colorIndex];

    return Container(
      width: _w,
      height: _h,
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Center(
        child: Text(
          _titleAbbrev(book.title),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: AppTheme.darkText.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }
}
