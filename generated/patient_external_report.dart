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

abstract class PatientExternalReport
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  PatientExternalReport._({
    this.reportId,
    required this.patientId,
    required this.type,
    required this.reportDate,
    required this.filePath,
    required this.prescribedDoctorId,
    this.prescriptionId,
    required this.uploadedBy,
    required this.reviewed,
    this.createdAt,
  });

  factory PatientExternalReport({
    int? reportId,
    required int patientId,
    required String type,
    required DateTime reportDate,
    required String filePath,
    required int prescribedDoctorId,
    int? prescriptionId,
    required int uploadedBy,
    required bool reviewed,
    DateTime? createdAt,
  }) = _PatientExternalReportImpl;

  factory PatientExternalReport.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return PatientExternalReport(
      reportId: jsonSerialization['reportId'] as int?,
      patientId: jsonSerialization['patientId'] as int,
      type: jsonSerialization['type'] as String,
      reportDate: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['reportDate'],
      ),
      filePath: jsonSerialization['filePath'] as String,
      prescribedDoctorId: jsonSerialization['prescribedDoctorId'] as int,
      prescriptionId: jsonSerialization['prescriptionId'] as int?,
      uploadedBy: jsonSerialization['uploadedBy'] as int,
      reviewed: jsonSerialization['reviewed'] as bool,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  int? reportId;

  int patientId;

  String type;

  DateTime reportDate;

  String filePath;

  int prescribedDoctorId;

  int? prescriptionId;

  int uploadedBy;

  bool reviewed;

  DateTime? createdAt;

  /// Returns a shallow copy of this [PatientExternalReport]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PatientExternalReport copyWith({
    int? reportId,
    int? patientId,
    String? type,
    DateTime? reportDate,
    String? filePath,
    int? prescribedDoctorId,
    int? prescriptionId,
    int? uploadedBy,
    bool? reviewed,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PatientExternalReport',
      if (reportId != null) 'reportId': reportId,
      'patientId': patientId,
      'type': type,
      'reportDate': reportDate.toJson(),
      'filePath': filePath,
      'prescribedDoctorId': prescribedDoctorId,
      if (prescriptionId != null) 'prescriptionId': prescriptionId,
      'uploadedBy': uploadedBy,
      'reviewed': reviewed,
      if (createdAt != null) 'createdAt': createdAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PatientExternalReport',
      if (reportId != null) 'reportId': reportId,
      'patientId': patientId,
      'type': type,
      'reportDate': reportDate.toJson(),
      'filePath': filePath,
      'prescribedDoctorId': prescribedDoctorId,
      if (prescriptionId != null) 'prescriptionId': prescriptionId,
      'uploadedBy': uploadedBy,
      'reviewed': reviewed,
      if (createdAt != null) 'createdAt': createdAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PatientExternalReportImpl extends PatientExternalReport {
  _PatientExternalReportImpl({
    int? reportId,
    required int patientId,
    required String type,
    required DateTime reportDate,
    required String filePath,
    required int prescribedDoctorId,
    int? prescriptionId,
    required int uploadedBy,
    required bool reviewed,
    DateTime? createdAt,
  }) : super._(
         reportId: reportId,
         patientId: patientId,
         type: type,
         reportDate: reportDate,
         filePath: filePath,
         prescribedDoctorId: prescribedDoctorId,
         prescriptionId: prescriptionId,
         uploadedBy: uploadedBy,
         reviewed: reviewed,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [PatientExternalReport]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PatientExternalReport copyWith({
    Object? reportId = _Undefined,
    int? patientId,
    String? type,
    DateTime? reportDate,
    String? filePath,
    int? prescribedDoctorId,
    Object? prescriptionId = _Undefined,
    int? uploadedBy,
    bool? reviewed,
    Object? createdAt = _Undefined,
  }) {
    return PatientExternalReport(
      reportId: reportId is int? ? reportId : this.reportId,
      patientId: patientId ?? this.patientId,
      type: type ?? this.type,
      reportDate: reportDate ?? this.reportDate,
      filePath: filePath ?? this.filePath,
      prescribedDoctorId: prescribedDoctorId ?? this.prescribedDoctorId,
      prescriptionId: prescriptionId is int?
          ? prescriptionId
          : this.prescriptionId,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      reviewed: reviewed ?? this.reviewed,
      createdAt: createdAt is DateTime? ? createdAt : this.createdAt,
    );
  }
}
