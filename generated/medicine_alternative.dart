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

abstract class MedicineAlternative
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  MedicineAlternative._({
    required this.primaryMedicineId,
    required this.primaryName,
    required this.alternativeId,
    required this.alternativeName,
    required this.stock,
  });

  factory MedicineAlternative({
    required int primaryMedicineId,
    required String primaryName,
    required int alternativeId,
    required String alternativeName,
    required int stock,
  }) = _MedicineAlternativeImpl;

  factory MedicineAlternative.fromJson(Map<String, dynamic> jsonSerialization) {
    return MedicineAlternative(
      primaryMedicineId: jsonSerialization['primaryMedicineId'] as int,
      primaryName: jsonSerialization['primaryName'] as String,
      alternativeId: jsonSerialization['alternativeId'] as int,
      alternativeName: jsonSerialization['alternativeName'] as String,
      stock: jsonSerialization['stock'] as int,
    );
  }

  int primaryMedicineId;

  String primaryName;

  int alternativeId;

  String alternativeName;

  int stock;

  /// Returns a shallow copy of this [MedicineAlternative]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  MedicineAlternative copyWith({
    int? primaryMedicineId,
    String? primaryName,
    int? alternativeId,
    String? alternativeName,
    int? stock,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MedicineAlternative',
      'primaryMedicineId': primaryMedicineId,
      'primaryName': primaryName,
      'alternativeId': alternativeId,
      'alternativeName': alternativeName,
      'stock': stock,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'MedicineAlternative',
      'primaryMedicineId': primaryMedicineId,
      'primaryName': primaryName,
      'alternativeId': alternativeId,
      'alternativeName': alternativeName,
      'stock': stock,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _MedicineAlternativeImpl extends MedicineAlternative {
  _MedicineAlternativeImpl({
    required int primaryMedicineId,
    required String primaryName,
    required int alternativeId,
    required String alternativeName,
    required int stock,
  }) : super._(
         primaryMedicineId: primaryMedicineId,
         primaryName: primaryName,
         alternativeId: alternativeId,
         alternativeName: alternativeName,
         stock: stock,
       );

  /// Returns a shallow copy of this [MedicineAlternative]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  MedicineAlternative copyWith({
    int? primaryMedicineId,
    String? primaryName,
    int? alternativeId,
    String? alternativeName,
    int? stock,
  }) {
    return MedicineAlternative(
      primaryMedicineId: primaryMedicineId ?? this.primaryMedicineId,
      primaryName: primaryName ?? this.primaryName,
      alternativeId: alternativeId ?? this.alternativeId,
      alternativeName: alternativeName ?? this.alternativeName,
      stock: stock ?? this.stock,
    );
  }
}
