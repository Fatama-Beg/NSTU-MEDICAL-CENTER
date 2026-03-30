import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import '../auth/auth_user.dart';

class NotificationEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  // 1. Create Notification for the authenticated user
  Future<bool> createNotification(
    Session session, {
    required String title,
    required String message,
  }) async {
    try {
      final resolvedUserId = requireAuthenticatedUserId(session);
      await session.db.unsafeExecute(
        '''
        INSERT INTO notifications (user_id, title, message, is_read, created_at)
        VALUES (@uid, @t, @m, FALSE, NOW())
        ''',
        parameters: QueryParameters.named({
          'uid': resolvedUserId,
          't': title.trim(),
          'm': message.trim(),
        }),
      );
      return true;
    } catch (e, st) {
      session.log(
        'createNotification failed: $e',
        level: LogLevel.error,
        stackTrace: st,
      );
      return false;
    }
  }

  // 2. Get Notifications for the authenticated user
  Future<List<NotificationInfo>> getMyNotifications(
    Session session, {
    required int limit,
  }) async {
    final resolvedUserId = requireAuthenticatedUserId(session);
    final rows = await session.db.unsafeQuery(
      '''
      SELECT notification_id, user_id, title, message, is_read, created_at
      FROM notifications
      WHERE user_id = @uid
      ORDER BY created_at DESC
      LIMIT @lim
      ''',
      parameters: QueryParameters.named({'uid': resolvedUserId, 'lim': limit}),
    );

    return rows.map((r) {
      final m = r.toColumnMap();
      return NotificationInfo(
        notificationId: m['notification_id'] as int,
        userId: m['user_id'] as int,
        title: (m['title'] as String?) ?? '',
        message: (m['message'] as String?) ?? '',
        isRead: (m['is_read'] as bool?) ?? false,
        createdAt: m['created_at'] as DateTime,
      );
    }).toList();
  }

  // 3. Get Counts for the authenticated user
  Future<Map<String, int>> getMyNotificationCounts(Session session) async {
    final resolvedUserId = requireAuthenticatedUserId(session);
    final rows = await session.db.unsafeQuery(
      '''
      SELECT
        SUM(CASE WHEN is_read = FALSE THEN 1 ELSE 0 END)::int AS unread,
        SUM(CASE WHEN is_read = TRUE  THEN 1 ELSE 0 END)::int AS read
      FROM notifications
      WHERE user_id = @uid
      ''',
      parameters: QueryParameters.named({'uid': resolvedUserId}),
    );

    if (rows.isEmpty) return {'unread': 0, 'read': 0};

    final map = rows.first.toColumnMap();
    return {
      'unread': (map['unread'] as int?) ?? 0,
      'read': (map['read'] as int?) ?? 0,
    };
  }

  // 4. Get By ID (scoped to authenticated user)
  Future<NotificationInfo?> getNotificationById(
    Session session, {
    required int notificationId,
  }) async {
    final resolvedUserId = requireAuthenticatedUserId(session);
    final rows = await session.db.unsafeQuery(
      '''
      SELECT notification_id, user_id, title, message, is_read, created_at
      FROM notifications
      WHERE notification_id = @nid AND user_id = @uid
      LIMIT 1
      ''',
      parameters:
          QueryParameters.named({'nid': notificationId, 'uid': resolvedUserId}),
    );

    if (rows.isEmpty) return null;

    final m = rows.first.toColumnMap();
    return NotificationInfo(
      notificationId: m['notification_id'] as int,
      userId: m['user_id'] as int,
      title: (m['title'] as String?) ?? '',
      message: (m['message'] as String?) ?? '',
      isRead: (m['is_read'] as bool?) ?? false,
      createdAt: m['created_at'] as DateTime,
    );
  }

  // 5. Mark One Read (scoped to authenticated user)
  Future<bool> markAsRead(
    Session session, {
    required int notificationId,
  }) async {
    final resolvedUserId = requireAuthenticatedUserId(session);
    try {
      await session.db.unsafeExecute(
        '''
        UPDATE notifications
        SET is_read = TRUE
        WHERE notification_id = @nid AND user_id = @uid
        ''',
        parameters: QueryParameters.named(
            {'nid': notificationId, 'uid': resolvedUserId}),
      );
      return true;
    } catch (e, st) {
      session.log(
        'markAsRead failed: $e',
        level: LogLevel.error,
        stackTrace: st,
      );
      return false;
    }
  }

  // 6. Mark All Read (scoped to authenticated user)
  Future<bool> markAllAsRead(Session session) async {
    final resolvedUserId = requireAuthenticatedUserId(session);
    try {
      await session.db.unsafeExecute(
        '''
        UPDATE notifications
        SET is_read = TRUE
        WHERE user_id = @uid AND is_read = FALSE
        ''',
        parameters: QueryParameters.named({'uid': resolvedUserId}),
      );
      return true;
    } catch (e, st) {
      session.log(
        'markAllAsRead failed: $e',
        level: LogLevel.error,
        stackTrace: st,
      );
      return false;
    }
  }
}
