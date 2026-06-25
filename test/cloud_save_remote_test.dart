import 'dart:convert';

import 'package:all_of_me_demo/cloud_save.dart';
import 'package:all_of_me_demo/cloud_save_factory.dart';
import 'package:all_of_me_demo/cloud_save_remote.dart';
import 'package:all_of_me_demo/cloud_save_session.dart';
import 'package:all_of_me_demo/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  Future<CloudSavePackage> package() {
    final snapshot = AppSnapshot.seeded(DateTime(2026, 6, 21));
    return CloudSavePackage.fromBackupJson(
      snapshot.toBackupJson(),
      saveId: 'cloud-save-remote',
      createdAt: DateTime.utc(2026, 6, 24, 12),
    );
  }

  test('factory uses local preview adapter until a base URL is configured', () {
    expect(
      createDefaultCloudSaveAdapter(baseUrl: ''),
      isA<SharedPreferencesCloudSaveAdapter>(),
    );

    final adapter = createDefaultCloudSaveAdapter(
      session: CloudSaveSession.create(
        baseUrl: 'https://cloud.example.test/api',
        accountLabel: 'Test account',
      ),
      tokenStore: MemoryCloudSaveTokenStore(' token '),
    );

    expect(adapter, isA<RemoteCloudSaveAdapter>());
    expect(adapter.info.isRemote, isTrue);
    expect(adapter.info.accountLabel, 'Test account');
  });

  test('factory prefills official cloud without auto-connecting', () {
    final connectionSession = defaultCloudSaveConnectionSession();

    expect(connectionSession.baseUrl, officialCloudSaveBaseUrl);
    expect(connectionSession.accountLabel, officialCloudSaveAccountLabel);
    expect(defaultCloudSaveSessionFromEnvironment(baseUrl: ''), isNull);
  });

  test('auth client registers devices and parses bearer tokens', () async {
    final client = RemoteCloudSaveAuthClient(
      baseUrl: Uri.parse('https://cloud.example.test/api'),
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.toString(),
          'https://cloud.example.test/api/v1/devices/register',
        );
        expect(
          request.headers['content-type'],
          'application/json; charset=utf-8',
        );
        expect(jsonDecode(request.body), {'deviceLabel': 'Miguel iPhone'});

        return http.Response(
          jsonEncode({
            'accountId': 'account-test',
            'deviceId': 'device-test',
            'deviceLabel': 'Miguel iPhone',
            'token': 'registered-token',
            'tokenType': 'Bearer',
          }),
          201,
        );
      }),
    );

    final registration = await client.registerDevice(
      deviceLabel: ' Miguel iPhone ',
    );

    expect(registration.accountId, 'account-test');
    expect(registration.deviceId, 'device-test');
    expect(registration.deviceLabel, 'Miguel iPhone');
    expect(registration.token, 'registered-token');
    expect(registration.tokenType, 'Bearer');
  });

  test('auth client creates and redeems device link codes', () async {
    final client = RemoteCloudSaveAuthClient(
      baseUrl: Uri.parse('https://cloud.example.test/api'),
      client: MockClient((request) async {
        final path = request.url.path;
        if (path == '/api/v1/devices/link-codes') {
          expect(request.method, 'POST');
          expect(request.headers['authorization'], 'Bearer owner-token');
          expect(jsonDecode(request.body), isEmpty);
          return http.Response(
            jsonEncode({
              'code': 'AOM-12345-ABCDE',
              'expiresAt': '2026-06-24T12:10:00.000Z',
            }),
            201,
          );
        }
        if (path == '/api/v1/devices/link') {
          expect(request.method, 'POST');
          expect(jsonDecode(request.body), {
            'code': 'aom-12345-abcde',
            'deviceLabel': 'Miguel iPad',
          });
          return http.Response(
            jsonEncode({
              'accountId': 'account-test',
              'deviceId': 'device-linked',
              'deviceLabel': 'Miguel iPad',
              'token': 'linked-token',
              'tokenType': 'Bearer',
            }),
            201,
          );
        }
        return http.Response('not found', 404);
      }),
    );

    final linkCode = await client.createDeviceLinkCode(
      accessToken: ' owner-token ',
    );
    final registration = await client.redeemDeviceLinkCode(
      code: 'aom-12345-abcde',
      deviceLabel: ' Miguel iPad ',
    );

    expect(linkCode.code, 'AOM-12345-ABCDE');
    expect(linkCode.expiresAt, DateTime.parse('2026-06-24T12:10:00.000Z'));
    expect(registration.accountId, 'account-test');
    expect(registration.deviceId, 'device-linked');
    expect(registration.deviceLabel, 'Miguel iPad');
    expect(registration.token, 'linked-token');
  });

  test('remote adapter posts packages with JSON and bearer auth', () async {
    final cloudPackage = await package();
    final adapter = RemoteCloudSaveAdapter(
      baseUrl: Uri.parse('https://cloud.example.test/api'),
      credentialsProvider: const StaticCloudSaveCredentialsProvider(
        'test-token',
      ),
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.toString(),
          'https://cloud.example.test/api/v1/saves',
        );
        expect(request.headers['authorization'], 'Bearer test-token');
        expect(
          request.headers['content-type'],
          'application/json; charset=utf-8',
        );

        final json = (jsonDecode(request.body) as Map).cast<String, Object?>();
        expect(
          ((json['metadata']! as Map).cast<String, Object?>())['saveId'],
          'cloud-save-remote',
        );
        return http.Response('', 204);
      }),
    );

    final metadata = await adapter.saveNow(cloudPackage);

    expect(metadata.saveId, 'cloud-save-remote');
  });

  test('remote adapter reads latest save and version metadata', () async {
    final cloudPackage = await package();
    final adapter = RemoteCloudSaveAdapter(
      baseUrl: Uri.parse('https://cloud.example.test/api/'),
      client: MockClient((request) async {
        final path = request.url.path;
        if (path == '/api/v1/saves') {
          return http.Response(
            jsonEncode([cloudPackage.metadata.toJson()]),
            200,
          );
        }
        if (path == '/api/v1/saves/latest') {
          return http.Response(jsonEncode(cloudPackage.toJson()), 200);
        }
        return http.Response('not found', 404);
      }),
    );

    expect((await adapter.latestMetadata())?.saveId, 'cloud-save-remote');
    expect(
      (await adapter.downloadLatest())?.metadata.saveId,
      'cloud-save-remote',
    );
    expect((await adapter.listVersions()).single.saveId, 'cloud-save-remote');
  });

  test('remote adapter treats missing latest save as empty', () async {
    final adapter = RemoteCloudSaveAdapter(
      baseUrl: Uri.parse('https://cloud.example.test'),
      client: MockClient((request) async {
        if (request.url.path == '/v1/saves') {
          return http.Response('[]', 200);
        }
        return http.Response('not found', 404);
      }),
    );

    expect(await adapter.latestMetadata(), isNull);
    expect(await adapter.downloadLatest(), isNull);
    expect(await adapter.listVersions(), isEmpty);
  });

  test('remote adapter surfaces server failures', () async {
    final adapter = RemoteCloudSaveAdapter(
      baseUrl: Uri.parse('https://cloud.example.test'),
      client: MockClient(
        (request) async => http.Response(
          jsonEncode({
            'message': 'Could not save cloud save.',
            'errorId': 'err-save-test',
            'requestId': 'req-save-test',
          }),
          503,
          headers: {'x-request-id': 'req-save-test'},
        ),
      ),
    );

    await expectLater(
      adapter.latestMetadata(),
      throwsA(
        isA<CloudSaveRemoteException>()
            .having((error) => error.statusCode, 'statusCode', 503)
            .having((error) => error.errorId, 'errorId', 'err-save-test')
            .having((error) => error.requestId, 'requestId', 'req-save-test')
            .having(
              (error) => error.supportReference,
              'supportReference',
              'err-save-test',
            ),
      ),
    );
  });
}
