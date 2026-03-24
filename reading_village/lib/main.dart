import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reading_village/infrastructure/di/service_locator.dart';
import 'package:reading_village/infrastructure/ui/config/app_theme.dart';
import 'package:reading_village/adapters/repositories/villager_favorites.dart';
import 'package:reading_village/infrastructure/ui/widgets/common/skeleton.dart';
import 'package:reading_village/adapters/providers/book_provider.dart';
import 'package:reading_village/adapters/providers/tag_provider.dart';
import 'package:reading_village/adapters/providers/village_provider.dart';
import 'package:reading_village/infrastructure/ui/localization/language_provider.dart';
import 'package:reading_village/infrastructure/ui/localization/context_ext.dart';
import 'package:reading_village/infrastructure/ui/screens/game_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initServiceLocator();
  await sl<LanguageProvider>().load(LanguageProvider.defaultLocale);
  runApp(const ReadingVillageApp());
}

class ReadingVillageApp extends StatelessWidget {
  const ReadingVillageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: sl<BookProvider>()),
        ChangeNotifierProvider.value(value: sl<TagProvider>()),
        ChangeNotifierProvider.value(value: sl<VillageProvider>()),
        ChangeNotifierProvider.value(value: sl<LanguageProvider>()),
      ],
      child: MaterialApp(
        title: 'Reading Village',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: AppInitializer(),
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final bookProvider = context.read<BookProvider>();
    final tagProvider = context.read<TagProvider>();
    final villageProvider = context.read<VillageProvider>();
    final languageProvider = context.read<LanguageProvider>();

    await VillagerFavorites.load();
    await tagProvider.loadTags();
    await bookProvider.loadData();
    await villageProvider.loadData();
    await languageProvider.load(villageProvider.language);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.cream,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_stories, size: 64, color: AppTheme.pink),
              SizedBox(height: 16),
              Text(
                'Reading Village',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkText,
                ),
              ),
              SizedBox(height: 8),
              Text(
                context.t('building_your_village'),
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.darkText.withValues(alpha: 0.6),
                ),
              ),
              SizedBox(height: 24),
              Skeleton(width: 180, height: 12, borderRadius: 6),
              SizedBox(height: 10),
              Skeleton(width: 120, height: 12, borderRadius: 6),
            ],
          ),
        ),
      );
    }

    return GameScreen();
  }
}
