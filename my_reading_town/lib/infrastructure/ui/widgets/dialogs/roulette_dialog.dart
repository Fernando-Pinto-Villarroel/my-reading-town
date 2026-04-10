import 'dart:math';
import 'dart:ui' as ui;
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:my_reading_town/infrastructure/ui/config/app_theme.dart';
import 'package:my_reading_town/adapters/providers/village_provider.dart';
import 'package:my_reading_town/application/services/notification_service.dart';
import 'package:my_reading_town/infrastructure/di/service_locator.dart';
import 'package:my_reading_town/infrastructure/ui/localization/language_provider.dart';
import 'package:my_reading_town/infrastructure/ui/widgets/common/resource_icon.dart';
import 'package:my_reading_town/domain/rules/roulette_rules.dart';
import 'package:my_reading_town/domain/rules/species_rules.dart';

// Circus palette — bold, vivid, alternating so adjacent segments never share a hue
const List<Color> _circusColors = [
  Color(0xFFD32F2F), // deep red
  Color(0xFF1565C0), // royal blue
  Color(0xFFF9A825), // golden amber
  Color(0xFF2E7D32), // forest green
  Color(0xFF6A1B9A), // deep purple
  Color(0xFFD84315), // burnt orange
  Color(0xFF00695C), // dark teal
  Color(0xFFC62828), // crimson
  Color(0xFF283593), // indigo
  Color(0xFF558B2F), // olive green
  Color(0xFF6A1B9A), // cyan teal
];

class _RouletteReward {
  final String key;
  final String type;
  final int? amount;
  final String assetPath;
  final Widget Function(double size) iconBuilder;

  const _RouletteReward({
    required this.key,
    required this.type,
    this.amount,
    required this.assetPath,
    required this.iconBuilder,
  });
}

List<_RouletteReward> _buildRewards(VillagerSpeciesData? weeklySpecies) {
  final speciesAsset = weeklySpecies != null
      ? 'assets/images/${weeklySpecies.id}_villager.png'
      : 'assets/images/cat_villager.png';

  return [
    _RouletteReward(
      key: 'coins_50',
      type: 'coins',
      amount: 50,
      assetPath: 'assets/images/coin.png',
      iconBuilder: (s) => ResourceIcon.coin(size: s),
    ),
    _RouletteReward(
      key: 'gems_5',
      type: 'gems',
      amount: 5,
      assetPath: 'assets/images/gem.png',
      iconBuilder: (s) => ResourceIcon.gem(size: s),
    ),
    _RouletteReward(
      key: 'coins_100',
      type: 'coins',
      amount: 100,
      assetPath: 'assets/images/coin.png',
      iconBuilder: (s) => ResourceIcon.coin(size: s),
    ),
    _RouletteReward(
      key: 'wood_30',
      type: 'wood',
      amount: 30,
      assetPath: 'assets/images/wood.png',
      iconBuilder: (s) => ResourceIcon.wood(size: s),
    ),
    _RouletteReward(
      key: 'sandwich',
      type: 'sandwich',
      assetPath: 'assets/images/sandwich_item.png',
      iconBuilder: (s) =>
          Image.asset('assets/images/sandwich_item.png', width: s, height: s),
    ),
    _RouletteReward(
      key: 'species',
      type: 'species',
      assetPath: speciesAsset,
      iconBuilder: (s) => Image.asset(
        speciesAsset,
        width: s,
        height: s,
        errorBuilder: (_, __, ___) => Icon(Icons.pets, size: s, color: AppTheme.gemPurple),
      ),
    ),
    _RouletteReward(
      key: 'metal_15',
      type: 'metal',
      amount: 15,
      assetPath: 'assets/images/metal.png',
      iconBuilder: (s) => ResourceIcon.metal(size: s),
    ),
    _RouletteReward(
      key: 'gems_15',
      type: 'gems',
      amount: 15,
      assetPath: 'assets/images/gem.png',
      iconBuilder: (s) => ResourceIcon.gem(size: s),
    ),
    _RouletteReward(
      key: 'hammer',
      type: 'hammer',
      assetPath: 'assets/images/hammer_item.png',
      iconBuilder: (s) =>
          Image.asset('assets/images/hammer_item.png', width: s, height: s),
    ),
    _RouletteReward(
      key: 'book',
      type: 'book',
      assetPath: 'assets/images/book_item.png',
      iconBuilder: (s) =>
          Image.asset('assets/images/book_item.png', width: s, height: s),
    ),
    _RouletteReward(
      key: 'glasses',
      type: 'glasses',
      assetPath: 'assets/images/glasses_item.png',
      iconBuilder: (s) =>
          Image.asset('assets/images/glasses_item.png', width: s, height: s),
    ),
  ];
}

void showRouletteDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _RouletteDialog(),
  );
}

class _RouletteDialog extends StatefulWidget {
  @override
  State<_RouletteDialog> createState() => _RouletteDialogState();
}

class _RouletteDialogState extends State<_RouletteDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  bool _isSpinning = false;
  // true while waiting for the reward popup to be dismissed — suppresses the
  // "not enough gems" warning and the spin button during that window.
  bool _showingReward = false;
  double _currentAngle = 0.0;
  final Random _random = Random();

  late List<_RouletteReward> _rewards;
  VillagerSpeciesData? _weeklySpecies;
  late List<ui.Image?> _segmentImages;
  bool _imagesLoaded = false;

  @override
  void initState() {
    super.initState();
    _weeklySpecies = SpeciesRules.weeklySpeciesReward();
    _rewards = _buildRewards(_weeklySpecies);
    _segmentImages = List.filled(_rewards.length, null);
    _controller = AnimationController(vsync: this);
    _controller.addListener(() {
      setState(() => _currentAngle = _rotationAnimation.value);
    });
    _loadImages();
  }

  Future<void> _loadImages() async {
    for (int i = 0; i < _rewards.length; i++) {
      try {
        final data = await rootBundle.load(_rewards[i].assetPath);
        final codec = await ui.instantiateImageCodec(
          data.buffer.asUint8List(),
          targetWidth: 64,
        );
        final frame = await codec.getNextFrame();
        if (mounted) _segmentImages[i] = frame.image;
      } catch (_) {}
    }
    if (mounted) setState(() => _imagesLoaded = true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _spin() async {
    final village = context.read<VillageProvider>();
    final lang = context.read<LanguageProvider>();
    final wasFree = village.canSpinRouletteForFree;
    final canSpin = await village.spinRoulette();
    if (!canSpin) return;
    if (wasFree && mounted) {
      final remaining = village.rouletteNextFreeSpinIn;
      sl<NotificationService>().scheduleRouletteFreeSpin(
        remaining: remaining,
        title: lang.translate('notif_roulette_spin_title'),
        body: lang.translate('notif_roulette_spin_body'),
      );
    }

    setState(() {
      _isSpinning = true;
    });

    final targetIndex = RouletteRules.pickWeightedIndex(
      _random,
      _rewards.map((r) => r.key).toList(),
    );
    final segmentAngle = 2 * pi / _rewards.length;

    // The rotation angle at which segment targetIndex's midpoint sits under
    // the pointer (top of wheel, angle -pi/2), independent of _currentAngle.
    final desiredAngle = -(targetIndex * segmentAngle + segmentAngle / 2);

    // Add several full counterclockwise spins for the visual effect, then
    // nudge exactly to desiredAngle so the pointer always matches the reward.
    final extraSpins = (6 + _random.nextInt(4)) * 2 * pi;
    final base = _currentAngle - extraSpins;
    double diff = (desiredAngle - base) % (2 * pi);
    if (diff > 0) diff -= 2 * pi; // keep going counterclockwise
    final finalTarget = base + diff;

    _rotationAnimation = Tween<double>(
      begin: _currentAngle,
      end: finalTarget,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    ));

    _controller
      ..reset()
      ..duration = const Duration(milliseconds: 4000);

    await _controller.forward();

    if (!mounted) return;
    setState(() {
      _isSpinning = false;
      _showingReward = true;
    });

    final reward = _rewards[targetIndex];

    if (reward.type == 'species' && _weeklySpecies != null) {
      final result = await village.applySpeciesBonus(_weeklySpecies!.id);
      if (!mounted || result == null) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _SpeciesBonusPopup(
          speciesData: _weeklySpecies!,
          isDuplicate: result.isDuplicate,
          lang: lang,
        ),
      );
    } else {
      await village.applyRouletteReward({
        'type': reward.type,
        'amount': reward.amount,
      });

      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _RouletteRewardPopup(
          reward: reward,
          lang: lang,
        ),
      );
    }

    if (!mounted) return;

    // Only after the popup is dismissed do we reveal the current gem/spin state
    setState(() => _showingReward = false);
  }

  @override
  Widget build(BuildContext context) {
    final village = context.watch<VillageProvider>();
    final lang = context.read<LanguageProvider>();
    final isFree = village.canSpinRouletteForFree;
    final gems = village.gems;
    final gemCost = RouletteRules.gemCostPerSpin;
    // Only evaluate affordability when we're in a neutral state
    final canAfford = isFree || gems >= gemCost;
    final timeLeft = village.rouletteNextFreeSpinIn;

    final canDismiss = !_isSpinning && !_showingReward;

    return PopScope(
      canPop: canDismiss,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () { if (canDismiss) Navigator.of(context).pop(); },
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: AppTheme.cream,
          insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: GestureDetector(
        onTap: () {},
        child: SingleChildScrollView(
          child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Text(
                    lang.translate('roulette'),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkText,
                    ),
                  ),
                  Spacer(),
                  if (!_isSpinning && !_showingReward)
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                ],
              ),

              // "Next free spin" countdown — only shown when not spinning/showing reward
              if (!isFree && !_isSpinning && !_showingReward) ...[
                SizedBox(height: 4),
                Text(
                  lang
                      .translate('roulette_next_free')
                      .replaceAll('{hours}', '${timeLeft.inHours}')
                      .replaceAll('{minutes}', '${timeLeft.inMinutes % 60}')
                      .replaceAll('{seconds}', '${timeLeft.inSeconds % 60}'),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.darkText.withValues(alpha: 0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              SizedBox(height: 20),

              // ── Wheel ──────────────────────────────────────────────────
              // Outer Stack: wheel + fixed pointer (clips none so pointer
              // can overlap the gold ring from above)
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  // Gold-ringed wheel container
                  Container(
                    width: 296,
                    height: 296,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
                        stops: [0.93, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFFB8860B).withValues(alpha: 0.5),
                          blurRadius: 14,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Spinning wheel
                          Transform.rotate(
                            angle: _currentAngle,
                            child: CustomPaint(
                              size: Size(280, 280),
                              painter: _WheelPainter(
                                rewards: _rewards,
                                images: _segmentImages,
                                imagesLoaded: _imagesLoaded,
                              ),
                            ),
                          ),
                          // Centre pin
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Color(0xFFB8860B), width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Icon(Icons.casino,
                                size: 22, color: Color(0xFFB8860B)),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ▼ Fixed pointer — sits outside the spinning part, at 12 o'clock
                  // `top: -18` so the tip lands on the wheel's outer gold ring
                  Positioned(
                    top: -18,
                    child: CustomPaint(
                      size: Size(32, 36),
                      painter: _PointerPainter(),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 24),

              // ── Spin button area ───────────────────────────────────────
              // "Not enough gems" only shown after the reward popup is gone
              if (!_isSpinning && !_showingReward && !canAfford)
                Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    lang
                        .translate('roulette_not_enough_gems')
                        .replaceAll('{gems}', '$gemCost'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.red.shade400,
                    ),
                  ),
                ),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (!_isSpinning && !_showingReward && canAfford)
                      ? _spin
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isFree ? AppTheme.coinGold : AppTheme.gemPurple,
                    foregroundColor: AppTheme.darkText,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isFree) ...[
                        Icon(Icons.stars, size: 20),
                        SizedBox(width: 8),
                        Text(
                          lang.translate('roulette_free_spin'),
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ] else ...[
                        ResourceIcon.gem(size: 20),
                        SizedBox(width: 6),
                        Text(
                          '$gemCost ${lang.translate('gems')} — ${lang.translate('roulette_spin')}',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
        ),
      ),
    ),
  );
  }
}

