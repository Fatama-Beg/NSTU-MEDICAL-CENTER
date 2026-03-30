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

abstract class AuditEntry
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  AuditEntry._({
    required this.auditId,
    required this.action,
    this.targetName,
    required this.createdAt,
    this.adminName,
  });

  factory AuditEntry({
    required int auditId,
    required String action,
    String? targetName,
    required DateTime createdAt,
    String? adminName,
  }) = _AuditEntryImpl;

  factory AuditEntry.fromJson(Map<String, dynamic> jsonSerialization) {
    return AuditEntry(
      auditId: jsonSerialization['auditId'] as int,
      action: jsonSerialization['action'] as String,
      targetName: jsonSerialization['targetName'] as String?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      adminName: jsonSerialization['adminName'] as String?,
    );
  }

  int auditId;

  String action;

  String? targetName;

  DateTime createdAt;

  String? adminName;

  /// Returns a shallow copy of this [AuditEntry]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AuditEntry copyWith({
    int? auditId,
    String? action,
    String? targetName,
    DateTime? createdAt,
    String? adminName,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AuditEntry',
      'auditId': auditId,
      'action': action,
      if (targetName != null) 'targetName': targetName,
      'createdAt': createdAt.toJson(),
      if (adminName != null) 'adminName': adminName,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'AuditEntry',
      'auditId': auditId,
      'action': action,
      if (targetName != null) 'targetName': targetName,
      'createdAt': createdAt.toJson(),
      if (adminName != null) 'adminName': adminName,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AuditEntryImpl extends AuditEntry {
  _AuditEntryImpl({
    required int auditId,
    required String action,
    String? targetName,
    required DateTime createdAt,
    String? adminName,
  }) : super._(
         auditId: auditId,
         action: action,
         targetName: targetName,
         createdAt: createdAt,
         adminName: adminName,
       );

  /// Returns a shallow copy of this [AuditEntry]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AuditEntry copyWith({
    int? auditId,
    String? action,
    Object? targetName = _Undefined,
    DateTime? createdAt,
    Object? adminName = _Undefined,
  }) {
    return AuditEntry(
      auditId: auditId ?? this.auditId,
      action: action ?? this.action,
      targetName: targetName is String? ? targetName : this.targetName,
      createdAt: createdAt ?? this.createdAt,
      adminName: adminName is String? ? adminName : this.adminName,
    );
  }
}
