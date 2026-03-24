import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reading_village/infrastructure/ui/config/app_theme.dart';
import 'package:reading_village/infrastructure/persistence/database_helper.dart';
import 'package:reading_village/adapters/providers/village_provider.dart';
import 'package:reading_village/infrastructure/ui/widgets/common/missions_active_tab.dart';
import 'package:reading_village/infrastructure/ui/widgets/common/missions_tree_tab.dart';

export 'package:reading_village/infrastructure/ui/widgets/common/missions_active_tab.dart' show MissionColors;

void showMissionsModal(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => const MissionsDialog(),
  );
}

class MissionsDialog extends StatefulWidget {
  const MissionsDialog({super.key});

  @override
  State<MissionsDialog> createState() => _MissionsDialogState();
}

class _MissionsDialogState extends State<MissionsDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _totalPagesRead = 0;
  int _completedBooks = 0;
  bool _statsLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBookStats();
  }

  Future<void> _loadBookStats() async {
    final db = DatabaseHelper();
    final pages = await db.getTotalPagesRead();
    final books = await db.getCompletedBooksCount();
    if (mounted) {
      setState(() {
        _totalPagesRead = pages;
        _completedBooks = books;
        _statsLoaded = true;
      });
      final village = context.read<VillageProvider>();
      await village.checkMissions(
          totalPagesRead: _totalPagesRead, completedBooks: _completedBooks);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final screenSize = MediaQuery.of(context).size;
    final maxHeight = isLandscape
        ? screenSize.height * 0.92
        : screenSize.height * 0.82;
    final maxWidth = isLandscape ? 680.0 : screenSize.width * 0.98;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isLandscape ? 24 : 6,
        vertical: isLandscape ? 16 : 24,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: maxWidth,
        constraints: BoxConstraints(maxHeight: maxHeight),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cream,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.flag, size: 24, color: AppTheme.pink),
                const SizedBox(width: 8),
                Text('Missions',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkText)),
                const Spacer(),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context)),
              ],
            ),
            TabBar(
              controller: _tabController,
              labelColor: AppTheme.darkText,
              unselectedLabelColor:
                  AppTheme.darkText.withValues(alpha: 0.5),
              indicatorColor: AppTheme.pink,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(fontSize: 13),
              tabs: const [
                Tab(text: 'Active Missions'),
                Tab(text: 'Mission Tree'),
              ],
            ),
            const SizedBox(height: 8),
            Flexible(
              child: TabBarView(
                controller: _tabController,
                children: [
                  ActiveMissionsTab(
                    totalPagesRead: _totalPagesRead,
                    completedBooks: _completedBooks,
                    statsLoaded: _statsLoaded,
                    onClaimed: () => _loadBookStats(),
                  ),
                  MissionTreeTab(
                    totalPagesRead: _totalPagesRead,
                    completedBooks: _completedBooks,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
