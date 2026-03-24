import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reading_village/infrastructure/ui/config/app_theme.dart';
import 'package:reading_village/domain/entities/book_search_result.dart';
import 'package:reading_village/adapters/services/book_search_adapter.dart';
import 'package:reading_village/adapters/services/image_service_adapter.dart';
import 'package:reading_village/infrastructure/ui/widgets/dialogs/book_form_dialog.dart';
import 'package:reading_village/infrastructure/ui/widgets/common/skeleton.dart';
import 'package:reading_village/infrastructure/ui/localization/language_provider.dart';

class BookSearchDialog extends StatefulWidget {
  const BookSearchDialog({super.key});

  @override
  State<BookSearchDialog> createState() => _BookSearchDialogState();
}

class _BookSearchDialogState extends State<BookSearchDialog> {
  final _searchController = TextEditingController();
  final _bookSearchAdapter = BookSearchAdapter();
  List<BookSearchResult> _results = [];
  bool _loading = false;
  String? _error;
  Timer? _debounce;
  int _searchId = 0;
  String? _lastQuery;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 2) return;
    _debounce = Timer(Duration(milliseconds: 600), () {
      _search(query);
    });
  }

  Future<void> _search(String query) async {
    final trimmed = query.trim();
    if (trimmed == _lastQuery && _results.isNotEmpty) return;
    _lastQuery = trimmed;
    final id = ++_searchId;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await _bookSearchAdapter.searchBooks(trimmed);
      if (!mounted || id != _searchId) return;
      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || id != _searchId) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _selectResult(BookSearchResult result) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (_) => _PrefillBookForm(result: result),
    );
  }

  void _goManual() {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (_) => BookFormDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = context.read<LanguageProvider>();
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: EdgeInsets.symmetric(horizontal: isLandscape ? 80 : 20, vertical: 24),
      title: Row(
        children: [
          Icon(Icons.search, size: 22, color: AppTheme.lavender),
          SizedBox(width: 8),
          Text(langProvider.translate('search_books_online'), style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SizedBox(
        width: isLandscape ? 420 : double.maxFinite,
        height: isLandscape ? 280 : 380,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              onSubmitted: (v) { _debounce?.cancel(); if (v.trim().length >= 2) _search(v); },
              autofocus: true,
              style: TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: langProvider.translate('search_books_hint'),
                hintStyle: TextStyle(fontSize: 13),
                prefixIcon: Icon(Icons.search, size: 18),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _debounce?.cancel();
                          setState(() { _results = []; _error = null; _loading = false; _lastQuery = null; });
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            SizedBox(height: 8),
            if (_error != null)
              Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, size: 16, color: Colors.red.shade300),
                    SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(langProvider.translate('search_failed'),
                              style: TextStyle(fontSize: 12, color: Colors.red.shade400)),
                          Text('${langProvider.translate('reason')} $_error',
                              style: TextStyle(fontSize: 11, color: Colors.red.shade300),
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _loading
                  ? _buildSkeletonList()
                  : _results.isEmpty
                      ? Center(
                          child: Text(
                            _searchController.text.isEmpty
                                ? langProvider.translate('type_to_search')
                                : langProvider.translate('no_results_found'),
                            style: TextStyle(fontSize: 13, color: AppTheme.darkText.withValues(alpha: 0.5)),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _results.length,
                          separatorBuilder: (_, __) => Divider(height: 1),
                          itemBuilder: (ctx, i) => _resultTile(_results[i], langProvider),
                        ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(langProvider.translate('cancel')),
        ),
        OutlinedButton.icon(
          onPressed: _goManual,
          icon: Icon(Icons.edit, size: 16),
          label: Text(langProvider.translate('add_manually')),
        ),
      ],
    );
  }

  Widget _resultTile(BookSearchResult result, LanguageProvider langProvider) {
    final thumbUrl = result.thumbnailUrl;
    final smallThumb = thumbUrl?.replaceAll('-M.jpg', '-S.jpg');

    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: smallThumb != null
          ? SkeletonImage(
              image: NetworkImage(smallThumb),
              width: 36,
              height: 52,
              borderRadius: 6,
            )
          : _coverPlaceholder(),
      title: Text(result.title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (result.author != null)
            Text(result.author!, style: TextStyle(fontSize: 11, color: AppTheme.darkText.withValues(alpha: 0.6)), maxLines: 1, overflow: TextOverflow.ellipsis),
          if (result.pageCount != null)
            Text('${result.pageCount} ${langProvider.translate('pages_label')}', style: TextStyle(fontSize: 11, color: AppTheme.lavender)),
        ],
      ),
      onTap: () => _selectResult(result),
    );
  }

  Widget _coverPlaceholder() {
    return Container(
      width: 36, height: 52,
      decoration: BoxDecoration(
        color: AppTheme.lavender.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(Icons.menu_book, size: 18, color: AppTheme.lavender),
    );
  }

  Widget _buildSkeletonList() {
    return ListView.separated(
      itemCount: 5,
      separatorBuilder: (_, __) => Divider(height: 1),
      itemBuilder: (_, __) => Padding(
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          children: [
            Skeleton(width: 36, height: 52, borderRadius: 6),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Skeleton(width: 160, height: 13, borderRadius: 4),
                  SizedBox(height: 6),
                  Skeleton(width: 100, height: 11, borderRadius: 4),
                  SizedBox(height: 4),
                  Skeleton(width: 60, height: 11, borderRadius: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrefillBookForm extends StatefulWidget {
  final BookSearchResult result;
  const _PrefillBookForm({required this.result});

  @override
  State<_PrefillBookForm> createState() => _PrefillBookFormState();
}

class _PrefillBookFormState extends State<_PrefillBookForm> {
  String? _coverPath;
  bool _downloading = false;
  final _imageAdapter = ImageServiceAdapter();

  @override
  void initState() {
    super.initState();
    _downloadCover();
  }

  Future<void> _downloadCover() async {
    if (widget.result.thumbnailUrl == null) return;
    setState(() => _downloading = true);
    final path = await _imageAdapter.saveImageFromUrl(widget.result.thumbnailUrl!);
    if (!mounted) return;
    setState(() {
      _coverPath = path;
      _downloading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BookFormDialog(
      prefillTitle: widget.result.title,
      prefillAuthor: widget.result.author,
      prefillPages: widget.result.pageCount,
      prefillCoverPath: _coverPath,
      coverLoading: _downloading,
    );
  }
}
