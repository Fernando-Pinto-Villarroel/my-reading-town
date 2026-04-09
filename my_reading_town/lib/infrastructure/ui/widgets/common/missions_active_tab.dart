import 'dart:async';
import 'package:flutter/material.dart';
import 'package:my_reading_town/infrastructure/ui/widgets/common/app_toast.dart';
import 'package:provider/provider.dart';
import 'package:my_reading_town/infrastructure/ui/config/app_theme.dart';
import 'package:my_reading_town/domain/entities/mission.dart';
import 'package:my_reading_town/domain/entities/mission_data.dart';
import 'package:my_reading_town/domain/rules/holiday_rules.dart';
import 'package:my_reading_town/domain/rules/species_rules.dart';
import 'package:my_reading_town/adapters/providers/village_provider.dart';
import 'package:my_reading_town/infrastructure/ui/widgets/common/resource_icon.dart';
import 'package:my_reading_town/infrastructure/ui/localization/context_ext.dart';

Color _rarityColor(VillagerRarity rarity) {
  switch (rarity) {
    case VillagerRarity.common:
      return const Color(0xFF78909C);
    case VillagerRarity.rare:
      return const Color(0xFF1E88E5);
    case VillagerRarity.extraordinary:
      return const Color(0xFF8E24AA);
    case VillagerRarity.legendary:
      return const Color(0xFFEF6C00);
    case VillagerRarity.godly:
      return const Color(0xFFE53935);
  }
}

class MissionColors {
  static const Color basicConstruction = AppTheme.mint;
  static const Color advancedConstruction = AppTheme.skyBlue;
  static const Color villager = AppTheme.pink;
  static const Color bookTracking = AppTheme.lavender;
  static const Color halloween = Color(0xFFFF8C42);
  static const Color christmas = Color(0xFF66BB6A);
  static const Color easter = Color(0xFFEC407A);
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
      case MissionBranch.halloween:
        return halloween;
      case MissionBranch.christmas:
        return christmas;
      case MissionBranch.easter:
        return easter;
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
      case MissionBranch.halloween:
        return Icons.nightlight_round;
      case MissionBranch.christmas:
        return Icons.ac_unit;
      case MissionBranch.easter:
        return Icons.egg_alt;
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
            Text(context.t('all_missions_completed'),
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkText)),
            const SizedBox(height: 4),
            Text(context.t('true_village_master'),
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

    final isHoliday = HolidayRules.isHolidayBranch(mission.branch);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCompleted ? color.withValues(alpha: 0.15) : AppTheme.softWhite,
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
                      context.t(
                        'branch_${mission.branch.name.replaceAllMapped(RegExp(r'[A-Z]'), (m) => '_${m[0]!.toLowerCase()}')}',
                        fallback: MissionData.branchDisplayName(mission.branch),
                      ),
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.darkText),
                    ),
                  ],
                ),
              ),
              if (isHoliday) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    context.t('event_badge'),
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: color),
                  ),
                ),
              ],
              const Spacer(),
              if (isCompleted) Icon(Icons.check_circle, size: 20, color: color),
            ],
          ),
          if (isHoliday) ...[
            const SizedBox(height: 4),
            EventCountdownBadge(branch: mission.branch, color: color),
          ],
          const SizedBox(height: 8),
          Text(
            context.t('mission_title_${mission.id}', fallback: mission.title),
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkText),
          ),
          const SizedBox(height: 2),
          Text(
            context.t('mission_desc_${mission.id}',
                fallback: mission.description),
            style: TextStyle(
                fontSize: 12, color: AppTheme.darkText.withValues(alpha: 0.6)),
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
              Expanded(
                child: RewardBadges(reward: mission.reward),
              ),
              const SizedBox(width: 8),
              if (isCompleted)
                Expanded(
                  child: ClaimButton(
                    mission: mission,
                    village: village,
                    onClaimed: onClaimed,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class EventCountdownBadge extends StatefulWidget {
  final MissionBranch branch;
  final Color color;
  const EventCountdownBadge({super.key, required this.branch, required this.color});

  @override
  State<EventCountdownBadge> createState() => _EventCountdownBadgeState();
}

class _EventCountdownBadgeState extends State<EventCountdownBadge> {
  late Timer _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = _calcRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _remaining = _calcRemaining());
    });
  }

  Duration _calcRemaining() {
    final event = HolidayRules.eventForBranch(widget.branch);
    if (event == null) return Duration.zero;
    final diff = event.eventEnd(DateTime.now()).difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = _remaining.inDays;
    final h = _remaining.inHours % 24;
    final m = _remaining.inMinutes % 60;
    final s = _remaining.inSeconds % 60;
    final countdown =
        '${d.toString().padLeft(2, '0')}:${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return Row(
      children: [
        Icon(Icons.timer_outlined, size: 11, color: widget.color),
        const SizedBox(width: 3),
        Text(
          '${context.t('event_ends_in')} $countdown',
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: widget.color),
        ),
      ],
    );
  }
}