// ── Reward popup modal ─────────────────────────────────────────────────────────

class _RouletteRewardPopup extends StatefulWidget {
  final _RouletteReward reward;
  final LanguageProvider lang;

  const _RouletteRewardPopup({required this.reward, required this.lang});

  @override
  State<_RouletteRewardPopup> createState() => _RouletteRewardPopupState();
}

class _RouletteRewardPopupState extends State<_RouletteRewardPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;
  late ConfettiController _confettiCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.bounceOut);
    _confettiCtrl = ConfettiController(duration: const Duration(seconds: 2));
    _animCtrl.forward();
    _confettiCtrl.play();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  String _label() {
    final lang = widget.lang;
    final r = widget.reward;
    if (r.amount != null) {
      switch (r.type) {
        case 'coins':
          return '+${r.amount} ${lang.translate('coins')}';
        case 'gems':
          return '+${r.amount} ${lang.translate('gems')}';
        case 'wood':
          return '+${r.amount} ${lang.translate('wood')}';
        case 'metal':
          return '+${r.amount} ${lang.translate('metal')}';
      }
    }
    switch (r.type) {
      case 'sandwich':
        return lang.translate('constructor_sandwich');
      case 'hammer':
        return lang.translate('constructor_hammer');
      case 'book':
        return lang.translate('happiness_book');
      case 'glasses':
        return lang.translate('magic_glasses');
    }
    return r.type;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.4),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Confetti at top-centre
          Positioned(
            top: 0,
            child: ConfettiWidget(
              confettiController: _confettiCtrl,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 25,
              gravity: 0.25,
              colors: [
                AppTheme.pink,
                AppTheme.lavender,
                AppTheme.mint,
                AppTheme.coinGold,
                AppTheme.peach,
              ],
            ),
          ),
          // Popup card
          ScaleTransition(
            scale: _scaleAnim,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 40),
              padding: EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              decoration: BoxDecoration(
                color: AppTheme.softWhite,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.coinGold.withValues(alpha: 0.4),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    widget.lang.translate('roulette_you_won'),
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.coinGold,
                    ),
                  ),
                  SizedBox(height: 20),
                  // Reward icon
                  widget.reward.iconBuilder(72),
                  SizedBox(height: 16),
                  // Reward label
                  Text(
                    _label(),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 28),
                  // Claim button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.coinGold,
                        foregroundColor: AppTheme.darkText,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        widget.lang.translate('claim_reward'),
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
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

