import 'package:serverpod/serverpod.dart';

int requireAuthenticatedUserId(Session session) {
  final auth = session.authenticated;
  if (auth == null) {
    throw StateError('User is not authenticated.');
  }

  final userId = int.tryParse(auth.userIdentifier);
  if (userId == null) {
    throw StateError('Invalid authenticated user id: ${auth.userIdentifier}');
  }

  return userId;
}
