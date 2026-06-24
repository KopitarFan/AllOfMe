import 'cloud_save.dart';
import 'cloud_save_remote.dart';

const String cloudSaveBaseUrlEnvironmentKey = 'ALLOFME_CLOUD_SAVE_BASE_URL';
const String cloudSaveBearerTokenEnvironmentKey =
    'ALLOFME_CLOUD_SAVE_BEARER_TOKEN';

CloudSaveAdapter createDefaultCloudSaveAdapter({
  String baseUrl = const String.fromEnvironment(cloudSaveBaseUrlEnvironmentKey),
  String bearerToken = const String.fromEnvironment(
    cloudSaveBearerTokenEnvironmentKey,
  ),
}) {
  final trimmedBaseUrl = baseUrl.trim();
  if (trimmedBaseUrl.isEmpty) {
    return const SharedPreferencesCloudSaveAdapter();
  }

  return RemoteCloudSaveAdapter(
    baseUrl: Uri.parse(trimmedBaseUrl),
    bearerToken: _trimmedOrNull(bearerToken),
  );
}

String? _trimmedOrNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
