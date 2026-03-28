import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:reading_village/infrastructure/di/service_locator.dart';
import 'package:reading_village/infrastructure/ui/config/app_theme.dart';
import 'package:reading_village/adapters/providers/book_provider.dart';
import 'package:reading_village/adapters/providers/tag_provider.dart';
import 'package:reading_village/adapters/providers/village_provider.dart';
import 'package:reading_village/infrastructure/ui/localization/language_provider.dart';
import 'package:reading_village/infrastructure/ui/screens/splash_screen.dart';
import 'package:reading_village/application/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initServiceLocator();
  await sl<LanguageProvider>().load(LanguageProvider.defaultLocale);
  await sl<NotificationService>().initialize();
  await sl<NotificationService>().requestPermission();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
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
        home: const SplashScreen(),
      ),
    );
  }
}
