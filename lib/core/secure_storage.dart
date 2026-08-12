import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SecureStorageService {
  // TODO(SECURITY): Revert to FlutterSecureStorage when an Apple Developer Certificate is available.
  // Using SharedPreferences as a temporary fallback to bypass macOS Keychain sandbox errors (-34018)
  // during local prototyping without an active Apple Team ID.
  
  SecureStorageService();

  Future<void> saveSecretKey(String connectionId, String secretKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('s3_secret_$connectionId', secretKey);
  }

  Future<String?> getSecretKey(String connectionId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('s3_secret_$connectionId');
  }

  Future<void> deleteSecretKey(String connectionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('s3_secret_$connectionId');
  }
}

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});