// ── Fixed downward-pointing pointer ───────────────────────────────────────────

class _PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // White shadow/outline pass
    final outlinePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.round;

    // Red fill
    final fillPaint = Paint()
      ..color = const Color(0xFFD32F2F)
      ..style = PaintingStyle.fill;

    // Triangle pointing DOWN: apex at bottom-centre, base at top
    final path = Path()
      ..moveTo(size.width / 2, size.height) // tip  (bottom)
      ..lineTo(0, 0) // top-left
      ..lineTo(size.width, 0) // top-right
      ..close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, outlinePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Wheel painter ──────────────────────────────────────────────────────────────

class _WheelPainter extends CustomPainter {
  final List<_RouletteReward> rewards;
  final List<ui.Image?> images;
  final bool imagesLoaded;

  _WheelPainter({
    required this.rewards,
    required this.images,
    required this.imagesLoaded,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final segmentAngle = 2 * pi / rewards.length;

    final fillPaint = Paint()..style = PaintingStyle.fill;
    final dividerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white
      ..strokeWidth = 2.5;

    // Filled segments
    for (int i = 0; i < rewards.length; i++) {
      final startAngle = i * segmentAngle - pi / 2;
      fillPaint.color = _circusColors[i % _circusColors.length];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle,
        true,
        fillPaint,
      );
    }

    // White divider lines
    for (int i = 0; i < rewards.length; i++) {
      final angle = i * segmentAngle - pi / 2;
      canvas.drawLine(
        center,
        Offset(
            center.dx + radius * cos(angle), center.dy + radius * sin(angle)),
        dividerPaint,
      );
    }

    // Outer white ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white.withValues(alpha: 0.9)
        ..strokeWidth = 3,
    );

    // Per-segment content: image + amount label
    for (int i = 0; i < rewards.length; i++) {
      final startAngle = i * segmentAngle - pi / 2;
      final midAngle = startAngle + segmentAngle / 2;

      // Content anchor at ~62 % of radius
      final contentRadius = radius * 0.62;
      final contentCenter = Offset(
        center.dx + contentRadius * cos(midAngle),
        center.dy + contentRadius * sin(midAngle),
      );

      canvas.save();
      canvas.translate(contentCenter.dx, contentCenter.dy);
      // Rotate so image/text reads radially outward
      canvas.rotate(midAngle + pi / 2);

      // Asset image — toward the rim, drawn at natural aspect ratio
      final img = images[i];
      if (img != null) {
        const maxDim = 34.0;
        final imgW = img.width.toDouble();
        final imgH = img.height.toDouble();
        final scale = (imgW >= imgH) ? maxDim / imgW : maxDim / imgH;
        final drawW = imgW * scale;
        final drawH = imgH * scale;
        final src = Rect.fromLTWH(0, 0, imgW, imgH);
        final dst = Rect.fromCenter(
          center: const Offset(0, -18),
          width: drawW,
          height: drawH,
        );
        canvas.drawImageRect(
            img, src, dst, Paint()..filterQuality = FilterQuality.medium);
      }

      // Amount label — toward the centre, with black outline
      final label = _amountLabel(rewards[i]);
      if (label.isNotEmpty) {
        _drawOutlinedText(canvas, label, const Offset(0, 17), 11);
      }

      canvas.restore();
    }
  }

  String _amountLabel(_RouletteReward reward) {
    if (reward.amount != null) return '+${reward.amount}';
    return '';
  }

  void _drawOutlinedText(
      Canvas canvas, String text, Offset center, double fontSize) {
    const offsets = [
      Offset(-1.5, -1.5),
      Offset(1.5, -1.5),
      Offset(-1.5, 1.5),
      Offset(1.5, 1.5),
      Offset(0, -1.5),
      Offset(0, 1.5),
      Offset(-1.5, 0),
      Offset(1.5, 0),
    ];

    TextPainter make(Color color) {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: 56);
      return tp;
    }

    final outline = make(Colors.black);
    for (final off in offsets) {
      outline.paint(
          canvas, center + off - Offset(outline.width / 2, outline.height / 2));
    }
    final fill = make(Colors.white);
    fill.paint(canvas, center - Offset(fill.width / 2, fill.height / 2));
  }

  @override
  bool shouldRepaint(covariant _WheelPainter old) =>
      old.imagesLoaded != imagesLoaded;
}

