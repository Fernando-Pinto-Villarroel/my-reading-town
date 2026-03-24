import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reading_village/infrastructure/ui/config/app_theme.dart';
import 'package:reading_village/domain/entities/mission.dart';
import 'package:reading_village/domain/entities/mission_data.dart';
import 'package:reading_village/adapters/providers/village_provider.dart';
import 'package:reading_village/infrastructure/ui/widgets/common/resource_icon.dart';

class MissionColors {
  static const Color basicConstruction = AppTheme.mint;
  static const Color advancedConstruction = AppTheme.skyBlue;
  static const Color villager = AppTheme.pink;
  static const Color bookTracking = AppTheme.lavender;
  static const Color locked = Color(0xFFBDBDBD);

  static Color forBranch(MissionBranch branch) {
    switch (branch) {
      case MissionBranch.basicConstruction:
        return basicConstruction;
      case MissionBranch.advancedConstruction:
        return advancedConstruction;
      case MissionBranch.villager:
        return villager;
      case MissionBranch.bookTracking:
        return bookTracking;
    }
  }

  static IconData iconForBranch(MissionBranch branch) {
    switch (branch) {
      case MissionBranch.basicConstruction:
        return Icons.construction;
      case MissionBranch.advancedConstruction:
        return Icons.apartment;
      case MissionBranch.villager:
        return Icons.pets;
      case MissionBranch.bookTracking:
        return Icons.auto_stories;
    }
  }
}

const Color expTextColor = Color(0xFFB8860B);

class ActiveMissionsTab extends StatelessWidget {
  final int totalPagesRead;
  final int completedBooks;
  final bool statsLoaded;
  final VoidCallback onClaimed;

  const ActiveMissionsTab({
    super.key,
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
            Icon(Icons.emoji_events,
                size: 64, color: AppTheme.coinGold.withValues(alpha: 0.5)),
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
        return ActiveMissionCard(
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

class ActiveMissionCard extends StatelessWidget {
  final Mission mission;
  final VillageProvider village;
  final int totalPagesRead;
  final int completedBooks;
  final VoidCallback onClaimed;

  const ActiveMissionCard({
    super.key,
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
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
          Row(
            children: [
              RewardBadges(reward: mission.reward),
              const Spacer(),
              if (isCompleted)
                ClaimButton(
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

class RewardBadges extends StatelessWidget {
  final MissionReward reward;
  const RewardBadges({super.key, required this.reward});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      children: [
        if (reward.exp > 0)
          _assetBadge(
            asset: Icon(Icons.star, size: 14, color: expTextColor),
            text: '${reward.exp} XP',
            color: expTextColor,
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

class ClaimButton extends StatelessWidget {
  final Mission mission;
  final VillageProvider village;
  final VoidCallback onClaimed;

  const ClaimButton({
    super.key,
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
