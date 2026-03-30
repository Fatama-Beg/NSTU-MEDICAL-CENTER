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

abstract class StockReport
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  StockReport._({
    required this.itemName,
    required this.previous,
    required this.current,
    required this.used,
  });

  factory StockReport({
    required String itemName,
    required int previous,
    required int current,
    required int used,
  }) = _StockReportImpl;

  factory StockReport.fromJson(Map<String, dynamic> jsonSerialization) {
    return StockReport(
      itemName: jsonSerialization['itemName'] as String,
      previous: jsonSerialization['previous'] as int,
      current: jsonSerialization['current'] as int,
      used: jsonSerialization['used'] as int,
    );
  }

  String itemName;

  int previous;

  int current;

  int used;

  /// Returns a shallow copy of this [StockReport]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  StockReport copyWith({
    String? itemName,
    int? previous,
    int? current,
    int? used,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'StockReport',
      'itemName': itemName,
      'previous': previous,
      'current': current,
      'used': used,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'StockReport',
      'itemName': itemName,
      'previous': previous,
      'current': current,
      'used': used,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _StockReportImpl extends StockReport {
  _StockReportImpl({
    required String itemName,
    required int previous,
    required int current,
    required int used,
  }) : super._(
         itemName: itemName,
         previous: previous,
         current: current,
         used: used,
       );

  /// Returns a shallow copy of this [StockReport]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  StockReport copyWith({
    String? itemName,
    int? previous,
    int? current,
    int? used,
  }) {
    return StockReport(
      itemName: itemName ?? this.itemName,
      previous: previous ?? this.previous,
      current: current ?? this.current,
      used: used ?? this.used,
    );
  }
}
