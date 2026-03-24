import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reading_village/infrastructure/ui/config/app_theme.dart';
import 'package:reading_village/domain/rules/village_rules.dart';
import 'package:reading_village/infrastructure/ui/game/village_game.dart';
import 'package:reading_village/adapters/providers/village_provider.dart';
import 'package:reading_village/infrastructure/ui/widgets/common/resource_icon.dart';
import 'package:reading_village/infrastructure/ui/widgets/common/shared_utils.dart';
import 'package:reading_village/infrastructure/ui/localization/language_provider.dart';

void showExpansionDialog(
  BuildContext context, {
  required int chunkX,
  required int chunkY,
  required VillageProvider village,
  required VillageGame game,
  required VoidCallback onSyncGameState,
}) {
  final gemCost = VillageRules.expansionGemCost(village.expansionCount);
  final coinCost = VillageRules.expansionCoinCost(village.expansionCount);
  final canAffordGems = village.gems >= gemCost;
  final canAffordCoins = village.coins >= coinCost;

  final langProvider = context.read<LanguageProvider>();
  game.setHighlightedChunk(chunkX, chunkY);

  showDialog(
    context: context,
    barrierColor: Colors.black26,
    builder: (ctx) {
      final landscape = isLandscape(ctx);
      final gridPreview = _buildGridPreview(landscape, langProvider);
      final payButtons = _buildPayButtons(
        ctx,
        langProvider: langProvider,
        landscape: landscape,
        coinCost: coinCost,
        gemCost: gemCost,
        canAffordCoins: canAffordCoins,
        canAffordGems: canAffordGems,
        village: village,
        game: game,
        chunkX: chunkX,
        chunkY: chunkY,
        onSyncGameState: onSyncGameState,
      );

      return AlertDialog(
        backgroundColor: AppTheme.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: EdgeInsets.fromLTRB(
            landscape ? 16 : 20, landscape ? 10 : 16, landscape ? 16 : 20, 8),
        titlePadding: EdgeInsets.fromLTRB(
            landscape ? 16 : 20, landscape ? 14 : 20, landscape ? 16 : 20, 0),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome,
                size: landscape ? 18 : 22, color: AppTheme.pink),
            const SizedBox(width: 8),
            Text(
              langProvider.translate('expand_territory'),
              style: TextStyle(
                fontSize: landscape ? 15 : 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkText,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.auto_awesome,
                size: landscape ? 18 : 22, color: AppTheme.pink),
          ],
        ),
        content: ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: landscape ? 420.0 : 320.0),
          child: landscape
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    gridPreview,
                    const SizedBox(width: 16),
                    Flexible(child: payButtons),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    gridPreview,
                    const SizedBox(height: 14),
                    payButtons,
                  ],
                ),
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                game.setHighlightedChunk(null, null);
              },
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.darkText.withAlpha(160),
              ),
              child: Text(langProvider.translate('cancel')),
            ),
          ),
        ],
      );
    },
  ).then((_) {
    game.setHighlightedChunk(null, null);
  });
}

Widget _buildGridPreview(bool landscape, LanguageProvider langProvider) {
  return Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: AppTheme.softWhite,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.pink.withAlpha(100), width: 2),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: landscape ? 70 : 100,
          height: landscape ? 70 : 100,
          child: GridView.count(
            crossAxisCount: 5,
            physics: const NeverScrollableScrollPhysics(),
            children: List.generate(25, (i) {
              final isCenter = i == 12;
              return Container(
                margin: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: isCenter
                      ? AppTheme.pink.withAlpha(180)
                      : AppTheme.mint.withAlpha(120),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: isCenter
                    ? Icon(Icons.signpost,
                        size: landscape ? 7 : 10, color: AppTheme.softWhite)
                    : null,
              );
            }),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          langProvider.translate('tiles_5x5'),
          style: TextStyle(
            fontSize: landscape ? 10 : 12,
            color: AppTheme.darkText.withAlpha(160),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

Widget _buildPayButtons(
  BuildContext ctx, {
  required LanguageProvider langProvider,
  required bool landscape,
  required int coinCost,
  required int gemCost,
  required bool canAffordCoins,
  required bool canAffordGems,
  required VillageProvider village,
  required VillageGame game,
  required int chunkX,
  required int chunkY,
  required VoidCallback onSyncGameState,
}) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        langProvider.translate('unlock_area_with'),
        style: TextStyle(
          fontSize: landscape ? 12 : 14,
          color: AppTheme.darkText,
          fontWeight: FontWeight.w500,
        ),
      ),
      SizedBox(height: landscape ? 8 : 12),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: _ExpansionPayButton(
              icon: ResourceIcon.coin(size: landscape ? 22 : 28),
              amount: coinCost,
              canAfford: canAffordCoins,
              color: AppTheme.coinGold,
              isCompact: landscape,
              onPressed: () async {
                Navigator.pop(ctx);
                game.setHighlightedChunk(null, null);
                final success =
                    await village.expandTerritoryWithCoins(chunkX, chunkY);
                if (success) onSyncGameState();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              langProvider.translate('or'),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.darkText.withAlpha(140),
                fontSize: landscape ? 11 : 13,
              ),
            ),
          ),
          Expanded(
            child: _ExpansionPayButton(
              icon: ResourceIcon.gem(size: landscape ? 22 : 28),
              amount: gemCost,
              canAfford: canAffordGems,
              color: AppTheme.gemPurple,
              isCompact: landscape,
              onPressed: () async {
                Navigator.pop(ctx);
                game.setHighlightedChunk(null, null);
                final success =
                    await village.expandTerritoryWithGems(chunkX, chunkY);
                if (success) onSyncGameState();
              },
            ),
          ),
        ],
      ),
    ],
  );
}

class _ExpansionPayButton extends StatelessWidget {
  final Widget icon;
  final int amount;
  final bool canAfford;
  final Color color;
  final VoidCallback onPressed;
  final bool isCompact;

  const _ExpansionPayButton({
    required this.icon,
    required this.amount,
    required this.canAfford,
    required this.color,
    required this.onPressed,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: canAfford ? 1.0 : 0.5,
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: canAfford ? color.withAlpha(30) : Colors.grey.withAlpha(20),
        borderRadius: BorderRadius.circular(isCompact ? 12 : 16),
        child: InkWell(
          onTap: canAfford ? onPressed : null,
          borderRadius: BorderRadius.circular(isCompact ? 12 : 16),
          child: Container(
            padding: EdgeInsets.symmetric(
                vertical: isCompact ? 8 : 12,
                horizontal: isCompact ? 6 : 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isCompact ? 12 : 16),
              border: Border.all(
                color: canAfford
                    ? color.withAlpha(120)
                    : Colors.grey.withAlpha(60),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                icon,
                SizedBox(height: isCompact ? 4 : 6),
                Text(
                  '$amount',
                  style: TextStyle(
                    fontSize: isCompact ? 13 : 16,
                    fontWeight: FontWeight.bold,
                    color: canAfford ? AppTheme.darkText : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
