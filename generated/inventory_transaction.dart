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

abstract class InventoryTransactionInfo
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  InventoryTransactionInfo._({
    required this.itemId,
    required this.transactionType,
    required this.quantity,
    required this.createdAt,
  });

  factory InventoryTransactionInfo({
    required int itemId,
    required String transactionType,
    required int quantity,
    required DateTime createdAt,
  }) = _InventoryTransactionInfoImpl;

  factory InventoryTransactionInfo.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return InventoryTransactionInfo(
      itemId: jsonSerialization['itemId'] as int,
      transactionType: jsonSerialization['transactionType'] as String,
      quantity: jsonSerialization['quantity'] as int,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  int itemId;

  String transactionType;

  int quantity;

  DateTime createdAt;

  /// Returns a shallow copy of this [InventoryTransactionInfo]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  InventoryTransactionInfo copyWith({
    int? itemId,
    String? transactionType,
    int? quantity,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'InventoryTransactionInfo',
      'itemId': itemId,
      'transactionType': transactionType,
      'quantity': quantity,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'InventoryTransactionInfo',
      'itemId': itemId,
      'transactionType': transactionType,
      'quantity': quantity,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _InventoryTransactionInfoImpl extends InventoryTransactionInfo {
  _InventoryTransactionInfoImpl({
    required int itemId,
    required String transactionType,
    required int quantity,
    required DateTime createdAt,
  }) : super._(
         itemId: itemId,
         transactionType: transactionType,
         quantity: quantity,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [InventoryTransactionInfo]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  InventoryTransactionInfo copyWith({
    int? itemId,
    String? transactionType,
    int? quantity,
    DateTime? createdAt,
  }) {
    return InventoryTransactionInfo(
      itemId: itemId ?? this.itemId,
      transactionType: transactionType ?? this.transactionType,
      quantity: quantity ?? this.quantity,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
