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

abstract class DispenserProfileR
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  DispenserProfileR._({
    required this.name,
    required this.email,
    required this.phone,
    required this.designation,
    required this.qualification,
    this.profilePictureUrl,
  });

  factory DispenserProfileR({
    required String name,
    required String email,
    required String phone,
    required String designation,
    required String qualification,
    String? profilePictureUrl,
  }) = _DispenserProfileRImpl;

  factory DispenserProfileR.fromJson(Map<String, dynamic> jsonSerialization) {
    return DispenserProfileR(
      name: jsonSerialization['name'] as String,
      email: jsonSerialization['email'] as String,
      phone: jsonSerialization['phone'] as String,
      designation: jsonSerialization['designation'] as String,
      qualification: jsonSerialization['qualification'] as String,
      profilePictureUrl: jsonSerialization['profilePictureUrl'] as String?,
    );
  }

  String name;

  String email;

  String phone;

  String designation;

  String qualification;

  String? profilePictureUrl;

  /// Returns a shallow copy of this [DispenserProfileR]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  DispenserProfileR copyWith({
    String? name,
    String? email,
    String? phone,
    String? designation,
    String? qualification,
    String? profilePictureUrl,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DispenserProfileR',
      'name': name,
      'email': email,
      'phone': phone,
      'designation': designation,
      'qualification': qualification,
      if (profilePictureUrl != null) 'profilePictureUrl': profilePictureUrl,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DispenserProfileR',
      'name': name,
      'email': email,
      'phone': phone,
      'designation': designation,
      'qualification': qualification,
      if (profilePictureUrl != null) 'profilePictureUrl': profilePictureUrl,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DispenserProfileRImpl extends DispenserProfileR {
  _DispenserProfileRImpl({
    required String name,
    required String email,
    required String phone,
    required String designation,
    required String qualification,
    String? profilePictureUrl,
  }) : super._(
         name: name,
         email: email,
         phone: phone,
         designation: designation,
         qualification: qualification,
         profilePictureUrl: profilePictureUrl,
       );

  /// Returns a shallow copy of this [DispenserProfileR]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  DispenserProfileR copyWith({
    String? name,
    String? email,
    String? phone,
    String? designation,
    String? qualification,
    Object? profilePictureUrl = _Undefined,
  }) {
    return DispenserProfileR(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      designation: designation ?? this.designation,
      qualification: qualification ?? this.qualification,
      profilePictureUrl: profilePictureUrl is String?
          ? profilePictureUrl
          : this.profilePictureUrl,
    );
  }
}
