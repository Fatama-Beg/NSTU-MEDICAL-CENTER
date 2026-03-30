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

abstract class AmbulanceContact
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  AmbulanceContact._({
    required this.contactId,
    required this.contactTitle,
    required this.phoneBn,
    required this.phoneEn,
    required this.isPrimary,
  });

  factory AmbulanceContact({
    required int contactId,
    required String contactTitle,
    required String phoneBn,
    required String phoneEn,
    required bool isPrimary,
  }) = _AmbulanceContactImpl;

  factory AmbulanceContact.fromJson(Map<String, dynamic> jsonSerialization) {
    return AmbulanceContact(
      contactId: jsonSerialization['contactId'] as int,
      contactTitle: jsonSerialization['contactTitle'] as String,
      phoneBn: jsonSerialization['phoneBn'] as String,
      phoneEn: jsonSerialization['phoneEn'] as String,
      isPrimary: jsonSerialization['isPrimary'] as bool,
    );
  }

  int contactId;

  String contactTitle;

  String phoneBn;

  String phoneEn;

  bool isPrimary;

  /// Returns a shallow copy of this [AmbulanceContact]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AmbulanceContact copyWith({
    int? contactId,
    String? contactTitle,
    String? phoneBn,
    String? phoneEn,
    bool? isPrimary,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AmbulanceContact',
      'contactId': contactId,
      'contactTitle': contactTitle,
      'phoneBn': phoneBn,
      'phoneEn': phoneEn,
      'isPrimary': isPrimary,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'AmbulanceContact',
      'contactId': contactId,
      'contactTitle': contactTitle,
      'phoneBn': phoneBn,
      'phoneEn': phoneEn,
      'isPrimary': isPrimary,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _AmbulanceContactImpl extends AmbulanceContact {
  _AmbulanceContactImpl({
    required int contactId,
    required String contactTitle,
    required String phoneBn,
    required String phoneEn,
    required bool isPrimary,
  }) : super._(
         contactId: contactId,
         contactTitle: contactTitle,
         phoneBn: phoneBn,
         phoneEn: phoneEn,
         isPrimary: isPrimary,
       );

  /// Returns a shallow copy of this [AmbulanceContact]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AmbulanceContact copyWith({
    int? contactId,
    String? contactTitle,
    String? phoneBn,
    String? phoneEn,
    bool? isPrimary,
  }) {
    return AmbulanceContact(
      contactId: contactId ?? this.contactId,
      contactTitle: contactTitle ?? this.contactTitle,
      phoneBn: phoneBn ?? this.phoneBn,
      phoneEn: phoneEn ?? this.phoneEn,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }
}
