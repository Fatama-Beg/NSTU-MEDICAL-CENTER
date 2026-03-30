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

abstract class PrescriptionStats
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  PrescriptionStats._({
    required this.today,
    required this.week,
    required this.month,
    required this.year,
  });

  factory PrescriptionStats({
    required int today,
    required int week,
    required int month,
    required int year,
  }) = _PrescriptionStatsImpl;

  factory PrescriptionStats.fromJson(Map<String, dynamic> jsonSerialization) {
    return PrescriptionStats(
      today: jsonSerialization['today'] as int,
      week: jsonSerialization['week'] as int,
      month: jsonSerialization['month'] as int,
      year: jsonSerialization['year'] as int,
    );
  }

  int today;

  int week;

  int month;

  int year;

  /// Returns a shallow copy of this [PrescriptionStats]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PrescriptionStats copyWith({
    int? today,
    int? week,
    int? month,
    int? year,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PrescriptionStats',
      'today': today,
      'week': week,
      'month': month,
      'year': year,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PrescriptionStats',
      'today': today,
      'week': week,
      'month': month,
      'year': year,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _PrescriptionStatsImpl extends PrescriptionStats {
  _PrescriptionStatsImpl({
    required int today,
    required int week,
    required int month,
    required int year,
  }) : super._(
         today: today,
         week: week,
         month: month,
         year: year,
       );

  /// Returns a shallow copy of this [PrescriptionStats]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PrescriptionStats copyWith({
    int? today,
    int? week,
    int? month,
    int? year,
  }) {
    return PrescriptionStats(
      today: today ?? this.today,
      week: week ?? this.week,
      month: month ?? this.month,
      year: year ?? this.year,
    );
  }
}