// ── Species bonus popup ────────────────────────────────────────────────────────

class _SpeciesBonusPopup extends StatefulWidget {
  final VillagerSpeciesData speciesData;
  final bool isDuplicate;
  final LanguageProvider lang;

  const _SpeciesBonusPopup({
    required this.speciesData,
    required this.isDuplicate,
    required this.lang,
  });

  @override
  State<_SpeciesBonusPopup> createState() => _SpeciesBonusPopupState();
}

class _SpeciesBonusPopupState extends State<_SpeciesBonusPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;
  late ConfettiController _confettiCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.bounceOut);
    _confettiCtrl = ConfettiController(duration: const Duration(seconds: 3));
    _animCtrl.forward();
    _confettiCtrl.play();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  Color _rarityColor(VillagerRarity rarity) {
    switch (rarity) {
      case VillagerRarity.common: return const Color(0xFF9E9E9E);
      case VillagerRarity.rare: return const Color(0xFF2196F3);
      case VillagerRarity.extraordinary: return const Color(0xFF9C27B0);
      case VillagerRarity.legendary: return const Color(0xFFFF9800);
      case VillagerRarity.godly: return const Color(0xFFF44336);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    final species = widget.speciesData;
    final rarityColor = _rarityColor(species.rarity);
    final isDuplicate = widget.isDuplicate;

    return Material(
      color: Colors.black.withValues(alpha: 0.5),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 0,
            child: ConfettiWidget(
              confettiController: _confettiCtrl,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 30,
              gravity: 0.25,
              colors: [rarityColor, AppTheme.coinGold, AppTheme.pink, AppTheme.lavender],
            ),
          ),
          ScaleTransition(
            scale: _scaleAnim,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 32),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              decoration: BoxDecoration(
                color: AppTheme.softWhite,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: rarityColor, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: rarityColor.withValues(alpha: 0.35),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isDuplicate
                        ? lang.translate('roulette_species_duplicate')
                        : lang.translate('roulette_species_bonus'),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDuplicate ? AppTheme.darkText : rarityColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: rarityColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/images/${species.id}_villager.png',
                        width: 60,
                        height: 60,
                        filterQuality: FilterQuality.medium,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.pets,
                          size: 40,
                          color: rarityColor,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    lang.translate(species.nameKey),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkText,
                    ),
                  ),
                  SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: rarityColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: rarityColor, width: 1),
                    ),
                    child: Text(
                      lang.translate(SpeciesRules.rarityKey(species.rarity)),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: rarityColor,
                      ),
                    ),
                  ),
                  if (isDuplicate) ...[
                    SizedBox(height: 12),
                    Text(
                      lang.translate('roulette_species_duplicate_desc')
                          .replaceAll('{species}', lang.translate(species.nameKey))
                          .replaceAll('{gems}', '${SpeciesRules.duplicateSpeciesGemCompensation}'),
                      style: TextStyle(fontSize: 13, color: AppTheme.darkText.withValues(alpha: 0.7)),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ResourceIcon.gem(size: 20),
                        SizedBox(width: 4),
                        Text(
                          '+${SpeciesRules.duplicateSpeciesGemCompensation} ${lang.translate('gems')}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.gemPurple,
                          ),
                        ),
                      ],
                    ),
                  ],
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: rarityColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        lang.translate('done'),
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
