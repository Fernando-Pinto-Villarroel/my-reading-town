import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:my_reading_town/infrastructure/ui/config/app_theme.dart';
import 'package:my_reading_town/domain/rules/minigame_rules.dart';
import 'package:my_reading_town/adapters/providers/village_provider.dart';
import 'package:my_reading_town/infrastructure/ui/widgets/common/match_character_role_body.dart';
import 'package:my_reading_town/infrastructure/ui/widgets/popups/minigame_win_screen.dart';
import 'package:my_reading_town/infrastructure/ui/localization/context_ext.dart';
import 'package:my_reading_town/infrastructure/ui/localization/language_provider.dart';
import 'package:my_reading_town/application/services/notification_service.dart';
import 'package:my_reading_town/infrastructure/di/service_locator.dart';

const List<Color> _bgGradient = [
  Color(0xFFFCE4EC),
  Color(0xFFF8BBD0),
  Color(0xFFF48FB1),
];

const Color _accentColor = Color(0xFFE91E63);
const Color _darkAccent = Color(0xFFAD1457);
const String _villagerSprite = 'koala_villager.png';

class BookOrNotScreen extends StatefulWidget {
  const BookOrNotScreen({super.key});

  @override
  State<BookOrNotScreen> createState() => _BookOrNotScreenState();
}

class _BookOrNotScreenState extends State<BookOrNotScreen> {
  List<Map<String, dynamic>> _questions = [];
  final Random _random = Random();
  int _consecutiveWins = 0;
  static const String _minigameId = 'book_or_not';
  static final _config = MinigameRules.configs[_minigameId]!;

