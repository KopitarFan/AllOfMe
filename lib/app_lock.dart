import 'package:local_auth/local_auth.dart';

abstract class AppAuthenticator {
  Future<AppLockStatus> status();

  Future<bool> authenticate({required String reason});
}

class AppLockStatus {
  const AppLockStatus({
    required this.isSupported,
    required this.availableBiometrics,
  });

  final bool isSupported;
  final List<BiometricType> availableBiometrics;

  bool get hasFaceId => availableBiometrics.contains(BiometricType.face);

  bool get hasBiometrics => availableBiometrics.isNotEmpty;

  String get methodLabel {
    if (hasFaceId) {
      return 'Face ID';
    }
    if (hasBiometrics) {
      return 'biometric unlock';
    }
    return 'device passcode';
  }

  String get availabilityLabel {
    if (!isSupported) {
      return 'Unavailable on this device';
    }
    if (hasFaceId) {
      return 'Face ID available';
    }
    if (hasBiometrics) {
      return 'Biometric unlock available';
    }
    return 'Device passcode available';
  }
}

class LocalAppAuthenticator implements AppAuthenticator {
  const LocalAppAuthenticator();

  @override
  Future<AppLockStatus> status() async {
    final auth = LocalAuthentication();
    try {
      final availableBiometrics = await auth.getAvailableBiometrics();
      final isSupported =
          availableBiometrics.isNotEmpty || await auth.isDeviceSupported();
      return AppLockStatus(
        isSupported: isSupported,
        availableBiometrics: availableBiometrics,
      );
    } catch (_) {
      return const AppLockStatus(isSupported: false, availableBiometrics: []);
    }
  }

  @override
  Future<bool> authenticate({required String reason}) async {
    final auth = LocalAuthentication();
    try {
      final status = await this.status();
      if (!status.isSupported) {
        return false;
      }

      return auth.authenticate(
        localizedReason: reason,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }
}
