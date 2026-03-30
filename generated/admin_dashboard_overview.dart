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

abstract class AdminDashboardOverview
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  AdminDashboardOverview._({
    required this.totalUsers,
    required this.totalStockItems,
  });

  factory AdminDashboardOverview({
    required int totalUsers,
    required int totalStockItems,
  }) = _AdminDashboardOverviewImpl;

  factory AdminDashboardOverview.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return AdminDashboardOverview(
      totalUsers: jsonSerialization['totalUsers'] as int,
      totalStockItems: jsonSerialization['totalStockItems'] as int,
    );
  }

  int totalUsers;

  int totalStockItems;

  /// Returns a shallow copy of this [AdminDashboardOverview]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AdminDashboardOverview copyWith({
    int? totalUsers,
    int? totalStockItems,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AdminDashboardOverview',
      'totalUsers': totalUsers,
      'totalStockItems': totalStockItems,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'AdminDashboardOverview',
      'totalUsers': totalUsers,
      'totalStockItems': totalStockItems,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _AdminDashboardOverviewImpl extends AdminDashboardOverview {
  _AdminDashboardOverviewImpl({
    required int totalUsers,
    required int totalStockItems,
  }) : super._(
         totalUsers: totalUsers,
         totalStockItems: totalStockItems,
       );

  /// Returns a shallow copy of this [AdminDashboardOverview]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AdminDashboardOverview copyWith({
    int? totalUsers,
    int? totalStockItems,
  }) {
    return AdminDashboardOverview(
      totalUsers: totalUsers ?? this.totalUsers,
      totalStockItems: totalStockItems ?? this.totalStockItems,
    );
  }
}
