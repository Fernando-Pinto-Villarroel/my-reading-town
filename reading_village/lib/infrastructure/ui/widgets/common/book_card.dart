import 'dart:io';
import 'package:flutter/material.dart';
import 'package:reading_village/domain/entities/book.dart';
import 'package:reading_village/infrastructure/ui/config/app_theme.dart';
import 'package:reading_village/infrastructure/ui/widgets/common/skeleton.dart';

class BookCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
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
                            book.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkText,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (book.isCompleted)
                          Container(
                            margin: EdgeInsets.only(left: 6),
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.coinGold.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star, size: 12, color: AppTheme.coinGold),
                                SizedBox(width: 2),
                                Text('Done!',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.darkText)),
                              ],
                            ),
                          ),
                        if (onEdit != null)
                          GestureDetector(
                            onTap: onEdit,
                            child: Padding(
                              padding: EdgeInsets.only(left: 6),
                              child: Icon(Icons.edit, size: 18, color: AppTheme.lavender),
                            ),
                          ),
                      ],
                    ),
                    if (book.author != null && book.author!.isNotEmpty) ...[
                      SizedBox(height: 2),
                      Text(
                        book.author!,
                        style: TextStyle(fontSize: 12, color: AppTheme.darkText.withValues(alpha: 0.6)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (book.tags.isNotEmpty) ...[
                      SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: book.tags.map((tag) {
                          return Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: Color(tag.colorValue).withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              tag.title,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.darkText),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: book.progress,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          book.isCompleted ? AppTheme.coinGold : AppTheme.lavender,
                        ),
                        minHeight: 8,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${book.pagesRead} / ${book.totalPages} pages',
                          style: TextStyle(fontSize: 12, color: AppTheme.darkText.withValues(alpha: 0.7)),
                        ),
                        if (!book.isCompleted)
                          SizedBox(
                            height: 28,
                            child: ElevatedButton.icon(
                              onPressed: onLogPages,
                              icon: Icon(Icons.menu_book, size: 14),
                              label: Text('Log', style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.pink,
                                padding: EdgeInsets.symmetric(horizontal: 10),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCover() {
    if (book.coverImagePath != null && book.coverImagePath!.isNotEmpty) {
      return SkeletonImage(
        image: FileImage(File(book.coverImagePath!)),
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
