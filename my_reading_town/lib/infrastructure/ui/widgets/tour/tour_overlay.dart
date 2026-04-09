import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:my_reading_town/infrastructure/ui/config/app_theme.dart';
import 'package:my_reading_town/infrastructure/ui/localization/language_provider.dart';
import 'package:my_reading_town/adapters/repositories/villager_favorites.dart';

enum _StepKind { villagerChat, highlight, input }

enum _HighlightTarget {
  missions,
  build,
  reading,
  backpack,
  minigames,
  photo,
  stats,
  settings,
  roulette,
  store,
  speciesBook,
}

const int tourTotalSteps = 26;

const List<_StepKind> _stepKinds = [
  _StepKind.villagerChat, // 0: welcome
  _StepKind.villagerChat, // 1: resources
  _StepKind.highlight, // 2: missions spotlight
  _StepKind.villagerChat, // 3: missions explain
  _StepKind.highlight, // 4: build spotlight
  _StepKind.villagerChat, // 5: build explain
  _StepKind.highlight, // 6: reading spotlight
  _StepKind.villagerChat, // 7: reading explain
  _StepKind.highlight, // 8: backpack spotlight
  _StepKind.villagerChat, // 9: backpack explain
  _StepKind.highlight, // 10: minigames spotlight
  _StepKind.villagerChat, // 11: minigames explain
  _StepKind.highlight, // 12: photo spotlight
  _StepKind.villagerChat, // 13: photo explain
  _StepKind.highlight, // 14: stats spotlight
  _StepKind.villagerChat, // 15: stats explain
  _StepKind.highlight, // 16: settings spotlight
  _StepKind.villagerChat, // 17: settings explain
  _StepKind.highlight, // 18: roulette spotlight
  _StepKind.villagerChat, // 19: roulette explain
  _StepKind.highlight, // 20: store spotlight
  _StepKind.villagerChat, // 21: store explain
  _StepKind.highlight, // 22: species book spotlight
  _StepKind.villagerChat, // 23: species book explain
  _StepKind.input, // 24: username + town name form
  _StepKind.villagerChat, // 25: farewell
];

const List<_HighlightTarget?> _highlightTargets = [
  null,
  null,
  _HighlightTarget.missions,
  null,
  _HighlightTarget.build,
  null,
  _HighlightTarget.reading,
  null,
  _HighlightTarget.backpack,
  null,
  _HighlightTarget.minigames,
  null,
  _HighlightTarget.photo,
  null,
  _HighlightTarget.stats,
  null,
  _HighlightTarget.settings,
  null,
  _HighlightTarget.roulette,
  null,
  _HighlightTarget.store,
  null,
  _HighlightTarget.speciesBook,
  null,
  null,
  null,
];

class TourOverlay extends StatefulWidget {
  final int stepIndex;
  final String villagerName;
  final String villagerSpecies;
  final GlobalKey missionsButtonKey;
  final GlobalKey buildButtonKey;
  final GlobalKey readingButtonKey;
  final GlobalKey backpackButtonKey;
  final GlobalKey minigamesButtonKey;
  final GlobalKey photoButtonKey;
  final GlobalKey statsButtonKey;
  final GlobalKey settingsButtonKey;
  final GlobalKey rouletteButtonKey;
  final GlobalKey storeButtonKey;
  final GlobalKey speciesButtonKey;
  final GlobalKey? resourcesKey;
  final String Function(String key, {String? fallback}) translate;
  final VoidCallback onAdvance;
  final void Function(String username, String townName) onInputSubmit;

  const TourOverlay({
    super.key,
    required this.stepIndex,
    required this.villagerName,
    required this.villagerSpecies,
    required this.missionsButtonKey,
    required this.buildButtonKey,
    required this.readingButtonKey,
    required this.backpackButtonKey,
    required this.minigamesButtonKey,
    required this.photoButtonKey,
    required this.statsButtonKey,
    required this.settingsButtonKey,
    required this.rouletteButtonKey,
    required this.storeButtonKey,
    required this.speciesButtonKey,
    this.resourcesKey,
    required this.translate,
    required this.onAdvance,
    required this.onInputSubmit,
  });

  @override
  State<TourOverlay> createState() => _TourOverlayState();
}

