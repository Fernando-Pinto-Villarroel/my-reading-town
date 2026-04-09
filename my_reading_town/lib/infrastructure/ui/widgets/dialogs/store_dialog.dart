import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_reading_town/app_constants.dart';
import 'package:my_reading_town/domain/rules/store_rules.dart';
import 'package:my_reading_town/domain/rules/species_rules.dart';
import 'package:my_reading_town/application/services/store_service.dart';
import 'package:my_reading_town/adapters/providers/village_provider.dart';
import 'package:my_reading_town/infrastructure/ui/config/app_theme.dart';
import 'package:my_reading_town/infrastructure/ui/localization/language_provider.dart';
import 'package:my_reading_town/infrastructure/ui/widgets/common/resource_icon.dart';
import 'package:my_reading_town/infrastructure/ui/widgets/common/app_toast.dart';

void showStoreDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _StoreDialog(),
  );
}

class _StoreDialog extends StatefulWidget {
  @override
  State<_StoreDialog> createState() => _StoreDialogState();
}

class _StoreDialogState extends State<_StoreDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Map<String, DiscountInfo> _discounts;
  late StoreService _storeService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _discounts = StoreRules.computeDiscounts();
    _storeService = StoreService();
    _storeService.initialize();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _storeService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.read<LanguageProvider>();
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;
    final dialogWidth =
        isLandscape ? screenSize.width * 0.75 : screenSize.width * 0.92;
    final dialogHeight =
        isLandscape ? screenSize.height * 0.88 : screenSize.height * 0.82;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      clipBehavior: Clip.antiAlias,
      backgroundColor: AppTheme.cream,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isLandscape ? 40 : 16,
        vertical: isLandscape ? 16 : 32,
      ),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Column(
          children: [
            _StoreHeader(lang: lang),
            _StoreTabBar(
              controller: _tabController,
              lang: lang,
              discounts: _discounts,
            ),
            Consumer<VillageProvider>(
              builder: (_, village, __) =>
                  _GemBalanceBar(gems: village.gems, lang: lang),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: NeverScrollableScrollPhysics(),
                children: [
                  _ResourcesTab(lang: lang),
                  _PowerupsTab(lang: lang),
                  _GemsTab(
                      lang: lang,
                      discounts: _discounts,
                      storeService: _storeService),
                  _PacksTab(
                      lang: lang,
                      discounts: _discounts,
                      storeService: _storeService),
                  _SpeciesTab(
                      lang: lang,
                      storeService: _storeService),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreHeader extends StatelessWidget {
  final LanguageProvider lang;

  const _StoreHeader({required this.lang});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.pink, AppTheme.lavender],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 12, 16),
      child: Row(
        children: [
          Icon(Icons.storefront_rounded, color: Colors.white, size: 28),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              lang.translate('store_title'),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _StoreTabBar extends StatelessWidget {
  final TabController controller;
  final LanguageProvider lang;
  final Map<String, DiscountInfo> discounts;

  const _StoreTabBar({
    required this.controller,
    required this.lang,
    required this.discounts,
  });

  bool get _hasDiscounts => discounts.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.softWhite,
      child: TabBar(
        controller: controller,
        indicatorColor: AppTheme.darkPink,
        indicatorWeight: 3,
        labelColor: AppTheme.darkPink,
        unselectedLabelColor: AppTheme.darkText.withValues(alpha: 0.5),
        labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        unselectedLabelStyle: TextStyle(fontSize: 11),
        tabs: [
          Tab(
            icon: Icon(Icons.inventory_2, size: 18),
            text: lang.translate('store_tab_resources'),
          ),
          Tab(
            icon: Icon(Icons.auto_awesome, size: 18),
            text: lang.translate('store_tab_powerups'),
          ),
          Tab(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.diamond, size: 18),
                if (_hasDiscounts)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text('%',
                          style: TextStyle(
                              fontSize: 7,
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            text: lang.translate('store_tab_gems'),
          ),
          Tab(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.card_giftcard, size: 18),
                if (_hasDiscounts)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text('%',
                          style: TextStyle(
                              fontSize: 7,
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            text: lang.translate('store_tab_packs'),
          ),
          Tab(
            icon: Icon(Icons.pets, size: 18),
            text: lang.translate('store_tab_species'),
          ),
        ],
      ),
    );
  }
}

class _ResourcesTab extends StatelessWidget {
  final LanguageProvider lang;

  const _ResourcesTab({required this.lang});

  @override
  Widget build(BuildContext context) {
    final village = context.watch<VillageProvider>();

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(
            icon: ResourceIcon.coin(size: 18),
            text: lang.translate('coins'),
            color: AppTheme.mediumOrange,
          ),
          SizedBox(height: 8),
          _ResourceGrid(
            items: StoreRules.coinItems,
            village: village,
            lang: lang,
          ),
          SizedBox(height: 16),
          _SectionLabel(
            icon: ResourceIcon.wood(size: 18),
            text: lang.translate('wood'),
            color: AppTheme.darkOrange,
          ),
          SizedBox(height: 8),
          _ResourceGrid(
            items: StoreRules.woodItems,
            village: village,
            lang: lang,
          ),
          SizedBox(height: 16),
          _SectionLabel(
            icon: ResourceIcon.metal(size: 18),
            text: lang.translate('metal'),
            color: Colors.blueGrey,
          ),
          SizedBox(height: 8),
          _ResourceGrid(
            items: StoreRules.metalItems,
            village: village,
            lang: lang,
          ),
        ],
      ),
    );
  }
}

class _ResourceGrid extends StatelessWidget {
  final List<StoreResourceItem> items;
  final VillageProvider village;
  final LanguageProvider lang;

  const _ResourceGrid({
    required this.items,
    required this.village,
    required this.lang,
  });

  Widget _iconFor(ResourceType type, double size) {
    switch (type) {
      case ResourceType.coins:
        return ResourceIcon.coin(size: size);
      case ResourceType.wood:
        return ResourceIcon.wood(size: size);
      case ResourceType.metal:
        return ResourceIcon.metal(size: size);
    }
  }

  Color _colorFor(ResourceType type) {
    switch (type) {
      case ResourceType.coins:
        return AppTheme.coinGold;
      case ResourceType.wood:
        return AppTheme.mediumOrange;
      case ResourceType.metal:
        return Colors.blueGrey.shade300;
    }
  }

  Future<void> _buy(BuildContext context, StoreResourceItem item) async {
    if (village.gems < item.gemCost) {
      _showNotEnoughGems(context, lang);
      return;
    }

    final confirmed = await _showGemConfirmDialog(context, lang, item.gemCost);
    if (!confirmed || !context.mounted) return;

    switch (item.resource) {
      case ResourceType.coins:
        await village.addResources(gems: -item.gemCost, coins: item.amount);
        break;
      case ResourceType.wood:
        await village.addResources(gems: -item.gemCost, wood: item.amount);
        break;
      case ResourceType.metal:
        await village.addResources(gems: -item.gemCost, metal: item.amount);
        break;
    }

    if (context.mounted) {
      _showPurchaseSuccess(context, lang);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.55,
      children: items.map((item) {
        final canAfford = village.gems >= item.gemCost;
        final color = _colorFor(item.resource);
        return _StoreCard(
          topColor: color.withValues(alpha: 0.2),
          borderColor: color,
          onTap: () => _buy(context, item),
          canAfford: canAfford,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _iconFor(item.resource, 50),
              SizedBox(width: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '+${item.amount}',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkText,
                    ),
                  ),
                  SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ResourceIcon.gem(size: 18),
                      SizedBox(width: 3),
                      Text(
                        '${item.gemCost}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color:
                              canAfford ? AppTheme.darkLavender : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _PowerupsTab extends StatelessWidget {
  final LanguageProvider lang;

  const _PowerupsTab({required this.lang});

  @override
  Widget build(BuildContext context) {
    final village = context.watch<VillageProvider>();

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PowerupSection(
            assetPath: 'assets/images/book_item.png',
            labelKey: 'happiness_book',
            descKey: 'happiness_book_desc',
            items: StoreRules.bookItems,
            color: AppTheme.pink,
            village: village,
            lang: lang,
          ),
          SizedBox(height: 16),
          _PowerupSection(
            assetPath: 'assets/images/sandwich_item.png',
            labelKey: 'constructor_sandwich',
            descKey: 'sandwich_desc',
            items: StoreRules.sandwichItems,
            color: AppTheme.mediumOrange,
            village: village,
            lang: lang,
          ),
          SizedBox(height: 16),
          _PowerupSection(
            assetPath: 'assets/images/hammer_item.png',
            labelKey: 'constructor_hammer',
            descKey: 'hammer_desc',
            items: StoreRules.hammerItems,
            color: AppTheme.darkSkyBlue,
            village: village,
            lang: lang,
          ),
          SizedBox(height: 16),
          _PowerupSection(
            assetPath: 'assets/images/glasses_item.png',
            labelKey: 'magic_glasses',
            descKey: 'glasses_desc',
            items: StoreRules.glassesItems,
            color: AppTheme.darkMint,
            village: village,
            lang: lang,
          ),
        ],
      ),
    );
  }
}

class _PowerupSection extends StatelessWidget {
  final String assetPath;
  final String labelKey;
  final String descKey;
  final List<StorePowerupItem> items;
  final Color color;
  final VillageProvider village;
  final LanguageProvider lang;

  const _PowerupSection({
    required this.assetPath,
    required this.labelKey,
    required this.descKey,
    required this.items,
    required this.color,
    required this.village,
    required this.lang,
  });

  Future<void> _buy(BuildContext context, StorePowerupItem item) async {
    if (village.gems < item.gemCost) {
      _showNotEnoughGems(context, lang);
      return;
    }

    final confirmed = await _showGemConfirmDialog(context, lang, item.gemCost);
    if (!confirmed || !context.mounted) return;

    await village.addResources(gems: -item.gemCost);
    final inventoryType = StoreRules.inventoryTypeForPowerup(item.powerup);
    await village.addItemToInventory(inventoryType, amount: item.quantity);

    if (context.mounted) {
      _showPurchaseSuccess(context, lang);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(assetPath, width: 24, height: 24),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang.translate(labelKey),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    lang.translate(descKey),
                    style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.darkText.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.55,
          children: items.map((item) {
            final canAfford = village.gems >= item.gemCost;
            return _StoreCard(
              topColor: color.withValues(alpha: 0.15),
              borderColor: color,
              onTap: () => _buy(context, item),
              canAfford: canAfford,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(assetPath, width: 50, height: 50),
                  SizedBox(width: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'x${item.quantity}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkText,
                        ),
                      ),
                      SizedBox(height: 3),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ResourceIcon.gem(size: 18),
                          SizedBox(width: 3),
                          Text(
                            '${item.gemCost}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: canAfford
                                  ? AppTheme.darkLavender
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _GemsTab extends StatelessWidget {
  final LanguageProvider lang;
  final Map<String, DiscountInfo> discounts;
  final StoreService storeService;

  const _GemsTab({
    required this.lang,
    required this.discounts,
    required this.storeService,
  });

  @override
  Widget build(BuildContext context) {
    final village = context.watch<VillageProvider>();

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _DiscountBanner(discounts: discounts, lang: lang),
          SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.05,
            children: StoreRules.gemsItems.map((item) {
              final discount = discounts[item.productId];
              final finalPrice = discount != null
                  ? StoreRules.applyDiscount(item.basePrice, discount.percent)
                  : item.basePrice;
              return _GemsPriceCard(
                item: item,
                finalPrice: finalPrice,
                discount: discount,
                lang: lang,
                onTap: () => _purchase(context, item, village, finalPrice),
              );
            }).toList(),
          ),
          SizedBox(height: 8),
          if (!AppConstants.playStore) _SimulationNotice(lang: lang),
        ],
      ),
    );
  }

  Future<void> _purchase(
    BuildContext context,
    StoreGemsItem item,
    VillageProvider village,
    double finalPrice,
  ) async {
    if (!AppConstants.playStore) {
      await village.addResources(gems: item.gems);
      if (context.mounted) {
        _showSimulatedPurchase(
            context,
            lang,
            lang
                .translate('store_gems_received')
                .replaceAll('{gems}', '${item.gems}'));
      }
      return;
    }

    final result = await storeService.purchaseGems(item);
    if (!context.mounted) return;

    if (result.state == StorePurchaseState.error) {
      _showError(context, lang, result.errorMessage);
    }
  }
}

class _PacksTab extends StatelessWidget {
  final LanguageProvider lang;
  final Map<String, DiscountInfo> discounts;
  final StoreService storeService;

  const _PacksTab({
    required this.lang,
    required this.discounts,
    required this.storeService,
  });

  @override
  Widget build(BuildContext context) {
    final village = context.watch<VillageProvider>();

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _DiscountBanner(discounts: discounts, lang: lang),
          SizedBox(height: 12),
          ...StoreRules.packs.map((pack) {
            final discount = discounts[pack.productId];
            final finalPrice = discount != null
                ? StoreRules.applyDiscount(pack.basePrice, discount.percent)
                : pack.basePrice;
            return Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: _PackCard(
                pack: pack,
                finalPrice: finalPrice,
                discount: discount,
                lang: lang,
                onTap: () => _purchase(context, pack, village, finalPrice),
              ),
            );
          }),
          if (!AppConstants.playStore) _SimulationNotice(lang: lang),
        ],
      ),
    );
  }

  Future<void> _purchase(
    BuildContext context,
    StorePack pack,
    VillageProvider village,
    double finalPrice,
  ) async {
    if (!AppConstants.playStore) {
      await _applyPackContents(village, pack);
      if (context.mounted) {
        _showSimulatedPurchase(
          context,
          lang,
          lang
              .translate('store_pack_received')
              .replaceAll('{pack}', lang.translate('store_pack_${pack.id}')),
        );
      }
      return;
    }

    final result = await storeService.purchasePack(pack);
    if (!context.mounted) return;

    if (result.state == StorePurchaseState.error) {
      _showError(context, lang, result.errorMessage);
    }
  }

  Future<void> _applyPackContents(
      VillageProvider village, StorePack pack) async {
    await village.addResources(
      coins: pack.coins,
      wood: pack.wood,
      metal: pack.metal,
      gems: pack.gems,
    );
    if (pack.bookPowerups > 0) {
      await village.addItemToInventory('book_happiness',
          amount: pack.bookPowerups);
    }
    if (pack.sandwichPowerups > 0) {
      await village.addItemToInventory('sandwich_speed',
          amount: pack.sandwichPowerups);
    }
    if (pack.hammerPowerups > 0) {
      await village.addItemToInventory('hammer_constructor',
          amount: pack.hammerPowerups);
    }
    if (pack.glassesPowerups > 0) {
      await village.addItemToInventory('glasses_reading',
          amount: pack.glassesPowerups);
    }
  }
}

class _GemsPriceCard extends StatelessWidget {
  final StoreGemsItem item;
  final double finalPrice;
  final DiscountInfo? discount;
  final LanguageProvider lang;
  final VoidCallback onTap;

  const _GemsPriceCard({
    required this.item,
    required this.finalPrice,
    required this.discount,
    required this.lang,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const gemColor = AppTheme.gemPurple;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEDE7F6), Color(0xFFD1C4E9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: gemColor.withValues(alpha: 0.5), width: 2),
          boxShadow: [
            BoxShadow(
              color: gemColor.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            if (discount != null)
              Positioned(
                top: 8,
                right: 8,
                child: _DiscountBadge(percent: discount!.percent),
              ),
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ResourceIcon.gem(size: 38),
                    SizedBox(height: 5),
                    Text(
                      '${item.gems} ${lang.translate('gems')}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkLavender,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 4),
                    if (discount != null) ...[
                      Text(
                        '\$${item.basePrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      SizedBox(height: 2),
                    ],
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.darkLavender,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        '\$${finalPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PackCard extends StatelessWidget {
  final StorePack pack;
  final double finalPrice;
  final DiscountInfo? discount;
  final LanguageProvider lang;
  final VoidCallback onTap;

  const _PackCard({
    required this.pack,
    required this.finalPrice,
    required this.discount,
    required this.lang,
    required this.onTap,
  });

  Color get _color {
    final hex = pack.colorHex;
    return Color(int.parse('FF$hex', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    final packName = lang.translate('store_pack_${pack.id}');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.3),
              color.withValues(alpha: 0.1)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color, width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        padding: EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.card_giftcard, size: 26, color: Colors.white),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          packName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkText,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 5),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          lang
                              .translate('store_save')
                              .replaceAll('{pct}', '${pack.savingsPercent}'),
                          style: TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5),
                  _PackContentsRow(pack: pack),
                ],
              ),
            ),
            SizedBox(width: 10),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (discount != null) ...[
                  _DiscountBadge(percent: discount!.percent),
                  SizedBox(height: 4),
                  Text(
                    '\$${pack.basePrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  SizedBox(height: 2),
                ],
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '\$${finalPrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PackContentsRow extends StatelessWidget {
  final StorePack pack;

  const _PackContentsRow({required this.pack});

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];

    void add(Widget icon, int amount) {
      if (amount <= 0) return;
      items.add(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          SizedBox(width: 2),
          Text('+$amount',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkText)),
          SizedBox(width: 7),
        ],
      ));
    }

    add(ResourceIcon.coin(size: 17), pack.coins);
    add(ResourceIcon.wood(size: 17), pack.wood);
    add(ResourceIcon.metal(size: 17), pack.metal);
    add(ResourceIcon.gem(size: 17), pack.gems);
    add(Image.asset('assets/images/book_item.png', width: 22, height: 22),
        pack.bookPowerups);
    add(Image.asset('assets/images/sandwich_item.png', width: 22, height: 22),
        pack.sandwichPowerups);
    add(Image.asset('assets/images/hammer_item.png', width: 22, height: 22),
        pack.hammerPowerups);
    add(Image.asset('assets/images/glasses_item.png', width: 22, height: 22),
        pack.glassesPowerups);

    return Wrap(children: items);
  }
}

