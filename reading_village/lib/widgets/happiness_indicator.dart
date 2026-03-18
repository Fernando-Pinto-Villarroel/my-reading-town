import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class HappinessIndicator extends StatelessWidget {
  final int happiness;

  const HappinessIndicator({super.key, required this.happiness});

  IconData get _moodIcon {
    if (happiness >= 80) return Icons.sentiment_very_satisfied;
    if (happiness >= 60) return Icons.sentiment_satisfied;
    if (happiness >= 40) return Icons.sentiment_neutral;
    if (happiness >= 20) return Icons.sentiment_dissatisfied;
    return Icons.sentiment_very_dissatisfied;
  }

  Color get _barColor {
    if (happiness >= 80) return AppTheme.coinGold;
    if (happiness >= 60) return AppTheme.mint;
    if (happiness >= 40) return AppTheme.peach;
    if (happiness >= 20) return Colors.orange.shade300;
    return Colors.red.shade300;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xAA000000),
        borderRadius: BorderRadius.circular(14),
      ),
      child: SizedBox(
        width: 150,
        child: Row(
          children: [
            Icon(_moodIcon, color: _barColor, size: 28),
            SizedBox(width: 6),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: happiness / 100,
                  backgroundColor: Colors.grey.shade600,
                  valueColor: AlwaysStoppedAnimation<Color>(_barColor),
                  minHeight: 10,
                ),
              ),
            ),
            SizedBox(width: 6),
            SizedBox(
              width: 38,
              child: Text(
                '$happiness%',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 15,
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
