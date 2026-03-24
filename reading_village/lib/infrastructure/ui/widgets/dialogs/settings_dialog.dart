import 'package:flutter/material.dart';
import 'package:reading_village/infrastructure/ui/config/app_theme.dart';
import 'package:reading_village/domain/rules/village_rules.dart';
import 'package:reading_village/adapters/providers/village_provider.dart';
import 'package:reading_village/infrastructure/ui/widgets/common/shared_utils.dart';

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
                    Icon(Icons.settings,
                        size: 24, color: AppTheme.lavender),
                    SizedBox(width: 8),
                    Text('Settings',
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
                      Text('Player Level ${village.playerLevel}',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkText)),
                      SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color:
                                  AppTheme.darkText.withValues(alpha: 0.3),
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
                          '${village.exp} EXP ($expToNext to next level)',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.darkText
                                  .withValues(alpha: 0.6))),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                SizedBox(height: 12),
                TextField(
                  controller: townNameController,
                  decoration: InputDecoration(
                    labelText: 'Town Name',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
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
                    child: Text('Save'),
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