class _TourOverlayState extends State<TourOverlay>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  late final TextEditingController _usernameController;
  late final TextEditingController _townNameController;
  String? _submittedUsername;
  String? _usernameError;
  String? _townNameError;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 1.8),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutBack,
    ));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    ));
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _pulseAnim = Tween<double>(begin: 0, end: 1).animate(_pulseController);
    _usernameController = TextEditingController();
    _townNameController = TextEditingController();

    _playEntrance();
  }

  @override
  void didUpdateWidget(TourOverlay old) {
    super.didUpdateWidget(old);
    if (old.stepIndex != widget.stepIndex) {
      final kind = widget.stepIndex < tourTotalSteps
          ? _stepKinds[widget.stepIndex]
          : null;
      if (kind == _StepKind.villagerChat) _playEntrance();
    }
  }

  void _playEntrance() {
    _entranceController.forward(from: 0);
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
    _usernameController.dispose();
    _townNameController.dispose();
    super.dispose();
  }

  String _getChatMessage() {
    final t = widget.translate;
    final name = widget.villagerName;
    switch (widget.stepIndex) {
      case 0:
        return t('tour_welcome').replaceAll('{name}', name);
      case 1:
        return t('tour_resources');
      case 3:
        return t('tour_missions_explain');
      case 5:
        return t('tour_build_explain');
      case 7:
        return t('tour_reading_explain');
      case 9:
        return t('tour_backpack_explain');
      case 11:
        return t('tour_minigames_explain');
      case 13:
        return t('tour_photo_explain');
      case 15:
        return t('tour_stats_explain');
      case 17:
        return t('tour_settings_explain');
      case 19:
        return t('tour_roulette_explain');
      case 21:
        return t('tour_store_explain');
      case 23:
        return t('tour_species_book_explain');
      case 25:
        return t('tour_farewell')
            .replaceAll('{name}', _submittedUsername ?? '');
      default:
        return '';
    }
  }

  Rect _getSpotRect(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return Rect.zero;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return Rect.zero;
    final pos = box.localToGlobal(Offset.zero);
    return Rect.fromLTWH(pos.dx, pos.dy, box.size.width, box.size.height);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();

    final step = widget.stepIndex;
    if (step >= tourTotalSteps || step < 0) return const SizedBox.shrink();

    final kind = _stepKinds[step];
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;

    Widget content;
    if (kind == _StepKind.highlight) {
      content = _buildHighlightStep(context, step, size, isLandscape);
    } else if (kind == _StepKind.input) {
      content = _buildInputStep(context, size, isLandscape);
    } else {
      content = _buildChatStep(context, step, size, isLandscape);
    }

    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final rightPadding = MediaQuery.of(context).padding.right;

    return Stack(
      children: [
        content,
        Positioned(
          bottom: bottomPadding + 8,
          right: rightPadding + 8,
          child: _TourLanguageButton(),
        ),
      ],
    );
  }

  Widget _buildChatStep(
      BuildContext context, int step, Size size, bool isLandscape) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final villagerSize = isLandscape ? size.height * 0.72 : size.width * 0.58;
    final overlayOpacity = step == 5 ? 0.52 : 0.65;

    final showResourceSpot = step == 1 && widget.resourcesKey != null;
    final resourceRect =
        showResourceSpot ? _getSpotRect(widget.resourcesKey!) : Rect.zero;
    const resSpotPadding = 10.0;
    const resCornerRadius = 16.0;

    return GestureDetector(
      onTap: widget.onAdvance,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          if (showResourceSpot && resourceRect != Rect.zero)
            FadeTransition(
              opacity: _fadeAnim,
              child: ClipPath(
                clipper: _SpotlightClipper(
                  spotRect: resourceRect,
                  padding: resSpotPadding,
                  cornerRadius: resCornerRadius,
                ),
                child: Container(
                    color: Colors.black.withValues(alpha: overlayOpacity)),
              ),
            )
          else
            FadeTransition(
              opacity: _fadeAnim,
              child: Container(
                  color: Colors.black.withValues(alpha: overlayOpacity)),
            ),
          if (showResourceSpot && resourceRect != Rect.zero)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (ctx, _) => CustomPaint(
                    painter: _PulsingBorderPainter(
                      spotRect: resourceRect,
                      padding: resSpotPadding,
                      cornerRadius: resCornerRadius,
                      progress: _pulseAnim.value,
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            left: isLandscape ? 4 : 0,
            bottom: bottomPadding,
            child: SlideTransition(
              position: _slideAnim,
              child: _VillagerImage(
                species: widget.villagerSpecies,
                size: villagerSize,
              ),
            ),
          ),
          Positioned(
            left: isLandscape ? villagerSize * 1.0 : villagerSize * 0.38,
            right: isLandscape ? null : 12,
            bottom: bottomPadding + villagerSize * (isLandscape ? 0.6 : 1.32),
            child: SlideTransition(
              position: _slideAnim,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isLandscape ? size.width * 0.48 : double.infinity,
                ),
                child: _ChatBubble(
                  villagerName: widget.villagerName,
                  message: _getChatMessage(),
                  tapHint: widget.translate('tour_tap_continue'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightStep(
      BuildContext context, int step, Size size, bool isLandscape) {
    final target = _highlightTargets[step];
    if (target == null) return const SizedBox.shrink();

    final key = switch (target) {
      _HighlightTarget.missions => widget.missionsButtonKey,
      _HighlightTarget.build => widget.buildButtonKey,
      _HighlightTarget.reading => widget.readingButtonKey,
      _HighlightTarget.backpack => widget.backpackButtonKey,
      _HighlightTarget.minigames => widget.minigamesButtonKey,
      _HighlightTarget.photo => widget.photoButtonKey,
      _HighlightTarget.stats => widget.statsButtonKey,
      _HighlightTarget.settings => widget.settingsButtonKey,
      _HighlightTarget.roulette => widget.rouletteButtonKey,
      _HighlightTarget.store => widget.storeButtonKey,
      _HighlightTarget.speciesBook => widget.speciesButtonKey,
    };

    final spotRect = _getSpotRect(key);
    const spotPadding = 14.0;
    const spotRadius = 20.0;

    final instrKey = switch (step) {
      2 => 'tour_highlight_missions',
      4 => 'tour_highlight_build',
      6 => 'tour_highlight_reading',
      8 => 'tour_highlight_backpack',
      10 => 'tour_highlight_minigames',
      12 => 'tour_highlight_photo',
      14 => 'tour_highlight_stats',
      16 => 'tour_highlight_settings',
      18 => 'tour_highlight_roulette',
      20 => 'tour_highlight_store',
      22 => 'tour_highlight_species_book',
      _ => 'tour_tap_highlighted',
    };
    final instruction = widget.translate(instrKey);

    final showAbove =
        spotRect != Rect.zero && spotRect.center.dy > size.height * 0.55;
    final instrTop = spotRect == Rect.zero
        ? size.height * 0.3
        : showAbove
            ? (spotRect.top - spotPadding - 72).clamp(16.0, size.height - 100)
            : (spotRect.bottom + spotPadding + 8).clamp(0.0, size.height - 100);

    final peekSize = isLandscape ? 82.0 : 76.0;
    final leftInset = MediaQuery.of(context).padding.left;
    final rightInset = MediaQuery.of(context).padding.right;

    return Stack(
      children: [
        if (spotRect != Rect.zero)
          Positioned.fill(
            child: ClipPath(
              clipper: _SpotlightClipper(
                spotRect: spotRect,
                padding: spotPadding,
                cornerRadius: spotRadius,
              ),
              child: GestureDetector(
                onTap: () {},
                behavior: HitTestBehavior.opaque,
                child: Container(color: Colors.black.withValues(alpha: 0.72)),
              ),
            ),
          )
        else
          Positioned.fill(
            child: GestureDetector(
              onTap: () {},
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.black.withValues(alpha: 0.72)),
            ),
          ),
        if (spotRect != Rect.zero)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _pulseAnim,
                builder: (ctx, _) => CustomPaint(
                  painter: _PulsingBorderPainter(
                    spotRect: spotRect,
                    padding: spotPadding,
                    cornerRadius: spotRadius,
                    progress: _pulseAnim.value,
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          left: 16 + leftInset,
          right: 16 + rightInset,
          top: instrTop,
          child: _InstructionBubble(text: instruction),
        ),
        Positioned(
          left: isLandscape ? 4 : 0,
          bottom: MediaQuery.of(context).padding.bottom,
          child: IgnorePointer(
            child: _VillagerImage(
              species: widget.villagerSpecies,
              size: peekSize,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputStep(BuildContext context, Size size, bool isLandscape) {
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final topPadding = MediaQuery.of(context).padding.top;
    final leftPadding = MediaQuery.of(context).padding.left;
    final rightPadding = MediaQuery.of(context).padding.right;
    final peekSize = isLandscape ? 70.0 : 80.0;
    final hPad = isLandscape ? size.width * 0.15 : 20.0;

    // In landscape the villager overlays the form decoratively — don't reserve
    // bottom space for it, giving the form the full available screen height.
    // In portrait, reserve space so the villager peeks below the form.
    final bottomReserve = isLandscape
        ? bottomPadding + 16.0
        : keyboardInset + bottomPadding + peekSize + 8.0;

    final availableHeight = size.height - topPadding - 12.0 - bottomReserve;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () {},
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.black.withValues(alpha: 0.78)),
          ),
        ),
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              leftPadding + hPad,
              topPadding + 12,
              rightPadding + hPad,
              bottomReserve,
            ),
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    minHeight: availableHeight.clamp(0.0, double.infinity)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [_buildInputCard(isLandscape)],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: isLandscape ? 4 : 0,
          bottom: bottomPadding,
          child: IgnorePointer(
            child: _VillagerImage(
              species: widget.villagerSpecies,
              size: peekSize,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputCard(bool isLandscape) {
    final t = widget.translate;
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      decoration: BoxDecoration(
        color: AppTheme.softWhite,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.lavender, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: AppTheme.lavender.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                t('tour_input_title'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.gemPurple,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              t('tour_input_subtitle'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.darkText,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 22),
          _InputField(
            controller: _usernameController,
            icon: Icons.person_rounded,
            label: t('username'),
            hint: 'e.g. Sakura',
            accentColor: AppTheme.gemPurple,
            errorText: _usernameError,
          ),
          const SizedBox(height: 14),
          _InputField(
            controller: _townNameController,
            icon: Icons.home_rounded,
            label: t('town_name'),
            hint: 'e.g. Blossom Valley',
            accentColor: AppTheme.mediumOrange,
            errorText: _townNameError,
          ),
          const SizedBox(height: 26),
          Center(
            child: GestureDetector(
              onTap: () {
                final username = _usernameController.text.trim();
                final townName = _townNameController.text.trim();
                final minMsg = t('tour_input_min_chars');
                setState(() {
                  _usernameError = username.length < 3 ? minMsg : null;
                  _townNameError = townName.length < 3 ? minMsg : null;
                });
                if (_usernameError != null || _townNameError != null) return;
                setState(() => _submittedUsername = username);
                widget.onInputSubmit(username, townName);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 36, vertical: 15),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.pink, AppTheme.lavender],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.pink.withValues(alpha: 0.45),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Text(
                  t('tour_input_confirm'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final IconData icon;
  final String label;
  final String hint;
  final Color accentColor;
  final String? errorText;

  const _InputField({
    required this.controller,
    required this.icon,
    required this.label,
    required this.hint,
    required this.accentColor,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: accentColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: accentColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          inputFormatters: [LengthLimitingTextInputFormatter(20)],
          style: const TextStyle(color: AppTheme.darkText, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppTheme.darkText.withValues(alpha: 0.38),
              fontSize: 13,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppTheme.lavender, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: errorText != null ? AppTheme.pink : AppTheme.lavender,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: accentColor, width: 2),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 5),
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 12, color: AppTheme.pink),
              const SizedBox(width: 4),
              Text(
                errorText!,
                style: const TextStyle(
                  color: AppTheme.pink,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// Inserted via Overlay.of(context) so it renders above showDialog / showModalBottomSheet.
class TourModalChatOverlay extends StatefulWidget {
  final String villagerName;
  final String villagerSpecies;
  final String message;
  final String tapHint;
  final VoidCallback onTap;

  const TourModalChatOverlay({
    super.key,
    required this.villagerName,
    required this.villagerSpecies,
    required this.message,
    required this.tapHint,
    required this.onTap,
  });

  @override
  State<TourModalChatOverlay> createState() => _TourModalChatOverlayState();
}

class _TourModalChatOverlayState extends State<TourModalChatOverlay>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 1.8),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutBack,
    ));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    ));
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isLandscape = size.width > size.height;
    final villagerSize = isLandscape ? size.height * 0.72 : size.width * 0.58;
    final gradientHeight = villagerSize + bottomPadding + 80;

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: gradientHeight,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.72),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: isLandscape ? 4 : 0,
            bottom: bottomPadding,
            child: SlideTransition(
              position: _slideAnim,
              child: _VillagerImage(
                species: widget.villagerSpecies,
                size: villagerSize,
              ),
            ),
          ),
          Positioned(
            left: isLandscape ? villagerSize * 1.0 : villagerSize * 0.38,
            right: isLandscape ? null : 12,
            bottom: bottomPadding + villagerSize * (isLandscape ? 0.6 : 1.32),
            child: SlideTransition(
              position: _slideAnim,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isLandscape ? size.width * 0.48 : double.infinity,
                ),
                child: _ChatBubble(
                  villagerName: widget.villagerName,
                  message: widget.message,
                  tapHint: widget.tapHint,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TourLanguageButton extends StatelessWidget {
  const _TourLanguageButton();

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final currentLocale = languageProvider.currentLocale;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.softWhite.withValues(alpha: 0.93),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.lavender, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: PopupMenuButton<String>(
        initialValue: currentLocale,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        color: AppTheme.cream,
        elevation: 6,
        onSelected: (locale) {
          VillagerFavorites.setLocale(locale);
          VillagerFavorites.load();
          context.read<LanguageProvider>().changeLanguage(locale);
        },
        itemBuilder: (_) => LanguageProvider.supportedLanguages.entries
            .map((entry) => PopupMenuItem<String>(
                  value: entry.key,
                  child: Text(
                    entry.value['name']!,
                    style: TextStyle(
                      color: AppTheme.darkText,
                      fontWeight: entry.key == currentLocale
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ))
            .toList(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.language_rounded,
                  size: 16, color: AppTheme.lavender),
              const SizedBox(width: 4),
              Text(
                currentLocale.toUpperCase(),
                style: const TextStyle(
                  color: AppTheme.gemPurple,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.keyboard_arrow_down,
                  size: 14, color: AppTheme.lavender),
            ],
          ),
        ),
      ),
    );
  }
}

class _VillagerImage extends StatelessWidget {
  final String species;
  final double size;

  const _VillagerImage({required this.species, required this.size});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/${species}_villager.png',
      width: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => SizedBox(
        width: size,
        height: size,
        child: Icon(Icons.pets, size: size * 0.5, color: AppTheme.pink),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String villagerName;
  final String message;
  final String tapHint;

  const _ChatBubble({
    required this.villagerName,
    required this.message,
    required this.tapHint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: AppTheme.softWhite,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(20),
        ),
        border: Border.all(color: AppTheme.lavender, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            villagerName,
            style: const TextStyle(
              color: AppTheme.gemPurple,
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(
              color: AppTheme.darkText,
              fontSize: 13.5,
              height: 1.52,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.lavender.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.touch_app_rounded,
                      size: 12, color: AppTheme.darkText),
                  const SizedBox(width: 4),
                  Text(
                    tapHint,
                    style: const TextStyle(
                      color: AppTheme.darkText,
                      fontSize: 10.5,
                      fontStyle: FontStyle.italic,
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

class _InstructionBubble extends StatelessWidget {
  final String text;

  const _InstructionBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.softWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.pink, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppTheme.darkText,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          height: 1.4,
        ),
      ),
    );
  }
}

class _SpotlightClipper extends CustomClipper<Path> {
  final Rect spotRect;
  final double padding;
  final double cornerRadius;

  const _SpotlightClipper({
    required this.spotRect,
    required this.padding,
    required this.cornerRadius,
  });

  @override
  Path getClip(Size size) {
    final inflated = spotRect.inflate(padding);
    final rrect =
        RRect.fromRectAndRadius(inflated, Radius.circular(cornerRadius));
    return Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;
  }

  @override
  bool shouldReclip(_SpotlightClipper old) =>
      old.spotRect != spotRect || old.padding != padding;
}

class _PulsingBorderPainter extends CustomPainter {
  final Rect spotRect;
  final double padding;
  final double cornerRadius;
  final double progress;

  const _PulsingBorderPainter({
    required this.spotRect,
    required this.padding,
    required this.cornerRadius,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pulse = sin(progress * pi * 2) * 0.5 + 0.5;
    final inflated = spotRect.inflate(padding);
    final rrect =
        RRect.fromRectAndRadius(inflated, Radius.circular(cornerRadius));

    final glowPaint = Paint()
      ..color = AppTheme.pink.withValues(alpha: 0.25 + pulse * 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10 + pulse * 6
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawRRect(rrect, glowPaint);

    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.75 + pulse * 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRRect(rrect, borderPaint);

    final accentPaint = Paint()
      ..color = AppTheme.pink.withValues(alpha: 0.5 + pulse * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(rrect.inflate(3), accentPaint);
  }

  @override
  bool shouldRepaint(_PulsingBorderPainter old) =>
      old.progress != progress || old.spotRect != spotRect;
}
