import 'storage.dart';

Future<AppStore> createPlatformAppStore() async {
  return SharedPreferencesAppStore();
}
