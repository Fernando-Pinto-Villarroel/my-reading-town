import 'dart:convert';
import 'package:my_reading_town/infrastructure/ui/widgets/common/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:my_reading_town/infrastructure/persistence/database_helper.dart';
import 'package:my_reading_town/application/services/backup_service.dart';
import 'package:my_reading_town/application/services/notification_service.dart';

void showSettingsDialog(BuildContext context, VillageProvider village) {
  final usernameController = TextEditingController(text: village.username);
  final townNameController = TextEditingController(text: village.townName);

  showDialog(
    context: context,
    builder: (ctx) {
      final progress = VillageRules.expProgressToNextLevel(village.exp);
      final expToNext = VillageRules.expToNextLevel(village.exp);
      final landscape = isLandscape(ctx);
      return StatefulBuilder(
        builder: (ctx, setState) {
          String? usernameError;
          String? townNameError;

          void save() {
            final username = usernameController.text.trim();
            final townName = townNameController.text.trim();
            final minMsg = ctx.t('tour_input_min_chars');
            final uErr = username.isNotEmpty && username.length < 3 ? minMsg : null;
            final tErr = townName.isNotEmpty && townName.length < 3 ? minMsg : null;
            setState(() {
              usernameError = uErr;
              townNameError = tErr;
            });
            if (uErr != null || tErr != null) return;
            if (username.isNotEmpty) village.updateUsername(username);
            if (townName.isNotEmpty) village.updateTownName(townName);
            Navigator.pop(ctx);
          }

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
                  inputFormatters: [LengthLimitingTextInputFormatter(30)],
                  decoration: InputDecoration(
                    labelText: ctx.t('username'),
                    errorText: usernameError,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: usernameError != null
                            ? AppTheme.pink
                            : AppTheme.lavender.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                SizedBox(height: 14),
                TextField(
                  controller: townNameController,
                  inputFormatters: [LengthLimitingTextInputFormatter(30)],
                  decoration: InputDecoration(
                    labelText: ctx.t('town_name'),
                    errorText: townNameError,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: townNameError != null
                            ? AppTheme.pink
                            : AppTheme.lavender.withValues(alpha: 0.5),
                      ),
                    ),
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
                    onPressed: save,
                    child: Text(ctx.t('save')),
                  ),
                ),
                SizedBox(height: 20),
                Divider(color: AppTheme.darkText.withValues(alpha: 0.15)),
                SizedBox(height: 4),
                _NotificationSettingsSection(),
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
                        showAppToast(ctx, msg, backgroundColor: const Color(0xFFE53935), icon: Icons.error_outline, duration: const Duration(seconds: 4));
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

class _NotificationSettingsSection extends StatefulWidget {
  @override
  State<_NotificationSettingsSection> createState() =>
      _NotificationSettingsSectionState();
}

class _NotificationSettingsSectionState
    extends State<_NotificationSettingsSection> {
  List<bool> _activeDays = List.filled(7, true);
  int _startHour = 8;
  int _endHour = 22;
  int _perDay = 2;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final db = DatabaseHelper();
    final s = await db.getNotificationSettings();
    final daysStr = s['days_enabled'] as String;
    setState(() {
      _activeDays = daysStr.split('').map((c) => c == '1').toList();
      if (_activeDays.length != 7) _activeDays = List.filled(7, true);
      _startHour = s['start_hour'] as int;
      _endHour = s['end_hour'] as int;
      _perDay = s['per_day'] as int;
      _loading = false;
    });
  }

  Future<void> _saveSettings() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final daysStr = _activeDays.map((b) => b ? '1' : '0').join();
      final db = DatabaseHelper();
      await db.saveNotificationSettings(
        daysEnabled: daysStr,
        startHour: _startHour,
        endHour: _endHour,
        perDay: _perDay,
      );
      final lang =
          mounted ? context.read<LanguageProvider>().currentLocale : 'en';
      final messages = await _loadNotificationMessages(lang);
      await sl<NotificationService>().scheduleNotifications(
        activeDays: _activeDays,
        startHour: _startHour,
        endHour: _endHour,
        notificationsPerDay: _perDay,
        messages: messages,
      );
      if (mounted) {
        showSuccessToast(context, context.t('notification_saved'));
      }
    } catch (_) {}
    if (mounted) setState(() => _saving = false);
  }

  Future<List<Map<String, String>>> _loadNotificationMessages(
      String locale) async {
    try {
      final data = await rootBundle
          .loadString('assets/messages/$locale/notification_messages.json');
      final json = jsonDecode(data) as Map<String, dynamic>;
      final list = json['messages'] as List;
      return list
          .map((e) => {
                'title': e['title'] as String,
                'body': e['body'] as String,
              })
          .toList();
    } catch (_) {
      return [
        {'title': 'Time to read!', 'body': 'Your village is waiting!'}
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.read<LanguageProvider>();
    final dayKeys = [
      'notification_day_mon',
      'notification_day_tue',
      'notification_day_wed',
      'notification_day_thu',
      'notification_day_fri',
      'notification_day_sat',
      'notification_day_sun',
    ];

    if (_loading) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
            child: CircularProgressIndicator(color: AppTheme.lavender)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.notifications_rounded,
                size: 20, color: AppTheme.lavender),
            SizedBox(width: 8),
            Text(
              context.t('notification_settings'),
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkText),
            ),
          ],
        ),
        SizedBox(height: 12),
        Text(
          context.t('notification_days_label'),
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkText.withValues(alpha: 0.7)),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: List.generate(7, (i) {
            final isActive = _activeDays[i];
            return GestureDetector(
              onTap: () => setState(() => _activeDays[i] = !_activeDays[i]),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 180),
                padding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppTheme.lavender
                      : AppTheme.lavender.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive
                        ? AppTheme.darkLavender
                        : AppTheme.lavender.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  lang.translate(dayKeys[i]),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isActive
                        ? AppTheme.darkText
                        : AppTheme.darkText.withValues(alpha: 0.45),
                  ),
                ),
              ),
            );
          }),
        ),
        SizedBox(height: 14),
        Text(
          context.t('notification_hours_label'),
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkText.withValues(alpha: 0.7)),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _HourPicker(
                label: context.t('notification_from_label'),
                value: _startHour,
                min: 0,
                max: _endHour - 1,
                onChanged: (v) => setState(() => _startHour = v),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _HourPicker(
                label: context.t('notification_to_label'),
                value: _endHour,
                min: _startHour + 1,
                max: 23,
                onChanged: (v) => setState(() => _endHour = v),
              ),
            ),
          ],
        ),
        SizedBox(height: 14),
        Text(
          context.t('notification_count_label'),
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkText.withValues(alpha: 0.7)),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              onPressed:
                  _perDay > 1 ? () => setState(() => _perDay--) : null,
              icon: Icon(Icons.remove_circle_outline_rounded),
              color: AppTheme.lavender,
              disabledColor: AppTheme.lavender.withValues(alpha: 0.3),
            ),
            Expanded(
              child: Center(
                child: Text(
                  '$_perDay',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkText),
                ),
              ),
            ),
            IconButton(
              onPressed:
                  _perDay < 10 ? () => setState(() => _perDay++) : null,
              icon: Icon(Icons.add_circle_outline_rounded),
              color: AppTheme.lavender,
              disabledColor: AppTheme.lavender.withValues(alpha: 0.3),
            ),
          ],
        ),
        SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: _saving
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        color: AppTheme.darkText, strokeWidth: 2))
                : Icon(Icons.notifications_active_rounded, size: 18),
            label: Text(context.t('notification_save')),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lavender,
              foregroundColor: AppTheme.darkText,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: _saving ? null : _saveSettings,
          ),
        ),
        SizedBox(height: 8),
      ],
    );
  }
}

class _HourPicker extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _HourPicker({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.lavender.withValues(alpha: 0.08),
        border:
            Border.all(color: AppTheme.lavender.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.darkText.withValues(alpha: 0.55))),
                Text(
                  '${value.toString().padLeft(2, '0')}:00',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkLavender),
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: value < max ? () => onChanged(value + 1) : null,
                child: Icon(Icons.keyboard_arrow_up_rounded,
                    size: 20,
                    color: value < max
                        ? AppTheme.lavender
                        : AppTheme.lavender.withValues(alpha: 0.3)),
              ),
              GestureDetector(
                onTap: value > min ? () => onChanged(value - 1) : null,
                child: Icon(Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: value > min
                        ? AppTheme.lavender
                        : AppTheme.lavender.withValues(alpha: 0.3)),
              ),
            ],
          ),
        ],
      ),
    );
  }
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
