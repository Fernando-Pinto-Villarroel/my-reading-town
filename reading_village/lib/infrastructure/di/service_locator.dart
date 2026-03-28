import 'package:get_it/get_it.dart';
import 'package:reading_village/infrastructure/persistence/database_helper.dart';
import 'package:reading_village/adapters/repositories/sqlite_village_repository.dart';
import 'package:reading_village/adapters/repositories/sqlite_book_repository.dart';
import 'package:reading_village/adapters/repositories/sqlite_inventory_repository.dart';
import 'package:reading_village/adapters/services/book_search_adapter.dart';
import 'package:reading_village/adapters/services/image_service_adapter.dart';
import 'package:reading_village/domain/ports/village_repository.dart';
import 'package:reading_village/domain/ports/book_repository.dart';
import 'package:reading_village/domain/ports/inventory_repository.dart';
import 'package:reading_village/domain/ports/book_search_port.dart';
import 'package:reading_village/domain/ports/image_port.dart';
import 'package:reading_village/application/services/building_service.dart';
import 'package:reading_village/application/services/villager_service.dart';
import 'package:reading_village/application/services/reading_service.dart';
import 'package:reading_village/application/services/inventory_service.dart';
import 'package:reading_village/application/services/mission_service.dart';
import 'package:reading_village/application/services/player_service.dart';
import 'package:reading_village/application/services/tag_service.dart';
import 'package:reading_village/application/services/backup_service.dart';
import 'package:reading_village/application/services/notification_service.dart';
import 'package:reading_village/adapters/providers/village_provider.dart';
import 'package:reading_village/adapters/providers/book_provider.dart';
import 'package:reading_village/adapters/providers/tag_provider.dart';
import 'package:reading_village/infrastructure/ui/localization/language_provider.dart';

final sl = GetIt.instance;

void initServiceLocator() {
  // Infrastructure
  sl.registerLazySingleton(() => DatabaseHelper());
  sl.registerLazySingleton<VillageRepository>(() => SqliteVillageRepository(sl()));
  sl.registerLazySingleton<BookRepository>(() => SqliteBookRepository(sl()));
  sl.registerLazySingleton<InventoryRepository>(() => SqliteInventoryRepository(sl()));
  sl.registerLazySingleton<BookSearchPort>(() => BookSearchAdapter());
  sl.registerLazySingleton<ImagePort>(() => ImageServiceAdapter());

  // Application services
  sl.registerLazySingleton(() => BuildingService(sl()));
  sl.registerLazySingleton(() => VillagerService(sl(), sl()));
  sl.registerLazySingleton(() => ReadingService(sl()));
  sl.registerLazySingleton(() => InventoryService(sl(), sl()));
  sl.registerLazySingleton(() => MissionService(sl(), sl()));
  sl.registerLazySingleton(() => PlayerService(sl()));
  sl.registerLazySingleton(() => TagService(sl()));
  sl.registerLazySingleton(() => BackupService(sl()));
  sl.registerLazySingleton(() => NotificationService());

  // Adapters (providers)
  sl.registerLazySingleton(() => VillageProvider(
    sl<VillageRepository>(),
    sl<BuildingService>(),
    sl<VillagerService>(),
    sl<InventoryService>(),
    sl<MissionService>(),
    sl<PlayerService>(),
  ));
  sl.registerLazySingleton(() => BookProvider(
    sl<ReadingService>(),
    sl<ImagePort>(),
  ));
  sl.registerLazySingleton(() => TagProvider(sl<TagService>()));
  sl.registerLazySingleton(() => LanguageProvider());
}
