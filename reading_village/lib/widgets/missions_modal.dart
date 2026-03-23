import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../data/database_helper.dart';
import '../models/mission.dart';
import '../providers/village_provider.dart';
import 'resource_icon.dart';

/// Color palette for mission branches.
class MissionColors {
  static const Color basicConstruction = AppTheme.mint;
  static const Color advancedConstruction = AppTheme.skyBlue;
  static const Color villager = AppTheme.pink;
  static const Color bookTracking = AppTheme.lavender;
  static const Color locked = Color(0xFFBDBDBD);

  static Color forBranch(MissionBranch branch) {
    switch (branch) {
      case MissionBranch.basicConstruction: return basicConstruction;
      case MissionBranch.advancedConstruction: return advancedConstruction;
      case MissionBranch.villager: return villager;
      case MissionBranch.bookTracking: return bookTracking;
    }
  }

  static IconData iconForBranch(MissionBranch branch) {
    switch (branch) {
      case MissionBranch.basicConstruction: return Icons.construction;
      case MissionBranch.advancedConstruction: return Icons.apartment;
      case MissionBranch.villager: return Icons.pets;
      case MissionBranch.bookTracking: return Icons.auto_stories;
    }
  }
}

/// Shows the missions modal dialog.
void showMissionsModal(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => const _MissionsDialog(),
  );
}

class _MissionsDialog extends StatefulWidget {
  const _MissionsDialog();

  @override
  State<_MissionsDialog> createState() => _MissionsDialogState();
}

class _MissionsDialogState extends State<_MissionsDialog>
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
      // Check missions with book stats
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
            // Header
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
            // Tabs
            TabBar(
              controller: _tabController,
              labelColor: AppTheme.darkText,
              unselectedLabelColor: AppTheme.darkText.withValues(alpha: 0.5),
              indicatorColor: AppTheme.pink,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(fontSize: 13),
              tabs: const [
                Tab(text: 'Active Missions'),
                Tab(text: 'Mission Tree'),
              ],
            ),
            const SizedBox(height: 8),
            // Tab content
            Flexible(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _ActiveMissionsTab(
                    totalPagesRead: _totalPagesRead,
                    completedBooks: _completedBooks,
                    statsLoaded: _statsLoaded,
                    onClaimed: () => _loadBookStats(),
                  ),
                  _MissionTreeTab(
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

// ════════════════════════════════════════════════════════════════
// ─── ACTIVE MISSIONS TAB ────────────────────────────────────
// ════════════════════════════════════════════════════════════════

class _ActiveMissionsTab extends StatelessWidget {
  final int totalPagesRead;
  final int completedBooks;
  final bool statsLoaded;
  final VoidCallback onClaimed;

  const _ActiveMissionsTab({
    required this.totalPagesRead,
    required this.completedBooks,
    required this.statsLoaded,
    required this.onClaimed,
  });

  @override
  Widget build(BuildContext context) {
    final village = context.watch<VillageProvider>();
    final activeMissions = village.getActiveMissions();

    if (!statsLoaded) {
      return const Center(
        child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(AppTheme.pink)),
      );
    }

    if (activeMissions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events, size: 64,
                color: AppTheme.coinGold.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text('All missions completed!',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkText)),
            const SizedBox(height: 4),
            Text('You are a true village master!',
                style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.darkText.withValues(alpha: 0.6))),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      itemCount: activeMissions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final mission = activeMissions[i];
        return _ActiveMissionCard(
          mission: mission,
          village: village,
          totalPagesRead: totalPagesRead,
          completedBooks: completedBooks,
          onClaimed: onClaimed,
        );
      },
    );
  }
}

class _ActiveMissionCard extends StatelessWidget {
  final Mission mission;
  final VillageProvider village;
  final int totalPagesRead;
  final int completedBooks;
  final VoidCallback onClaimed;

  const _ActiveMissionCard({
    required this.mission,
    required this.village,
    required this.totalPagesRead,
    required this.completedBooks,
    required this.onClaimed,
  });

