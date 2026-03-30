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

abstract class Prescription
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  Prescription._({
    this.id,
    this.patientId,
    required this.doctorId,
    this.doctorName,
    this.name,
    this.age,
    this.mobileNumber,
    this.gender,
    this.prescriptionDate,
    this.cc,
    this.oe,
    this.advice,
    this.test,
    this.nextVisit,
    this.isOutside,
    this.createdAt,
  });

  factory Prescription({
    int? id,
    int? patientId,
    required int doctorId,
    String? doctorName,
    String? name,
    int? age,
    String? mobileNumber,
    String? gender,
    DateTime? prescriptionDate,
    String? cc,
    String? oe,
    String? advice,
    String? test,
    String? nextVisit,
    bool? isOutside,
    DateTime? createdAt,
  }) = _PrescriptionImpl;

  factory Prescription.fromJson(Map<String, dynamic> jsonSerialization) {
    return Prescription(
      id: jsonSerialization['id'] as int?,
      patientId: jsonSerialization['patientId'] as int?,
      doctorId: jsonSerialization['doctorId'] as int,
      doctorName: jsonSerialization['doctorName'] as String?,
      name: jsonSerialization['name'] as String?,
      age: jsonSerialization['age'] as int?,
      mobileNumber: jsonSerialization['mobileNumber'] as String?,
      gender: jsonSerialization['gender'] as String?,
      prescriptionDate: jsonSerialization['prescriptionDate'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['prescriptionDate'],
            ),
      cc: jsonSerialization['cc'] as String?,
      oe: jsonSerialization['oe'] as String?,
      advice: jsonSerialization['advice'] as String?,
      test: jsonSerialization['test'] as String?,
      nextVisit: jsonSerialization['nextVisit'] as String?,
      isOutside: jsonSerialization['isOutside'] as bool?,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  int? id;

  int? patientId;

  int doctorId;

  String? doctorName;

  String? name;

  int? age;

  String? mobileNumber;

  String? gender;

  DateTime? prescriptionDate;

  String? cc;

  String? oe;

  String? advice;

  String? test;

  String? nextVisit;

  bool? isOutside;

  DateTime? createdAt;

  /// Returns a shallow copy of this [Prescription]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Prescription copyWith({
    int? id,
    int? patientId,
    int? doctorId,
    String? doctorName,
    String? name,
    int? age,
    String? mobileNumber,
    String? gender,
    DateTime? prescriptionDate,
    String? cc,
    String? oe,
    String? advice,
    String? test,
    String? nextVisit,
    bool? isOutside,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Prescription',
      if (id != null) 'id': id,
      if (patientId != null) 'patientId': patientId,
      'doctorId': doctorId,
      if (doctorName != null) 'doctorName': doctorName,
      if (name != null) 'name': name,
      if (age != null) 'age': age,
      if (mobileNumber != null) 'mobileNumber': mobileNumber,
      if (gender != null) 'gender': gender,
      if (prescriptionDate != null)
        'prescriptionDate': prescriptionDate?.toJson(),
      if (cc != null) 'cc': cc,
      if (oe != null) 'oe': oe,
      if (advice != null) 'advice': advice,
      if (test != null) 'test': test,
      if (nextVisit != null) 'nextVisit': nextVisit,
      if (isOutside != null) 'isOutside': isOutside,
      if (createdAt != null) 'createdAt': createdAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Prescription',
      if (id != null) 'id': id,
      if (patientId != null) 'patientId': patientId,
      'doctorId': doctorId,
      if (doctorName != null) 'doctorName': doctorName,
      if (name != null) 'name': name,
      if (age != null) 'age': age,
      if (mobileNumber != null) 'mobileNumber': mobileNumber,
      if (gender != null) 'gender': gender,
      if (prescriptionDate != null)
        'prescriptionDate': prescriptionDate?.toJson(),
      if (cc != null) 'cc': cc,
      if (oe != null) 'oe': oe,
      if (advice != null) 'advice': advice,
      if (test != null) 'test': test,
      if (nextVisit != null) 'nextVisit': nextVisit,
      if (isOutside != null) 'isOutside': isOutside,
      if (createdAt != null) 'createdAt': createdAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PrescriptionImpl extends Prescription {
  _PrescriptionImpl({
    int? id,
    int? patientId,
    required int doctorId,
    String? doctorName,
    String? name,
    int? age,
    String? mobileNumber,
    String? gender,
    DateTime? prescriptionDate,
    String? cc,
    String? oe,
    String? advice,
    String? test,
    String? nextVisit,
    bool? isOutside,
    DateTime? createdAt,
  }) : super._(
         id: id,
         patientId: patientId,
         doctorId: doctorId,
         doctorName: doctorName,
         name: name,
         age: age,
         mobileNumber: mobileNumber,
         gender: gender,
         prescriptionDate: prescriptionDate,
         cc: cc,
         oe: oe,
         advice: advice,
         test: test,
         nextVisit: nextVisit,
         isOutside: isOutside,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [Prescription]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Prescription copyWith({
    Object? id = _Undefined,
    Object? patientId = _Undefined,
    int? doctorId,
    Object? doctorName = _Undefined,
    Object? name = _Undefined,
    Object? age = _Undefined,
    Object? mobileNumber = _Undefined,
    Object? gender = _Undefined,
    Object? prescriptionDate = _Undefined,
    Object? cc = _Undefined,
    Object? oe = _Undefined,
    Object? advice = _Undefined,
    Object? test = _Undefined,
    Object? nextVisit = _Undefined,
    Object? isOutside = _Undefined,
    Object? createdAt = _Undefined,
  }) {
    return Prescription(
      id: id is int? ? id : this.id,
      patientId: patientId is int? ? patientId : this.patientId,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName is String? ? doctorName : this.doctorName,
      name: name is String? ? name : this.name,
      age: age is int? ? age : this.age,
      mobileNumber: mobileNumber is String? ? mobileNumber : this.mobileNumber,
      gender: gender is String? ? gender : this.gender,
      prescriptionDate: prescriptionDate is DateTime?
          ? prescriptionDate
          : this.prescriptionDate,
      cc: cc is String? ? cc : this.cc,
      oe: oe is String? ? oe : this.oe,
      advice: advice is String? ? advice : this.advice,
      test: test is String? ? test : this.test,
      nextVisit: nextVisit is String? ? nextVisit : this.nextVisit,
      isOutside: isOutside is bool? ? isOutside : this.isOutside,
      createdAt: createdAt is DateTime? ? createdAt : this.createdAt,
    );
  }
}
