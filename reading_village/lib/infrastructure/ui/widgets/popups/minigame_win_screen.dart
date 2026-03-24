import 'package:flutter/material.dart';
import 'package:reading_village/infrastructure/ui/config/app_theme.dart';

class MinigameWinScreen extends StatelessWidget {
  final String? rewardType;
  final int winsNeeded;
  final VoidCallback onBack;

  const MinigameWinScreen({
    super.key,
    required this.rewardType,
    required this.winsNeeded,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    String rewardText;
    String rewardAsset;
    Color rewardColor;

    switch (rewardType) {
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
                    '$winsNeeded consecutive correct answers!',
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
                      onPressed: onBack,
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
