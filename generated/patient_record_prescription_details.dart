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
import 'patient_record_prescribed_item.dart' as _i2;
import 'package:backend_server/src/generated/protocol.dart' as _i3;

abstract class PatientPrescriptionDetails
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  PatientPrescriptionDetails._({
    required this.prescriptionId,
    required this.name,
    this.mobileNumber,
    this.gender,
    this.age,
    this.cc,
    this.oe,
    this.advice,
    this.test,
    required this.items,
  });

  factory PatientPrescriptionDetails({
    required int prescriptionId,
    required String name,
    String? mobileNumber,
    String? gender,
    int? age,
    String? cc,
    String? oe,
    String? advice,
    String? test,
    required List<_i2.PatientPrescribedItem> items,
  }) = _PatientPrescriptionDetailsImpl;

  factory PatientPrescriptionDetails.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return PatientPrescriptionDetails(
      prescriptionId: jsonSerialization['prescriptionId'] as int,
      name: jsonSerialization['name'] as String,
      mobileNumber: jsonSerialization['mobileNumber'] as String?,
      gender: jsonSerialization['gender'] as String?,
      age: jsonSerialization['age'] as int?,
      cc: jsonSerialization['cc'] as String?,
      oe: jsonSerialization['oe'] as String?,
      advice: jsonSerialization['advice'] as String?,
      test: jsonSerialization['test'] as String?,
      items: _i3.Protocol().deserialize<List<_i2.PatientPrescribedItem>>(
        jsonSerialization['items'],
      ),
    );
  }

  int prescriptionId;

  String name;

  String? mobileNumber;

  String? gender;

  int? age;

  String? cc;

  String? oe;

  String? advice;

  String? test;

  List<_i2.PatientPrescribedItem> items;

  /// Returns a shallow copy of this [PatientPrescriptionDetails]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PatientPrescriptionDetails copyWith({
    int? prescriptionId,
    String? name,
    String? mobileNumber,
    String? gender,
    int? age,
    String? cc,
    String? oe,
    String? advice,
    String? test,
    List<_i2.PatientPrescribedItem>? items,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PatientPrescriptionDetails',
      'prescriptionId': prescriptionId,
      'name': name,
      if (mobileNumber != null) 'mobileNumber': mobileNumber,
      if (gender != null) 'gender': gender,
      if (age != null) 'age': age,
      if (cc != null) 'cc': cc,
      if (oe != null) 'oe': oe,
      if (advice != null) 'advice': advice,
      if (test != null) 'test': test,
      'items': items.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PatientPrescriptionDetails',
      'prescriptionId': prescriptionId,
      'name': name,
      if (mobileNumber != null) 'mobileNumber': mobileNumber,
      if (gender != null) 'gender': gender,
      if (age != null) 'age': age,
      if (cc != null) 'cc': cc,
      if (oe != null) 'oe': oe,
      if (advice != null) 'advice': advice,
      if (test != null) 'test': test,
      'items': items.toJson(valueToJson: (v) => v.toJsonForProtocol()),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PatientPrescriptionDetailsImpl extends PatientPrescriptionDetails {
  _PatientPrescriptionDetailsImpl({
    required int prescriptionId,
    required String name,
    String? mobileNumber,
    String? gender,
    int? age,
    String? cc,
    String? oe,
    String? advice,
    String? test,
    required List<_i2.PatientPrescribedItem> items,
  }) : super._(
         prescriptionId: prescriptionId,
         name: name,
         mobileNumber: mobileNumber,
         gender: gender,
         age: age,
         cc: cc,
         oe: oe,
         advice: advice,
         test: test,
         items: items,
       );

  /// Returns a shallow copy of this [PatientPrescriptionDetails]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PatientPrescriptionDetails copyWith({
    int? prescriptionId,
    String? name,
    Object? mobileNumber = _Undefined,
    Object? gender = _Undefined,
    Object? age = _Undefined,
    Object? cc = _Undefined,
    Object? oe = _Undefined,
    Object? advice = _Undefined,
    Object? test = _Undefined,
    List<_i2.PatientPrescribedItem>? items,
  }) {
    return PatientPrescriptionDetails(
      prescriptionId: prescriptionId ?? this.prescriptionId,
      name: name ?? this.name,
      mobileNumber: mobileNumber is String? ? mobileNumber : this.mobileNumber,
      gender: gender is String? ? gender : this.gender,
      age: age is int? ? age : this.age,
      cc: cc is String? ? cc : this.cc,
      oe: oe is String? ? oe : this.oe,
      advice: advice is String? ? advice : this.advice,
      test: test is String? ? test : this.test,
      items: items ?? this.items.map((e0) => e0.copyWith()).toList(),
    );
  }
}
