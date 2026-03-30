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
import 'roster_user_role.dart' as _i2;
import 'shift_type.dart' as _i3;

abstract class OndutyStaff
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  OndutyStaff._({
    required this.staffId,
    required this.staffName,
    required this.staffRole,
    required this.shiftDate,
    required this.shift,
  });

  factory OndutyStaff({
    required int staffId,
    required String staffName,
    required _i2.RosterUserRole staffRole,
    required DateTime shiftDate,
    required _i3.ShiftType shift,
  }) = _OndutyStaffImpl;

  factory OndutyStaff.fromJson(Map<String, dynamic> jsonSerialization) {
    return OndutyStaff(
      staffId: jsonSerialization['staffId'] as int,
      staffName: jsonSerialization['staffName'] as String,
      staffRole: _i2.RosterUserRole.fromJson(
        (jsonSerialization['staffRole'] as String),
      ),
      shiftDate: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['shiftDate'],
      ),
      shift: _i3.ShiftType.fromJson((jsonSerialization['shift'] as String)),
    );
  }

  int staffId;

  String staffName;

  _i2.RosterUserRole staffRole;

  DateTime shiftDate;

  _i3.ShiftType shift;

  /// Returns a shallow copy of this [OndutyStaff]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  OndutyStaff copyWith({
    int? staffId,
    String? staffName,
    _i2.RosterUserRole? staffRole,
    DateTime? shiftDate,
    _i3.ShiftType? shift,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'OndutyStaff',
      'staffId': staffId,
      'staffName': staffName,
      'staffRole': staffRole.toJson(),
      'shiftDate': shiftDate.toJson(),
      'shift': shift.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'OndutyStaff',
      'staffId': staffId,
      'staffName': staffName,
      'staffRole': staffRole.toJson(),
      'shiftDate': shiftDate.toJson(),
      'shift': shift.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _OndutyStaffImpl extends OndutyStaff {
  _OndutyStaffImpl({
    required int staffId,
    required String staffName,
    required _i2.RosterUserRole staffRole,
    required DateTime shiftDate,
    required _i3.ShiftType shift,
  }) : super._(
         staffId: staffId,
         staffName: staffName,
         staffRole: staffRole,
         shiftDate: shiftDate,
         shift: shift,
       );

  /// Returns a shallow copy of this [OndutyStaff]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  OndutyStaff copyWith({
    int? staffId,
    String? staffName,
    _i2.RosterUserRole? staffRole,
    DateTime? shiftDate,
    _i3.ShiftType? shift,
  }) {
    return OndutyStaff(
      staffId: staffId ?? this.staffId,
      staffName: staffName ?? this.staffName,
      staffRole: staffRole ?? this.staffRole,
      shiftDate: shiftDate ?? this.shiftDate,
      shift: shift ?? this.shift,
    );
  }
}
