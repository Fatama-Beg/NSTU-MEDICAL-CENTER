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

abstract class PatientPrescriptionListItem
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  PatientPrescriptionListItem._({
    required this.prescriptionId,
    required this.name,
    this.mobileNumber,
    this.gender,
    this.age,
    this.prescriptionDate,
  });

  factory PatientPrescriptionListItem({
    required int prescriptionId,
    required String name,
    String? mobileNumber,
    String? gender,
    int? age,
    DateTime? prescriptionDate,
  }) = _PatientPrescriptionListItemImpl;

  factory PatientPrescriptionListItem.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return PatientPrescriptionListItem(
      prescriptionId: jsonSerialization['prescriptionId'] as int,
      name: jsonSerialization['name'] as String,
      mobileNumber: jsonSerialization['mobileNumber'] as String?,
      gender: jsonSerialization['gender'] as String?,
      age: jsonSerialization['age'] as int?,
      prescriptionDate: jsonSerialization['prescriptionDate'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['prescriptionDate'],
            ),
    );
  }

  int prescriptionId;

  String name;

  String? mobileNumber;

  String? gender;

  int? age;

  DateTime? prescriptionDate;

  /// Returns a shallow copy of this [PatientPrescriptionListItem]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PatientPrescriptionListItem copyWith({
    int? prescriptionId,
    String? name,
    String? mobileNumber,
    String? gender,
    int? age,
    DateTime? prescriptionDate,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PatientPrescriptionListItem',
      'prescriptionId': prescriptionId,
      'name': name,
      if (mobileNumber != null) 'mobileNumber': mobileNumber,
      if (gender != null) 'gender': gender,
      if (age != null) 'age': age,
      if (prescriptionDate != null)
        'prescriptionDate': prescriptionDate?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PatientPrescriptionListItem',
      'prescriptionId': prescriptionId,
      'name': name,
      if (mobileNumber != null) 'mobileNumber': mobileNumber,
      if (gender != null) 'gender': gender,
      if (age != null) 'age': age,
      if (prescriptionDate != null)
        'prescriptionDate': prescriptionDate?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PatientPrescriptionListItemImpl extends PatientPrescriptionListItem {
  _PatientPrescriptionListItemImpl({
    required int prescriptionId,
    required String name,
    String? mobileNumber,
    String? gender,
    int? age,
    DateTime? prescriptionDate,
  }) : super._(
         prescriptionId: prescriptionId,
         name: name,
         mobileNumber: mobileNumber,
         gender: gender,
         age: age,
         prescriptionDate: prescriptionDate,
       );

  /// Returns a shallow copy of this [PatientPrescriptionListItem]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PatientPrescriptionListItem copyWith({
    int? prescriptionId,
    String? name,
    Object? mobileNumber = _Undefined,
    Object? gender = _Undefined,
    Object? age = _Undefined,
    Object? prescriptionDate = _Undefined,
  }) {
    return PatientPrescriptionListItem(
      prescriptionId: prescriptionId ?? this.prescriptionId,
      name: name ?? this.name,
      mobileNumber: mobileNumber is String? ? mobileNumber : this.mobileNumber,
      gender: gender is String? ? gender : this.gender,
      age: age is int? ? age : this.age,
      prescriptionDate: prescriptionDate is DateTime?
          ? prescriptionDate
          : this.prescriptionDate,
    );
  }
}
