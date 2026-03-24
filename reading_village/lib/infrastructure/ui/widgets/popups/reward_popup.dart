import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:reading_village/infrastructure/ui/config/app_theme.dart';
import 'package:reading_village/infrastructure/ui/widgets/common/resource_icon.dart';

class RewardPopup extends StatefulWidget {
  final int coinsEarned;
  final int gemsEarned;
  final int woodEarned;
  final int metalEarned;
  final bool bookCompleted;
  final VoidCallback onDismiss;

  const RewardPopup({
    super.key,
    required this.coinsEarned,
    required this.gemsEarned,
    this.woodEarned = 0,
    this.metalEarned = 0,
    this.bookCompleted = false,
    required this.onDismiss,
  });

  @override
  State<RewardPopup> createState() => _RewardPopupState();
}

class _RewardPopupState extends State<RewardPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.bounceOut,
    );

    _confettiController = ConfettiController(
      duration: Duration(seconds: 1),
    );

    _animController.forward();
    _confettiController.play();
  }

  @override
  void dispose() {
    _animController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.3),
      child: InkWell(
        onTap: widget.onDismiss,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                particleDrag: 0.05,
                emissionFrequency: 0.05,
                numberOfParticles: widget.bookCompleted ? 30 : 15,
                gravity: 0.2,
                colors: [
                  AppTheme.pink,
                  AppTheme.lavender,
                  AppTheme.mint,
                  AppTheme.coinGold,
                  AppTheme.peach,
                ],
              ),
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  padding: EdgeInsets.all(32),
                  margin: EdgeInsets.symmetric(horizontal: 40),
                  decoration: BoxDecoration(
                    color: AppTheme.softWhite,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.pink.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: GestureDetector(
                          onTap: widget.onDismiss,
                          child: Icon(Icons.close, size: 22, color: Colors.grey),
                        ),
                      ),
                      Text(
                        widget.bookCompleted
                            ? 'BOOK COMPLETED!'
                            : 'Reading Rewards!',
                        style: TextStyle(
                          fontSize: widget.bookCompleted ? 22 : 20,
                          fontWeight: FontWeight.bold,
                          color: widget.bookCompleted
                              ? AppTheme.coinGold
                              : AppTheme.darkText,
                        ),
                      ),
                      SizedBox(height: 20),
                      if (widget.coinsEarned > 0) ...[
                        _RewardRow(
                          icon: ResourceIcon.coin(size: 28),
                          text: '+${widget.coinsEarned} coins!',
                          color: AppTheme.darkText,
                        ),
                        SizedBox(height: 8),
                      ],
                      if (widget.woodEarned > 0) ...[
                        _RewardRow(
                          icon: ResourceIcon.wood(size: 28),
                          text: '+${widget.woodEarned} wood!',
                          color: AppTheme.darkText,
                        ),
                        SizedBox(height: 8),
                      ],
                      if (widget.metalEarned > 0) ...[
                        _RewardRow(
                          icon: ResourceIcon.metal(size: 28),
                          text: '+${widget.metalEarned} metal!',
                          color: AppTheme.darkText,
                        ),
                        SizedBox(height: 8),
                      ],
                      if (widget.gemsEarned > 0)
                        _RewardRow(
                          icon: ResourceIcon.gem(size: 28),
                          text: '+${widget.gemsEarned} gems!',
                          color: AppTheme.gemPurple,
                        ),
                      if (widget.bookCompleted) ...[
                        SizedBox(height: 16),
                        Text(
                          'Amazing job finishing your book!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.darkText.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                      SizedBox(height: 16),
                      Text(
                        'Tap anywhere to continue',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RewardRow extends StatelessWidget {
  final Widget icon;
  final String text;
  final Color color;

  const _RewardRow({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
