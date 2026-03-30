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

abstract class Rosterlists
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  Rosterlists._({
    required this.userId,
    required this.name,
    required this.role,
  });

  factory Rosterlists({
    required String userId,
    required String name,
    required String role,
  }) = _RosterlistsImpl;

  factory Rosterlists.fromJson(Map<String, dynamic> jsonSerialization) {
    return Rosterlists(
      userId: jsonSerialization['userId'] as String,
      name: jsonSerialization['name'] as String,
      role: jsonSerialization['role'] as String,
    );
  }

  String userId;

  String name;

  String role;

  /// Returns a shallow copy of this [Rosterlists]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Rosterlists copyWith({
    String? userId,
    String? name,
    String? role,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Rosterlists',
      'userId': userId,
      'name': name,
      'role': role,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Rosterlists',
      'userId': userId,
      'name': name,
      'role': role,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _RosterlistsImpl extends Rosterlists {
  _RosterlistsImpl({
    required String userId,
    required String name,
    required String role,
  }) : super._(
         userId: userId,
         name: name,
         role: role,
       );

  /// Returns a shallow copy of this [Rosterlists]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Rosterlists copyWith({
    String? userId,
    String? name,
    String? role,
  }) {
    return Rosterlists(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      role: role ?? this.role,
    );
  }
}
