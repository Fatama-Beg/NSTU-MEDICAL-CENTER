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

abstract class LabTests
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  LabTests._({
    this.id,
    required this.testName,
    required this.description,
    required this.studentFee,
    required this.teacherFee,
    required this.outsideFee,
    required this.available,
  });

  factory LabTests({
    int? id,
    required String testName,
    required String description,
    required double studentFee,
    required double teacherFee,
    required double outsideFee,
    required bool available,
  }) = _LabTestsImpl;

  factory LabTests.fromJson(Map<String, dynamic> jsonSerialization) {
    return LabTests(
      id: jsonSerialization['id'] as int?,
      testName: jsonSerialization['testName'] as String,
      description: jsonSerialization['description'] as String,
      studentFee: (jsonSerialization['studentFee'] as num).toDouble(),
      teacherFee: (jsonSerialization['teacherFee'] as num).toDouble(),
      outsideFee: (jsonSerialization['outsideFee'] as num).toDouble(),
      available: jsonSerialization['available'] as bool,
    );
  }

  int? id;

  String testName;

  String description;

  double studentFee;

  double teacherFee;

  double outsideFee;

  bool available;

  /// Returns a shallow copy of this [LabTests]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  LabTests copyWith({
    int? id,
    String? testName,
    String? description,
    double? studentFee,
    double? teacherFee,
    double? outsideFee,
    bool? available,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LabTests',
      if (id != null) 'id': id,
      'testName': testName,
      'description': description,
      'studentFee': studentFee,
      'teacherFee': teacherFee,
      'outsideFee': outsideFee,
      'available': available,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'LabTests',
      if (id != null) 'id': id,
      'testName': testName,
      'description': description,
      'studentFee': studentFee,
      'teacherFee': teacherFee,
      'outsideFee': outsideFee,
      'available': available,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _LabTestsImpl extends LabTests {
  _LabTestsImpl({
    int? id,
    required String testName,
    required String description,
    required double studentFee,
    required double teacherFee,
    required double outsideFee,
    required bool available,
  }) : super._(
         id: id,
         testName: testName,
         description: description,
         studentFee: studentFee,
         teacherFee: teacherFee,
         outsideFee: outsideFee,
         available: available,
       );

  /// Returns a shallow copy of this [LabTests]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  LabTests copyWith({
    Object? id = _Undefined,
    String? testName,
    String? description,
    double? studentFee,
    double? teacherFee,
    double? outsideFee,
    bool? available,
  }) {
    return LabTests(
      id: id is int? ? id : this.id,
      testName: testName ?? this.testName,
      description: description ?? this.description,
      studentFee: studentFee ?? this.studentFee,
      teacherFee: teacherFee ?? this.teacherFee,
      outsideFee: outsideFee ?? this.outsideFee,
      available: available ?? this.available,
    );
  }
}
