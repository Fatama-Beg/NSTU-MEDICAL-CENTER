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

abstract class TopMedicine
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  TopMedicine._({
    required this.medicineName,
    required this.used,
  });

  factory TopMedicine({
    required String medicineName,
    required int used,
  }) = _TopMedicineImpl;

  factory TopMedicine.fromJson(Map<String, dynamic> jsonSerialization) {
    return TopMedicine(
      medicineName: jsonSerialization['medicineName'] as String,
      used: jsonSerialization['used'] as int,
    );
  }

  String medicineName;

  int used;

  /// Returns a shallow copy of this [TopMedicine]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TopMedicine copyWith({
    String? medicineName,
    int? used,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TopMedicine',
      'medicineName': medicineName,
      'used': used,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'TopMedicine',
      'medicineName': medicineName,
      'used': used,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _TopMedicineImpl extends TopMedicine {
  _TopMedicineImpl({
    required String medicineName,
    required int used,
  }) : super._(
         medicineName: medicineName,
         used: used,
       );

  /// Returns a shallow copy of this [TopMedicine]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TopMedicine copyWith({
    String? medicineName,
    int? used,
  }) {
    return TopMedicine(
      medicineName: medicineName ?? this.medicineName,
      used: used ?? this.used,
    );
  }
}
