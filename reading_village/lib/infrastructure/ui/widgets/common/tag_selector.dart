import 'package:flutter/material.dart';
import 'package:reading_village/infrastructure/ui/config/app_theme.dart';
import 'package:reading_village/domain/entities/tag.dart';

class TagSelector extends StatelessWidget {
  final List<Tag> availableTags;
  final List<int> selectedTagIds;
  final ValueChanged<List<int>> onChanged;
  final VoidCallback? onManageTags;

  const TagSelector({
    super.key,
    required this.availableTags,
    required this.selectedTagIds,
    required this.onChanged,
    this.onManageTags,
  });

  void _removeTag(int tagId) {
    onChanged(selectedTagIds.where((id) => id != tagId).toList());
  }

  @override
  Widget build(BuildContext context) {
    final selectedTags = availableTags.where((t) => t.id != null && selectedTagIds.contains(t.id)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Tags', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.darkText)),
            Spacer(),
            if (onManageTags != null)
              GestureDetector(
                onTap: onManageTags,
                child: Text('Manage', style: TextStyle(fontSize: 12, color: AppTheme.lavender, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        SizedBox(height: 6),
        if (selectedTags.isEmpty)
          Text('No tags added', style: TextStyle(fontSize: 12, color: AppTheme.darkText.withValues(alpha: 0.4)))
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: selectedTags.map((tag) {
              return GestureDetector(
                onTap: () => _removeTag(tag.id!),
                child: Container(
                  height: 30,
                  decoration: BoxDecoration(
                    color: Color(tag.colorValue),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.darkText.withValues(alpha: 0.3), width: 1.5),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.close, size: 14, color: AppTheme.darkText.withValues(alpha: 0.7)),
                      SizedBox(width: 4),
                      Text(
                        tag.title,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.darkText),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
