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

abstract class LabTenHistory
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  LabTenHistory._({
    required this.resultId,
    required this.testId,
    this.testName,
    required this.patientName,
    required this.mobileNumber,
    required this.isUploaded,
    this.submittedAt,
    this.createdAt,
  });

  factory LabTenHistory({
    required int resultId,
    required int testId,
    String? testName,
    required String patientName,
    required String mobileNumber,
    required bool isUploaded,
    DateTime? submittedAt,
    DateTime? createdAt,
  }) = _LabTenHistoryImpl;

  factory LabTenHistory.fromJson(Map<String, dynamic> jsonSerialization) {
    return LabTenHistory(
      resultId: jsonSerialization['resultId'] as int,
      testId: jsonSerialization['testId'] as int,
      testName: jsonSerialization['testName'] as String?,
      patientName: jsonSerialization['patientName'] as String,
      mobileNumber: jsonSerialization['mobileNumber'] as String,
      isUploaded: jsonSerialization['isUploaded'] as bool,
      submittedAt: jsonSerialization['submittedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['submittedAt'],
            ),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  int resultId;

  int testId;

  String? testName;

  String patientName;

  String mobileNumber;

  bool isUploaded;

  DateTime? submittedAt;

  DateTime? createdAt;

  /// Returns a shallow copy of this [LabTenHistory]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  LabTenHistory copyWith({
    int? resultId,
    int? testId,
    String? testName,
    String? patientName,
    String? mobileNumber,
    bool? isUploaded,
    DateTime? submittedAt,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LabTenHistory',
      'resultId': resultId,
      'testId': testId,
      if (testName != null) 'testName': testName,
      'patientName': patientName,
      'mobileNumber': mobileNumber,
      'isUploaded': isUploaded,
      if (submittedAt != null) 'submittedAt': submittedAt?.toJson(),
      if (createdAt != null) 'createdAt': createdAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'LabTenHistory',
      'resultId': resultId,
      'testId': testId,
      if (testName != null) 'testName': testName,
      'patientName': patientName,
      'mobileNumber': mobileNumber,
      'isUploaded': isUploaded,
      if (submittedAt != null) 'submittedAt': submittedAt?.toJson(),
      if (createdAt != null) 'createdAt': createdAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _LabTenHistoryImpl extends LabTenHistory {
  _LabTenHistoryImpl({
    required int resultId,
    required int testId,
    String? testName,
    required String patientName,
    required String mobileNumber,
    required bool isUploaded,
    DateTime? submittedAt,
    DateTime? createdAt,
  }) : super._(
         resultId: resultId,
         testId: testId,
         testName: testName,
         patientName: patientName,
         mobileNumber: mobileNumber,
         isUploaded: isUploaded,
         submittedAt: submittedAt,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [LabTenHistory]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  LabTenHistory copyWith({
    int? resultId,
    int? testId,
    Object? testName = _Undefined,
    String? patientName,
    String? mobileNumber,
    bool? isUploaded,
    Object? submittedAt = _Undefined,
    Object? createdAt = _Undefined,
  }) {
    return LabTenHistory(
      resultId: resultId ?? this.resultId,
      testId: testId ?? this.testId,
      testName: testName is String? ? testName : this.testName,
      patientName: patientName ?? this.patientName,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      isUploaded: isUploaded ?? this.isUploaded,
      submittedAt: submittedAt is DateTime? ? submittedAt : this.submittedAt,
      createdAt: createdAt is DateTime? ? createdAt : this.createdAt,
    );
  }
}
