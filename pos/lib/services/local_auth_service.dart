import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/foundation.dart';

class LocalAuthService {
  static final _auth = LocalAuthentication();

  static Future<bool> hasBiometrics() async {
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } on PlatformException catch (e) {
      debugPrint('Error checking biometrics: $e');
      return false;
    }
  }

  static Future<bool> authenticate() async {
    try {
      final hasBio = await hasBiometrics();
      if (!hasBio) return false;

      return await _auth.authenticate(
        localizedReason: 'Please authenticate to log in',
      );
    } on PlatformException catch (e) {
      debugPrint('Error using biometrics: $e');
      return false;
    }
  }
}
