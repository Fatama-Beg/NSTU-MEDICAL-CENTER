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

abstract class DispensedItemSummary
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  DispensedItemSummary._({
    required this.medicineName,
    required this.quantity,
    required this.isAlternative,
  });

  factory DispensedItemSummary({
    required String medicineName,
    required int quantity,
    required bool isAlternative,
  }) = _DispensedItemSummaryImpl;

  factory DispensedItemSummary.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return DispensedItemSummary(
      medicineName: jsonSerialization['medicineName'] as String,
      quantity: jsonSerialization['quantity'] as int,
      isAlternative: jsonSerialization['isAlternative'] as bool,
    );
  }

  String medicineName;

  int quantity;

  bool isAlternative;

  /// Returns a shallow copy of this [DispensedItemSummary]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  DispensedItemSummary copyWith({
    String? medicineName,
    int? quantity,
    bool? isAlternative,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DispensedItemSummary',
      'medicineName': medicineName,
      'quantity': quantity,
      'isAlternative': isAlternative,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DispensedItemSummary',
      'medicineName': medicineName,
      'quantity': quantity,
      'isAlternative': isAlternative,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _DispensedItemSummaryImpl extends DispensedItemSummary {
  _DispensedItemSummaryImpl({
    required String medicineName,
    required int quantity,
    required bool isAlternative,
  }) : super._(
         medicineName: medicineName,
         quantity: quantity,
         isAlternative: isAlternative,
       );

  /// Returns a shallow copy of this [DispensedItemSummary]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  DispensedItemSummary copyWith({
    String? medicineName,
    int? quantity,
    bool? isAlternative,
  }) {
    return DispensedItemSummary(
      medicineName: medicineName ?? this.medicineName,
      quantity: quantity ?? this.quantity,
      isAlternative: isAlternative ?? this.isAlternative,
    );
  }
}
