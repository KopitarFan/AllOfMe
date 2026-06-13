import 'storage.dart';
import 'storage_factory_stub.dart'
    if (dart.library.io) 'storage_factory_io.dart';

Future<AppStore> createDefaultAppStore() => createPlatformAppStore();
