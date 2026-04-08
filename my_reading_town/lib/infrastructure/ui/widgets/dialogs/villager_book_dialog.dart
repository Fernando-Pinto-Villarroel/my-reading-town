import 'package:flutter/material.dart';
import 'package:my_reading_town/infrastructure/ui/widgets/common/app_toast.dart';
import 'package:provider/provider.dart';
import 'package:my_reading_town/infrastructure/ui/config/app_theme.dart';
import 'package:my_reading_town/adapters/providers/village_provider.dart';
import 'package:my_reading_town/infrastructure/ui/localization/language_provider.dart';

void showSelectVillagerForBook(BuildContext context, VillageProvider village) {
  if (village.villagers.isEmpty) return;
  final langProvider = context.read<LanguageProvider>();

  showDialog(
    context: context,
    builder: (ctx) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxHeight: 400),
          decoration: BoxDecoration(
            color: AppTheme.cream,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_stories, size: 24, color: AppTheme.pink),
                  const SizedBox(width: 8),
                  Text(langProvider.translate('give_book_to'),
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkText)),
                  const Spacer(),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: village.villagers.length,
                  itemBuilder: (_, i) {
                    final v = village.villagers[i];
                    final hasBuff = village.villagerHasHappinessBoost(v.id!);
                    return ListTile(
                      leading: Image.asset(
                        'assets/images/${v.spriteFile}',
                        width: 32,
                        height: 42,
                        filterQuality: FilterQuality.medium,
                      ),
                      title: Text(v.name,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkText)),
                      subtitle: Text(
                        hasBuff
                            ? langProvider.translate('already_boosted')
                            : '${langProvider.translate('villager_happiness')} ${v.happiness}%',
                        style: TextStyle(
                            fontSize: 12,
                            color: hasBuff
                                ? AppTheme.mint
                                : AppTheme.darkText.withValues(alpha: 0.5)),
                      ),
                      trailing: hasBuff
                          ? Icon(Icons.check_circle, color: AppTheme.mint)
                          : null,
                      onTap: hasBuff
                          ? null
                          : () async {
                              Navigator.pop(ctx);
                              final success = await village.useBookItem(v.id!);
                              if (success && context.mounted) {
                                showSuccessToast(context, '${v.name} ${langProvider.translate('happiness_book_active')}');
                              }
                            },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
