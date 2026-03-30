/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _i1;

abstract class NotificationInfo
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  NotificationInfo._({
    required this.notificationId,
    required this.userId,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationInfo({
    required int notificationId,
    required int userId,
    required String title,
    required String message,
    required bool isRead,
    required DateTime createdAt,
  }) = _NotificationInfoImpl;

  factory NotificationInfo.fromJson(Map<String, dynamic> jsonSerialization) {
    return NotificationInfo(
      notificationId: jsonSerialization['notificationId'] as int,
      userId: jsonSerialization['userId'] as int,
      title: jsonSerialization['title'] as String,
      message: jsonSerialization['message'] as String,
      isRead: jsonSerialization['isRead'] as bool,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  int notificationId;

  int userId;

  String title;

  String message;

  bool isRead;

  DateTime createdAt;

  /// Returns a shallow copy of this [NotificationInfo]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  NotificationInfo copyWith({
    int? notificationId,
    int? userId,
    String? title,
    String? message,
    bool? isRead,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'NotificationInfo',
      'notificationId': notificationId,
      'userId': userId,
      'title': title,
      'message': message,
      'isRead': isRead,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'NotificationInfo',
      'notificationId': notificationId,
      'userId': userId,
      'title': title,
      'message': message,
      'isRead': isRead,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _NotificationInfoImpl extends NotificationInfo {
  _NotificationInfoImpl({
    required int notificationId,
    required int userId,
    required String title,
    required String message,
    required bool isRead,
    required DateTime createdAt,
  }) : super._(
         notificationId: notificationId,
         userId: userId,
         title: title,
         message: message,
         isRead: isRead,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [NotificationInfo]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  NotificationInfo copyWith({
    int? notificationId,
    int? userId,
    String? title,
    String? message,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationInfo(
      notificationId: notificationId ?? this.notificationId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
