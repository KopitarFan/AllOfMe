import 'package:all_of_me_demo/cloud_save_factory.dart';
import 'package:all_of_me_demo/cloud_save_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cloud save session serializes without access token data', () {
    final session = CloudSaveSession.create(
      baseUrl: 'https://cloud.example.test/api',
      accountLabel: 'Test cloud',
      connectedAt: DateTime.utc(2026, 6, 24, 12),
    );

    final json = session.toJson();

    expect(json['baseUrl'], 'https://cloud.example.test/api/');
    expect(json['accountLabel'], 'Test cloud');
    expect(json['connectedAt'], '2026-06-24T12:00:00.000Z');
    expect(json.containsKey('accessToken'), isFalse);
  });

  test('memory token store saves, trims, loads, and clears tokens', () async {
    final store = MemoryCloudSaveTokenStore();

    await store.save(' token ');
    expect(await store.load(), 'token');

    await store.clear();
    expect(await store.load(), isNull);
  });

  test(
    'credentials provider reads the current token from token store',
    () async {
      final store = MemoryCloudSaveTokenStore();
      final provider = CloudSaveSessionCredentialsProvider(store);

      expect(await provider.bearerToken(), isNull);

      await store.save('first-token');
      expect(await provider.bearerToken(), 'first-token');

      await store.save('second-token');
      expect(await provider.bearerToken(), 'second-token');
    },
  );
}
