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

abstract class LabToday
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  LabToday._({
    required this.todayTotal,
    required this.todayPendingUploads,
    required this.todaySubmitted,
    required this.yesterdayTotal,
    required this.yesterdayPendingUploads,
    required this.yesterdaySubmitted,
  });

  factory LabToday({
    required int todayTotal,
    required int todayPendingUploads,
    required int todaySubmitted,
    required int yesterdayTotal,
    required int yesterdayPendingUploads,
    required int yesterdaySubmitted,
  }) = _LabTodayImpl;

  factory LabToday.fromJson(Map<String, dynamic> jsonSerialization) {
    return LabToday(
      todayTotal: jsonSerialization['todayTotal'] as int,
      todayPendingUploads: jsonSerialization['todayPendingUploads'] as int,
      todaySubmitted: jsonSerialization['todaySubmitted'] as int,
      yesterdayTotal: jsonSerialization['yesterdayTotal'] as int,
      yesterdayPendingUploads:
          jsonSerialization['yesterdayPendingUploads'] as int,
      yesterdaySubmitted: jsonSerialization['yesterdaySubmitted'] as int,
    );
  }

  int todayTotal;

  int todayPendingUploads;

  int todaySubmitted;

  int yesterdayTotal;

  int yesterdayPendingUploads;

  int yesterdaySubmitted;

  /// Returns a shallow copy of this [LabToday]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  LabToday copyWith({
    int? todayTotal,
    int? todayPendingUploads,
    int? todaySubmitted,
    int? yesterdayTotal,
    int? yesterdayPendingUploads,
    int? yesterdaySubmitted,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LabToday',
      'todayTotal': todayTotal,
      'todayPendingUploads': todayPendingUploads,
      'todaySubmitted': todaySubmitted,
      'yesterdayTotal': yesterdayTotal,
      'yesterdayPendingUploads': yesterdayPendingUploads,
      'yesterdaySubmitted': yesterdaySubmitted,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'LabToday',
      'todayTotal': todayTotal,
      'todayPendingUploads': todayPendingUploads,
      'todaySubmitted': todaySubmitted,
      'yesterdayTotal': yesterdayTotal,
      'yesterdayPendingUploads': yesterdayPendingUploads,
      'yesterdaySubmitted': yesterdaySubmitted,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _LabTodayImpl extends LabToday {
  _LabTodayImpl({
    required int todayTotal,
    required int todayPendingUploads,
    required int todaySubmitted,
    required int yesterdayTotal,
    required int yesterdayPendingUploads,
    required int yesterdaySubmitted,
  }) : super._(
         todayTotal: todayTotal,
         todayPendingUploads: todayPendingUploads,
         todaySubmitted: todaySubmitted,
         yesterdayTotal: yesterdayTotal,
         yesterdayPendingUploads: yesterdayPendingUploads,
         yesterdaySubmitted: yesterdaySubmitted,
       );

  /// Returns a shallow copy of this [LabToday]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  LabToday copyWith({
    int? todayTotal,
    int? todayPendingUploads,
    int? todaySubmitted,
    int? yesterdayTotal,
    int? yesterdayPendingUploads,
    int? yesterdaySubmitted,
  }) {
    return LabToday(
      todayTotal: todayTotal ?? this.todayTotal,
      todayPendingUploads: todayPendingUploads ?? this.todayPendingUploads,
      todaySubmitted: todaySubmitted ?? this.todaySubmitted,
      yesterdayTotal: yesterdayTotal ?? this.yesterdayTotal,
      yesterdayPendingUploads:
          yesterdayPendingUploads ?? this.yesterdayPendingUploads,
      yesterdaySubmitted: yesterdaySubmitted ?? this.yesterdaySubmitted,
    );
  }
}
