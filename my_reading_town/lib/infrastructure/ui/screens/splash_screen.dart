import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:my_reading_town/adapters/providers/book_provider.dart';
import 'package:my_reading_town/adapters/providers/tag_provider.dart';
import 'package:my_reading_town/adapters/providers/village_provider.dart';
import 'package:my_reading_town/adapters/repositories/villager_favorites.dart';
import 'package:my_reading_town/application/services/notification_service.dart';
import 'package:my_reading_town/domain/rules/holiday_rules.dart';
import 'package:my_reading_town/infrastructure/di/service_locator.dart';
import 'package:my_reading_town/infrastructure/persistence/database_helper.dart';
import 'package:my_reading_town/infrastructure/ui/config/app_theme.dart';
import 'package:my_reading_town/infrastructure/ui/localization/language_provider.dart';
import 'package:my_reading_town/infrastructure/ui/screens/game_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _progress = 0.0;
  List<String> _tips = [];
  int _tipIndex = 0;
  String _tapHint = 'tap for next tip';

  static const _backgroundImages = [
    'assets/images/splash_bg_1.png',
    'assets/images/splash_bg_2.png',
    'assets/images/splash_bg_3.png',
  ];

  late final String _backgroundImage;

  @override
  void initState() {
    super.initState();
    _backgroundImage =
        _backgroundImages[Random().nextInt(_backgroundImages.length)];
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeApp());
  }

  Future<void> _setProgress(double value) async {
    if (mounted) setState(() => _progress = value);
  }

  Future<List<Map<String, String>>> _loadNotificationMessages(
      String locale) async {
    try {
      final data = await rootBundle
          .loadString('assets/messages/$locale/notification_messages.json');
      final json = jsonDecode(data) as Map<String, dynamic>;
      final list = json['messages'] as List;
      return list
          .map((e) => {
                'title': e['title'] as String,
                'body': e['body'] as String,
              })
          .toList();
    } catch (_) {
      return [
        {'title': 'Time to read!', 'body': 'Your village is waiting for you!'}
      ];
    }
  }

  Future<void> _scheduleEventReminders(
      NotificationService notif, String locale) async {
    final lang = context.read<LanguageProvider>();
    final now = DateTime.now();
    for (int i = 0; i < HolidayRules.allEvents.length; i++) {
      final event = HolidayRules.allEvents[i];
      final eventName = lang.translate('branch_${event.id}');
      final start = DateTime(now.year, event.startMonth, event.startDay);
      final end = DateTime(now.year, event.endMonth, event.endDay, 23, 59, 59);
      if (end.isBefore(now)) continue;

      final notifs = <({DateTime scheduledAt, String title, String body})>[];

      final startNotif = start.isAfter(now) ? start : now.add(const Duration(hours: 1));
      notifs.add((
        scheduledAt: startNotif,
        title: lang.translate('notif_event_start_title').replaceAll('{event}', eventName),
        body: lang.translate('notif_event_start_body').replaceAll('{event}', eventName),
      ));

      final mid = start.add(Duration(milliseconds: end.difference(start).inMilliseconds ~/ 2));
      if (mid.isAfter(now)) {
        notifs.add((
          scheduledAt: mid,
          title: lang.translate('notif_event_mid_title').replaceAll('{event}', eventName),
          body: lang.translate('notif_event_mid_body').replaceAll('{event}', eventName),
        ));
      }

      final endingWarning = end.subtract(const Duration(days: 3));
      if (endingWarning.isAfter(now)) {
        notifs.add((
          scheduledAt: endingWarning,
          title: lang.translate('notif_event_ending_title').replaceAll('{event}', eventName),
          body: lang.translate('notif_event_ending_body').replaceAll('{event}', eventName),
        ));
      }

      await notif.scheduleEventReminders(eventIndex: i, notifications: notifs);
    }
  }

  Future<void> _loadTips(String locale) async {
    try {
      final data = await rootBundle
          .loadString('assets/messages/$locale/reading_tips.json');
      final json = jsonDecode(data) as Map<String, dynamic>;
      final tips = List<String>.from(json['tips'] as List);
      tips.shuffle();
      if (mounted) {
        setState(() {
          _tips = tips;
          _tipIndex = 0;
        });
      }
    } catch (_) {}
  }

  Future<void> _initializeApp() async {
    final bookProvider = context.read<BookProvider>();
    final tagProvider = context.read<TagProvider>();
    final villageProvider = context.read<VillageProvider>();
    final languageProvider = context.read<LanguageProvider>();
    final navigator = Navigator.of(context);

    try {
      await villageProvider.loadData();
      await _setProgress(0.2);

      final locale = villageProvider.language;
      await languageProvider.load(locale);
      await _loadTips(locale);

      if (mounted) {
        setState(() {
          _tapHint = languageProvider.translate('splash_tap_tip');
        });
      }
      await _setProgress(0.45);

      VillagerFavorites.setLocale(locale);
      await VillagerFavorites.load();
      await _setProgress(0.6);

      await tagProvider.loadTags();
      await _setProgress(0.75);

      await bookProvider.loadData();
      await _setProgress(0.9);

      try {
        final notif = sl<NotificationService>();
        final db = DatabaseHelper();
        final settings = await db.getNotificationSettings();
        final daysStr = settings['days_enabled'] as String;
        final activeDays =
            daysStr.split('').map((c) => c == '1').toList();
        final startHour = settings['start_hour'] as int;
        final endHour = settings['end_hour'] as int;
        final perDay = settings['per_day'] as int;
        final messages = await _loadNotificationMessages(locale);
        await notif.scheduleNotifications(
          activeDays: activeDays,
          startHour: startHour,
          endHour: endHour,
          notificationsPerDay: perDay,
          messages: messages,
        );
        await _scheduleEventReminders(notif, locale);
      } catch (_) {}

      await _setProgress(1.0);
      await Future.delayed(const Duration(milliseconds: 1500));
    } catch (_) {
      await _setProgress(1.0);
    }

    if (mounted) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      navigator.pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => GameScreen(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  void _nextTip() {
    if (_tips.isEmpty) return;
    setState(() => _tipIndex = (_tipIndex + 1) % _tips.length);
  }

  Widget _outlinedIcon(IconData icon, double size) {
    return Stack(
      children: [
        for (final offset in const [
          Offset(-1.5, -1.5),
          Offset(1.5, -1.5),
          Offset(-1.5, 1.5),
          Offset(1.5, 1.5),
        ])
          Transform.translate(
            offset: offset,
            child: Icon(icon, size: size, color: Colors.black),
          ),
        Icon(icon, size: size, color: Colors.white),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              _backgroundImage,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppTheme.lavender, AppTheme.pink],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: screenHeight * 0.35,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.55),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: screenHeight * 0.45,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.55),
                    Colors.black.withValues(alpha: 0.75),
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 48,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'My Reading Town',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    shadows: [
                      Shadow(
                          color: Colors.black,
                          blurRadius: 0,
                          offset: Offset(-2, -2)),
                      Shadow(
                          color: Colors.black,
                          blurRadius: 0,
                          offset: Offset(2, -2)),
                      Shadow(
                          color: Colors.black,
                          blurRadius: 0,
                          offset: Offset(-2, 2)),
                      Shadow(
                          color: Colors.black,
                          blurRadius: 0,
                          offset: Offset(2, 2)),
                      Shadow(
                          color: Colors.black,
                          blurRadius: 0,
                          offset: Offset(0, 2)),
                      Shadow(
                          color: Colors.black,
                          blurRadius: 0,
                          offset: Offset(0, -2)),
                      Shadow(
                          color: Colors.black,
                          blurRadius: 0,
                          offset: Offset(2, 0)),
                      Shadow(
                          color: Colors.black,
                          blurRadius: 0,
                          offset: Offset(-2, 0)),
                      Shadow(
                          color: Colors.black,
                          blurRadius: 6,
                          offset: Offset(0, 2)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _outlinedIcon(Icons.pets, 28),
                    const SizedBox(width: 8),
                    _outlinedIcon(Icons.menu_book_rounded, 28),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom + 36,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_tips.isNotEmpty) ...[
                    GestureDetector(
                      onTap: _nextTip,
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.15),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        ),
                        child: Text(
                          _tips[_tipIndex],
                          key: ValueKey(_tipIndex),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontStyle: FontStyle.italic,
                            height: 1.5,
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                blurRadius: 8,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _nextTip,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.touch_app_rounded,
                            size: 12,
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _tapHint,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.55),
                              fontSize: 11,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: _progress),
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.easeInOut,
                    builder: (context, value, _) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: value,
                              minHeight: 5,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.25),
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(AppTheme.pink),
                            ),
                          ),
                        ],
                      );
                    },
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
