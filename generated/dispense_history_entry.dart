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
import 'dispensed_item_summary.dart' as _i2;
import 'package:backend_server/src/generated/protocol.dart' as _i3;

abstract class DispenseHistoryEntry
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  DispenseHistoryEntry._({
    required this.dispenseId,
    required this.prescriptionId,
    this.patientId,
    required this.patientName,
    required this.mobileNumber,
    required this.dispensedAt,
    required this.items,
  });

  factory DispenseHistoryEntry({
    required int dispenseId,
    required int prescriptionId,
    int? patientId,
    required String patientName,
    required String mobileNumber,
    required DateTime dispensedAt,
    required List<_i2.DispensedItemSummary> items,
  }) = _DispenseHistoryEntryImpl;

  factory DispenseHistoryEntry.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return DispenseHistoryEntry(
      dispenseId: jsonSerialization['dispenseId'] as int,
      prescriptionId: jsonSerialization['prescriptionId'] as int,
      patientId: jsonSerialization['patientId'] as int?,
      patientName: jsonSerialization['patientName'] as String,
      mobileNumber: jsonSerialization['mobileNumber'] as String,
      dispensedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['dispensedAt'],
      ),
      items: _i3.Protocol().deserialize<List<_i2.DispensedItemSummary>>(
        jsonSerialization['items'],
      ),
    );
  }

  int dispenseId;

  int prescriptionId;

  int? patientId;

  String patientName;

  String mobileNumber;

  DateTime dispensedAt;

  List<_i2.DispensedItemSummary> items;

  /// Returns a shallow copy of this [DispenseHistoryEntry]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  DispenseHistoryEntry copyWith({
    int? dispenseId,
    int? prescriptionId,
    int? patientId,
    String? patientName,
    String? mobileNumber,
    DateTime? dispensedAt,
    List<_i2.DispensedItemSummary>? items,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DispenseHistoryEntry',
      'dispenseId': dispenseId,
      'prescriptionId': prescriptionId,
      if (patientId != null) 'patientId': patientId,
      'patientName': patientName,
      'mobileNumber': mobileNumber,
      'dispensedAt': dispensedAt.toJson(),
      'items': items.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DispenseHistoryEntry',
      'dispenseId': dispenseId,
      'prescriptionId': prescriptionId,
      if (patientId != null) 'patientId': patientId,
      'patientName': patientName,
      'mobileNumber': mobileNumber,
      'dispensedAt': dispensedAt.toJson(),
      'items': items.toJson(valueToJson: (v) => v.toJsonForProtocol()),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DispenseHistoryEntryImpl extends DispenseHistoryEntry {
  _DispenseHistoryEntryImpl({
    required int dispenseId,
    required int prescriptionId,
    int? patientId,
    required String patientName,
    required String mobileNumber,
    required DateTime dispensedAt,
    required List<_i2.DispensedItemSummary> items,
  }) : super._(
         dispenseId: dispenseId,
         prescriptionId: prescriptionId,
         patientId: patientId,
         patientName: patientName,
         mobileNumber: mobileNumber,
         dispensedAt: dispensedAt,
         items: items,
       );

  /// Returns a shallow copy of this [DispenseHistoryEntry]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  DispenseHistoryEntry copyWith({
    int? dispenseId,
    int? prescriptionId,
    Object? patientId = _Undefined,
    String? patientName,
    String? mobileNumber,
    DateTime? dispensedAt,
    List<_i2.DispensedItemSummary>? items,
  }) {
    return DispenseHistoryEntry(
      dispenseId: dispenseId ?? this.dispenseId,
      prescriptionId: prescriptionId ?? this.prescriptionId,
      patientId: patientId is int? ? patientId : this.patientId,
      patientName: patientName ?? this.patientName,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      dispensedAt: dispensedAt ?? this.dispensedAt,
      items: items ?? this.items.map((e0) => e0.copyWith()).toList(),
    );
  }
}
