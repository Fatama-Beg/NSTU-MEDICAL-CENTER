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
import 'report_prescription.dart' as _i2;
import 'report_monthly.dart' as _i3;
import 'report_top_medicine.dart' as _i4;
import 'report_stock.dart' as _i5;
import 'package:backend_server/src/generated/protocol.dart' as _i6;

abstract class DashboardAnalytics
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  DashboardAnalytics._({
    required this.totalPatients,
    required this.outPatients,
    required this.totalPrescriptions,
    required this.medicinesDispensed,
    required this.doctorCount,
    required this.patientCount,
    required this.prescriptionStats,
    required this.monthlyBreakdown,
    required this.topMedicines,
    required this.stockReport,
  });

  factory DashboardAnalytics({
    required int totalPatients,
    required int outPatients,
    required int totalPrescriptions,
    required int medicinesDispensed,
    required int doctorCount,
    required int patientCount,
    required _i2.PrescriptionStats prescriptionStats,
    required List<_i3.MonthlyBreakdown> monthlyBreakdown,
    required List<_i4.TopMedicine> topMedicines,
    required List<_i5.StockReport> stockReport,
  }) = _DashboardAnalyticsImpl;

  factory DashboardAnalytics.fromJson(Map<String, dynamic> jsonSerialization) {
    return DashboardAnalytics(
      totalPatients: jsonSerialization['totalPatients'] as int,
      outPatients: jsonSerialization['outPatients'] as int,
      totalPrescriptions: jsonSerialization['totalPrescriptions'] as int,
      medicinesDispensed: jsonSerialization['medicinesDispensed'] as int,
      doctorCount: jsonSerialization['doctorCount'] as int,
      patientCount: jsonSerialization['patientCount'] as int,
      prescriptionStats: _i6.Protocol().deserialize<_i2.PrescriptionStats>(
        jsonSerialization['prescriptionStats'],
      ),
      monthlyBreakdown: _i6.Protocol().deserialize<List<_i3.MonthlyBreakdown>>(
        jsonSerialization['monthlyBreakdown'],
      ),
      topMedicines: _i6.Protocol().deserialize<List<_i4.TopMedicine>>(
        jsonSerialization['topMedicines'],
      ),
      stockReport: _i6.Protocol().deserialize<List<_i5.StockReport>>(
        jsonSerialization['stockReport'],
      ),
    );
  }

  int totalPatients;

  int outPatients;

  int totalPrescriptions;

  int medicinesDispensed;

  int doctorCount;

  int patientCount;

  _i2.PrescriptionStats prescriptionStats;

  List<_i3.MonthlyBreakdown> monthlyBreakdown;

  List<_i4.TopMedicine> topMedicines;

  List<_i5.StockReport> stockReport;

  /// Returns a shallow copy of this [DashboardAnalytics]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  DashboardAnalytics copyWith({
    int? totalPatients,
    int? outPatients,
    int? totalPrescriptions,
    int? medicinesDispensed,
    int? doctorCount,
    int? patientCount,
    _i2.PrescriptionStats? prescriptionStats,
    List<_i3.MonthlyBreakdown>? monthlyBreakdown,
    List<_i4.TopMedicine>? topMedicines,
    List<_i5.StockReport>? stockReport,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DashboardAnalytics',
      'totalPatients': totalPatients,
      'outPatients': outPatients,
      'totalPrescriptions': totalPrescriptions,
      'medicinesDispensed': medicinesDispensed,
      'doctorCount': doctorCount,
      'patientCount': patientCount,
      'prescriptionStats': prescriptionStats.toJson(),
      'monthlyBreakdown': monthlyBreakdown.toJson(
        valueToJson: (v) => v.toJson(),
      ),
      'topMedicines': topMedicines.toJson(valueToJson: (v) => v.toJson()),
      'stockReport': stockReport.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DashboardAnalytics',
      'totalPatients': totalPatients,
      'outPatients': outPatients,
      'totalPrescriptions': totalPrescriptions,
      'medicinesDispensed': medicinesDispensed,
      'doctorCount': doctorCount,
      'patientCount': patientCount,
      'prescriptionStats': prescriptionStats.toJsonForProtocol(),
      'monthlyBreakdown': monthlyBreakdown.toJson(
        valueToJson: (v) => v.toJsonForProtocol(),
      ),
      'topMedicines': topMedicines.toJson(
        valueToJson: (v) => v.toJsonForProtocol(),
      ),
      'stockReport': stockReport.toJson(
        valueToJson: (v) => v.toJsonForProtocol(),
      ),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _DashboardAnalyticsImpl extends DashboardAnalytics {
  _DashboardAnalyticsImpl({
    required int totalPatients,
    required int outPatients,
    required int totalPrescriptions,
    required int medicinesDispensed,
    required int doctorCount,
    required int patientCount,
    required _i2.PrescriptionStats prescriptionStats,
    required List<_i3.MonthlyBreakdown> monthlyBreakdown,
    required List<_i4.TopMedicine> topMedicines,
    required List<_i5.StockReport> stockReport,
  }) : super._(
         totalPatients: totalPatients,
         outPatients: outPatients,
         totalPrescriptions: totalPrescriptions,
         medicinesDispensed: medicinesDispensed,
         doctorCount: doctorCount,
         patientCount: patientCount,
         prescriptionStats: prescriptionStats,
         monthlyBreakdown: monthlyBreakdown,
         topMedicines: topMedicines,
         stockReport: stockReport,
       );

  /// Returns a shallow copy of this [DashboardAnalytics]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  DashboardAnalytics copyWith({
    int? totalPatients,
    int? outPatients,
    int? totalPrescriptions,
    int? medicinesDispensed,
    int? doctorCount,
    int? patientCount,
    _i2.PrescriptionStats? prescriptionStats,
    List<_i3.MonthlyBreakdown>? monthlyBreakdown,
    List<_i4.TopMedicine>? topMedicines,
    List<_i5.StockReport>? stockReport,
  }) {
    return DashboardAnalytics(
      totalPatients: totalPatients ?? this.totalPatients,
      outPatients: outPatients ?? this.outPatients,
      totalPrescriptions: totalPrescriptions ?? this.totalPrescriptions,
      medicinesDispensed: medicinesDispensed ?? this.medicinesDispensed,
      doctorCount: doctorCount ?? this.doctorCount,
      patientCount: patientCount ?? this.patientCount,
      prescriptionStats: prescriptionStats ?? this.prescriptionStats.copyWith(),
      monthlyBreakdown:
          monthlyBreakdown ??
          this.monthlyBreakdown.map((e0) => e0.copyWith()).toList(),
      topMedicines:
          topMedicines ?? this.topMedicines.map((e0) => e0.copyWith()).toList(),
      stockReport:
          stockReport ?? this.stockReport.map((e0) => e0.copyWith()).toList(),
    );
  }
}
