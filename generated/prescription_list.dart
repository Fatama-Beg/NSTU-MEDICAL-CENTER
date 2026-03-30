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

abstract class PrescriptionList
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  PrescriptionList._({
    required this.prescriptionId,
    required this.date,
    required this.doctorName,
    this.revisedFromPrescriptionId,
    this.sourceReportId,
    this.sourceReportType,
    this.sourceReportCreatedAt,
  });

  factory PrescriptionList({
    required int prescriptionId,
    required DateTime date,
    required String doctorName,
    int? revisedFromPrescriptionId,
    int? sourceReportId,
    String? sourceReportType,
    DateTime? sourceReportCreatedAt,
  }) = _PrescriptionListImpl;

  factory PrescriptionList.fromJson(Map<String, dynamic> jsonSerialization) {
    return PrescriptionList(
      prescriptionId: jsonSerialization['prescriptionId'] as int,
      date: _i1.DateTimeJsonExtension.fromJson(jsonSerialization['date']),
      doctorName: jsonSerialization['doctorName'] as String,
      revisedFromPrescriptionId:
          jsonSerialization['revisedFromPrescriptionId'] as int?,
      sourceReportId: jsonSerialization['sourceReportId'] as int?,
      sourceReportType: jsonSerialization['sourceReportType'] as String?,
      sourceReportCreatedAt: jsonSerialization['sourceReportCreatedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['sourceReportCreatedAt'],
            ),
    );
  }

  int prescriptionId;

  DateTime date;

  String doctorName;

  int? revisedFromPrescriptionId;

  int? sourceReportId;

  String? sourceReportType;

  DateTime? sourceReportCreatedAt;

  /// Returns a shallow copy of this [PrescriptionList]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PrescriptionList copyWith({
    int? prescriptionId,
    DateTime? date,
    String? doctorName,
    int? revisedFromPrescriptionId,
    int? sourceReportId,
    String? sourceReportType,
    DateTime? sourceReportCreatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PrescriptionList',
      'prescriptionId': prescriptionId,
      'date': date.toJson(),
      'doctorName': doctorName,
      if (revisedFromPrescriptionId != null)
        'revisedFromPrescriptionId': revisedFromPrescriptionId,
      if (sourceReportId != null) 'sourceReportId': sourceReportId,
      if (sourceReportType != null) 'sourceReportType': sourceReportType,
      if (sourceReportCreatedAt != null)
        'sourceReportCreatedAt': sourceReportCreatedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PrescriptionList',
      'prescriptionId': prescriptionId,
      'date': date.toJson(),
      'doctorName': doctorName,
      if (revisedFromPrescriptionId != null)
        'revisedFromPrescriptionId': revisedFromPrescriptionId,
      if (sourceReportId != null) 'sourceReportId': sourceReportId,
      if (sourceReportType != null) 'sourceReportType': sourceReportType,
      if (sourceReportCreatedAt != null)
        'sourceReportCreatedAt': sourceReportCreatedAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PrescriptionListImpl extends PrescriptionList {
  _PrescriptionListImpl({
    required int prescriptionId,
    required DateTime date,
    required String doctorName,
    int? revisedFromPrescriptionId,
    int? sourceReportId,
    String? sourceReportType,
    DateTime? sourceReportCreatedAt,
  }) : super._(
         prescriptionId: prescriptionId,
         date: date,
         doctorName: doctorName,
         revisedFromPrescriptionId: revisedFromPrescriptionId,
         sourceReportId: sourceReportId,
         sourceReportType: sourceReportType,
         sourceReportCreatedAt: sourceReportCreatedAt,
       );

  /// Returns a shallow copy of this [PrescriptionList]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PrescriptionList copyWith({
    int? prescriptionId,
    DateTime? date,
    String? doctorName,
    Object? revisedFromPrescriptionId = _Undefined,
    Object? sourceReportId = _Undefined,
    Object? sourceReportType = _Undefined,
    Object? sourceReportCreatedAt = _Undefined,
  }) {
    return PrescriptionList(
      prescriptionId: prescriptionId ?? this.prescriptionId,
      date: date ?? this.date,
      doctorName: doctorName ?? this.doctorName,
      revisedFromPrescriptionId: revisedFromPrescriptionId is int?
          ? revisedFromPrescriptionId
          : this.revisedFromPrescriptionId,
      sourceReportId: sourceReportId is int?
          ? sourceReportId
          : this.sourceReportId,
      sourceReportType: sourceReportType is String?
          ? sourceReportType
          : this.sourceReportType,
      sourceReportCreatedAt: sourceReportCreatedAt is DateTime?
          ? sourceReportCreatedAt
          : this.sourceReportCreatedAt,
    );
  }
}
