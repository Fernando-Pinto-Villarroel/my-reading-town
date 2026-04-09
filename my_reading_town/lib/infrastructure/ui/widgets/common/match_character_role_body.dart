import 'package:flutter/material.dart';
import 'package:my_reading_town/infrastructure/ui/config/app_theme.dart';
import 'package:my_reading_town/infrastructure/ui/localization/context_ext.dart';

class MinigameTopBar extends StatelessWidget {
  final String title;
  final bool isLandscape;
  final int consecutiveWins;
  final int winsNeeded;
  final VoidCallback onBack;

  const MinigameTopBar({
    super.key,
    required this.title,
    required this.isLandscape,
    required this.consecutiveWins,
    required this.winsNeeded,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: isLandscape ? 4 : 8,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
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
              title,
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
                  '$consecutiveWins / $winsNeeded',
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
}

class QuestionBubble extends StatelessWidget {
  final String villagerSprite;
  final String subtitle;
  final String questionText;

  const QuestionBubble({
    super.key,
    required this.villagerSprite,
    required this.subtitle,
    required this.questionText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          'assets/images/$villagerSprite',
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
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.darkText.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  questionText,
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
}

class OptionButton extends StatelessWidget {
  final String option;
  final Color backgroundColor;
  final Color borderColor;
  final VoidCallback? onTap;

  const OptionButton({
    super.key,
    required this.option,
    required this.backgroundColor,
    required this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2),
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
}

class ResultFeedback extends StatelessWidget {
  final bool isCorrect;
  final int consecutiveWins;
  final int winsNeeded;
  final String correctAnswer;

  const ResultFeedback({
    super.key,
    required this.isCorrect,
    required this.consecutiveWins,
    required this.winsNeeded,
    required this.correctAnswer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isCorrect
            ? AppTheme.mint.withValues(alpha: 0.3)
            : AppTheme.pink.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCorrect ? Icons.check_circle : Icons.cancel,
            color: isCorrect ? const Color(0xFF2E7D32) : Colors.red.shade400,
            size: 22,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              isCorrect
                  ? '${context.t('correct_answer')} $consecutiveWins/$winsNeeded'
                  : '${context.t('wrong_answer')} $correctAnswer',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color:
                    isCorrect ? const Color(0xFF2E7D32) : Colors.red.shade400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

