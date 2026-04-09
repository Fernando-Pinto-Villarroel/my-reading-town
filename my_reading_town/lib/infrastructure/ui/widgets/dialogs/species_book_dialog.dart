import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_reading_town/infrastructure/ui/config/app_theme.dart';
import 'package:my_reading_town/adapters/providers/village_provider.dart';
import 'package:my_reading_town/infrastructure/ui/localization/language_provider.dart';
import 'package:my_reading_town/domain/rules/species_rules.dart';
import 'package:my_reading_town/domain/entities/villager.dart';

void showSpeciesBookDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _SpeciesBookDialog(),
  );
}

class _SpeciesBookDialog extends StatefulWidget {
  @override
  State<_SpeciesBookDialog> createState() => _SpeciesBookDialogState();
}

class _SpeciesBookDialogState extends State<_SpeciesBookDialog> {
  VillagerRarity? _selectedRarity;

  Color _rarityColor(VillagerRarity rarity) {
    switch (rarity) {
      case VillagerRarity.common: return const Color(0xFF78909C);
      case VillagerRarity.rare: return const Color(0xFF1E88E5);
      case VillagerRarity.extraordinary: return const Color(0xFF8E24AA);
      case VillagerRarity.legendary: return const Color(0xFFEF6C00);
      case VillagerRarity.godly: return const Color(0xFFE53935);
    }
  }

