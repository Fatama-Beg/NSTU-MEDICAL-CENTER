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

abstract class AdminProfileRespond
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  AdminProfileRespond._({
    required this.name,
    required this.email,
    required this.phone,
    this.profilePictureUrl,
    this.designation,
    this.qualification,
  });

  factory AdminProfileRespond({
    required String name,
    required String email,
    required String phone,
    String? profilePictureUrl,
    String? designation,
    String? qualification,
  }) = _AdminProfileRespondImpl;

  factory AdminProfileRespond.fromJson(Map<String, dynamic> jsonSerialization) {
    return AdminProfileRespond(
      name: jsonSerialization['name'] as String,
      email: jsonSerialization['email'] as String,
      phone: jsonSerialization['phone'] as String,
      profilePictureUrl: jsonSerialization['profilePictureUrl'] as String?,
      designation: jsonSerialization['designation'] as String?,
      qualification: jsonSerialization['qualification'] as String?,
    );
  }

  String name;

  String email;

  String phone;

  String? profilePictureUrl;

  String? designation;

  String? qualification;

  /// Returns a shallow copy of this [AdminProfileRespond]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AdminProfileRespond copyWith({
    String? name,
    String? email,
    String? phone,
    String? profilePictureUrl,
    String? designation,
    String? qualification,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AdminProfileRespond',
      'name': name,
      'email': email,
      'phone': phone,
      if (profilePictureUrl != null) 'profilePictureUrl': profilePictureUrl,
      if (designation != null) 'designation': designation,
      if (qualification != null) 'qualification': qualification,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'AdminProfileRespond',
      'name': name,
      'email': email,
      'phone': phone,
      if (profilePictureUrl != null) 'profilePictureUrl': profilePictureUrl,
      if (designation != null) 'designation': designation,
      if (qualification != null) 'qualification': qualification,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AdminProfileRespondImpl extends AdminProfileRespond {
  _AdminProfileRespondImpl({
    required String name,
    required String email,
    required String phone,
    String? profilePictureUrl,
    String? designation,
    String? qualification,
  }) : super._(
         name: name,
         email: email,
         phone: phone,
         profilePictureUrl: profilePictureUrl,
         designation: designation,
         qualification: qualification,
       );

  /// Returns a shallow copy of this [AdminProfileRespond]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AdminProfileRespond copyWith({
    String? name,
    String? email,
    String? phone,
    Object? profilePictureUrl = _Undefined,
    Object? designation = _Undefined,
    Object? qualification = _Undefined,
  }) {
    return AdminProfileRespond(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profilePictureUrl: profilePictureUrl is String?
          ? profilePictureUrl
          : this.profilePictureUrl,
      designation: designation is String? ? designation : this.designation,
      qualification: qualification is String?
          ? qualification
          : this.qualification,
    );
  }
}
