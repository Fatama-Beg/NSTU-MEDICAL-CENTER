import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:serverpod/serverpod.dart';

import '../auth/auth_user.dart';

class PasswordEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;
  Future<String> changePassword(
    Session session, {
    required String currentPassword,
    required String newPassword,
  }) async {
    final resolvedUserId = requireAuthenticatedUserId(session);
    return _changePasswordByUserId(
      session,
      userId: resolvedUserId,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}

Future<String> _changePasswordByUserId(
  Session session, {
  required int userId,
  required String currentPassword,
  required String newPassword,
}) async {
  final currentHash = sha256.convert(utf8.encode(currentPassword)).toString();

  final rows = await session.db.unsafeQuery(
    r'''
    SELECT user_id FROM users
    WHERE user_id = @userId
      AND password_hash = @currentHash
      AND is_active = true
    ''',
    parameters: QueryParameters.named({
      'userId': userId,
      'currentHash': currentHash,
    }),
  );

  if (rows.isEmpty) return 'INVALID_CREDENTIALS';

  final newHash = sha256.convert(utf8.encode(newPassword)).toString();

  final updated = await session.db.unsafeExecute(
    r'''
    UPDATE users
    SET password_hash = @newHash
    WHERE user_id = @userId AND is_active = true
    ''',
    parameters: QueryParameters.named({
      'newHash': newHash,
      'userId': userId,
    }),
  );

  return updated == 1 ? 'OK' : 'FAILED';
}
