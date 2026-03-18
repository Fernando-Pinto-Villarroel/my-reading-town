import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'providers/book_provider.dart';
import 'providers/village_provider.dart';
import 'screens/game_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ReadingVillageApp());
}

class ReadingVillageApp extends StatelessWidget {
  const ReadingVillageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BookProvider()),
        ChangeNotifierProvider(create: (_) => VillageProvider()),
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
    final villageProvider = context.read<VillageProvider>();

    await bookProvider.loadData();
    await villageProvider.loadData();

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
                'Building your village...',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.darkText.withValues(alpha: 0.6),
                ),
              ),
              SizedBox(height: 24),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.pink),
              ),
            ],
          ),
        ),
      );
    }

    return GameScreen();
  }
}
