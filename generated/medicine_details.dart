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

abstract class MedicineDetail
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  MedicineDetail._({
    required this.prescribedItemId,
    this.itemId,
    required this.medicineName,
    required this.dosageTimes,
    required this.duration,
    required this.stock,
  });

  factory MedicineDetail({
    required int prescribedItemId,
    int? itemId,
    required String medicineName,
    required String dosageTimes,
    required int duration,
    required int stock,
  }) = _MedicineDetailImpl;

  factory MedicineDetail.fromJson(Map<String, dynamic> jsonSerialization) {
    return MedicineDetail(
      prescribedItemId: jsonSerialization['prescribedItemId'] as int,
      itemId: jsonSerialization['itemId'] as int?,
      medicineName: jsonSerialization['medicineName'] as String,
      dosageTimes: jsonSerialization['dosageTimes'] as String,
      duration: jsonSerialization['duration'] as int,
      stock: jsonSerialization['stock'] as int,
    );
  }

  int prescribedItemId;

  int? itemId;

  String medicineName;

  String dosageTimes;

  int duration;

  int stock;

  /// Returns a shallow copy of this [MedicineDetail]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  MedicineDetail copyWith({
    int? prescribedItemId,
    int? itemId,
    String? medicineName,
    String? dosageTimes,
    int? duration,
    int? stock,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MedicineDetail',
      'prescribedItemId': prescribedItemId,
      if (itemId != null) 'itemId': itemId,
      'medicineName': medicineName,
      'dosageTimes': dosageTimes,
      'duration': duration,
      'stock': stock,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'MedicineDetail',
      'prescribedItemId': prescribedItemId,
      if (itemId != null) 'itemId': itemId,
      'medicineName': medicineName,
      'dosageTimes': dosageTimes,
      'duration': duration,
      'stock': stock,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MedicineDetailImpl extends MedicineDetail {
  _MedicineDetailImpl({
    required int prescribedItemId,
    int? itemId,
    required String medicineName,
    required String dosageTimes,
    required int duration,
    required int stock,
  }) : super._(
         prescribedItemId: prescribedItemId,
         itemId: itemId,
         medicineName: medicineName,
         dosageTimes: dosageTimes,
         duration: duration,
         stock: stock,
       );

  /// Returns a shallow copy of this [MedicineDetail]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  MedicineDetail copyWith({
    int? prescribedItemId,
    Object? itemId = _Undefined,
    String? medicineName,
    String? dosageTimes,
    int? duration,
    int? stock,
  }) {
    return MedicineDetail(
      prescribedItemId: prescribedItemId ?? this.prescribedItemId,
      itemId: itemId is int? ? itemId : this.itemId,
      medicineName: medicineName ?? this.medicineName,
      dosageTimes: dosageTimes ?? this.dosageTimes,
      duration: duration ?? this.duration,
      stock: stock ?? this.stock,
    );
  }
}
