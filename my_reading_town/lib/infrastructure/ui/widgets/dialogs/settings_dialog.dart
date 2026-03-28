import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_reading_town/infrastructure/ui/config/app_theme.dart';
import 'package:my_reading_town/domain/rules/village_rules.dart';
import 'package:my_reading_town/adapters/providers/village_provider.dart';
import 'package:my_reading_town/adapters/providers/book_provider.dart';
import 'package:my_reading_town/adapters/providers/tag_provider.dart';
import 'package:my_reading_town/adapters/repositories/villager_favorites.dart';
import 'package:my_reading_town/infrastructure/ui/widgets/common/shared_utils.dart';
import 'package:my_reading_town/infrastructure/ui/localization/language_provider.dart';
import 'package:my_reading_town/infrastructure/ui/localization/context_ext.dart';
import 'package:my_reading_town/infrastructure/di/service_locator.dart';
import 'package:my_reading_town/application/services/backup_service.dart';

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
            horizontal: landscape ? 65 : 22, vertical: landscape ? 18 : 26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: EdgeInsets.all(20),
          constraints: BoxConstraints(maxHeight: 620),
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
                SizedBox(height: 20),
                Divider(color: AppTheme.darkText.withValues(alpha: 0.15)),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.storage_rounded,
                        size: 20, color: AppTheme.darkMint),
                    SizedBox(width: 8),
                    Text(ctx.t('data_management'),
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkText)),
                  ],
                ),
                SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.upload_file, color: AppTheme.darkMint),
                    label: Text(ctx.t('export_data')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.darkText,
                      side: BorderSide(color: AppTheme.darkMint),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () async {
                      try {
                        await sl<BackupService>().exportData();
                      } catch (_) {}
                    },
                  ),
                ),
                SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.download_rounded,
                        color: AppTheme.darkSkyBlue),
                    label: Text(ctx.t('import_data')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.darkText,
                      side: BorderSide(color: AppTheme.darkSkyBlue),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () async {
                      final confirmed = await _showImportWarning(ctx);
                      if (confirmed != true || !ctx.mounted) return;
                      try {
                        final success = await sl<BackupService>().importData();
                        if (success && ctx.mounted) {
                          await village.loadData();
                          await sl<BookProvider>().loadData();
                          await sl<TagProvider>().loadTags();
                          VillagerFavorites.setLocale(village.language);
                          await VillagerFavorites.load();
                          if (ctx.mounted) Navigator.pop(ctx);
                        }
                      } on FormatException catch (e) {
                        if (!ctx.mounted) return;
                        final msg = _importErrorMessage(ctx, e.message);
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(msg,
                                        style: const TextStyle(
                                            color: Colors.white))),
                              ],
                            ),
                            backgroundColor: const Color(0xFFFF6B6B),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      } catch (_) {}
                    },
                  ),
                ),
                SizedBox(height: 16),
                Divider(color: AppTheme.darkText.withValues(alpha: 0.15)),
                SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.delete_forever, color: Colors.white),
                    label: Text(ctx.t('reset_all_data'),
                        style: const TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B6B),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () async {
                      final confirmed = await _showResetWarning(ctx);
                      if (confirmed != true || !ctx.mounted) return;
                      await sl<BackupService>().resetData();
                      if (!ctx.mounted) return;
                      await village.loadData();
                      await sl<BookProvider>().loadData();
                      await sl<TagProvider>().loadTags();
                      VillagerFavorites.setLocale(village.language);
                      await VillagerFavorites.load();
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
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

Future<bool?> _showImportWarning(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppTheme.cream,
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppTheme.mediumOrange),
          SizedBox(width: 8),
          Expanded(
            child: Text(ctx.t('import_warning_title'),
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: AppTheme.darkText)),
          ),
        ],
      ),
      content: Text(ctx.t('import_warning_body'),
          style: TextStyle(color: AppTheme.darkText)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child:
              Text(ctx.t('cancel'), style: TextStyle(color: AppTheme.darkText)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.darkSkyBlue,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(ctx.t('import_confirm'),
              style: const TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

Future<bool?> _showResetWarning(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppTheme.cream,
      title: Row(
        children: [
          const Icon(Icons.warning_rounded, color: Color(0xFFFF6B6B)),
          SizedBox(width: 8),
          Expanded(
            child: Text(ctx.t('reset_warning_title'),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Color(0xFFFF6B6B))),
          ),
        ],
      ),
      content: Text(ctx.t('reset_warning_body'),
          style: TextStyle(color: AppTheme.darkText)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child:
              Text(ctx.t('cancel'), style: TextStyle(color: AppTheme.darkText)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6B6B),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(ctx.t('reset_confirm'),
              style: const TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

String _importErrorMessage(BuildContext context, String errorCode) {
  final lang = context.read<LanguageProvider>();
  if (errorCode == 'invalid_backup_not_json') {
    return lang.translate('import_error_not_json');
  }
  return lang.translate('import_error_invalid_file');
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
