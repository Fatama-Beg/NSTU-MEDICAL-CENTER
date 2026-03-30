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

abstract class Roster
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  Roster._({
    this.rosterId,
    required this.staffId,
    required this.staffName,
    required this.staffRole,
    required this.shift,
    required this.shiftDate,
  });

  factory Roster({
    int? rosterId,
    required int staffId,
    required String staffName,
    required String staffRole,
    required String shift,
    required DateTime shiftDate,
  }) = _RosterImpl;

  factory Roster.fromJson(Map<String, dynamic> jsonSerialization) {
    return Roster(
      rosterId: jsonSerialization['rosterId'] as int?,
      staffId: jsonSerialization['staffId'] as int,
      staffName: jsonSerialization['staffName'] as String,
      staffRole: jsonSerialization['staffRole'] as String,
      shift: jsonSerialization['shift'] as String,
      shiftDate: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['shiftDate'],
      ),
    );
  }

  int? rosterId;

  int staffId;

  String staffName;

  String staffRole;

  String shift;

  DateTime shiftDate;

  /// Returns a shallow copy of this [Roster]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Roster copyWith({
    int? rosterId,
    int? staffId,
    String? staffName,
    String? staffRole,
    String? shift,
    DateTime? shiftDate,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Roster',
      if (rosterId != null) 'rosterId': rosterId,
      'staffId': staffId,
      'staffName': staffName,
      'staffRole': staffRole,
      'shift': shift,
      'shiftDate': shiftDate.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Roster',
      if (rosterId != null) 'rosterId': rosterId,
      'staffId': staffId,
      'staffName': staffName,
      'staffRole': staffRole,
      'shift': shift,
      'shiftDate': shiftDate.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _RosterImpl extends Roster {
  _RosterImpl({
    int? rosterId,
    required int staffId,
    required String staffName,
    required String staffRole,
    required String shift,
    required DateTime shiftDate,
  }) : super._(
         rosterId: rosterId,
         staffId: staffId,
         staffName: staffName,
         staffRole: staffRole,
         shift: shift,
         shiftDate: shiftDate,
       );

  /// Returns a shallow copy of this [Roster]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Roster copyWith({
    Object? rosterId = _Undefined,
    int? staffId,
    String? staffName,
    String? staffRole,
    String? shift,
    DateTime? shiftDate,
  }) {
    return Roster(
      rosterId: rosterId is int? ? rosterId : this.rosterId,
      staffId: staffId ?? this.staffId,
      staffName: staffName ?? this.staffName,
      staffRole: staffRole ?? this.staffRole,
      shift: shift ?? this.shift,
      shiftDate: shiftDate ?? this.shiftDate,
    );
  }
}