class _DiscountBadge extends StatelessWidget {
  final double percent;

  const _DiscountBadge({required this.percent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.red.withValues(alpha: 0.4), blurRadius: 4)
        ],
      ),
      child: Text(
        '-${percent.toInt()}%',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _DiscountBanner extends StatefulWidget {
  final Map<String, DiscountInfo> discounts;
  final LanguageProvider lang;

  const _DiscountBanner({required this.discounts, required this.lang});

  @override
  State<_DiscountBanner> createState() => _DiscountBannerState();
}

class _DiscountBannerState extends State<_DiscountBanner> {
  late final Stream<Duration> _countdown;

  @override
  void initState() {
    super.initState();
    if (widget.discounts.isNotEmpty) {
      final endsAt = widget.discounts.values.first.endsAt;
      _countdown = Stream.periodic(
        const Duration(seconds: 1),
        (_) {
          final rem = endsAt.difference(DateTime.now());
          return rem.isNegative ? Duration.zero : rem;
        },
      );
    }
  }

  String _format(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m ${s.toString().padLeft(2, '0')}s';
    return '${m.toString().padLeft(2, '0')}m ${s.toString().padLeft(2, '0')}s';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.discounts.isEmpty) return SizedBox.shrink();

    final labelKey = widget.discounts.values.first.labelKey;
    final label = widget.lang.translate(labelKey);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.celebration, color: Colors.white, size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                StreamBuilder<Duration>(
                  stream: _countdown,
                  initialData: widget.discounts.values.first.timeRemaining,
                  builder: (_, snap) {
                    final rem = snap.data ?? Duration.zero;
                    return Text(
                      '${widget.lang.translate('store_discount_ends_in')} ${_format(rem)}',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.9)),
                    );
                  },
                ),
              ],
            ),
          ),
          Icon(Icons.local_fire_department, color: Colors.white, size: 22),
        ],
      ),
    );
  }
}

