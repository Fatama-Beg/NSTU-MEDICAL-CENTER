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

abstract class PatientPrescribedItem
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  PatientPrescribedItem._({
    required this.medicineName,
    this.dosageTimes,
    this.mealTiming,
    this.duration,
  });

  factory PatientPrescribedItem({
    required String medicineName,
    String? dosageTimes,
    String? mealTiming,
    int? duration,
  }) = _PatientPrescribedItemImpl;

  factory PatientPrescribedItem.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return PatientPrescribedItem(
      medicineName: jsonSerialization['medicineName'] as String,
      dosageTimes: jsonSerialization['dosageTimes'] as String?,
      mealTiming: jsonSerialization['mealTiming'] as String?,
      duration: jsonSerialization['duration'] as int?,
    );
  }

  String medicineName;

  String? dosageTimes;

  String? mealTiming;

  int? duration;

  /// Returns a shallow copy of this [PatientPrescribedItem]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PatientPrescribedItem copyWith({
    String? medicineName,
    String? dosageTimes,
    String? mealTiming,
    int? duration,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PatientPrescribedItem',
      'medicineName': medicineName,
      if (dosageTimes != null) 'dosageTimes': dosageTimes,
      if (mealTiming != null) 'mealTiming': mealTiming,
      if (duration != null) 'duration': duration,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PatientPrescribedItem',
      'medicineName': medicineName,
      if (dosageTimes != null) 'dosageTimes': dosageTimes,
      if (mealTiming != null) 'mealTiming': mealTiming,
      if (duration != null) 'duration': duration,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PatientPrescribedItemImpl extends PatientPrescribedItem {
  _PatientPrescribedItemImpl({
    required String medicineName,
    String? dosageTimes,
    String? mealTiming,
    int? duration,
  }) : super._(
         medicineName: medicineName,
         dosageTimes: dosageTimes,
         mealTiming: mealTiming,
         duration: duration,
       );

  /// Returns a shallow copy of this [PatientPrescribedItem]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PatientPrescribedItem copyWith({
    String? medicineName,
    Object? dosageTimes = _Undefined,
    Object? mealTiming = _Undefined,
    Object? duration = _Undefined,
  }) {
    return PatientPrescribedItem(
      medicineName: medicineName ?? this.medicineName,
      dosageTimes: dosageTimes is String? ? dosageTimes : this.dosageTimes,
      mealTiming: mealTiming is String? ? mealTiming : this.mealTiming,
      duration: duration is int? ? duration : this.duration,
    );
  }
}