class RewardBadges extends StatelessWidget {
  final MissionReward reward;
  const RewardBadges({super.key, required this.reward});

  @override
  Widget build(BuildContext context) {
    final speciesData = reward.speciesId != null
        ? SpeciesRules.findById(reward.speciesId!)
        : null;
    final speciesColor =
        speciesData != null ? _rarityColor(speciesData.rarity) : AppTheme.gemPurple;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
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
        if (reward.speciesId != null)
          _assetBadge(
            asset: SizedBox(
              width: 20,
              height: 20,
              child: Image.asset(
                'assets/images/${reward.speciesId}_villager.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    Icon(Icons.pets, size: 14, color: speciesColor),
              ),
            ),
            text: speciesData != null
                ? context.t(speciesData.nameKey, fallback: speciesData.nameKey)
                : context.t('species_new'),
            color: speciesColor,
            bgColor: speciesColor.withValues(alpha: 0.15),
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
        final result = await village.claimMissionReward(mission.id);
        if (result.success) {
          onClaimed();
          if (context.mounted) {
            if (result.speciesId != null) {
              _showSpeciesRewardDialog(context, result);
            } else {
              showSuccessToast(context,
                  '${context.t('reward_claimed_prefix')} ${mission.reward}');
            }
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
          context.t('claim_reward'),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _showSpeciesRewardDialog(
    BuildContext context,
    ({
      bool success,
      bool isDuplicate,
      String? speciesId,
      String? speciesNameKey
    }) result,
  ) {
    final speciesData = result.speciesId != null
        ? SpeciesRules.findById(result.speciesId!)
        : null;
    final rarityColor =
        speciesData != null ? _rarityColor(speciesData.rarity) : AppTheme.gemPurple;
    final speciesName = result.speciesNameKey != null
        ? context.t(result.speciesNameKey!, fallback: result.speciesNameKey!)
        : '';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.cream,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (result.isDuplicate) ...[
                Icon(Icons.warning_amber_rounded,
                    size: 48, color: AppTheme.coinGold),
                const SizedBox(height: 8),
                Text(
                  context.t('roulette_species_duplicate'),
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkText),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  context
                      .t('roulette_species_duplicate_desc')
                      .replaceAll('{species}', speciesName)
                      .replaceAll('{gems}',
                          '${SpeciesRules.duplicateSpeciesGemCompensation}'),
                  style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.darkText.withValues(alpha: 0.7)),
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: rarityColor.withValues(alpha: 0.12),
                    border: Border.all(color: rarityColor, width: 2.5),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/${result.speciesId}_villager.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          Icon(Icons.pets, size: 48, color: rarityColor),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  context.t('species_new'),
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkText),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  speciesName,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: rarityColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                if (speciesData != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: rarityColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: rarityColor),
                    ),
                    child: Text(
                      context.t(SpeciesRules.rarityKey(speciesData.rarity)),
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: rarityColor),
                    ),
                  ),
              ],
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [AppTheme.pink, AppTheme.lavender]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    context.t('done'),
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