  Map<String, dynamic>? _currentQuestion;
  bool? _selectedAnswer;
  bool? _isCorrect;
  bool _isLoading = true;
  bool _showResult = false;
  bool _hasWon = false;
  String? _rewardType;
  final Set<int> _usedIndices = {};

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final languageProvider = sl<LanguageProvider>();
    String locale = languageProvider.currentLocale;
    if (!['en', 'es', 'fr', 'it', 'pt'].contains(locale)) locale = 'en';
    final jsonStr = await rootBundle
        .loadString('assets/messages/$locale/book_or_not.json');
    final data = json.decode(jsonStr) as Map<String, dynamic>;
    setState(() {
      _questions = List<Map<String, dynamic>>.from(data['questions']);
      _isLoading = false;
      _nextQuestion();
    });
  }

  void _nextQuestion() {
    if (_questions.isEmpty) return;
    if (_usedIndices.length >= _questions.length) _usedIndices.clear();
    int idx;
    do {
      idx = _random.nextInt(_questions.length);
    } while (_usedIndices.contains(idx));
    _usedIndices.add(idx);
    setState(() {
      _currentQuestion = _questions[idx];
      _selectedAnswer = null;
      _isCorrect = null;
      _showResult = false;
    });
  }

  void _selectAnswer(bool answer) {
    if (_selectedAnswer != null) return;
    final isReal = _currentQuestion!['is_real'] as bool;
    final isCorrect = answer == isReal;

    setState(() {
      _selectedAnswer = answer;
      _isCorrect = isCorrect;
      _showResult = true;
    });

    if (isCorrect) {
      _consecutiveWins++;
      if (_consecutiveWins >= _config.winsNeeded) {
        _onGameWon();
      } else {
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (mounted) _nextQuestion();
        });
      }
    } else {
      _consecutiveWins = 0;
      _usedIndices.clear();
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (mounted) _nextQuestion();
      });
    }
  }

  Future<void> _onGameWon() async {
    final village = context.read<VillageProvider>();
    final rewardType = await village.grantMinigameReward();
    await village.setMinigameCooldown(_minigameId, _config.cooldownHours);
    if (mounted) {
      final lang = context.read<LanguageProvider>();
      final name = lang.translate('book_or_not');
      sl<NotificationService>().scheduleMinigameAvailable(
        minigameId: _minigameId,
        remaining: Duration(hours: _config.cooldownHours),
        title: lang.translate('notif_minigame_ready_title'),
        body: lang
            .translate('notif_minigame_ready_body')
            .replaceAll('{name}', name),
      );
    }
    setState(() {
      _hasWon = true;
      _rewardType = rewardType;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _bgGradient[0],
        body: Center(child: CircularProgressIndicator(color: _accentColor)),
      );
    }

    if (_hasWon) {
      return MinigameWinScreen(
        rewardType: _rewardType,
        winsNeeded: _config.winsNeeded,
        onBack: () => Navigator.pop(context),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _bgGradient,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isLandscape = constraints.maxWidth > constraints.maxHeight;
              return Column(
                children: [
                  MinigameTopBar(
                    title: context.t('book_or_not'),
                    isLandscape: isLandscape,
                    consecutiveWins: _consecutiveWins,
                    winsNeeded: _config.winsNeeded,
                    onBack: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: isLandscape
                        ? _buildLandscapeLayout()
                        : _buildPortraitLayout(),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPortraitLayout() {
    if (_currentQuestion == null) return const SizedBox.shrink();
    final author = _currentQuestion!['author'] as String?;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 12),
          QuestionBubble(
            villagerSprite: _villagerSprite,
            subtitle: context.t('is_this_real_book'),
            questionText: _currentQuestion!['title'] as String,
          ),
          if (author != null && _showResult && _isCorrect == true) ...[
            const SizedBox(height: 4),
            _AuthorLabel(
              label: context.t('by_author').replaceAll('{author}', author),
            ),
          ],
          const SizedBox(height: 24),
          _BinaryChoiceRow(
            leftLabel: context.t('real_book'),
            rightLabel: context.t('made_up'),
            leftIcon: Icons.menu_book,
            rightIcon: Icons.not_interested,
            onLeftTap: _selectedAnswer == null ? () => _selectAnswer(true) : null,
            onRightTap:
                _selectedAnswer == null ? () => _selectAnswer(false) : null,
            leftState: _buttonState(true),
            rightState: _buttonState(false),
          ),
          if (_showResult) ...[
            const SizedBox(height: 16),
            _BinaryResultFeedback(
              isCorrect: _isCorrect!,
              consecutiveWins: _consecutiveWins,
              winsNeeded: _config.winsNeeded,
              correctLabel: (_currentQuestion!['is_real'] as bool)
                  ? context.t('real_book')
                  : context.t('made_up'),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildLandscapeLayout() {
    if (_currentQuestion == null) return const SizedBox.shrink();
    final author = _currentQuestion!['author'] as String?;
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  QuestionBubble(
                    villagerSprite: _villagerSprite,
                    subtitle: context.t('is_this_real_book'),
                    questionText: _currentQuestion!['title'] as String,
                  ),
                  if (author != null && _showResult && _isCorrect == true) ...[
                    const SizedBox(height: 6),
                    _AuthorLabel(
                      label: context
                          .t('by_author')
                          .replaceAll('{author}', author),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              children: [
                _BinaryChoiceRow(
                  leftLabel: context.t('real_book'),
                  rightLabel: context.t('made_up'),
                  leftIcon: Icons.menu_book,
                  rightIcon: Icons.not_interested,
                  onLeftTap:
                      _selectedAnswer == null ? () => _selectAnswer(true) : null,
                  onRightTap:
                      _selectedAnswer == null ? () => _selectAnswer(false) : null,
                  leftState: _buttonState(true),
                  rightState: _buttonState(false),
                ),
                if (_showResult) ...[
                  const SizedBox(height: 12),
                  _BinaryResultFeedback(
                    isCorrect: _isCorrect!,
                    consecutiveWins: _consecutiveWins,
                    winsNeeded: _config.winsNeeded,
                    correctLabel: (_currentQuestion!['is_real'] as bool)
                        ? context.t('real_book')
                        : context.t('made_up'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  _BinaryButtonState _buttonState(bool isReal) {
    if (_selectedAnswer == null) return _BinaryButtonState.idle;
    final correctIsReal = _currentQuestion!['is_real'] as bool;
    if (isReal == correctIsReal) return _BinaryButtonState.correct;
    if (_selectedAnswer == isReal) return _BinaryButtonState.wrong;
    return _BinaryButtonState.dimmed;
  }
}

class _AuthorLabel extends StatelessWidget {
  final String label;
  const _AuthorLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.softWhite.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _accentColor.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontStyle: FontStyle.italic,
          color: _darkAccent,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

enum _BinaryButtonState { idle, correct, wrong, dimmed }

class _BinaryChoiceRow extends StatelessWidget {
  final String leftLabel;
  final String rightLabel;
  final IconData leftIcon;
  final IconData rightIcon;
  final VoidCallback? onLeftTap;
  final VoidCallback? onRightTap;
  final _BinaryButtonState leftState;
  final _BinaryButtonState rightState;

  const _BinaryChoiceRow({
    required this.leftLabel,
    required this.rightLabel,
    required this.leftIcon,
    required this.rightIcon,
    required this.onLeftTap,
    required this.onRightTap,
    required this.leftState,
    required this.rightState,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _BinaryButton(
            label: leftLabel,
            icon: leftIcon,
            state: leftState,
            onTap: onLeftTap,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _BinaryButton(
            label: rightLabel,
            icon: rightIcon,
            state: rightState,
            onTap: onRightTap,
          ),
        ),
      ],
    );
  }
}

class _BinaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final _BinaryButtonState state;
  final VoidCallback? onTap;

  const _BinaryButton({
    required this.label,
    required this.icon,
    required this.state,
    required this.onTap,
  });

  Color get _bgColor {
    switch (state) {
      case _BinaryButtonState.idle:
        return AppTheme.softWhite;
      case _BinaryButtonState.correct:
        return AppTheme.mint.withValues(alpha: 0.7);
      case _BinaryButtonState.wrong:
        return AppTheme.pink.withValues(alpha: 0.7);
      case _BinaryButtonState.dimmed:
        return AppTheme.softWhite.withValues(alpha: 0.4);
    }
  }

  Color get _borderColor {
    switch (state) {
      case _BinaryButtonState.idle:
        return _accentColor.withValues(alpha: 0.5);
      case _BinaryButtonState.correct:
        return const Color(0xFF2E7D32);
      case _BinaryButtonState.wrong:
        return Colors.red.shade400;
      case _BinaryButtonState.dimmed:
        return Colors.grey.shade300;
    }
  }

  Color get _iconColor {
    switch (state) {
      case _BinaryButtonState.idle:
        return _darkAccent;
      case _BinaryButtonState.correct:
        return const Color(0xFF2E7D32);
      case _BinaryButtonState.wrong:
        return Colors.red.shade400;
      case _BinaryButtonState.dimmed:
        return Colors.grey.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _borderColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: _borderColor.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: _iconColor),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: _iconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BinaryResultFeedback extends StatelessWidget {
  final bool isCorrect;
  final int consecutiveWins;
  final int winsNeeded;
  final String correctLabel;

  const _BinaryResultFeedback({
    required this.isCorrect,
    required this.consecutiveWins,
    required this.winsNeeded,
    required this.correctLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCorrect
            ? AppTheme.mint.withValues(alpha: 0.3)
            : AppTheme.pink.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCorrect ? const Color(0xFF2E7D32) : Colors.red.shade400,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color:
                    isCorrect ? const Color(0xFF2E7D32) : Colors.red.shade400,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                isCorrect
                    ? context.t('correct_answer')
                    : '${context.t('correct_answer')}: $correctLabel',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isCorrect
                      ? const Color(0xFF2E7D32)
                      : Colors.red.shade700,
                ),
              ),
            ],
          ),
          if (isCorrect) ...[
            const SizedBox(height: 4),
            Text(
              '$consecutiveWins / $winsNeeded',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