class _GemBalanceBar extends StatelessWidget {
  final int gems;
  final LanguageProvider lang;

  const _GemBalanceBar({required this.gems, required this.lang});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppTheme.cream,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.lavender.withValues(alpha: 0.35),
              AppTheme.gemPurple.withValues(alpha: 0.2)
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.lavender, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ResourceIcon.gem(size: 22),
            SizedBox(width: 7),
            Text(
              '${lang.translate('store_your_gems')}: ',
              style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.darkText.withValues(alpha: 0.7)),
            ),
            Text(
              '$gems',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkLavender),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final Widget icon;
  final String text;
  final Color color;

  const _SectionLabel(
      {required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        icon,
        SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _StoreCard extends StatelessWidget {
  final Color topColor;
  final Color borderColor;
  final VoidCallback onTap;
  final bool canAfford;
  final Widget child;

  const _StoreCard({
    required this.topColor,
    required this.borderColor,
    required this.onTap,
    required this.canAfford,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: canAfford ? topColor : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: canAfford ? borderColor : Colors.grey.shade300,
            width: 2,
          ),
          boxShadow: canAfford
              ? [
                  BoxShadow(
                      color: borderColor.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: Offset(0, 2))
                ]
              : [],
        ),
        child: child,
      ),
    );
  }
}

