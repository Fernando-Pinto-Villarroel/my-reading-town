import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../config/game_constants.dart';
import '../providers/village_provider.dart';

class MatchCharacterRoleScreen extends StatefulWidget {
  const MatchCharacterRoleScreen({super.key});

  @override
  State<MatchCharacterRoleScreen> createState() => _MatchCharacterRoleScreenState();
}

class _MatchCharacterRoleScreenState extends State<MatchCharacterRoleScreen> {
  List<Map<String, dynamic>> _questions = [];
  final Random _random = Random();
  int _consecutiveWins = 0;
  static const int _winsNeeded = 5;
  static const int _cooldownHours = 5;
  static const String _minigameId = 'match_character_role';

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
    final jsonStr = await rootBundle.loadString('assets/data/match_character_role.json');
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
    final wrongRoles = List<String>.from(question['wrong_roles']);
    wrongRoles.shuffle(_random);
    final options = [question['correct_role'] as String, ...wrongRoles.take(3)];
    options.shuffle(_random);

    final species = GameConstants.villagerSpecies[_random.nextInt(3)];
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
    final correct = _currentQuestion!['correct_role'] as String;
    final isCorrect = answer == correct;

    setState(() {
      _selectedAnswer = answer;
      _isCorrect = isCorrect;
      _showResult = true;
    });

    if (isCorrect) {
      _consecutiveWins++;
      if (_consecutiveWins >= _winsNeeded) {
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
    await village.setMinigameCooldown(_minigameId, _cooldownHours);
    setState(() {
      _hasWon = true;
      _rewardType = rewardType;
    });
  }

  Color _optionColor(String option) {
    if (_selectedAnswer == null) return AppTheme.softWhite;
    if (option == _currentQuestion!['correct_role']) {
      return AppTheme.mint.withValues(alpha: 0.7);
    }
    if (option == _selectedAnswer && !_isCorrect!) {
      return AppTheme.pink.withValues(alpha: 0.7);
    }
    return AppTheme.softWhite.withValues(alpha: 0.5);
  }

  Color _optionBorderColor(String option) {
    if (_selectedAnswer == null) return AppTheme.lavender.withValues(alpha: 0.5);
    if (option == _currentQuestion!['correct_role']) {
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
        backgroundColor: const Color(0xFFE3F2FD),
        body: Center(child: CircularProgressIndicator(color: AppTheme.skyBlue)),
      );
    }

    if (_hasWon) {
      return _buildWinScreen();
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFBBDEFB), Color(0xFFE3F2FD), Color(0xFFE1F5FE)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isLandscape = constraints.maxWidth > constraints.maxHeight;
              return Column(
                children: [
                  _buildTopBar(isLandscape),
                  Expanded(
                    child: isLandscape
                        ? _buildLandscapeLayout()
                        : _buildPortraitLayout(),
                  ),
                  _buildCloudDecoration(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(bool isLandscape) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: isLandscape ? 4 : 8,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.softWhite.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.arrow_back, color: AppTheme.darkText, size: 24),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Match the Character Role',
              style: TextStyle(
                fontSize: isLandscape ? 16 : 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkText,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.softWhite.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, size: 18, color: AppTheme.coinGold),
                const SizedBox(width: 4),
                Text(
                  '$_consecutiveWins / $_winsNeeded',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkText,
                  ),
                ),
              ],
            ),
          ),
        ],
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
          _buildQuestionBubble(),
          const SizedBox(height: 20),
          ..._shuffledOptions.map((option) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildOptionButton(option),
          )),
          if (_showResult) ...[
            const SizedBox(height: 8),
            _buildResultFeedback(),
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
            child: _buildQuestionBubble(),
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
                  child: _buildOptionButton(option),
                )),
                if (_showResult) _buildResultFeedback(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionBubble() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          'assets/images/$_villagerSprite',
          width: 64,
          height: 85,
          filterQuality: FilterQuality.medium,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.softWhite,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What is their role?',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.darkText.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Who is ${_currentQuestion!['character']}?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionButton(String option) {
    return GestureDetector(
      onTap: _selectedAnswer == null ? () => _selectAnswer(option) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: _optionColor(option),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _optionBorderColor(option),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          option,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.darkText,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildResultFeedback() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _isCorrect!
            ? AppTheme.mint.withValues(alpha: 0.3)
            : AppTheme.pink.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isCorrect! ? Icons.check_circle : Icons.cancel,
            color: _isCorrect! ? const Color(0xFF2E7D32) : Colors.red.shade400,
            size: 22,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              _isCorrect!
                  ? 'Correct! $_consecutiveWins/$_winsNeeded'
                  : 'Wrong! The answer was: ${_currentQuestion!['correct_role']}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _isCorrect! ? const Color(0xFF2E7D32) : Colors.red.shade400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCloudDecoration() {
    return SizedBox(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(6, (i) {
          return Text(
            i.isEven ? '☁️' : '✨',
            style: TextStyle(fontSize: i.isEven ? 20 : 14),
          );
        }),
      ),
    );
  }

  Widget _buildWinScreen() {
    String rewardText;
    String rewardAsset;
    Color rewardColor;

    switch (_rewardType) {
      case 'gems':
        rewardText = '+5 Gems!';
        rewardAsset = 'assets/images/gem.png';
        rewardColor = AppTheme.gemPurple;
        break;
      case 'book':
        rewardText = 'x1 Happiness Book!';
        rewardAsset = 'assets/images/book_item.png';
        rewardColor = AppTheme.pink;
        break;
      case 'sandwich':
        rewardText = 'x1 Constructor Sandwich!';
        rewardAsset = 'assets/images/sandwich_item.png';
        rewardColor = AppTheme.peach;
        break;
      case 'hammer':
        rewardText = 'x1 Constructor Hammer!';
        rewardAsset = 'assets/images/hammer_item.png';
        rewardColor = AppTheme.coinGold;
        break;
      default:
        rewardText = 'Reward!';
        rewardAsset = 'assets/images/gem.png';
        rewardColor = AppTheme.coinGold;
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFBBDEFB), Color(0xFFE3F2FD), Color(0xFFE1F5FE)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppTheme.softWhite,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.emoji_events, size: 64, color: AppTheme.coinGold),
                  const SizedBox(height: 16),
                  Text(
                    'You Won!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_winsNeeded consecutive correct answers!',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.darkText.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: rewardColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: rewardColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(rewardAsset, width: 36, height: 36),
                        const SizedBox(width: 10),
                        Text(
                          rewardText,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: rewardColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.skyBlue,
                        foregroundColor: AppTheme.darkText,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Back to Village',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
