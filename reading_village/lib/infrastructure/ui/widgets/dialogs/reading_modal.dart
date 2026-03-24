import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reading_village/infrastructure/ui/config/app_theme.dart';
import 'package:reading_village/adapters/providers/book_provider.dart';
import 'package:reading_village/adapters/providers/tag_provider.dart';
import 'package:reading_village/infrastructure/ui/widgets/common/book_card.dart';
import 'package:reading_village/infrastructure/ui/widgets/sheets/book_detail_sheet.dart';
import 'package:reading_village/infrastructure/ui/widgets/common/book_filter_bar.dart';
import 'package:reading_village/infrastructure/ui/widgets/dialogs/book_form_dialog.dart';
import 'package:reading_village/infrastructure/ui/widgets/dialogs/book_search_dialog.dart';
import 'package:reading_village/infrastructure/ui/widgets/dialogs/log_pages_dialog.dart';
import 'package:reading_village/infrastructure/ui/widgets/dialogs/reading_calendar_tab.dart';
import 'package:reading_village/infrastructure/ui/widgets/common/shared_utils.dart';
import 'package:reading_village/infrastructure/ui/widgets/dialogs/tag_manager_dialog.dart';

void showReadingModal(BuildContext context) {
  final landscape = isLandscape(context);
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    constraints: landscape
        ? BoxConstraints(
            maxWidth: 480,
            maxHeight: MediaQuery.of(context).size.height * 0.95)
        : null,
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: landscape ? 0.95 : 0.85,
      minChildSize: landscape ? 0.5 : 0.4,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) {
        return _ReadingModalContent(scrollController: scrollController);
      },
    ),
  );
}

class _ReadingModalContent extends StatelessWidget {
  final ScrollController scrollController;

  const _ReadingModalContent({required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewPadding.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.cream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              SizedBox(height: 8),
              _dragHandle(),
              Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 4, 4),
                child: Row(
                  children: [
                    Icon(Icons.menu_book, size: 24, color: AppTheme.darkText),
                    SizedBox(width: 8),
                    Text('Reading Tracker',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkText)),
                    Spacer(),
                    IconButton(
                      icon: Icon(Icons.label, size: 22, color: AppTheme.lavender),
                      tooltip: 'Manage Tags',
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          builder: (_) => TagManagerDialog(),
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.add_circle, size: 30, color: AppTheme.pink),
                      onPressed: () => _showAddBookDialog(context),
                    ),
                  ],
                ),
              ),
              TabBar(
                labelColor: AppTheme.lavender,
                unselectedLabelColor: AppTheme.darkText.withValues(alpha: 0.4),
                indicatorColor: AppTheme.lavender,
                indicatorWeight: 3,
                labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                tabs: [
                  Tab(text: 'Books'),
                  Tab(text: 'Calendar'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _BooksTab(scrollController: scrollController),
                    ReadingCalendarTab(scrollController: scrollController),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BooksTab extends StatelessWidget {
  final ScrollController scrollController;

  const _BooksTab({required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Consumer2<BookProvider, TagProvider>(
          builder: (ctx, bookProvider, tagProvider, _) {
            return BookFilterBar(
              filter: bookProvider.filter,
              availableTags: tagProvider.tags,
              onFilterChanged: (f) => bookProvider.setFilter(f),
            );
          },
        ),
        SizedBox(height: 4),
        Expanded(
          child: Consumer<BookProvider>(
            builder: (ctx, bookProvider, _) {
              final books = bookProvider.filteredBooks;
              if (bookProvider.books.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_stories,
                          size: 60, color: AppTheme.lavender),
                      SizedBox(height: 16),
                      Text(
                        'No books yet!\nTap + to add your first book.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.darkText.withValues(alpha: 0.6)),
                      ),
                    ],
                  ),
                );
              }
              if (books.isEmpty) {
                return Center(
                  child: Text('No books match your filters.',
                      style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.darkText.withValues(alpha: 0.5))),
                );
              }
              return ListView.builder(
                controller: scrollController,
                itemCount: books.length + 1,
                itemBuilder: (ctx, i) {
                  if (i == books.length) return SizedBox(height: 24);
                  final book = books[i];
                  return BookCard(
                    book: book,
                    onLogPages: book.isCompleted
                        ? () {}
                        : () => showLogPagesDialog(context, book.id!),
                    onTap: () => showBookDetailSheet(context, book),
                    onEdit: () => showDialog(
                      context: context,
                      builder: (_) => BookFormDialog(existingBook: book),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

void _showAddBookDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.add_circle, size: 22, color: AppTheme.pink),
          SizedBox(width: 8),
          Text('Add a Book',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('How would you like to add your book?',
              style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.darkText.withValues(alpha: 0.7))),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                showDialog(
                    context: context,
                    builder: (_) => BookSearchDialog());
              },
              icon: Icon(Icons.search, size: 18),
              label: Text('Search Online'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.lavender,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                showDialog(
                    context: context, builder: (_) => BookFormDialog());
              },
              icon: Icon(Icons.edit, size: 18),
              label: Text('Add Manually'),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: AppTheme.lavender),
              ),
            ),
          ),
        ],
      ),
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