class _SimulationNotice extends StatelessWidget {
  final LanguageProvider lang;

  const _SimulationNotice({required this.lang});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 8),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.amber.shade700),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              lang.translate('store_simulation_notice'),
              style: TextStyle(fontSize: 11, color: Colors.amber.shade800),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeciesTab extends StatelessWidget {
  final LanguageProvider lang;
  final StoreService storeService;

  const _SpeciesTab({required this.lang, required this.storeService});

  Color _rarityColor(VillagerRarity rarity) {
    switch (rarity) {
      case VillagerRarity.common: return const Color(0xFF9E9E9E);
      case VillagerRarity.rare: return const Color(0xFF2196F3);
      case VillagerRarity.extraordinary: return const Color(0xFF9C27B0);
      case VillagerRarity.legendary: return const Color(0xFFFF9800);
      case VillagerRarity.godly: return const Color(0xFFF44336);
    }
  }

  Future<void> _purchase(
      BuildContext context, VillagerSpeciesData species) async {
    final village = context.read<VillageProvider>();
    if (village.isSpeciesUnlocked(species.id)) return;

    if (!AppConstants.playStore) {
      await village.unlockSpeciesFromStore(species.id);
      if (context.mounted) {
        _showSimulatedPurchase(
          context,
          lang,
          lang.translate('store_species_unlock_success'),
        );
      }
      return;
    }

    final productId = SpeciesRules.productIdForSpecies(species.id);
    final result = await storeService.purchaseSpecies(productId);
    if (!context.mounted) return;
    if (result.state == StorePurchaseState.success) {
      await village.unlockSpeciesFromStore(species.id);
      if (context.mounted) {
        showSuccessToast(context, lang.translate('store_species_unlock_success'));
      }
    } else if (result.state == StorePurchaseState.error) {
      _showError(context, lang, result.errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final village = context.watch<VillageProvider>();
    final available = village.storeSpeciesAvailable;

    if (available.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.celebration, size: 48, color: AppTheme.coinGold),
              SizedBox(height: 12),
              Text(
                lang.translate('store_species_no_available'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkText,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.lavender.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.lavender),
            ),
            child: Row(
              children: [
                Icon(Icons.refresh, size: 16, color: AppTheme.darkLavender),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _nextRefreshText(),
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.darkLavender,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          ...available.map((species) => Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: _SpeciesStoreCard(
                  species: species,
                  lang: lang,
                  rarityColor: _rarityColor(species.rarity),
                  onTap: () => _purchase(context, species),
                ),
              )),
          if (!AppConstants.playStore) _SimulationNotice(lang: lang),
        ],
      ),
    );
  }

  String _nextRefreshText() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final diff = tomorrow.difference(now);
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    return lang.translate('store_species_refresh')
        .replaceAll('{time}', '${h}h ${m.toString().padLeft(2, '0')}m');
  }
}

