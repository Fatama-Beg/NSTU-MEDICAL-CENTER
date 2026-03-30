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

abstract class DispensedItemInput
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  DispensedItemInput._({
    required this.itemId,
    required this.medicineName,
    required this.quantity,
  });

  factory DispensedItemInput({
    required int itemId,
    required String medicineName,
    required int quantity,
  }) = _DispensedItemInputImpl;

  factory DispensedItemInput.fromJson(Map<String, dynamic> jsonSerialization) {
    return DispensedItemInput(
      itemId: jsonSerialization['itemId'] as int,
      medicineName: jsonSerialization['medicineName'] as String,
      quantity: jsonSerialization['quantity'] as int,
    );
  }

  int itemId;

  String medicineName;

  int quantity;

  /// Returns a shallow copy of this [DispensedItemInput]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  DispensedItemInput copyWith({
    int? itemId,
    String? medicineName,
    int? quantity,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DispensedItemInput',
      'itemId': itemId,
      'medicineName': medicineName,
      'quantity': quantity,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DispensedItemInput',
      'itemId': itemId,
      'medicineName': medicineName,
      'quantity': quantity,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _DispensedItemInputImpl extends DispensedItemInput {
  _DispensedItemInputImpl({
    required int itemId,
    required String medicineName,
    required int quantity,
  }) : super._(
         itemId: itemId,
         medicineName: medicineName,
         quantity: quantity,
       );

  /// Returns a shallow copy of this [DispensedItemInput]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  DispensedItemInput copyWith({
    int? itemId,
    String? medicineName,
    int? quantity,
  }) {
    return DispensedItemInput(
      itemId: itemId ?? this.itemId,
      medicineName: medicineName ?? this.medicineName,
      quantity: quantity ?? this.quantity,
    );
  }
}
