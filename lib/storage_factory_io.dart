import 'storage.dart';
import 'storage_database.dart';
import 'storage_io.dart';

Future<AppStore> createPlatformAppStore() async {
  return LocalDatabaseAppStore.create(
    legacyStore: await LocalFileAppStore.create(
      legacyStore: SharedPreferencesAppStore(),
    ),
  );
}