class _SpeciesStoreCard extends StatelessWidget {
  final VillagerSpeciesData species;
  final LanguageProvider lang;
  final Color rarityColor;
  final VoidCallback onTap;

  const _SpeciesStoreCard({
    required this.species,
    required this.lang,
    required this.rarityColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: rarityColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: rarityColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: rarityColor.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        padding: EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: rarityColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Image.asset(
                  'assets/images/${species.id}_villager.png',
                  width: 48,
                  height: 48,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.pets,
                    size: 32,
                    color: rarityColor,
                  ),
                ),
              ),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang.translate(species.nameKey),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkText,
                    ),
                  ),
                  SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: rarityColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: rarityColor, width: 1),
                    ),
                    child: Text(
                      lang.translate(SpeciesRules.rarityKey(species.rarity)),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: rarityColor,
                      ),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    lang.translate(species.descriptionKey),
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.darkText.withValues(alpha: 0.6),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: 12),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: rarityColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                lang.translate('store_species_buy')
                    .replaceAll('{price}', '\$${species.realPrice?.toStringAsFixed(2) ?? '0.00'}'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> _showGemConfirmDialog(
    BuildContext context, LanguageProvider lang, int gemCost) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppTheme.softWhite,
      title: Row(
        children: [
          ResourceIcon.gem(size: 22),
          SizedBox(width: 8),
          Text(
            lang.translate('store_confirm_title'),
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkText),
          ),
        ],
      ),
      content: Text(
        lang.translate('store_confirm_body').replaceAll('{gems}', '$gemCost'),
        style: TextStyle(fontSize: 14, color: AppTheme.darkText),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(
            lang.translate('cancel'),
            style: TextStyle(color: AppTheme.darkText.withValues(alpha: 0.6)),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.darkLavender,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            lang.translate('store_confirm_buy'),
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    ),
  );
  return confirmed == true;
}

void _showNotEnoughGems(BuildContext context, LanguageProvider lang) =>
    showErrorToast(context, lang.translate('store_not_enough_gems'));

void _showPurchaseSuccess(BuildContext context, LanguageProvider lang) =>
    showSuccessToast(context, lang.translate('store_purchase_success'));

void _showSimulatedPurchase(
    BuildContext context, LanguageProvider lang, String detail) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppTheme.softWhite,
      title: Row(
        children: [
          Text('🛒', style: TextStyle(fontSize: 24)),
          SizedBox(width: 8),
          Text(lang.translate('store_simulated_title'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(detail, style: TextStyle(fontSize: 14)),
          SizedBox(height: 8),
          Text(
            lang.translate('store_simulation_notice'),
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.darkMint,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(lang.translate('done'),
              style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

void _showError(BuildContext context, LanguageProvider lang, String? message) =>
    showErrorToast(context, message ?? lang.translate('store_purchase_error'));
