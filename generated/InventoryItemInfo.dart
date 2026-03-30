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

abstract class InventoryItemInfo
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  InventoryItemInfo._({
    required this.itemId,
    required this.itemName,
    required this.unit,
    required this.minimumStock,
    required this.categoryName,
    required this.currentQuantity,
    required this.canRestockDispenser,
  });

  factory InventoryItemInfo({
    required int itemId,
    required String itemName,
    required String unit,
    required int minimumStock,
    required String categoryName,
    required int currentQuantity,
    required bool canRestockDispenser,
  }) = _InventoryItemInfoImpl;

  factory InventoryItemInfo.fromJson(Map<String, dynamic> jsonSerialization) {
    return InventoryItemInfo(
      itemId: jsonSerialization['itemId'] as int,
      itemName: jsonSerialization['itemName'] as String,
      unit: jsonSerialization['unit'] as String,
      minimumStock: jsonSerialization['minimumStock'] as int,
      categoryName: jsonSerialization['categoryName'] as String,
      currentQuantity: jsonSerialization['currentQuantity'] as int,
      canRestockDispenser: jsonSerialization['canRestockDispenser'] as bool,
    );
  }

  int itemId;

  String itemName;

  String unit;

  int minimumStock;

  String categoryName;

  int currentQuantity;

  bool canRestockDispenser;

  /// Returns a shallow copy of this [InventoryItemInfo]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  InventoryItemInfo copyWith({
    int? itemId,
    String? itemName,
    String? unit,
    int? minimumStock,
    String? categoryName,
    int? currentQuantity,
    bool? canRestockDispenser,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'InventoryItemInfo',
      'itemId': itemId,
      'itemName': itemName,
      'unit': unit,
      'minimumStock': minimumStock,
      'categoryName': categoryName,
      'currentQuantity': currentQuantity,
      'canRestockDispenser': canRestockDispenser,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'InventoryItemInfo',
      'itemId': itemId,
      'itemName': itemName,
      'unit': unit,
      'minimumStock': minimumStock,
      'categoryName': categoryName,
      'currentQuantity': currentQuantity,
      'canRestockDispenser': canRestockDispenser,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _InventoryItemInfoImpl extends InventoryItemInfo {
  _InventoryItemInfoImpl({
    required int itemId,
    required String itemName,
    required String unit,
    required int minimumStock,
    required String categoryName,
    required int currentQuantity,
    required bool canRestockDispenser,
  }) : super._(
         itemId: itemId,
         itemName: itemName,
         unit: unit,
         minimumStock: minimumStock,
         categoryName: categoryName,
         currentQuantity: currentQuantity,
         canRestockDispenser: canRestockDispenser,
       );

  /// Returns a shallow copy of this [InventoryItemInfo]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  InventoryItemInfo copyWith({
    int? itemId,
    String? itemName,
    String? unit,
    int? minimumStock,
    String? categoryName,
    int? currentQuantity,
    bool? canRestockDispenser,
  }) {
    return InventoryItemInfo(
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      unit: unit ?? this.unit,
      minimumStock: minimumStock ?? this.minimumStock,
      categoryName: categoryName ?? this.categoryName,
      currentQuantity: currentQuantity ?? this.currentQuantity,
      canRestockDispenser: canRestockDispenser ?? this.canRestockDispenser,
    );
  }
}
