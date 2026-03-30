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

abstract class DoctorHomeRecentItem
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  DoctorHomeRecentItem._({
    required this.title,
    required this.subtitle,
    required this.timeAgo,
    required this.type,
    this.prescriptionId,
  });

  factory DoctorHomeRecentItem({
    required String title,
    required String subtitle,
    required String timeAgo,
    required String type,
    int? prescriptionId,
  }) = _DoctorHomeRecentItemImpl;

  factory DoctorHomeRecentItem.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return DoctorHomeRecentItem(
      title: jsonSerialization['title'] as String,
      subtitle: jsonSerialization['subtitle'] as String,
      timeAgo: jsonSerialization['timeAgo'] as String,
      type: jsonSerialization['type'] as String,
      prescriptionId: jsonSerialization['prescriptionId'] as int?,
    );
  }

  String title;

  String subtitle;

  String timeAgo;

  String type;

  int? prescriptionId;

  /// Returns a shallow copy of this [DoctorHomeRecentItem]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  DoctorHomeRecentItem copyWith({
    String? title,
    String? subtitle,
    String? timeAgo,
    String? type,
    int? prescriptionId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DoctorHomeRecentItem',
      'title': title,
      'subtitle': subtitle,
      'timeAgo': timeAgo,
      'type': type,
      if (prescriptionId != null) 'prescriptionId': prescriptionId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DoctorHomeRecentItem',
      'title': title,
      'subtitle': subtitle,
      'timeAgo': timeAgo,
      'type': type,
      if (prescriptionId != null) 'prescriptionId': prescriptionId,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DoctorHomeRecentItemImpl extends DoctorHomeRecentItem {
  _DoctorHomeRecentItemImpl({
    required String title,
    required String subtitle,
    required String timeAgo,
    required String type,
    int? prescriptionId,
  }) : super._(
         title: title,
         subtitle: subtitle,
         timeAgo: timeAgo,
         type: type,
         prescriptionId: prescriptionId,
       );

  /// Returns a shallow copy of this [DoctorHomeRecentItem]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  DoctorHomeRecentItem copyWith({
    String? title,
    String? subtitle,
    String? timeAgo,
    String? type,
    Object? prescriptionId = _Undefined,
  }) {
    return DoctorHomeRecentItem(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      timeAgo: timeAgo ?? this.timeAgo,
      type: type ?? this.type,
      prescriptionId: prescriptionId is int?
          ? prescriptionId
          : this.prescriptionId,
    );
  }
}
