import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_reading_town/infrastructure/ui/config/app_theme.dart';
import 'package:my_reading_town/infrastructure/ui/localization/context_ext.dart';
import 'package:my_reading_town/infrastructure/ui/widgets/common/resource_icon.dart';
import 'package:my_reading_town/domain/rules/village_rules.dart';

void showReadingCalculatorDialog(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _ReadingCalculatorContent(),
  );
}

enum _ResourceType { coins, gems, wood, metal }

class _ReadingCalculatorContent extends StatefulWidget {
  const _ReadingCalculatorContent();

  @override
  State<_ReadingCalculatorContent> createState() =>
      _ReadingCalculatorContentState();
}

class _ReadingCalculatorContentState extends State<_ReadingCalculatorContent> {
  _ResourceType _selectedResource = _ResourceType.coins;
  final TextEditingController _amountController = TextEditingController();
  _CalculationResult? _result;
  String? _error;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _calculate() {
    final text = _amountController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _error = context.t('calculator_enter_amount');
        _result = null;
      });
      return;
    }
    final amount = int.tryParse(text);
    if (amount == null || amount <= 0) {
      setState(() {
        _error = context.t('calculator_invalid_amount');
        _result = null;
      });
      return;
    }
    setState(() {
      _error = null;
      _result = _computeResult(_selectedResource, amount);
    });
  }

  _CalculationResult _computeResult(_ResourceType type, int target) {
    switch (type) {
      case _ResourceType.coins:
        final pagesForCoins = (target / VillageRules.coinsPerPage).ceil();
        final booksForCoins =
            (target / VillageRules.bookCompletionCoinBonus).ceil();
        return _CalculationResult(
          resourceType: type,
          target: target,
          pagesNeeded: pagesForCoins,
          booksNeeded: booksForCoins,
          ratePerPage: VillageRules.coinsPerPage,
          bonusPerBook: VillageRules.bookCompletionCoinBonus,
        );
      case _ResourceType.gems:
        final booksForGems =
            (target / VillageRules.bookCompletionGemBonus).ceil();
        return _CalculationResult(
          resourceType: type,
          target: target,
          pagesNeeded: null,
          booksNeeded: booksForGems,
          ratePerPage: null,
          bonusPerBook: VillageRules.bookCompletionGemBonus,
        );
      case _ResourceType.wood:
        final pagesForWood = (target / VillageRules.woodPerPage).ceil();
        return _CalculationResult(
          resourceType: type,
          target: target,
          pagesNeeded: pagesForWood,
          booksNeeded: null,
          ratePerPage: VillageRules.woodPerPage,
          bonusPerBook: null,
        );
      case _ResourceType.metal:
        final pagesForMetal = (target / VillageRules.metalPerPage).ceil();
        return _CalculationResult(
          resourceType: type,
          target: target,
          pagesNeeded: pagesForMetal,
          booksNeeded: null,
          ratePerPage: VillageRules.metalPerPage,
          bonusPerBook: null,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final landscape = MediaQuery.of(context).size.width >
        MediaQuery.of(context).size.height;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppTheme.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * (landscape ? 0.92 : 0.85),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 16, 20, landscape ? 8 : 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.calculate, size: 24, color: AppTheme.darkText),
                    const SizedBox(width: 8),
                    Text(
                      context.t('resource_calculator'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  context.t('resource_calculator_subtitle'),
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.darkText.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  context.t('calculator_resource_type'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkText,
                  ),
                ),
                const SizedBox(height: 8),
                _ResourceSelector(
                  selected: _selectedResource,
                  onChanged: (r) => setState(() {
                    _selectedResource = r;
                    _result = null;
                    _error = null;
                  }),
                ),
                const SizedBox(height: 16),
                Text(
                  context.t('calculator_target_amount'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkText,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: InputDecoration(
                          hintText: context.t('calculator_amount_hint'),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppTheme.lavender.withValues(alpha: 0.4),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppTheme.lavender.withValues(alpha: 0.4),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppTheme.lavender,
                              width: 2,
                            ),
                          ),
                          errorText: _error,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (_) => _calculate(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _calculate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.lavender,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        context.t('calculator_calculate'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkText,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_result != null) ...[
                  const SizedBox(height: 16),
                  _ResultCard(result: _result!),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResourceSelector extends StatelessWidget {
  final _ResourceType selected;
  final ValueChanged<_ResourceType> onChanged;

  const _ResourceSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _ResourceType.values.map((type) {
        final isSelected = type == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.lavender.withValues(alpha: 0.25)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.lavender
                      : AppTheme.darkText.withValues(alpha: 0.15),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _resourceIcon(type, 28),
                  const SizedBox(height: 4),
                  Text(
                    _resourceLabel(context, type),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? AppTheme.darkLavender
                          : AppTheme.darkText.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _resourceIcon(_ResourceType type, double size) {
    switch (type) {
      case _ResourceType.coins:
        return ResourceIcon.coin(size: size);
      case _ResourceType.gems:
        return ResourceIcon.gem(size: size);
      case _ResourceType.wood:
        return ResourceIcon.wood(size: size);
      case _ResourceType.metal:
        return ResourceIcon.metal(size: size);
    }
  }

  String _resourceLabel(BuildContext context, _ResourceType type) {
    switch (type) {
      case _ResourceType.coins:
        return context.t('coins');
      case _ResourceType.gems:
        return context.t('gems');
      case _ResourceType.wood:
        return context.t('wood');
      case _ResourceType.metal:
        return context.t('metal');
    }
  }
}

class _CalculationResult {
  final _ResourceType resourceType;
  final int target;
  final int? pagesNeeded;
  final int? booksNeeded;
  final int? ratePerPage;
  final int? bonusPerBook;

  const _CalculationResult({
    required this.resourceType,
    required this.target,
    required this.pagesNeeded,
    required this.booksNeeded,
    required this.ratePerPage,
    required this.bonusPerBook,
  });
}

class _ResultCard extends StatelessWidget {
  final _CalculationResult result;

  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.lavender.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.lavender.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome,
                  size: 18, color: AppTheme.darkLavender),
              const SizedBox(width: 6),
              Text(
                context
                    .t('calculator_result_title')
                    .replaceAll('{amount}', '${result.target}'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkLavender,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (result.pagesNeeded != null)
            _ResultRow(
              icon: Icons.book_outlined,
              color: AppTheme.mediumMint,
              text: context
                  .t('calculator_pages_needed')
                  .replaceAll('{pages}', '${result.pagesNeeded}'),
              detail: result.ratePerPage != null
                  ? context
                      .t('calculator_rate_per_page')
                      .replaceAll('{rate}', '${result.ratePerPage}')
                  : null,
            ),
          if (result.pagesNeeded != null && result.booksNeeded != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: Divider(color: AppTheme.lavender.withValues(alpha: 0.5), thickness: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    context.t('or'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkLavender,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: AppTheme.lavender.withValues(alpha: 0.5), thickness: 1)),
              ],
            ),
            const SizedBox(height: 10),
          ],
          if (result.booksNeeded != null)
            _ResultRow(
              icon: Icons.auto_stories,
              color: AppTheme.darkPink,
              text: context
                  .t('calculator_books_needed')
                  .replaceAll('{books}', '${result.booksNeeded}'),
              detail: result.bonusPerBook != null
                  ? context
                      .t('calculator_bonus_per_book')
                      .replaceAll('{bonus}', '${result.bonusPerBook}')
                  : null,
            ),
          if (result.resourceType == _ResourceType.gems) ...[
            const SizedBox(height: 8),
            Text(
              context.t('calculator_gems_note'),
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.darkText.withValues(alpha: 0.55),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final String? detail;

  const _ResultRow({
    required this.icon,
    required this.color,
    required this.text,
    this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkText,
                ),
              ),
              if (detail != null)
                Text(
                  detail!,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.darkText.withValues(alpha: 0.55),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
