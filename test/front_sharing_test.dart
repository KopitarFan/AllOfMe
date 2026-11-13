import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:all_of_me_demo/front_sharing.dart';
import 'package:all_of_me_demo/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('reset does not register a device when sharing is unused', () async {
    final sharing = FrontSharing(
      client: MockClient((_) async {
        fail(
          'Reset must not contact the server when sharing has never been used.',
        );
      }),
    );
    addTearDown(sharing.dispose);
    expect(await sharing.pauseForReset(AppSnapshot.seeded()), isTrue);
  });

  test(
    'reset reports an unconfirmed pause when secure storage is unavailable',
    () async {
      final sharing = FrontSharing(storage: const _UnavailableSecureStorage());
      addTearDown(sharing.dispose);
      expect(await sharing.pauseForReset(AppSnapshot.seeded()), isFalse);
    },
  );

  test('disabled sharing never registers or publishes', () async {
    var calls = 0;
    final sharing = FrontSharing(
      client: MockClient((_) async {
        calls++;
        return http.Response('{}', 500);
      }),
    );
    await sharing.frontChanged(AppSnapshot.seeded());
    await sharing.retry();
    expect(calls, 0);
    sharing.dispose();
  });

  test(
    'offline update survives a new client and only sends front names',
    () async {
      Map<String, dynamic>? sent;
      final sharing = FrontSharing(
        client: MockClient((request) async {
          if (request.url.path == '/v1/devices/register') {
            return http.Response(jsonEncode({'token': 'owner-token'}), 201);
          }
          return http.Response('{}', 200);
        }),
      );
      final snapshot = AppSnapshot.seeded();
      await sharing.setPaused(false, snapshot);
      sharing.dispose();
      final reopened = FrontSharing(
        client: MockClient((request) async {
          expect(request.headers['authorization'], 'Bearer owner-token');
          sent = (jsonDecode(request.body) as Map).cast<String, dynamic>();
          return http.Response('{"accepted":true}', 200);
        }),
      );
      await reopened.retry();
      expect(sent!.keys, unorderedEquals(['eventId', 'changedAt', 'members']));
      for (final member in sent!['members'] as List) {
        expect((member as Map).keys, ['name']);
      }
      reopened.dispose();
    },
  );

  test(
    'pause removes a pending update even if server confirmation fails',
    () async {
      var fail = false;
      var publishes = 0;
      final sharing = FrontSharing(
        client: MockClient((request) async {
          if (request.url.path == '/v1/devices/register') {
            return http.Response('{"token":"owner"}', 201);
          }
          if (request.url.path.endsWith('/status')) publishes++;
          return http.Response('{}', fail ? 503 : 200);
        }),
      );
      await sharing.setPaused(false, AppSnapshot.seeded());
      fail = true;
      await expectLater(
        sharing.setPaused(true, AppSnapshot.seeded()),
        throwsStateError,
      );
      await sharing.retry();
      expect(publishes, 0);
      sharing.dispose();
    },
  );
}

class _UnavailableSecureStorage extends FlutterSecureStorage {
  const _UnavailableSecureStorage();

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    throw StateError('Secure storage is unavailable.');
  }
}