  @override
  Widget build(BuildContext context) {
    final color = MissionColors.forBranch(mission.branch);
    final progress = village.missionProgress[mission.id];
    final isCompleted = progress?.isCompleted ?? false;
    final progressValues = village.getMissionProgressValues(mission,
        totalPagesRead: totalPagesRead, completedBooks: completedBooks);
    final progressRatio = progressValues.target > 0
        ? progressValues.current / progressValues.target
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCompleted
            ? color.withValues(alpha: 0.15)
            : AppTheme.softWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? color.withValues(alpha: 0.6)
              : color.withValues(alpha: 0.3),
          width: isCompleted ? 2 : 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Branch label + title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(MissionColors.iconForBranch(mission.branch),
                        size: 14, color: AppTheme.darkText),
                    const SizedBox(width: 4),
                    Text(
                      MissionData.branchDisplayName(mission.branch),
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.darkText),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (isCompleted)
                Icon(Icons.check_circle, size: 20, color: color),
            ],
          ),
          const SizedBox(height: 8),
          // Mission title
          Text(
            mission.title,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkText),
          ),
          const SizedBox(height: 2),
          Text(
            mission.description,
            style: TextStyle(
                fontSize: 12,
                color: AppTheme.darkText.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 10),
          // Progress bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progressRatio.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: color.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${progressValues.current}/${progressValues.target}',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkText),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Rewards + Claim button
          Row(
            children: [
              _RewardBadges(reward: mission.reward),
              const Spacer(),
              if (isCompleted)
                _ClaimButton(
                  mission: mission,
                  village: village,
                  onClaimed: onClaimed,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Darker gold color for XP text to ensure readability.
const Color _expTextColor = Color(0xFFB8860B); // dark goldenrod

class _RewardBadges extends StatelessWidget {
  final MissionReward reward;
  const _RewardBadges({required this.reward});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      children: [
        if (reward.exp > 0)
          _assetBadge(
            asset: Icon(Icons.star, size: 14, color: _expTextColor),
            text: '${reward.exp} XP',
            color: _expTextColor,
            bgColor: const Color(0xFFFFF3CD),
          ),
        if (reward.coins > 0)
          _assetBadge(
            asset: ResourceIcon.coin(size: 14),
            text: '${reward.coins}',
            color: AppTheme.darkOrange,
            bgColor: AppTheme.darkOrange.withValues(alpha: 0.15),
          ),
        if (reward.gems > 0)
          _assetBadge(
            asset: ResourceIcon.gem(size: 14),
            text: '${reward.gems}',
            color: AppTheme.gemPurple,
            bgColor: AppTheme.gemPurple.withValues(alpha: 0.15),
          ),
      ],
    );
  }

  Widget _assetBadge({
    required Widget asset,
    required String text,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          asset,
          const SizedBox(width: 3),
          Text(text,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _ClaimButton extends StatelessWidget {
  final Mission mission;
  final VillageProvider village;
  final VoidCallback onClaimed;

  const _ClaimButton({
    required this.mission,
    required this.village,
    required this.onClaimed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final success = await village.claimMissionReward(mission.id);
        if (success) {
          onClaimed();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Reward claimed: ${mission.reward}',
                  style: TextStyle(color: AppTheme.darkText),
                ),
                backgroundColor: AppTheme.mint,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.pink, AppTheme.lavender],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppTheme.pink.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          'Claim Reward',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// ─── MISSION TREE TAB ───────────────────────────────────────
// ════════════════════════════════════════════════════════════════

class _MissionTreeTab extends StatelessWidget {
  final int totalPagesRead;
  final int completedBooks;

  const _MissionTreeTab({
    required this.totalPagesRead,
    required this.completedBooks,
  });

  @override
  Widget build(BuildContext context) {
    final village = context.watch<VillageProvider>();

    return SingleChildScrollView(
      child: Column(
        children: [
          for (final branch in MissionBranch.values) ...[
            _BranchTreeCard(
              branch: branch,
              village: village,
              totalPagesRead: totalPagesRead,
              completedBooks: completedBooks,
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _BranchTreeCard extends StatefulWidget {
  final MissionBranch branch;
  final VillageProvider village;
  final int totalPagesRead;
  final int completedBooks;

  const _BranchTreeCard({
    required this.branch,
    required this.village,
    required this.totalPagesRead,
    required this.completedBooks,
  });

  @override
  State<_BranchTreeCard> createState() => _BranchTreeCardState();
}

class _BranchTreeCardState extends State<_BranchTreeCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final color = MissionColors.forBranch(widget.branch);
    final isUnlocked = widget.village.isBranchUnlocked(widget.branch);
    final isComplete = widget.village.isBranchFullyCompleted(widget.branch);
    final missions = MissionData.getMissionsForBranch(widget.branch);
    final deps = MissionData.branchDependencies(widget.branch);

    // Count completed/claimed
    int claimedCount = 0;
    for (final m in missions) {
      final p = widget.village.missionProgress[m.id];
      if (p != null && p.isClaimed) claimedCount++;
    }

    return Container(
      decoration: BoxDecoration(
        color: isUnlocked ? AppTheme.softWhite : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isComplete
              ? color.withValues(alpha: 0.6)
              : isUnlocked
                  ? color.withValues(alpha: 0.3)
                  : Colors.grey.shade300,
          width: isComplete ? 2 : 1.5,
        ),
      ),
      child: Column(
        children: [
          // Branch header
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? color.withValues(alpha: 0.2)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      MissionColors.iconForBranch(widget.branch),
                      size: 22,
                      color: isUnlocked ? AppTheme.darkText : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          MissionData.branchDisplayName(widget.branch),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isUnlocked
                                ? AppTheme.darkText
                                : Colors.grey,
                          ),
                        ),
                        if (!isUnlocked && deps.isNotEmpty)
                          Text(
                            'Requires: ${deps.map(MissionData.branchDisplayName).join(', ')}',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500),
                          ),
                        if (isUnlocked)
                          Text(
                            '$claimedCount / ${missions.length} completed',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.darkText
                                    .withValues(alpha: 0.5)),
                          ),
                      ],
                    ),
                  ),
                  if (isComplete)
                    Icon(Icons.emoji_events, size: 22,
                        color: AppTheme.coinGold),
                  if (!isUnlocked)
                    Icon(Icons.lock, size: 20, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 22,
                    color: isUnlocked ? AppTheme.darkText : Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          // Progress bar
          if (isUnlocked)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: missions.isEmpty
                      ? 0
                      : claimedCount / missions.length,
                  minHeight: 4,
                  backgroundColor: color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ),
          // Expanded mission list
          if (_expanded && isUnlocked) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: [
                  for (int i = 0; i < missions.length; i++) ...[
                    _MissionTreeNode(
                      mission: missions[i],
                      village: widget.village,
                      totalPagesRead: widget.totalPagesRead,
                      completedBooks: widget.completedBooks,
                      isLast: i == missions.length - 1,
                      isActive: widget.village.getActiveMission(widget.branch)?.id == missions[i].id,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (_expanded && !isUnlocked) ...[
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Complete the ${deps.map(MissionData.branchDisplayName).join(' and ')} branch to unlock.',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MissionTreeNode extends StatelessWidget {
  final Mission mission;
  final VillageProvider village;
  final int totalPagesRead;
  final int completedBooks;
  final bool isLast;
  final bool isActive;

  const _MissionTreeNode({
    required this.mission,
    required this.village,
    required this.totalPagesRead,
    required this.completedBooks,
    required this.isLast,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final progress = village.missionProgress[mission.id];
    final isClaimed = progress?.isClaimed ?? false;
    final isCompleted = progress?.isCompleted ?? false;
    final color = MissionColors.forBranch(mission.branch);

    // Determine node state
    Color nodeColor;
    IconData nodeIcon;
    if (isClaimed) {
      nodeColor = color;
      nodeIcon = Icons.check_circle;
    } else if (isCompleted) {
      nodeColor = AppTheme.coinGold;
      nodeIcon = Icons.stars;
    } else if (isActive) {
      nodeColor = color;
      nodeIcon = Icons.radio_button_checked;
    } else {
      nodeColor = Colors.grey.shade400;
      nodeIcon = Icons.radio_button_unchecked;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tree line + node icon
        SizedBox(
          width: 28,
          child: Column(
            children: [
              Icon(nodeIcon, size: 18, color: nodeColor),
              if (!isLast)
                Container(
                  width: 2,
                  height: 28,
                  color: isClaimed
                      ? color.withValues(alpha: 0.4)
                      : Colors.grey.shade300,
                ),
            ],
          ),
        ),
        // Mission info
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mission.title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isClaimed
                        ? AppTheme.darkText.withValues(alpha: 0.5)
                        : AppTheme.darkText,
                    decoration:
                        isClaimed ? TextDecoration.lineThrough : null,
                  ),
                ),
                _RewardBadges(reward: mission.reward),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
