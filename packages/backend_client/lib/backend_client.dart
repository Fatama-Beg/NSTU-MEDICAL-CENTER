export 'src/protocol/protocol.dart';
export 'package:serverpod_client/serverpod_client.dart';
import 'package:backend_client/backend_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cross-platform auth key storage.
///
/// Stores the Serverpod authentication key (JWT) in SharedPreferences.
/// Works for mobile/desktop/web.
// ignore: deprecated_member_use
class PrefsAuthenticationKeyManager extends AuthenticationKeyManager {
  static const _key = 'serverpod_auth_key';

  @override
  Future<String?> get() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_key);
    if (v == null || v.isEmpty) return null;
    return v;
  }

  @override
  Future<void> put(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, key);
  }

  @override
  Future<void> remove() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  @override
  Future<String?> toHeaderValue(String? key) async {
    final v = key?.trim();
    if (v == null || v.isEmpty) return null;
    // Serverpod expects Authorization: Bearer <authKey>
    return 'Bearer $v';
  }
}

late Client client;
late PrefsAuthenticationKeyManager authKeyManager;

void initServerpodClient() {
  // late String serverUrl = 'https://backend-production-71d1.up.railway.app/';
  late String serverUrl = 'http://localhost:8080';

  authKeyManager = PrefsAuthenticationKeyManager();
  client = Client(
    serverUrl,
    // ignore: deprecated_member_use_from_same_package
    authenticationKeyManager: authKeyManager,
  );

  print('Serverpod client initialized → $serverUrl');
}
