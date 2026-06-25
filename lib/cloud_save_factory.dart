import 'cloud_save.dart';
import 'cloud_save_remote.dart';
import 'cloud_save_session.dart';

const String cloudSaveBaseUrlEnvironmentKey = 'ALLOFME_CLOUD_SAVE_BASE_URL';
const String cloudSaveAccountLabelEnvironmentKey =
    'ALLOFME_CLOUD_SAVE_ACCOUNT_LABEL';
const String officialCloudSaveBaseUrl = 'https://api.allofmeapp.com/';
const String officialCloudSaveAccountLabel = 'All Of Me Cloud';

class CloudSaveSessionCredentialsProvider
    implements CloudSaveCredentialsProvider {
  const CloudSaveSessionCredentialsProvider(this.tokenStore);

  final CloudSaveTokenStore tokenStore;

  @override
  Future<String?> bearerToken() => tokenStore.load();
}

CloudSaveAdapter createDefaultCloudSaveAdapter({
  CloudSaveSession? session,
  CloudSaveTokenStore tokenStore = const SecureCloudSaveTokenStore(),
  String baseUrl = const String.fromEnvironment(cloudSaveBaseUrlEnvironmentKey),
  String accountLabel = const String.fromEnvironment(
    cloudSaveAccountLabelEnvironmentKey,
  ),
}) {
  return createCloudSaveAdapterForSession(
    session ??
        defaultCloudSaveSessionFromEnvironment(
          baseUrl: baseUrl,
          accountLabel: accountLabel,
        ),
    tokenStore: tokenStore,
  );
}

CloudSaveAdapter createCloudSaveAdapterForSession(
  CloudSaveSession? session, {
  CloudSaveTokenStore tokenStore = const SecureCloudSaveTokenStore(),
}) {
  if (session == null) {
    return const SharedPreferencesCloudSaveAdapter();
  }

  return RemoteCloudSaveAdapter(
    baseUrl: session.baseUri,
    accountLabel: session.accountLabel,
    credentialsProvider: CloudSaveSessionCredentialsProvider(tokenStore),
  );
}

CloudSaveSession? defaultCloudSaveSessionFromEnvironment({
  String baseUrl = const String.fromEnvironment(cloudSaveBaseUrlEnvironmentKey),
  String accountLabel = const String.fromEnvironment(
    cloudSaveAccountLabelEnvironmentKey,
  ),
}) {
  final trimmedBaseUrl = baseUrl.trim();
  if (trimmedBaseUrl.isEmpty) {
    return null;
  }

  return CloudSaveSession.create(
    baseUrl: trimmedBaseUrl,
    accountLabel: _trimmedOrNull(accountLabel),
  );
}

CloudSaveSession defaultCloudSaveConnectionSession({
  String baseUrl = const String.fromEnvironment(
    cloudSaveBaseUrlEnvironmentKey,
    defaultValue: officialCloudSaveBaseUrl,
  ),
  String accountLabel = const String.fromEnvironment(
    cloudSaveAccountLabelEnvironmentKey,
    defaultValue: officialCloudSaveAccountLabel,
  ),
}) {
  return CloudSaveSession.create(
    baseUrl: baseUrl,
    accountLabel: _trimmedOrNull(accountLabel),
  );
}

String? _trimmedOrNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
