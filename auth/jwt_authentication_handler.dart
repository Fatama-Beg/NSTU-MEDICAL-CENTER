import 'dart:io';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:serverpod/serverpod.dart';

const _uuid = Uuid();

String? _jwtSecret(Session session) {
  final fromPasswords = session.passwords['jwtSecret'];
  if (fromPasswords != null && fromPasswords.trim().isNotEmpty) {
    return fromPasswords.trim();
  }

  // Allow runtime env as fallback (useful for Railway).
  final fromEnv = Platform.environment['JWT_SECRET'];
  if (fromEnv != null && fromEnv.trim().isNotEmpty) {
    return fromEnv.trim();
  }

  // Fallback to Serverpod's service secret to avoid extra config locally.
  final fromServiceSecret = session.passwords['serviceSecret'];
  if (fromServiceSecret != null && fromServiceSecret.trim().isNotEmpty) {
    return fromServiceSecret.trim();
  }

  return null;
}

/// Auth handler that treats the Serverpod auth key as a signed JWT.
///
/// Expected JWT payload:
/// - `uid`: int (our `users.user_id`)
/// - `jti`: string unique id
///
/// This implementation validates against DB state to ensure the user is active.
Future<AuthenticationInfo?> jwtAuthenticationHandler(
  Session session,
  String token,
) async {
  try {
    final secret = _jwtSecret(session);
    if (secret == null) return null;

    final t = token.trim().startsWith('Bearer ')
        ? token.trim().substring('Bearer '.length).trim()
        : token.trim();
    if (t.isEmpty) return null;

    final jwt = JWT.verify(t, SecretKey(secret));

    final uid = jwt.payload['uid'];
    final userId = uid is int ? uid : int.tryParse(uid?.toString() ?? '');
    if (userId == null) return null;

    // Validate user is active.
    final rows = await session.db.unsafeQuery(
      'SELECT is_active FROM users WHERE user_id = @uid LIMIT 1',
      parameters: QueryParameters.named({'uid': userId}),
    );
    if (rows.isEmpty) return null;
    final row = rows.first.toColumnMap();

    final isActive = row['is_active'] == true;
    if (!isActive) return null;

    final jti = (jwt.payload['jti'] ?? _uuid.v4()).toString();

    return AuthenticationInfo(
      userId.toString(),
      const {},
      authId: jti,
    );
  } catch (_) {
    return null;
  }
}
