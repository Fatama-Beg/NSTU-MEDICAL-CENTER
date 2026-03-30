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

abstract class DispenseItemRequest
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  DispenseItemRequest._({
    required this.itemId,
    required this.medicineName,
    required this.quantity,
    required this.isAlternative,
    this.originalMedicineId,
  });

  factory DispenseItemRequest({
    required int itemId,
    required String medicineName,
    required int quantity,
    required bool isAlternative,
    int? originalMedicineId,
  }) = _DispenseItemRequestImpl;

  factory DispenseItemRequest.fromJson(Map<String, dynamic> jsonSerialization) {
    return DispenseItemRequest(
      itemId: jsonSerialization['itemId'] as int,
      medicineName: jsonSerialization['medicineName'] as String,
      quantity: jsonSerialization['quantity'] as int,
      isAlternative: jsonSerialization['isAlternative'] as bool,
      originalMedicineId: jsonSerialization['originalMedicineId'] as int?,
    );
  }

  int itemId;

  String medicineName;

  int quantity;

  bool isAlternative;

  int? originalMedicineId;

  /// Returns a shallow copy of this [DispenseItemRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  DispenseItemRequest copyWith({
    int? itemId,
    String? medicineName,
    int? quantity,
    bool? isAlternative,
    int? originalMedicineId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DispenseItemRequest',
      'itemId': itemId,
      'medicineName': medicineName,
      'quantity': quantity,
      'isAlternative': isAlternative,
      if (originalMedicineId != null) 'originalMedicineId': originalMedicineId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DispenseItemRequest',
      'itemId': itemId,
      'medicineName': medicineName,
      'quantity': quantity,
      'isAlternative': isAlternative,
      if (originalMedicineId != null) 'originalMedicineId': originalMedicineId,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DispenseItemRequestImpl extends DispenseItemRequest {
  _DispenseItemRequestImpl({
    required int itemId,
    required String medicineName,
    required int quantity,
    required bool isAlternative,
    int? originalMedicineId,
  }) : super._(
         itemId: itemId,
         medicineName: medicineName,
         quantity: quantity,
         isAlternative: isAlternative,
         originalMedicineId: originalMedicineId,
       );

  /// Returns a shallow copy of this [DispenseItemRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  DispenseItemRequest copyWith({
    int? itemId,
    String? medicineName,
    int? quantity,
    bool? isAlternative,
    Object? originalMedicineId = _Undefined,
  }) {
    return DispenseItemRequest(
      itemId: itemId ?? this.itemId,
      medicineName: medicineName ?? this.medicineName,
      quantity: quantity ?? this.quantity,
      isAlternative: isAlternative ?? this.isAlternative,
      originalMedicineId: originalMedicineId is int?
          ? originalMedicineId
          : this.originalMedicineId,
    );
  }
}
