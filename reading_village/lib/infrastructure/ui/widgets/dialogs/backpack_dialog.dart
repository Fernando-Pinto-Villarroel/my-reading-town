import 'package:flutter/material.dart';
import 'package:reading_village/infrastructure/ui/config/app_theme.dart';
import 'package:reading_village/domain/entities/inventory_item.dart';
import 'package:reading_village/adapters/providers/village_provider.dart';
import 'package:reading_village/infrastructure/ui/widgets/common/shared_utils.dart';
import 'package:reading_village/infrastructure/ui/widgets/dialogs/villager_book_dialog.dart';

void showBackpackDialog(BuildContext context, VillageProvider village) {
  showDialog(
    context: context,
    builder: (ctx) {
      final landscape = isLandscape(ctx);
      return Dialog(
        insetPadding: EdgeInsets.symmetric(
            horizontal: landscape ? 24 : 6, vertical: landscape ? 16 : 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxHeight: 500),
          decoration: BoxDecoration(
            color: AppTheme.cream,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.backpack, size: 24, color: AppTheme.peach),
                  const SizedBox(width: 8),
                  Text('Backpack',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkText)),
                  const Spacer(),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 8),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (village.activePowerups
                          .where((p) => p.isActive)
                          .isNotEmpty) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Active Powerups',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.lavender)),
                        ),
                        const SizedBox(height: 6),
                        ...village.activePowerups
                            .where((p) => p.isActive)
                            .map((p) => _ActivePowerupTile(powerup: p)),
                        const SizedBox(height: 12),
                      ],
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Items',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.lavender)),
                      ),
                      const SizedBox(height: 6),
                      _ItemTile(
                        assetPath: 'assets/images/book_item.png',
                        name: 'Happiness Book',
                        description:
                            'Boost a villager to 100% happiness for 24h',
                        quantity: village.itemQuantity('book'),
                        color: AppTheme.pink,
                        onUse: () {
                          Navigator.pop(ctx);
                          showSelectVillagerForBook(context, village);
                        },
                      ),
                      const SizedBox(height: 8),
                      _ItemTile(
                        assetPath: 'assets/images/sandwich_item.png',
                        name: 'Constructor Sandwich',
                        description: village.isSpeedBoostActive
                            ? 'Already active!'
                            : '2x construction speed for 1 hour',
                        quantity: village.itemQuantity('sandwich'),
                        color: AppTheme.peach,
                        alreadyActive: village.isSpeedBoostActive,
                        onUse: () async {
                          Navigator.pop(ctx);
                          final success =
                              await village.useSandwichItem();
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Construction speed doubled for 1 hour!',
                                    style:
                                        TextStyle(color: AppTheme.darkText)),
                                backgroundColor: AppTheme.mint,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      _ItemTile(
                        assetPath: 'assets/images/hammer_item.png',
                        name: 'Constructor Hammer',
                        description: village.isHammerActive
                            ? 'Already active!'
                            : '+1 extra constructor for 24 hours',
                        quantity: village.itemQuantity('hammer'),
                        color: AppTheme.coinGold,
                        alreadyActive: village.isHammerActive,
                        onUse: () async {
                          Navigator.pop(ctx);
                          final success =
                              await village.useHammerItem();
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Extra constructor slot for 24 hours!',
                                    style:
                                        TextStyle(color: AppTheme.darkText)),
                                backgroundColor: AppTheme.mint,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _ActivePowerupTile extends StatelessWidget {
  final ActivePowerup powerup;

  const _ActivePowerupTile({required this.powerup});

  @override
  Widget build(BuildContext context) {
    String name;
    String assetPath;
    Color color;
    switch (powerup.type) {
      case 'book_happiness':
        name = 'Happiness Boost';
        assetPath = 'assets/images/book_item.png';
        color = AppTheme.pink;
        break;
      case 'sandwich_speed':
        name = '2x Speed';
        assetPath = 'assets/images/sandwich_item.png';
        color = AppTheme.peach;
        break;
      case 'hammer_constructor':
        name = 'Extra Constructor';
        assetPath = 'assets/images/hammer_item.png';
        color = AppTheme.coinGold;
        break;
      default:
        name = powerup.type;
        assetPath = 'assets/images/gem.png';
        color = AppTheme.lavender;
    }

    final remaining = powerup.remainingTime;
    final timeStr = formatDuration(remaining);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Image.asset(assetPath, width: 24, height: 24),
          const SizedBox(width: 8),
          Expanded(
              child: Text(name,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkText))),
          Text(timeStr,
              style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.darkText.withValues(alpha: 0.6))),
        ],
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final String assetPath;
  final String name;
  final String description;
  final int quantity;
  final Color color;
  final VoidCallback onUse;
  final bool alreadyActive;

  const _ItemTile({
    required this.assetPath,
    required this.name,
    required this.description,
    required this.quantity,
    required this.color,
    required this.onUse,
    this.alreadyActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final canUse = quantity > 0 && !alreadyActive;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: canUse
            ? color.withValues(alpha: 0.08)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: canUse
              ? color.withValues(alpha: 0.3)
              : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: canUse
                  ? color.withValues(alpha: 0.2)
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Opacity(
                opacity: canUse ? 1.0 : 0.4,
                child: Image.asset(assetPath, width: 32, height: 32),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkText)),
                Text(description,
                    style: TextStyle(
                        fontSize: 11,
                        color: alreadyActive
                            ? AppTheme.mint
                            : AppTheme.darkText.withValues(alpha: 0.5))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              Text('x$quantity',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkText)),
              if (canUse)
                GestureDetector(
                  onTap: onUse,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Use',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ),
                )
              else if (alreadyActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.mint.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Active',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.mint)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
