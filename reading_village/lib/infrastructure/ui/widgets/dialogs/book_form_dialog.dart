import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reading_village/domain/entities/book.dart';
import 'package:reading_village/domain/entities/tag.dart';
import 'package:reading_village/adapters/providers/book_provider.dart';
import 'package:reading_village/adapters/providers/tag_provider.dart';
import 'package:reading_village/infrastructure/ui/widgets/common/cover_image_picker.dart';
import 'package:reading_village/infrastructure/ui/widgets/common/tag_selector.dart';
import 'package:reading_village/infrastructure/ui/widgets/dialogs/tag_manager_dialog.dart';

class BookFormDialog extends StatefulWidget {
  final Book? existingBook;

  final String? prefillTitle;
  final String? prefillAuthor;
  final int? prefillPages;
  final String? prefillCoverPath;
  final bool coverLoading;

  const BookFormDialog({
    super.key,
    this.existingBook,
    this.prefillTitle,
    this.prefillAuthor,
    this.prefillPages,
    this.prefillCoverPath,
    this.coverLoading = false,
  });

  @override
  State<BookFormDialog> createState() => _BookFormDialogState();
}

class _BookFormDialogState extends State<BookFormDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _authorController;
  late final TextEditingController _pagesController;
  String? _coverPath;
  bool _coverLoading = false;
  List<int> _selectedTagIds = [];
  String? _titleError;
  String? _pagesError;

  bool get _isEditing => widget.existingBook != null;

  @override
  void initState() {
    super.initState();
    final book = widget.existingBook;
    if (book != null) {
      _titleController = TextEditingController(text: book.title);
      _authorController = TextEditingController(text: book.author ?? '');
      _pagesController = TextEditingController(text: book.totalPages.toString());
      _coverPath = book.coverImagePath;
      _selectedTagIds = book.tags.where((t) => t.id != null).map((t) => t.id!).toList();
    } else {
      _titleController = TextEditingController(text: widget.prefillTitle ?? '');
      _authorController = TextEditingController(text: widget.prefillAuthor ?? '');
      _pagesController = TextEditingController(text: widget.prefillPages?.toString() ?? '');
      _coverPath = widget.prefillCoverPath;
      _coverLoading = widget.coverLoading;
    }
  }

  @override
  void didUpdateWidget(BookFormDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.coverLoading != oldWidget.coverLoading) {
      setState(() => _coverLoading = widget.coverLoading);
    }
    if (widget.prefillCoverPath != oldWidget.prefillCoverPath && _coverPath == null) {
      setState(() {
        _coverPath = widget.prefillCoverPath;
        _coverLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _pagesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tags = context.watch<TagProvider>().tags;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: EdgeInsets.symmetric(horizontal: isLandscape ? 80 : 24, vertical: 24),
      title: Text(_isEditing ? 'Edit Book' : 'Add a New Book', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: isLandscape ? 420 : double.maxFinite,
        child: SingleChildScrollView(
          child: isLandscape ? _landscapeLayout(tags) : _portraitLayout(tags),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(_isEditing ? 'Save' : 'Add'),
        ),
      ],
    );
  }

  Widget _portraitLayout(List<Tag> tags) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CoverImagePicker(
          imagePath: _coverPath,
          onChanged: (p) => setState(() { _coverPath = p; _coverLoading = false; }),
          loading: _coverLoading,
        ),
        SizedBox(height: 12),
        _titleField(),
        SizedBox(height: 10),
        _authorField(),
        SizedBox(height: 10),
        _pagesField(),
        SizedBox(height: 12),
        TagSelector(
          availableTags: tags,
          selectedTagIds: _selectedTagIds,
          onChanged: (ids) => setState(() => _selectedTagIds = ids),
          onManageTags: _openTagManager,
        ),
      ],
    );
  }

  Widget _landscapeLayout(List<Tag> tags) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CoverImagePicker(
          imagePath: _coverPath,
          onChanged: (p) => setState(() { _coverPath = p; _coverLoading = false; }),
          loading: _coverLoading,
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _titleField(),
              SizedBox(height: 10),
              _authorField(),
              SizedBox(height: 10),
              _pagesField(),
              SizedBox(height: 12),
              TagSelector(
                availableTags: tags,
                selectedTagIds: _selectedTagIds,
                onChanged: (ids) => setState(() => _selectedTagIds = ids),
                onManageTags: _openTagManager,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _titleField() {
    return TextField(
      controller: _titleController,
      decoration: InputDecoration(
        labelText: 'Book Title',
        hintText: 'e.g. The Little Prince',
        errorText: _titleError,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      textCapitalization: TextCapitalization.words,
      maxLength: 100,
    );
  }

  Widget _authorField() {
    return TextField(
      controller: _authorController,
      decoration: InputDecoration(
        labelText: 'Author (optional)',
        hintText: 'e.g. Antoine de Saint-Exupéry',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      textCapitalization: TextCapitalization.words,
      maxLength: 80,
    );
  }

  Widget _pagesField() {
    return TextField(
      controller: _pagesController,
      decoration: InputDecoration(
        labelText: 'Total Pages (2–9999)',
        hintText: 'e.g. 96',
        errorText: _pagesError,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      keyboardType: TextInputType.number,
    );
  }

  void _openTagManager() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: TagManagerDialog(
          selectedTagIds: _selectedTagIds,
          onSelectionChanged: (ids) => setState(() => _selectedTagIds = ids),
        ),
      ),
    );
  }

  void _submit() {
    final title = _titleController.text.trim();
    final author = _authorController.text.trim();
    final pages = int.tryParse(_pagesController.text.trim());
    String? tErr;
    String? pErr;

    if (title.isEmpty) {
      tErr = 'Title is required';
    } else if (title.length < 2) {
      tErr = 'Title must be at least 2 characters';
    }
    if (pages == null) {
      pErr = 'Enter a valid number';
    } else if (pages < 2) {
      pErr = 'Minimum 2 pages';
    } else if (pages > 9999) {
      pErr = 'Maximum 9999 pages';
    }

    if (tErr != null || pErr != null) {
      setState(() {
        _titleError = tErr;
        _pagesError = pErr;
      });
      return;
    }

    final provider = context.read<BookProvider>();

    if (_isEditing) {
      final book = widget.existingBook!;
      final oldCover = book.coverImagePath;
      final removeCover = oldCover != null && oldCover.isNotEmpty && (_coverPath == null || _coverPath!.isEmpty);

      provider.updateBookDetails(
        bookId: book.id!,
        title: title,
        author: author.isEmpty ? null : author,
        clearAuthor: author.isEmpty,
        totalPages: pages!,
        coverImagePath: _coverPath,
        removeCover: removeCover,
        tagIds: _selectedTagIds,
      );
    } else {
      provider.addBook(
        title: title,
        totalPages: pages!,
        author: author.isEmpty ? null : author,
        coverImagePath: _coverPath,
        tagIds: _selectedTagIds.isEmpty ? null : _selectedTagIds,
      );
    }
    Navigator.pop(context);
  }
}
