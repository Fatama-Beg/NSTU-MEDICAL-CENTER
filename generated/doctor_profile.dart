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

abstract class DoctorProfile
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  DoctorProfile._({
    this.userId,
    this.name,
    this.email,
    this.phone,
    this.profilePictureUrl,
    this.designation,
    this.qualification,
    this.signatureUrl,
  });

  factory DoctorProfile({
    int? userId,
    String? name,
    String? email,
    String? phone,
    String? profilePictureUrl,
    String? designation,
    String? qualification,
    String? signatureUrl,
  }) = _DoctorProfileImpl;

  factory DoctorProfile.fromJson(Map<String, dynamic> jsonSerialization) {
    return DoctorProfile(
      userId: jsonSerialization['userId'] as int?,
      name: jsonSerialization['name'] as String?,
      email: jsonSerialization['email'] as String?,
      phone: jsonSerialization['phone'] as String?,
      profilePictureUrl: jsonSerialization['profilePictureUrl'] as String?,
      designation: jsonSerialization['designation'] as String?,
      qualification: jsonSerialization['qualification'] as String?,
      signatureUrl: jsonSerialization['signatureUrl'] as String?,
    );
  }

  int? userId;

  String? name;

  String? email;

  String? phone;

  String? profilePictureUrl;

  String? designation;

  String? qualification;

  String? signatureUrl;

  /// Returns a shallow copy of this [DoctorProfile]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  DoctorProfile copyWith({
    int? userId,
    String? name,
    String? email,
    String? phone,
    String? profilePictureUrl,
    String? designation,
    String? qualification,
    String? signatureUrl,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DoctorProfile',
      if (userId != null) 'userId': userId,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (profilePictureUrl != null) 'profilePictureUrl': profilePictureUrl,
      if (designation != null) 'designation': designation,
      if (qualification != null) 'qualification': qualification,
      if (signatureUrl != null) 'signatureUrl': signatureUrl,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DoctorProfile',
      if (userId != null) 'userId': userId,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (profilePictureUrl != null) 'profilePictureUrl': profilePictureUrl,
      if (designation != null) 'designation': designation,
      if (qualification != null) 'qualification': qualification,
      if (signatureUrl != null) 'signatureUrl': signatureUrl,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DoctorProfileImpl extends DoctorProfile {
  _DoctorProfileImpl({
    int? userId,
    String? name,
    String? email,
    String? phone,
    String? profilePictureUrl,
    String? designation,
    String? qualification,
    String? signatureUrl,
  }) : super._(
         userId: userId,
         name: name,
         email: email,
         phone: phone,
         profilePictureUrl: profilePictureUrl,
         designation: designation,
         qualification: qualification,
         signatureUrl: signatureUrl,
       );

  /// Returns a shallow copy of this [DoctorProfile]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  DoctorProfile copyWith({
    Object? userId = _Undefined,
    Object? name = _Undefined,
    Object? email = _Undefined,
    Object? phone = _Undefined,
    Object? profilePictureUrl = _Undefined,
    Object? designation = _Undefined,
    Object? qualification = _Undefined,
    Object? signatureUrl = _Undefined,
  }) {
    return DoctorProfile(
      userId: userId is int? ? userId : this.userId,
      name: name is String? ? name : this.name,
      email: email is String? ? email : this.email,
      phone: phone is String? ? phone : this.phone,
      profilePictureUrl: profilePictureUrl is String?
          ? profilePictureUrl
          : this.profilePictureUrl,
      designation: designation is String? ? designation : this.designation,
      qualification: qualification is String?
          ? qualification
          : this.qualification,
      signatureUrl: signatureUrl is String? ? signatureUrl : this.signatureUrl,
    );
  }
}