  List<VillagerSpeciesData> _filteredSpecies() {
    if (_selectedRarity == null) return SpeciesRules.allSpecies;
    return SpeciesRules.allSpecies
        .where((s) => s.rarity == _selectedRarity)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.read<LanguageProvider>();
    final village = context.watch<VillageProvider>();
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;
    final filtered = _filteredSpecies();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      backgroundColor: const Color(0xFFFDF6E3),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isLandscape ? 32 : 16,
        vertical: isLandscape ? 12 : 28,
      ),
      child: SizedBox(
        width: isLandscape ? screenSize.width * 0.8 : screenSize.width * 0.95,
        height: isLandscape ? screenSize.height * 0.9 : screenSize.height * 0.85,
        child: Column(
          children: [
            _BookHeader(lang: lang),
            _RarityFilter(
              selectedRarity: _selectedRarity,
              onRaritySelected: (r) => setState(() => _selectedRarity = r),
              lang: lang,
              rarityColorFn: _rarityColor,
            ),
            Expanded(
              child: _SpeciesGrid(
                species: filtered,
                unlockedIds: village.unlockedSpeciesIds,
                playerLevel: village.playerLevel,
                lang: lang,
                rarityColorFn: _rarityColor,
                villagers: village.villagers,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookHeader extends StatelessWidget {
  final LanguageProvider lang;

  const _BookHeader({required this.lang});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF8D6E63), const Color(0xFF6D4C41)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 12, 16),
      child: Row(
        children: [
          Icon(Icons.menu_book_rounded, color: const Color(0xFFFFECB3), size: 28),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              lang.translate('species_book_title'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFFECB3),
                fontFamily: 'serif',
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: const Color(0xFFFFECB3)),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _RarityFilter extends StatelessWidget {
  final VillagerRarity? selectedRarity;
  final ValueChanged<VillagerRarity?> onRaritySelected;
  final LanguageProvider lang;
  final Color Function(VillagerRarity) rarityColorFn;

  const _RarityFilter({
    required this.selectedRarity,
    required this.onRaritySelected,
    required this.lang,
    required this.rarityColorFn,
  });

  @override
  Widget build(BuildContext context) {
    final rarities = [null, ...VillagerRarity.values];
    return Container(
      color: const Color(0xFFF5E6C8),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: rarities.map((rarity) {
            final isSelected = selectedRarity == rarity;
            final color = rarity == null
                ? const Color(0xFF6D4C41)
                : rarityColorFn(rarity);
            final label = rarity == null
                ? lang.translate('species_book_all')
                : lang.translate(SpeciesRules.rarityKey(rarity));
            return Padding(
              padding: EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onRaritySelected(rarity),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 150),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color
                        : color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: color,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : color,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _SpeciesGrid extends StatelessWidget {
  final List<VillagerSpeciesData> species;
  final List<String> unlockedIds;
  final int playerLevel;
  final LanguageProvider lang;
  final Color Function(VillagerRarity) rarityColorFn;
  final List<Villager> villagers;

  const _SpeciesGrid({
    required this.species,
    required this.unlockedIds,
    required this.playerLevel,
    required this.lang,
    required this.rarityColorFn,
    required this.villagers,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLandscape = MediaQuery.of(context).size.width >
        MediaQuery.of(context).size.height;
    final crossAxisCount = isLandscape
        ? (screenWidth > 900 ? 6 : 5)
        : (screenWidth > 480 ? 5 : 4);

    return GridView.builder(
      padding: EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.72,
      ),
      itemCount: species.length,
      itemBuilder: (context, i) {
        final s = species[i];
        final isUnlocked = unlockedIds.contains(s.id);
        return GestureDetector(
          onTap: () => _showSpeciesDetail(context, s, isUnlocked),
          child: _SpeciesCard(
            species: s,
            isUnlocked: isUnlocked,
            lang: lang,
            rarityColor: rarityColorFn(s.rarity),
          ),
        );
      },
    );
  }

  void _showSpeciesDetail(
      BuildContext context, VillagerSpeciesData species, bool isUnlocked) {
    final count = villagers.where((v) => v.species == species.id).length;
    showDialog(
      context: context,
      builder: (ctx) => _SpeciesDetailPopup(
        species: species,
        isUnlocked: isUnlocked,
        lang: lang,
        rarityColor: rarityColorFn(species.rarity),
        playerLevel: playerLevel,
        inhabitantCount: count,
      ),
    );
  }
}

class _SpeciesCard extends StatelessWidget {
  final VillagerSpeciesData species;
  final bool isUnlocked;
  final LanguageProvider lang;
  final Color rarityColor;

  const _SpeciesCard({
    required this.species,
    required this.isUnlocked,
    required this.lang,
    required this.rarityColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isUnlocked
            ? rarityColor.withValues(alpha: 0.08)
            : Colors.grey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnlocked ? rarityColor : Colors.grey.shade300,
          width: isUnlocked ? 1.5 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: EdgeInsets.all(6),
              child: isUnlocked
                  ? Image.asset(
                      'assets/images/${species.id}_villager.png',
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.pets,
                        size: 32,
                        color: rarityColor,
                      ),
                    )
                  : ColorFiltered(
                      colorFilter: ColorFilter.mode(
                          Colors.black, BlendMode.srcATop),
                      child: Image.asset(
                        'assets/images/${species.id}_villager.png',
                        filterQuality: FilterQuality.medium,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.lock,
                          size: 28,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isUnlocked
                        ? lang.translate(species.nameKey)
                        : lang.translate('species_book_locked'),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: isUnlocked
                          ? AppTheme.darkText
                          : Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? rarityColor.withValues(alpha: 0.2)
                          : Colors.grey.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      lang.translate(SpeciesRules.rarityKey(species.rarity)),
                      style: TextStyle(
                        fontSize: 7,
                        fontWeight: FontWeight.bold,
                        color: isUnlocked ? rarityColor : Colors.grey.shade400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeciesDetailPopup extends StatelessWidget {
  final VillagerSpeciesData species;
  final bool isUnlocked;
  final LanguageProvider lang;
  final Color rarityColor;
  final int playerLevel;
  final int inhabitantCount;

  const _SpeciesDetailPopup({
    required this.species,
    required this.isUnlocked,
    required this.lang,
    required this.rarityColor,
    required this.playerLevel,
    required this.inhabitantCount,
  });

  String _unlockDescription() {
    if (species.unlockType == 'starter') {
      return lang.translate('species_book_unlock_starter');
    }
    if (species.unlockType == 'level' && species.unlockLevel != null) {
      return lang.translate('species_book_unlock_level')
          .replaceAll('{level}', '${species.unlockLevel}');
    }
    if (species.unlockType == 'special') {
      return lang.translate('species_book_unlock_store');
    }
    return lang.translate('species_book_unlock_special');
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: const Color(0xFFFDF6E3),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: isUnlocked
                    ? rarityColor.withValues(alpha: 0.12)
                    : Colors.grey.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isUnlocked ? rarityColor : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: Center(
                child: isUnlocked
                    ? Image.asset(
                        'assets/images/${species.id}_villager.png',
                        width: 72,
                        height: 72,
                        filterQuality: FilterQuality.medium,
                        errorBuilder: (_, __, ___) => Icon(Icons.pets,
                            size: 40, color: rarityColor),
                      )
                    : ColorFiltered(
                        colorFilter:
                            ColorFilter.mode(Colors.black, BlendMode.srcATop),
                        child: Image.asset(
                          'assets/images/${species.id}_villager.png',
                          width: 72,
                          height: 72,
                          filterQuality: FilterQuality.medium,
                          errorBuilder: (_, __, ___) => Icon(Icons.lock,
                              size: 40, color: Colors.grey.shade400),
                        ),
                      ),
              ),
            ),
            SizedBox(height: 14),
            Text(
              isUnlocked
                  ? lang.translate(species.nameKey)
                  : lang.translate('species_book_locked'),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isUnlocked ? AppTheme.darkText : Colors.grey.shade500,
              ),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: rarityColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: rarityColor, width: 1.5),
              ),
              child: Text(
                lang.translate(SpeciesRules.rarityKey(species.rarity)),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: rarityColor,
                ),
              ),
            ),
            SizedBox(height: 16),
            if (isUnlocked) ...[
              _InfoRow(
                icon: Icons.cottage,
                label: lang.translate('species_book_detail_inhabitants'),
                value: '$inhabitantCount',
                color: rarityColor,
              ),
              SizedBox(height: 8),
            ],
            _InfoRow(
              icon: Icons.lock_open,
              label: lang.translate('species_book_detail_how'),
              value: _unlockDescription(),
              color: rarityColor,
            ),
            SizedBox(height: 8),
            if (isUnlocked) ...[
              Divider(color: const Color(0xFFD7B899), thickness: 1),
              SizedBox(height: 8),
              Text(
                lang.translate(species.descriptionKey),
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.darkText.withValues(alpha: 0.75),
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ] else ...[
              Divider(color: const Color(0xFFD7B899), thickness: 1),
              SizedBox(height: 8),
              Text(
                lang.translate('species_book_locked_desc'),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8D6E63),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  lang.translate('close'),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 13, color: AppTheme.darkText),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
