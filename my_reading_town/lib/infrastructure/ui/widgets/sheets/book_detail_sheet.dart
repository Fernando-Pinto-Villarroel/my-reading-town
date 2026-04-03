import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_reading_town/infrastructure/ui/config/app_theme.dart';
import 'package:my_reading_town/domain/entities/book.dart';
import 'package:my_reading_town/adapters/providers/book_provider.dart';
import 'package:my_reading_town/infrastructure/ui/widgets/dialogs/book_form_dialog.dart';
import 'package:my_reading_town/infrastructure/ui/widgets/dialogs/log_pages_dialog.dart';
import 'package:my_reading_town/infrastructure/ui/widgets/common/shared_utils.dart';
import 'package:my_reading_town/infrastructure/ui/widgets/common/skeleton.dart';
import 'package:my_reading_town/infrastructure/ui/localization/language_provider.dart';
import 'package:my_reading_town/infrastructure/ui/widgets/common/book_card.dart';

void showBookDetailSheet(BuildContext context, Book book) {
  final langProvider = context.read<LanguageProvider>();
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    isScrollControlled: true,
    constraints: sheetConstraints(context, portraitFrac: 0.5),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: _dragHandle()),
              SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (book.coverImagePath != null &&
                      book.coverImagePath!.isNotEmpty)
                    SkeletonImage(
                      image: FileImage(File(book.coverImagePath!)),
                      width: 60,
                      height: 86,
                      borderRadius: 10,
                    )
                  else
                    Container(
                      width: 60,
                      height: 86,
                      decoration: BoxDecoration(
                        color: AppTheme.lavender.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.menu_book,
                          size: 28, color: AppTheme.lavender),
                    ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(book.title,
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.darkText)),
                        if (book.author != null && book.author!.isNotEmpty) ...[
                          SizedBox(height: 2),
                          Text(book.author!,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.darkText
                                      .withValues(alpha: 0.6))),
                        ],
                        SizedBox(height: 4),
                        Text('${book.pagesRead} / ${book.totalPages} pages',
                            style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.lavender,
                                fontWeight: FontWeight.w600)),
                        if (book.isCompleted) ...[
                          SizedBox(height: 6),
                          Consumer<BookProvider>(
                            builder: (_, bp, __) {
                              final liveBook = bp.books.firstWhere(
                                (b) => b.id == book.id,
                                orElse: () => book,
                              );
                              return StarRatingRow(
                                rating: liveBook.rating,
                                bookId: book.id!,
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (book.tags.isNotEmpty) ...[
                SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: book.tags
                      .map((tag) => Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color:
                                  Color(tag.colorValue).withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(tag.title,
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.darkText)),
                          ))
                      .toList(),
                ),
              ],
              SizedBox(height: 16),
              if (!book.isCompleted)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetCtx);
                      showLogPagesDialog(context, book.id!);
                    },
                    icon: Icon(Icons.menu_book, size: 16),
                    label: Text(langProvider.translate('log_pages')),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.pink),
                  ),
                ),
              if (!book.isCompleted) SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetCtx);
                        showDialog(
                          context: context,
                          builder: (_) => BookFormDialog(existingBook: book),
                        );
                      },
                      icon:
                          Icon(Icons.edit, size: 16, color: AppTheme.lavender),
                      label: Text(langProvider.translate('edit'),
                          style: TextStyle(color: AppTheme.lavender)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: AppTheme.lavender.withValues(alpha: 0.5)),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetCtx);
                        _confirmDeleteBook(context, book);
                      },
                      icon: Icon(Icons.delete_outline,
                          size: 16, color: Colors.red.shade300),
                      label: Text(langProvider.translate('delete'),
                          style: TextStyle(color: Colors.red.shade300)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red.shade200),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

void _confirmDeleteBook(BuildContext context, Book book) {
  final bookProvider = context.read<BookProvider>();
  final langProvider = context.read<LanguageProvider>();
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(langProvider.translate('delete_book_title')),
      content: Text(
          '${langProvider.translate('delete_book_confirm_prefix')}${book.title}${langProvider.translate('delete_book_confirm_suffix')}'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(langProvider.translate('cancel'))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade300),
          onPressed: () {
            bookProvider.deleteBook(book.id!);
            Navigator.pop(ctx);
          },
          child: Text(langProvider.translate('delete'),
              style: TextStyle(color: Colors.white)),
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
