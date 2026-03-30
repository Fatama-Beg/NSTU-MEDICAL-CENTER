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

abstract class InventoryCategory
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  InventoryCategory._({
    this.categoryId,
    required this.categoryName,
    this.description,
  });

  factory InventoryCategory({
    int? categoryId,
    required String categoryName,
    String? description,
  }) = _InventoryCategoryImpl;

  factory InventoryCategory.fromJson(Map<String, dynamic> jsonSerialization) {
    return InventoryCategory(
      categoryId: jsonSerialization['categoryId'] as int?,
      categoryName: jsonSerialization['categoryName'] as String,
      description: jsonSerialization['description'] as String?,
    );
  }

  int? categoryId;

  String categoryName;

  String? description;

  /// Returns a shallow copy of this [InventoryCategory]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  InventoryCategory copyWith({
    int? categoryId,
    String? categoryName,
    String? description,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'InventoryCategory',
      if (categoryId != null) 'categoryId': categoryId,
      'categoryName': categoryName,
      if (description != null) 'description': description,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'InventoryCategory',
      if (categoryId != null) 'categoryId': categoryId,
      'categoryName': categoryName,
      if (description != null) 'description': description,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _InventoryCategoryImpl extends InventoryCategory {
  _InventoryCategoryImpl({
    int? categoryId,
    required String categoryName,
    String? description,
  }) : super._(
         categoryId: categoryId,
         categoryName: categoryName,
         description: description,
       );

  /// Returns a shallow copy of this [InventoryCategory]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  InventoryCategory copyWith({
    Object? categoryId = _Undefined,
    String? categoryName,
    Object? description = _Undefined,
  }) {
    return InventoryCategory(
      categoryId: categoryId is int? ? categoryId : this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      description: description is String? ? description : this.description,
    );
  }
}
