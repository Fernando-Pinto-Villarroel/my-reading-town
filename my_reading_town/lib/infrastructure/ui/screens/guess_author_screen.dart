import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:my_reading_town/infrastructure/ui/config/app_theme.dart';
import 'package:my_reading_town/domain/rules/village_rules.dart';
import 'package:my_reading_town/domain/rules/minigame_rules.dart';
import 'package:my_reading_town/adapters/providers/village_provider.dart';
import 'package:my_reading_town/infrastructure/ui/widgets/common/match_character_role_body.dart';
import 'package:my_reading_town/infrastructure/ui/widgets/popups/minigame_win_screen.dart';
import 'package:my_reading_town/infrastructure/ui/localization/context_ext.dart';
import 'package:my_reading_town/infrastructure/ui/localization/language_provider.dart';
import 'package:my_reading_town/application/services/notification_service.dart';
import 'package:my_reading_town/infrastructure/di/service_locator.dart';

class GuessAuthorScreen extends StatefulWidget {
  const GuessAuthorScreen({super.key});

  @override
  State<GuessAuthorScreen> createState() => _GuessAuthorScreenState();
}

class _GuessAuthorScreenState extends State<GuessAuthorScreen> {
  List<Map<String, dynamic>> _questions = [];
  final Random _random = Random();
  int _consecutiveWins = 0;
  static const String _minigameId = 'guess_author';
  static final _config = MinigameRules.configs[_minigameId]!;

  Map<String, dynamic>? _currentQuestion;
  List<String> _shuffledOptions = [];
  String? _selectedAnswer;
  bool? _isCorrect;
  String _villagerSprite = 'cat_villager.png';
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
    // Get locale from LanguageProvider
    final languageProvider = sl<LanguageProvider>();
    String locale = languageProvider.currentLocale;

    // Fallback to English if locale not supported
    if (!['en', 'es', 'fr', 'it', 'pt'].contains(locale)) {
      locale = 'en';
    }
    final jsonStr =
        await rootBundle.loadString('assets/messages/$locale/guess_author.json');
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
    final question = _questions[idx];
    final wrongAuthors = List<String>.from(question['wrong_authors']);
    wrongAuthors.shuffle(_random);
    final options = [
      question['correct_author'] as String,
      ...wrongAuthors.take(3)
    ];
    options.shuffle(_random);

    final species = VillageRules.villagerSpecies[_random.nextInt(3)];
    setState(() {
      _currentQuestion = question;
      _shuffledOptions = options;
      _selectedAnswer = null;
      _isCorrect = null;
      _showResult = false;
      _villagerSprite = '${species}_villager.png';
    });
  }

  void _selectAnswer(String answer) {
    if (_selectedAnswer != null) return;
    final correct = _currentQuestion!['correct_author'] as String;
    final isCorrect = answer == correct;

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
      final name = lang.translate('guess_the_author');
      sl<NotificationService>().scheduleMinigameAvailable(
        minigameId: _minigameId,
        remaining: Duration(hours: _config.cooldownHours),
        title: lang.translate('notif_minigame_ready_title'),
        body: lang.translate('notif_minigame_ready_body').replaceAll('{name}', name),
      );
    }
    setState(() {
      _hasWon = true;
      _rewardType = rewardType;
    });
  }

  Color _optionColor(String option) {
    if (_selectedAnswer == null) return AppTheme.softWhite;
    if (option == _currentQuestion!['correct_author']) {
      return AppTheme.mint.withValues(alpha: 0.7);
    }
    if (option == _selectedAnswer && !_isCorrect!) {
      return AppTheme.pink.withValues(alpha: 0.7);
    }
    return AppTheme.softWhite.withValues(alpha: 0.5);
  }

  Color _optionBorderColor(String option) {
    if (_selectedAnswer == null) {
      return AppTheme.lavender.withValues(alpha: 0.5);
    }
    if (option == _currentQuestion!['correct_author']) {
      return const Color(0xFF2E7D32);
    }
    if (option == _selectedAnswer && !_isCorrect!) {
      return Colors.red.shade400;
    }
    return Colors.grey.shade300;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFE8F5E9),
        body: Center(child: CircularProgressIndicator(color: AppTheme.mint)),
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
            colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9), Color(0xFFA5D6A7)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isLandscape = constraints.maxWidth > constraints.maxHeight;
              return Column(
                children: [
                  MinigameTopBar(
                    title: context.t('guess_the_author'),
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
                  const CloudDecoration(),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 12),
          QuestionBubble(
            villagerSprite: _villagerSprite,
            subtitle: context.t('who_wrote_this'),
            questionText: _currentQuestion!['book'] as String,
          ),
          const SizedBox(height: 20),
          ..._shuffledOptions.map((option) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: OptionButton(
                  option: option,
                  backgroundColor: _optionColor(option),
                  borderColor: _optionBorderColor(option),
                  onTap: _selectedAnswer == null
                      ? () => _selectAnswer(option)
                      : null,
                ),
              )),
          if (_showResult) ...[
            const SizedBox(height: 8),
            ResultFeedback(
              isCorrect: _isCorrect!,
              consecutiveWins: _consecutiveWins,
              winsNeeded: _config.winsNeeded,
              correctAnswer: _currentQuestion!['correct_author'] as String,
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildLandscapeLayout() {
    if (_currentQuestion == null) return const SizedBox.shrink();
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: QuestionBubble(
              villagerSprite: _villagerSprite,
              subtitle: context.t('who_wrote_this'),
              questionText: _currentQuestion!['book'] as String,
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              children: [
                ..._shuffledOptions.map((option) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: OptionButton(
                        option: option,
                        backgroundColor: _optionColor(option),
                        borderColor: _optionBorderColor(option),
                        onTap: _selectedAnswer == null
                            ? () => _selectAnswer(option)
                            : null,
                      ),
                    )),
                if (_showResult)
                  ResultFeedback(
                    isCorrect: _isCorrect!,
                    consecutiveWins: _consecutiveWins,
                    winsNeeded: _config.winsNeeded,
                    correctAnswer:
                        _currentQuestion!['correct_author'] as String,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
