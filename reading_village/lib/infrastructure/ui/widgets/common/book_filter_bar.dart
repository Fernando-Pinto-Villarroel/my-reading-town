import 'package:flutter/material.dart';
import 'package:reading_village/infrastructure/ui/config/app_theme.dart';
import 'package:reading_village/domain/entities/book_filter.dart';
import 'package:reading_village/domain/entities/tag.dart';
import 'package:reading_village/infrastructure/ui/localization/context_ext.dart';

class BookFilterBar extends StatefulWidget {
  final BookFilter filter;
  final List<Tag> availableTags;
  final ValueChanged<BookFilter> onFilterChanged;

  const BookFilterBar({
    super.key,
    required this.filter,
    required this.availableTags,
    required this.onFilterChanged,
  });

  @override
  State<BookFilterBar> createState() => _BookFilterBarState();
}

class _BookFilterBarState extends State<BookFilterBar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController =
        TextEditingController(text: widget.filter.searchQuery ?? '');
  }

  @override
  void didUpdateWidget(BookFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filter.searchQuery != widget.filter.searchQuery) {
      final newText = widget.filter.searchQuery ?? '';
      if (_searchController.text != newText) {
        _searchController.text = newText;
        _searchController.selection =
            TextSelection.collapsed(offset: newText.length);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = widget.filter;
    final onFilterChanged = widget.onFilterChanged;
    final availableTags = widget.availableTags;

    // Pre-compute translated strings to avoid Provider.of in itemBuilder
    final dateAddedLabel = context.t('date_added');
    final titleLabel = context.t('title_sort');
    final pagesLeftLabel = context.t('pages_left');
    final authorLabel = context.t('author_sort');

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => onFilterChanged(filter.copyWith(
                        searchQuery: () => v.isEmpty ? null : v)),
                    style: TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: context.t('search_by_title_author'),
                      hintStyle: TextStyle(
                          fontSize: 13,
                          color: AppTheme.darkText.withValues(alpha: 0.4)),
                      prefixIcon: Icon(Icons.search, size: 18),
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none),
                      filled: true,
                      fillColor: AppTheme.darkText.withValues(alpha: 0.06),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 6),
              _CompletionToggle(
                value: filter.showCompleted,
                onChanged: (v) =>
                    onFilterChanged(filter.copyWith(showCompleted: () => v)),
              ),
              SizedBox(width: 4),
              PopupMenuButton<BookSortField>(
                icon: Icon(Icons.sort, size: 20, color: AppTheme.darkText),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
                onSelected: (field) {
                  if (field == filter.sortField) {
                    onFilterChanged(filter.copyWith(
                      sortDirection:
                          filter.sortDirection == BookSortDirection.ascending
                              ? BookSortDirection.descending
                              : BookSortDirection.ascending,
                    ));
                  } else {
                    onFilterChanged(filter.copyWith(
                        sortField: field,
                        sortDirection: BookSortDirection.ascending));
                  }
                },
                itemBuilder: (_) => [
                  _sortItem(BookSortField.dateAdded, dateAddedLabel,
                      Icons.calendar_today),
                  _sortItem(
                      BookSortField.title, titleLabel, Icons.sort_by_alpha),
                  _sortItem(BookSortField.pagesLeft, pagesLeftLabel,
                      Icons.auto_stories),
                  _sortItem(BookSortField.author, authorLabel, Icons.person),
                ],
              ),
            ],
          ),
          if (availableTags.isNotEmpty) ...[
            SizedBox(height: 6),
            SizedBox(
              height: 28,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: availableTags.length,
                separatorBuilder: (_, __) => SizedBox(width: 6),
                itemBuilder: (ctx, i) {
                  final tag = availableTags[i];
                  final selected = filter.selectedTagIds.contains(tag.id);
                  return GestureDetector(
                    onTap: () {
                      final newIds = List<int>.from(filter.selectedTagIds);
                      selected ? newIds.remove(tag.id) : newIds.add(tag.id!);
                      onFilterChanged(filter.copyWith(selectedTagIds: newIds));
                    },
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: selected
                            ? Color(tag.colorValue)
                            : Color(tag.colorValue).withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        tag.title,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.darkText),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  PopupMenuItem<BookSortField> _sortItem(
      BookSortField field, String label, IconData icon) {
    final isActive = widget.filter.sortField == field;
    return PopupMenuItem(
      value: field,
      child: Row(
        children: [
          Icon(icon,
              size: 16,
              color: isActive ? AppTheme.lavender : AppTheme.darkText),
          SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
          if (isActive) ...[
            Spacer(),
            Icon(
              widget.filter.sortDirection == BookSortDirection.ascending
                  ? Icons.arrow_upward
                  : Icons.arrow_downward,
              size: 14,
              color: AppTheme.lavender,
            ),
          ],
        ],
      ),
    );
  }
}

class _CompletionToggle extends StatelessWidget {
  final bool? value;
  final ValueChanged<bool?> onChanged;

  const _CompletionToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    if (value == null) {
      icon = Icons.all_inclusive;
      color = AppTheme.darkText.withValues(alpha: 0.5);
    } else if (value == true) {
      icon = Icons.check_circle;
      color = AppTheme.coinGold;
    } else {
      icon = Icons.auto_stories;
      color = AppTheme.lavender;
    }

    return GestureDetector(
      onTap: () {
        if (value == null) {
          onChanged(false);
        } else if (value == false) {
          onChanged(true);
        } else {
          onChanged(null);
        }
      },
      child: Icon(icon, size: 22, color: color),
    );
  }
}
