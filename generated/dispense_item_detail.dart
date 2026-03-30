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

abstract class DispenseItemDetail
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  DispenseItemDetail._({
    required this.medicineName,
    required this.qtyNeeded,
    required this.stock,
    this.itemId,
    this.alternativeId,
    this.alternativeName,
  });

  factory DispenseItemDetail({
    required String medicineName,
    required int qtyNeeded,
    required int stock,
    int? itemId,
    int? alternativeId,
    String? alternativeName,
  }) = _DispenseItemDetailImpl;

  factory DispenseItemDetail.fromJson(Map<String, dynamic> jsonSerialization) {
    return DispenseItemDetail(
      medicineName: jsonSerialization['medicineName'] as String,
      qtyNeeded: jsonSerialization['qtyNeeded'] as int,
      stock: jsonSerialization['stock'] as int,
      itemId: jsonSerialization['itemId'] as int?,
      alternativeId: jsonSerialization['alternativeId'] as int?,
      alternativeName: jsonSerialization['alternativeName'] as String?,
    );
  }

  String medicineName;

  int qtyNeeded;

  int stock;

  int? itemId;

  int? alternativeId;

  String? alternativeName;

  /// Returns a shallow copy of this [DispenseItemDetail]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  DispenseItemDetail copyWith({
    String? medicineName,
    int? qtyNeeded,
    int? stock,
    int? itemId,
    int? alternativeId,
    String? alternativeName,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DispenseItemDetail',
      'medicineName': medicineName,
      'qtyNeeded': qtyNeeded,
      'stock': stock,
      if (itemId != null) 'itemId': itemId,
      if (alternativeId != null) 'alternativeId': alternativeId,
      if (alternativeName != null) 'alternativeName': alternativeName,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DispenseItemDetail',
      'medicineName': medicineName,
      'qtyNeeded': qtyNeeded,
      'stock': stock,
      if (itemId != null) 'itemId': itemId,
      if (alternativeId != null) 'alternativeId': alternativeId,
      if (alternativeName != null) 'alternativeName': alternativeName,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DispenseItemDetailImpl extends DispenseItemDetail {
  _DispenseItemDetailImpl({
    required String medicineName,
    required int qtyNeeded,
    required int stock,
    int? itemId,
    int? alternativeId,
    String? alternativeName,
  }) : super._(
         medicineName: medicineName,
         qtyNeeded: qtyNeeded,
         stock: stock,
         itemId: itemId,
         alternativeId: alternativeId,
         alternativeName: alternativeName,
       );

  /// Returns a shallow copy of this [DispenseItemDetail]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  DispenseItemDetail copyWith({
    String? medicineName,
    int? qtyNeeded,
    int? stock,
    Object? itemId = _Undefined,
    Object? alternativeId = _Undefined,
    Object? alternativeName = _Undefined,
  }) {
    return DispenseItemDetail(
      medicineName: medicineName ?? this.medicineName,
      qtyNeeded: qtyNeeded ?? this.qtyNeeded,
      stock: stock ?? this.stock,
      itemId: itemId is int? ? itemId : this.itemId,
      alternativeId: alternativeId is int? ? alternativeId : this.alternativeId,
      alternativeName: alternativeName is String?
          ? alternativeName
          : this.alternativeName,
    );
  }
}
