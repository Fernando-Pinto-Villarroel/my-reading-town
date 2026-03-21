import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../models/tag.dart';
import '../providers/tag_provider.dart';
import '../providers/book_provider.dart';

class TagManagerDialog extends StatefulWidget {
  /// If provided, shows checkboxes to add/remove tags for a book.
  final List<int>? selectedTagIds;
  final ValueChanged<List<int>>? onSelectionChanged;

  const TagManagerDialog({super.key, this.selectedTagIds, this.onSelectionChanged});

  @override
  State<TagManagerDialog> createState() => _TagManagerDialogState();
}

class _TagManagerDialogState extends State<TagManagerDialog> {
  late List<int> _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedTagIds != null ? List<int>.from(widget.selectedTagIds!) : [];
  }

  void _toggleTag(int tagId) {
    setState(() {
      if (_selected.contains(tagId)) {
        _selected.remove(tagId);
      } else {
        _selected.add(tagId);
      }
    });
    widget.onSelectionChanged?.call(List<int>.from(_selected));
  }

  @override
  Widget build(BuildContext context) {
    final isBookMode = widget.selectedTagIds != null;

    return Consumer<TagProvider>(
      builder: (context, tagProvider, _) {
        return Container(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 36),
          decoration: BoxDecoration(
            color: AppTheme.cream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.label, size: 22, color: AppTheme.lavender),
                  SizedBox(width: 8),
                  Text('Manage Tags', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkText)),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.add_circle, size: 28, color: AppTheme.pink),
                    onPressed: () => _showAddEditTagDialog(null),
                  ),
                ],
              ),
              if (isBookMode)
                Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text('Tap a tag to add or remove it from this book',
                      style: TextStyle(fontSize: 12, color: AppTheme.darkText.withValues(alpha: 0.5))),
                ),
              SizedBox(height: 8),
              if (tagProvider.tags.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('No tags yet. Tap + to create one!',
                      style: TextStyle(color: AppTheme.darkText.withValues(alpha: 0.5))),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: 300),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: tagProvider.tags.length,
                    separatorBuilder: (_, __) => SizedBox(height: 4),
                    itemBuilder: (ctx, i) {
                      final tag = tagProvider.tags[i];
                      return _tagTile(tag, isBookMode);
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _tagTile(Tag tag, bool isBookMode) {
    final isAssigned = _selected.contains(tag.id);

    return GestureDetector(
      onTap: isBookMode && tag.id != null ? () => _toggleTag(tag.id!) : null,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Color(tag.colorValue).withValues(alpha: isBookMode && isAssigned ? 0.5 : 0.25),
          borderRadius: BorderRadius.circular(10),
          border: isBookMode && isAssigned
              ? Border.all(color: AppTheme.darkText.withValues(alpha: 0.3), width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            if (isBookMode) ...[
              Icon(
                isAssigned ? Icons.check_box : Icons.check_box_outline_blank,
                size: 20,
                color: isAssigned ? AppTheme.lavender : AppTheme.darkText.withValues(alpha: 0.4),
              ),
              SizedBox(width: 8),
            ],
            Container(
              width: 20, height: 20,
              decoration: BoxDecoration(
                color: Color(tag.colorValue),
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(tag.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.darkText)),
            ),
            GestureDetector(
              onTap: () => _showAddEditTagDialog(tag),
              child: Icon(Icons.edit, size: 18, color: AppTheme.darkText.withValues(alpha: 0.5)),
            ),
            SizedBox(width: 12),
            GestureDetector(
              onTap: () => _confirmDelete(tag),
              child: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade300),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEditTagDialog(Tag? existing) {
    final controller = TextEditingController(text: existing?.title ?? '');
    int selectedColor = existing?.colorValue ?? AppTheme.tagColors.first.toARGB32();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(existing == null ? 'New Tag' : 'Edit Tag'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Tag Name',
                  hintText: 'e.g. Fantasy',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                textCapitalization: TextCapitalization.words,
                maxLength: 30,
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppTheme.tagColors.map((c) {
                  final isSelected = c.toARGB32() == selectedColor;
                  return GestureDetector(
                    onTap: () => setDState(() => selectedColor = c.toARGB32()),
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: AppTheme.darkText, width: 2.5) : null,
                      ),
                      child: isSelected ? Icon(Icons.check, size: 16, color: AppTheme.darkText) : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final title = controller.text.trim();
                if (title.isEmpty) return;
                final tagProvider = context.read<TagProvider>();
                if (existing != null) {
                  await tagProvider.updateTag(existing.id!, title, selectedColor);
                  if (mounted) context.read<BookProvider>().refreshBookTags();
                } else {
                  await tagProvider.addTag(title, selectedColor);
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(existing == null ? 'Create' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Tag tag) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Tag?'),
        content: Text('Remove "${tag.title}" from all books?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade300),
            onPressed: () async {
              final tagProvider = context.read<TagProvider>();
              await tagProvider.deleteTag(tag.id!);
              if (mounted) context.read<BookProvider>().refreshBookTags();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
