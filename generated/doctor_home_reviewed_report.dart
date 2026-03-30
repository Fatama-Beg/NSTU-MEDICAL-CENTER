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

abstract class DoctorHomeReviewedReport
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  DoctorHomeReviewedReport._({
    this.reportId,
    required this.type,
    required this.uploadedByName,
    this.prescriptionId,
    required this.timeAgo,
  });

  factory DoctorHomeReviewedReport({
    int? reportId,
    required String type,
    required String uploadedByName,
    int? prescriptionId,
    required String timeAgo,
  }) = _DoctorHomeReviewedReportImpl;

  factory DoctorHomeReviewedReport.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return DoctorHomeReviewedReport(
      reportId: jsonSerialization['reportId'] as int?,
      type: jsonSerialization['type'] as String,
      uploadedByName: jsonSerialization['uploadedByName'] as String,
      prescriptionId: jsonSerialization['prescriptionId'] as int?,
      timeAgo: jsonSerialization['timeAgo'] as String,
    );
  }

  int? reportId;

  String type;

  String uploadedByName;

  int? prescriptionId;

  String timeAgo;

  /// Returns a shallow copy of this [DoctorHomeReviewedReport]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  DoctorHomeReviewedReport copyWith({
    int? reportId,
    String? type,
    String? uploadedByName,
    int? prescriptionId,
    String? timeAgo,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DoctorHomeReviewedReport',
      if (reportId != null) 'reportId': reportId,
      'type': type,
      'uploadedByName': uploadedByName,
      if (prescriptionId != null) 'prescriptionId': prescriptionId,
      'timeAgo': timeAgo,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DoctorHomeReviewedReport',
      if (reportId != null) 'reportId': reportId,
      'type': type,
      'uploadedByName': uploadedByName,
      if (prescriptionId != null) 'prescriptionId': prescriptionId,
      'timeAgo': timeAgo,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DoctorHomeReviewedReportImpl extends DoctorHomeReviewedReport {
  _DoctorHomeReviewedReportImpl({
    int? reportId,
    required String type,
    required String uploadedByName,
    int? prescriptionId,
    required String timeAgo,
  }) : super._(
         reportId: reportId,
         type: type,
         uploadedByName: uploadedByName,
         prescriptionId: prescriptionId,
         timeAgo: timeAgo,
       );

  /// Returns a shallow copy of this [DoctorHomeReviewedReport]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  DoctorHomeReviewedReport copyWith({
    Object? reportId = _Undefined,
    String? type,
    String? uploadedByName,
    Object? prescriptionId = _Undefined,
    String? timeAgo,
  }) {
    return DoctorHomeReviewedReport(
      reportId: reportId is int? ? reportId : this.reportId,
      type: type ?? this.type,
      uploadedByName: uploadedByName ?? this.uploadedByName,
      prescriptionId: prescriptionId is int?
          ? prescriptionId
          : this.prescriptionId,
      timeAgo: timeAgo ?? this.timeAgo,
    );
  }
}
