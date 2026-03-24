import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reading_village/infrastructure/ui/config/app_theme.dart';
import 'package:reading_village/domain/rules/village_rules.dart';
import 'package:reading_village/adapters/providers/village_provider.dart';
import 'package:reading_village/adapters/repositories/villager_favorites.dart';
import 'package:reading_village/infrastructure/ui/widgets/common/shared_utils.dart';
import 'package:reading_village/infrastructure/ui/localization/language_provider.dart';
import 'package:reading_village/infrastructure/ui/localization/context_ext.dart';

void showSettingsDialog(BuildContext context, VillageProvider village) {
  final usernameController = TextEditingController(text: village.username);
  final townNameController = TextEditingController(text: village.townName);

  showDialog(
    context: context,
    builder: (ctx) {
      final progress = VillageRules.expProgressToNextLevel(village.exp);
      final expToNext = VillageRules.expToNextLevel(village.exp);
      final landscape = isLandscape(ctx);
      return Dialog(
        insetPadding: EdgeInsets.symmetric(
            horizontal: landscape ? 24 : 6, vertical: landscape ? 16 : 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cream,
            borderRadius: BorderRadius.circular(24),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.settings, size: 24, color: AppTheme.lavender),
                    SizedBox(width: 8),
                    Text(ctx.t('settings'),
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkText)),
                    Spacer(),
                    IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.lavender.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text('${ctx.t('player_level')} ${village.playerLevel}',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkText)),
                      SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: AppTheme.darkText.withValues(alpha: 0.3),
                              width: 1),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 10,
                            backgroundColor: Colors.grey.shade200,
                            valueColor:
                                AlwaysStoppedAnimation(AppTheme.lavender),
                          ),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                          '${village.exp} EXP ($expToNext ${ctx.t('exp_to_next_level')})',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.darkText.withValues(alpha: 0.6))),
                    ],
                  ),
                ),
                SizedBox(height: 18),
                TextField(
                  controller: usernameController,
                  decoration: InputDecoration(
                    labelText: ctx.t('username'),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                SizedBox(height: 24),
                TextField(
                  controller: townNameController,
                  decoration: InputDecoration(
                    labelText: ctx.t('town_name'),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                SizedBox(height: 16),
                _LanguageSelector(),
                SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      final username = usernameController.text.trim();
                      final townName = townNameController.text.trim();
                      if (username.isNotEmpty) {
                        village.updateUsername(username);
                      }
                      if (townName.isNotEmpty) {
                        village.updateTownName(townName);
                      }
                      Navigator.pop(ctx);
                    },
                    child: Text(ctx.t('save')),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _LanguageSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final currentLocale = languageProvider.currentLocale;

    return Row(
      children: [
        Icon(Icons.language, size: 24, color: AppTheme.lavender),
        SizedBox(width: 8),
        Text(context.t('language'),
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkText)),
        Spacer(),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.lavender.withValues(alpha: 0.1),
            border: Border.all(color: AppTheme.lavender.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currentLocale,
              isDense: true,
              borderRadius: BorderRadius.circular(12),
              dropdownColor: AppTheme.cream,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.lavender,
              ),
              icon: Icon(Icons.keyboard_arrow_down,
                  size: 18, color: AppTheme.lavender),
              items: LanguageProvider.supportedLanguages.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(
                    entry.value['name']!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: entry.key == currentLocale
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: AppTheme.darkText,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (locale) {
                if (locale != null) {
                  VillagerFavorites.setLocale(locale);
                  VillagerFavorites.load();
                  context.read<LanguageProvider>().changeLanguage(locale);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
