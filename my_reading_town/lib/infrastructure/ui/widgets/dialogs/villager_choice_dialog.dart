import 'package:flutter/material.dart';
import 'package:my_reading_town/domain/entities/pending_villager_choice.dart';
import 'package:my_reading_town/adapters/providers/village_provider.dart';
import 'package:my_reading_town/infrastructure/ui/config/app_theme.dart';
import 'package:my_reading_town/infrastructure/ui/localization/language_provider.dart';

void showVillagerChoiceDialog(
  BuildContext context, {
  required PendingVillagerChoice choice,
  required VillageProvider village,
  required LanguageProvider lang,
  required VoidCallback onComplete,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => PopScope(
      canPop: false,
      child: _VillagerChoiceDialog(
        choice: choice,
        village: village,
        lang: lang,
        onSelected: (species, name) async {
          await village.confirmVillagerChoice(
              choice.id, choice.houseId, species, name);
          if (ctx.mounted) Navigator.pop(ctx);
          onComplete();
        },
      ),
    ),
  );
}

class _VillagerChoiceDialog extends StatefulWidget {
  final PendingVillagerChoice choice;
  final VillageProvider village;
  final LanguageProvider lang;
  final Future<void> Function(String species, String name) onSelected;

  const _VillagerChoiceDialog({
    required this.choice,
    required this.village,
    required this.lang,
    required this.onSelected,
  });

  @override
  State<_VillagerChoiceDialog> createState() => _VillagerChoiceDialogState();
}

class _VillagerChoiceDialogState extends State<_VillagerChoiceDialog>
    with SingleTickerProviderStateMixin {
  int? _selectedIndex;
  bool _loading = false;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnim;

  static const Color _accentColor = Color(0xFFFFB3BA);
  static const Color _selectedBorder = Color(0xFFE8637A);
  static const Color _cardBg = Color(0xFFFFF8F0);
  static const Color _confirmColor = Color(0xFFB3FFD9);
  static const Color _confirmDark = Color(0xFF2E9E6B);

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _bounceAnim = Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    final species = widget.choice.speciesOptions;
    final names = widget.choice.nameOptions;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: _cardBg,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isLandscape ? 40 : 24,
        vertical: isLandscape ? 12 : 32,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _bounceAnim,
                builder: (_, child) => Transform.translate(
                  offset: Offset(0, _bounceAnim.value),
                  child: child,
                ),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _accentColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.home_rounded,
                      size: 36, color: _accentColor),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                lang.translate('villager_choose_title',
                    fallback: 'New Neighbor!'),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                lang.translate('villager_choose_subtitle',
                    fallback: 'Pick who will move into this house!'),
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.darkText.withValues(alpha: 0.65),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(3, (i) {
                  final isSelected = _selectedIndex == i;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: _loading
                            ? null
                            : () => setState(() => _selectedIndex = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _accentColor.withValues(alpha: 0.18)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? _selectedBorder
                                  : Colors.grey.shade200,
                              width: isSelected ? 2.5 : 1.5,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: _accentColor.withValues(alpha: 0.3),
                                      blurRadius: 12,
                                      spreadRadius: 1,
                                    )
                                  ]
                                : [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 6,
                                    )
                                  ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'assets/images/${species[i]}_villager.png',
                                width: 60,
                                height: 60,
                                filterQuality: FilterQuality.medium,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.pets,
                                  size: 48,
                                  color: _accentColor.withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                names[i],
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? _selectedBorder
                                      : AppTheme.darkText,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                lang.translate('species_${species[i]}',
                                    fallback: _capitalize(species[i])),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.darkText.withValues(alpha: 0.55),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (isSelected)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Icon(Icons.check_circle_rounded,
                                      size: 18, color: _selectedBorder),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: (_selectedIndex == null || _loading)
                      ? null
                      : () async {
                          setState(() => _loading = true);
                          await widget.onSelected(
                            species[_selectedIndex!],
                            names[_selectedIndex!],
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedIndex != null
                        ? _confirmColor
                        : Colors.grey.shade200,
                    foregroundColor:
                        _selectedIndex != null ? _confirmDark : Colors.grey,
                    elevation: _selectedIndex != null ? 2 : 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : Text(
                          lang.translate('villager_choose_confirm',
                              fallback: 'Move In!'),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
