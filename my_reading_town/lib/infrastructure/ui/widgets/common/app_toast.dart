import 'package:flutter/material.dart';
import 'package:my_reading_town/infrastructure/ui/config/app_theme.dart';

void showAppToast(
  BuildContext context,
  String message, {
  Color backgroundColor = Colors.black87,
  IconData? icon,
  Duration duration = const Duration(seconds: 2),
}) {
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) => _AppToast(
      message: message,
      backgroundColor: backgroundColor,
      icon: icon,
      duration: duration,
      onDismiss: () {
        if (entry.mounted) entry.remove();
      },
    ),
  );
  Overlay.of(context, rootOverlay: true).insert(entry);
}

class _AppToast extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final IconData? icon;
  final Duration duration;
  final VoidCallback onDismiss;

  const _AppToast({
    required this.message,
    required this.backgroundColor,
    required this.icon,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_AppToast> createState() => _AppToastState();
}

class _AppToastState extends State<_AppToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    _ctrl.forward();

    Future.delayed(widget.duration, () {
      if (mounted) {
        _ctrl.reverse().then((_) => widget.onDismiss());
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final bottomInset = mq.viewInsets.bottom + mq.padding.bottom;
    return Positioned(
      left: 16 + mq.padding.left,
      right: 16 + mq.padding.right,
      bottom: bottomInset + 24,
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
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

// Convenience wrappers matching the colours already used across the app.

void showSuccessToast(BuildContext context, String message) =>
    showAppToast(context, message,
        backgroundColor: AppTheme.darkMint,
        icon: Icons.check_circle_outline);

void showErrorToast(BuildContext context, String message) =>
    showAppToast(context, message,
        backgroundColor: const Color(0xFFE53935),
        icon: Icons.error_outline);

void showInfoToast(BuildContext context, String message) =>
    showAppToast(context, message,
        backgroundColor: AppTheme.darkSkyBlue,
        icon: Icons.info_outline);

void showWarningToast(BuildContext context, String message) =>
    showAppToast(context, message,
        backgroundColor: AppTheme.mediumOrange,
        icon: Icons.warning_amber_rounded);
