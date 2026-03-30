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

abstract class MonthlyBreakdown
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  MonthlyBreakdown._({
    required this.month,
    required this.total,
    required this.student,
    required this.teacher,
    required this.outside,
    required this.revenue,
  });

  factory MonthlyBreakdown({
    required int month,
    required int total,
    required int student,
    required int teacher,
    required int outside,
    required double revenue,
  }) = _MonthlyBreakdownImpl;

  factory MonthlyBreakdown.fromJson(Map<String, dynamic> jsonSerialization) {
    return MonthlyBreakdown(
      month: jsonSerialization['month'] as int,
      total: jsonSerialization['total'] as int,
      student: jsonSerialization['student'] as int,
      teacher: jsonSerialization['teacher'] as int,
      outside: jsonSerialization['outside'] as int,
      revenue: (jsonSerialization['revenue'] as num).toDouble(),
    );
  }

  int month;

  int total;

  int student;

  int teacher;

  int outside;

  double revenue;

  /// Returns a shallow copy of this [MonthlyBreakdown]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  MonthlyBreakdown copyWith({
    int? month,
    int? total,
    int? student,
    int? teacher,
    int? outside,
    double? revenue,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MonthlyBreakdown',
      'month': month,
      'total': total,
      'student': student,
      'teacher': teacher,
      'outside': outside,
      'revenue': revenue,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'MonthlyBreakdown',
      'month': month,
      'total': total,
      'student': student,
      'teacher': teacher,
      'outside': outside,
      'revenue': revenue,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _MonthlyBreakdownImpl extends MonthlyBreakdown {
  _MonthlyBreakdownImpl({
    required int month,
    required int total,
    required int student,
    required int teacher,
    required int outside,
    required double revenue,
  }) : super._(
         month: month,
         total: total,
         student: student,
         teacher: teacher,
         outside: outside,
         revenue: revenue,
       );

  /// Returns a shallow copy of this [MonthlyBreakdown]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  MonthlyBreakdown copyWith({
    int? month,
    int? total,
    int? student,
    int? teacher,
    int? outside,
    double? revenue,
  }) {
    return MonthlyBreakdown(
      month: month ?? this.month,
      total: total ?? this.total,
      student: student ?? this.student,
      teacher: teacher ?? this.teacher,
      outside: outside ?? this.outside,
      revenue: revenue ?? this.revenue,
    );
  }
}
