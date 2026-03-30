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

abstract class MedicineStockRangeRow
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  MedicineStockRangeRow._({
    required this.medicineName,
    required this.fromQuantity,
    required this.used,
    required this.toQuantity,
  });

  factory MedicineStockRangeRow({
    required String medicineName,
    required int fromQuantity,
    required int used,
    required int toQuantity,
  }) = _MedicineStockRangeRowImpl;

  factory MedicineStockRangeRow.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return MedicineStockRangeRow(
      medicineName: jsonSerialization['medicineName'] as String,
      fromQuantity: jsonSerialization['fromQuantity'] as int,
      used: jsonSerialization['used'] as int,
      toQuantity: jsonSerialization['toQuantity'] as int,
    );
  }

  String medicineName;

  int fromQuantity;

  int used;

  int toQuantity;

  /// Returns a shallow copy of this [MedicineStockRangeRow]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  MedicineStockRangeRow copyWith({
    String? medicineName,
    int? fromQuantity,
    int? used,
    int? toQuantity,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MedicineStockRangeRow',
      'medicineName': medicineName,
      'fromQuantity': fromQuantity,
      'used': used,
      'toQuantity': toQuantity,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'MedicineStockRangeRow',
      'medicineName': medicineName,
      'fromQuantity': fromQuantity,
      'used': used,
      'toQuantity': toQuantity,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _MedicineStockRangeRowImpl extends MedicineStockRangeRow {
  _MedicineStockRangeRowImpl({
    required String medicineName,
    required int fromQuantity,
    required int used,
    required int toQuantity,
  }) : super._(
         medicineName: medicineName,
         fromQuantity: fromQuantity,
         used: used,
         toQuantity: toQuantity,
       );

  /// Returns a shallow copy of this [MedicineStockRangeRow]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  MedicineStockRangeRow copyWith({
    String? medicineName,
    int? fromQuantity,
    int? used,
    int? toQuantity,
  }) {
    return MedicineStockRangeRow(
      medicineName: medicineName ?? this.medicineName,
      fromQuantity: fromQuantity ?? this.fromQuantity,
      used: used ?? this.used,
      toQuantity: toQuantity ?? this.toQuantity,
    );
  }
}
