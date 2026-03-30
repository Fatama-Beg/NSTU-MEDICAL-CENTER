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

abstract class PatientProfile
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  PatientProfile._({
    required this.name,
    required this.email,
    required this.phone,
    this.bloodGroup,
    this.dateOfBirth,
    this.gender,
    this.profilePictureUrl,
  });

  factory PatientProfile({
    required String name,
    required String email,
    required String phone,
    String? bloodGroup,
    DateTime? dateOfBirth,
    String? gender,
    String? profilePictureUrl,
  }) = _PatientProfileImpl;

  factory PatientProfile.fromJson(Map<String, dynamic> jsonSerialization) {
    return PatientProfile(
      name: jsonSerialization['name'] as String,
      email: jsonSerialization['email'] as String,
      phone: jsonSerialization['phone'] as String,
      bloodGroup: jsonSerialization['bloodGroup'] as String?,
      dateOfBirth: jsonSerialization['dateOfBirth'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['dateOfBirth'],
            ),
      gender: jsonSerialization['gender'] as String?,
      profilePictureUrl: jsonSerialization['profilePictureUrl'] as String?,
    );
  }

  String name;

  String email;

  String phone;

  String? bloodGroup;

  DateTime? dateOfBirth;

  String? gender;

  String? profilePictureUrl;

  /// Returns a shallow copy of this [PatientProfile]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PatientProfile copyWith({
    String? name,
    String? email,
    String? phone,
    String? bloodGroup,
    DateTime? dateOfBirth,
    String? gender,
    String? profilePictureUrl,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PatientProfile',
      'name': name,
      'email': email,
      'phone': phone,
      if (bloodGroup != null) 'bloodGroup': bloodGroup,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth?.toJson(),
      if (gender != null) 'gender': gender,
      if (profilePictureUrl != null) 'profilePictureUrl': profilePictureUrl,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PatientProfile',
      'name': name,
      'email': email,
      'phone': phone,
      if (bloodGroup != null) 'bloodGroup': bloodGroup,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth?.toJson(),
      if (gender != null) 'gender': gender,
      if (profilePictureUrl != null) 'profilePictureUrl': profilePictureUrl,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PatientProfileImpl extends PatientProfile {
  _PatientProfileImpl({
    required String name,
    required String email,
    required String phone,
    String? bloodGroup,
    DateTime? dateOfBirth,
    String? gender,
    String? profilePictureUrl,
  }) : super._(
         name: name,
         email: email,
         phone: phone,
         bloodGroup: bloodGroup,
         dateOfBirth: dateOfBirth,
         gender: gender,
         profilePictureUrl: profilePictureUrl,
       );

  /// Returns a shallow copy of this [PatientProfile]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PatientProfile copyWith({
    String? name,
    String? email,
    String? phone,
    Object? bloodGroup = _Undefined,
    Object? dateOfBirth = _Undefined,
    Object? gender = _Undefined,
    Object? profilePictureUrl = _Undefined,
  }) {
    return PatientProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      bloodGroup: bloodGroup is String? ? bloodGroup : this.bloodGroup,
      dateOfBirth: dateOfBirth is DateTime? ? dateOfBirth : this.dateOfBirth,
      gender: gender is String? ? gender : this.gender,
      profilePictureUrl: profilePictureUrl is String?
          ? profilePictureUrl
          : this.profilePictureUrl,
    );
  }
}
