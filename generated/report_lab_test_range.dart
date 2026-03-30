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

abstract class LabTestRangeRow
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  LabTestRangeRow._({
    required this.testName,
    required this.count,
    required this.totalAmount,
  });

  factory LabTestRangeRow({
    required String testName,
    required int count,
    required double totalAmount,
  }) = _LabTestRangeRowImpl;

  factory LabTestRangeRow.fromJson(Map<String, dynamic> jsonSerialization) {
    return LabTestRangeRow(
      testName: jsonSerialization['testName'] as String,
      count: jsonSerialization['count'] as int,
      totalAmount: (jsonSerialization['totalAmount'] as num).toDouble(),
    );
  }

  String testName;

  int count;

  double totalAmount;

  /// Returns a shallow copy of this [LabTestRangeRow]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  LabTestRangeRow copyWith({
    String? testName,
    int? count,
    double? totalAmount,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LabTestRangeRow',
      'testName': testName,
      'count': count,
      'totalAmount': totalAmount,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'LabTestRangeRow',
      'testName': testName,
      'count': count,
      'totalAmount': totalAmount,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _LabTestRangeRowImpl extends LabTestRangeRow {
  _LabTestRangeRowImpl({
    required String testName,
    required int count,
    required double totalAmount,
  }) : super._(
         testName: testName,
         count: count,
         totalAmount: totalAmount,
       );

  /// Returns a shallow copy of this [LabTestRangeRow]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  LabTestRangeRow copyWith({
    String? testName,
    int? count,
    double? totalAmount,
  }) {
    return LabTestRangeRow(
      testName: testName ?? this.testName,
      count: count ?? this.count,
      totalAmount: totalAmount ?? this.totalAmount,
    );
  }
}
