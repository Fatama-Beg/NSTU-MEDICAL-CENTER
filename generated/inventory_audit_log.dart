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

abstract class InventoryAuditLog
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  InventoryAuditLog._({
    this.id,
    this.userName,
    required this.action,
    this.oldQuantity,
    this.newQuantity,
    required this.timestamp,
  });

  factory InventoryAuditLog({
    int? id,
    String? userName,
    required String action,
    int? oldQuantity,
    int? newQuantity,
    required DateTime timestamp,
  }) = _InventoryAuditLogImpl;

  factory InventoryAuditLog.fromJson(Map<String, dynamic> jsonSerialization) {
    return InventoryAuditLog(
      id: jsonSerialization['id'] as int?,
      userName: jsonSerialization['userName'] as String?,
      action: jsonSerialization['action'] as String,
      oldQuantity: jsonSerialization['oldQuantity'] as int?,
      newQuantity: jsonSerialization['newQuantity'] as int?,
      timestamp: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['timestamp'],
      ),
    );
  }

  int? id;

  String? userName;

  String action;

  int? oldQuantity;

  int? newQuantity;

  DateTime timestamp;

  /// Returns a shallow copy of this [InventoryAuditLog]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  InventoryAuditLog copyWith({
    int? id,
    String? userName,
    String? action,
    int? oldQuantity,
    int? newQuantity,
    DateTime? timestamp,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'InventoryAuditLog',
      if (id != null) 'id': id,
      if (userName != null) 'userName': userName,
      'action': action,
      if (oldQuantity != null) 'oldQuantity': oldQuantity,
      if (newQuantity != null) 'newQuantity': newQuantity,
      'timestamp': timestamp.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'InventoryAuditLog',
      if (id != null) 'id': id,
      if (userName != null) 'userName': userName,
      'action': action,
      if (oldQuantity != null) 'oldQuantity': oldQuantity,
      if (newQuantity != null) 'newQuantity': newQuantity,
      'timestamp': timestamp.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _InventoryAuditLogImpl extends InventoryAuditLog {
  _InventoryAuditLogImpl({
    int? id,
    String? userName,
    required String action,
    int? oldQuantity,
    int? newQuantity,
    required DateTime timestamp,
  }) : super._(
         id: id,
         userName: userName,
         action: action,
         oldQuantity: oldQuantity,
         newQuantity: newQuantity,
         timestamp: timestamp,
       );

  /// Returns a shallow copy of this [InventoryAuditLog]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  InventoryAuditLog copyWith({
    Object? id = _Undefined,
    Object? userName = _Undefined,
    String? action,
    Object? oldQuantity = _Undefined,
    Object? newQuantity = _Undefined,
    DateTime? timestamp,
  }) {
    return InventoryAuditLog(
      id: id is int? ? id : this.id,
      userName: userName is String? ? userName : this.userName,
      action: action ?? this.action,
      oldQuantity: oldQuantity is int? ? oldQuantity : this.oldQuantity,
      newQuantity: newQuantity is int? ? newQuantity : this.newQuantity,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
