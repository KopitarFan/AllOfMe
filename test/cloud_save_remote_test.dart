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
          'https://cloud.example.test/api/v1/cloud-saves',
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
        if (path == '/api/v1/cloud-saves/latest/metadata') {
          return http.Response(jsonEncode(cloudPackage.metadata.toJson()), 200);
        }
        if (path == '/api/v1/cloud-saves/latest') {
          return http.Response(jsonEncode(cloudPackage.toJson()), 200);
        }
        if (path == '/api/v1/cloud-saves') {
          return http.Response(
            jsonEncode({
              'versions': [cloudPackage.metadata.toJson()],
            }),
            200,
          );
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
      client: MockClient((request) async => http.Response('not found', 404)),
    );

    expect(await adapter.latestMetadata(), isNull);
    expect(await adapter.downloadLatest(), isNull);
    expect(await adapter.listVersions(), isEmpty);
  });

  test('remote adapter surfaces server failures', () async {
    final adapter = RemoteCloudSaveAdapter(
      baseUrl: Uri.parse('https://cloud.example.test'),
      client: MockClient((request) async => http.Response('unavailable', 503)),
    );

    expect(adapter.latestMetadata(), throwsA(isA<CloudSaveRemoteException>()));
  });
}
