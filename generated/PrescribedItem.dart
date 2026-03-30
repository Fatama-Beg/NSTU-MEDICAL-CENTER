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

abstract class PrescribedItem
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  PrescribedItem._({
    this.id,
    required this.prescriptionId,
    this.itemId,
    required this.medicineName,
    this.dosageTimes,
    this.mealTiming,
    this.duration,
    this.stock,
  });

  factory PrescribedItem({
    int? id,
    required int prescriptionId,
    int? itemId,
    required String medicineName,
    String? dosageTimes,
    String? mealTiming,
    int? duration,
    int? stock,
  }) = _PrescribedItemImpl;

  factory PrescribedItem.fromJson(Map<String, dynamic> jsonSerialization) {
    return PrescribedItem(
      id: jsonSerialization['id'] as int?,
      prescriptionId: jsonSerialization['prescriptionId'] as int,
      itemId: jsonSerialization['itemId'] as int?,
      medicineName: jsonSerialization['medicineName'] as String,
      dosageTimes: jsonSerialization['dosageTimes'] as String?,
      mealTiming: jsonSerialization['mealTiming'] as String?,
      duration: jsonSerialization['duration'] as int?,
      stock: jsonSerialization['stock'] as int?,
    );
  }

  int? id;

  int prescriptionId;

  int? itemId;

  String medicineName;

  String? dosageTimes;

  String? mealTiming;

  int? duration;

  int? stock;

  /// Returns a shallow copy of this [PrescribedItem]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PrescribedItem copyWith({
    int? id,
    int? prescriptionId,
    int? itemId,
    String? medicineName,
    String? dosageTimes,
    String? mealTiming,
    int? duration,
    int? stock,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PrescribedItem',
      if (id != null) 'id': id,
      'prescriptionId': prescriptionId,
      if (itemId != null) 'itemId': itemId,
      'medicineName': medicineName,
      if (dosageTimes != null) 'dosageTimes': dosageTimes,
      if (mealTiming != null) 'mealTiming': mealTiming,
      if (duration != null) 'duration': duration,
      if (stock != null) 'stock': stock,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PrescribedItem',
      if (id != null) 'id': id,
      'prescriptionId': prescriptionId,
      if (itemId != null) 'itemId': itemId,
      'medicineName': medicineName,
      if (dosageTimes != null) 'dosageTimes': dosageTimes,
      if (mealTiming != null) 'mealTiming': mealTiming,
      if (duration != null) 'duration': duration,
      if (stock != null) 'stock': stock,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PrescribedItemImpl extends PrescribedItem {
  _PrescribedItemImpl({
    int? id,
    required int prescriptionId,
    int? itemId,
    required String medicineName,
    String? dosageTimes,
    String? mealTiming,
    int? duration,
    int? stock,
  }) : super._(
         id: id,
         prescriptionId: prescriptionId,
         itemId: itemId,
         medicineName: medicineName,
         dosageTimes: dosageTimes,
         mealTiming: mealTiming,
         duration: duration,
         stock: stock,
       );

  /// Returns a shallow copy of this [PrescribedItem]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PrescribedItem copyWith({
    Object? id = _Undefined,
    int? prescriptionId,
    Object? itemId = _Undefined,
    String? medicineName,
    Object? dosageTimes = _Undefined,
    Object? mealTiming = _Undefined,
    Object? duration = _Undefined,
    Object? stock = _Undefined,
  }) {
    return PrescribedItem(
      id: id is int? ? id : this.id,
      prescriptionId: prescriptionId ?? this.prescriptionId,
      itemId: itemId is int? ? itemId : this.itemId,
      medicineName: medicineName ?? this.medicineName,
      dosageTimes: dosageTimes is String? ? dosageTimes : this.dosageTimes,
      mealTiming: mealTiming is String? ? mealTiming : this.mealTiming,
      duration: duration is int? ? duration : this.duration,
      stock: stock is int? ? stock : this.stock,
    );
  }
}
