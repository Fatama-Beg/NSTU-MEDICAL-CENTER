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
import 'doctor_home_recent_item.dart' as _i2;
import 'doctor_home_reviewed_report.dart' as _i3;
import 'package:backend_server/src/generated/protocol.dart' as _i4;

abstract class DoctorHomeData
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  DoctorHomeData._({
    required this.doctorName,
    required this.doctorDesignation,
    this.doctorProfilePictureUrl,
    required this.today,
    required this.lastMonthPrescriptions,
    required this.lastWeekPrescriptions,
    required this.recent,
    required this.reviewedReports,
  });

  factory DoctorHomeData({
    required String doctorName,
    required String doctorDesignation,
    String? doctorProfilePictureUrl,
    required DateTime today,
    required int lastMonthPrescriptions,
    required int lastWeekPrescriptions,
    required List<_i2.DoctorHomeRecentItem> recent,
    required List<_i3.DoctorHomeReviewedReport> reviewedReports,
  }) = _DoctorHomeDataImpl;

  factory DoctorHomeData.fromJson(Map<String, dynamic> jsonSerialization) {
    return DoctorHomeData(
      doctorName: jsonSerialization['doctorName'] as String,
      doctorDesignation: jsonSerialization['doctorDesignation'] as String,
      doctorProfilePictureUrl:
          jsonSerialization['doctorProfilePictureUrl'] as String?,
      today: _i1.DateTimeJsonExtension.fromJson(jsonSerialization['today']),
      lastMonthPrescriptions:
          jsonSerialization['lastMonthPrescriptions'] as int,
      lastWeekPrescriptions: jsonSerialization['lastWeekPrescriptions'] as int,
      recent: _i4.Protocol().deserialize<List<_i2.DoctorHomeRecentItem>>(
        jsonSerialization['recent'],
      ),
      reviewedReports: _i4.Protocol()
          .deserialize<List<_i3.DoctorHomeReviewedReport>>(
            jsonSerialization['reviewedReports'],
          ),
    );
  }

  String doctorName;

  String doctorDesignation;

  String? doctorProfilePictureUrl;

  DateTime today;

  int lastMonthPrescriptions;

  int lastWeekPrescriptions;

  List<_i2.DoctorHomeRecentItem> recent;

  List<_i3.DoctorHomeReviewedReport> reviewedReports;

  /// Returns a shallow copy of this [DoctorHomeData]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  DoctorHomeData copyWith({
    String? doctorName,
    String? doctorDesignation,
    String? doctorProfilePictureUrl,
    DateTime? today,
    int? lastMonthPrescriptions,
    int? lastWeekPrescriptions,
    List<_i2.DoctorHomeRecentItem>? recent,
    List<_i3.DoctorHomeReviewedReport>? reviewedReports,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DoctorHomeData',
      'doctorName': doctorName,
      'doctorDesignation': doctorDesignation,
      if (doctorProfilePictureUrl != null)
        'doctorProfilePictureUrl': doctorProfilePictureUrl,
      'today': today.toJson(),
      'lastMonthPrescriptions': lastMonthPrescriptions,
      'lastWeekPrescriptions': lastWeekPrescriptions,
      'recent': recent.toJson(valueToJson: (v) => v.toJson()),
      'reviewedReports': reviewedReports.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DoctorHomeData',
      'doctorName': doctorName,
      'doctorDesignation': doctorDesignation,
      if (doctorProfilePictureUrl != null)
        'doctorProfilePictureUrl': doctorProfilePictureUrl,
      'today': today.toJson(),
      'lastMonthPrescriptions': lastMonthPrescriptions,
      'lastWeekPrescriptions': lastWeekPrescriptions,
      'recent': recent.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'reviewedReports': reviewedReports.toJson(
        valueToJson: (v) => v.toJsonForProtocol(),
      ),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DoctorHomeDataImpl extends DoctorHomeData {
  _DoctorHomeDataImpl({
    required String doctorName,
    required String doctorDesignation,
    String? doctorProfilePictureUrl,
    required DateTime today,
    required int lastMonthPrescriptions,
    required int lastWeekPrescriptions,
    required List<_i2.DoctorHomeRecentItem> recent,
    required List<_i3.DoctorHomeReviewedReport> reviewedReports,
  }) : super._(
         doctorName: doctorName,
         doctorDesignation: doctorDesignation,
         doctorProfilePictureUrl: doctorProfilePictureUrl,
         today: today,
         lastMonthPrescriptions: lastMonthPrescriptions,
         lastWeekPrescriptions: lastWeekPrescriptions,
         recent: recent,
         reviewedReports: reviewedReports,
       );

  /// Returns a shallow copy of this [DoctorHomeData]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  DoctorHomeData copyWith({
    String? doctorName,
    String? doctorDesignation,
    Object? doctorProfilePictureUrl = _Undefined,
    DateTime? today,
    int? lastMonthPrescriptions,
    int? lastWeekPrescriptions,
    List<_i2.DoctorHomeRecentItem>? recent,
    List<_i3.DoctorHomeReviewedReport>? reviewedReports,
  }) {
    return DoctorHomeData(
      doctorName: doctorName ?? this.doctorName,
      doctorDesignation: doctorDesignation ?? this.doctorDesignation,
      doctorProfilePictureUrl: doctorProfilePictureUrl is String?
          ? doctorProfilePictureUrl
          : this.doctorProfilePictureUrl,
      today: today ?? this.today,
      lastMonthPrescriptions:
          lastMonthPrescriptions ?? this.lastMonthPrescriptions,
      lastWeekPrescriptions:
          lastWeekPrescriptions ?? this.lastWeekPrescriptions,
      recent: recent ?? this.recent.map((e0) => e0.copyWith()).toList(),
      reviewedReports:
          reviewedReports ??
          this.reviewedReports.map((e0) => e0.copyWith()).toList(),
    );
  }
}
