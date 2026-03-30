import 'package:serverpod/serverpod.dart';
import 'package:backend_server/src/generated/protocol.dart';

class AdminReportEndpoints extends Endpoint {
    @override
  bool get requireLogin => true;
  Future<AdminDashboardOverview> getAdminDashboardOverview(
    Session session,
  ) async {
    try {
      final totalUsers =
          await _getSingleInt(session, 'SELECT COUNT(*) FROM users');
      final totalStockItems =
          await _getSingleInt(session, 'SELECT COUNT(*) FROM inventory_item');

      return AdminDashboardOverview(
        totalUsers: totalUsers,
        totalStockItems: totalStockItems,
      );
    } catch (e, st) {
      session.log(
        'Admin dashboard overview error: $e',
        level: LogLevel.error,
        stackTrace: st,
      );
      rethrow;
    }
  }

  Future<DashboardAnalytics> getDashboardAnalytics(Session session) async {
    try {
      // ---------- BASIC COUNTS ----------
      final totalPatients = await _getSingleInt(
        session,
        "SELECT COUNT(*) FROM users WHERE role IN ('STUDENT','TEACHER','OUTSIDE')",
      );

      final outPatients = await _getSingleInt(
        session,
        "SELECT COUNT(*) FROM users WHERE role = 'OUTSIDE'",
      );

      final totalPrescriptions = await _getSingleInt(
        session,
        "SELECT COUNT(*) FROM prescriptions",
      );

      final medicinesDispensed = await _getSingleInt(
        session,
        "SELECT COALESCE(SUM(quantity),0) FROM dispensed_items",
      );

      final doctorCount = await _getSingleInt(
        session,
        "SELECT COUNT(*) FROM users WHERE role = 'DOCTOR'",
      );

      // ---------- PRESCRIPTION STATS ----------
      final prescriptionStats = PrescriptionStats(
        today: await _getSingleInt(
          session,
          "SELECT COUNT(*) FROM prescriptions WHERE prescription_date = CURRENT_DATE",
        ),
        week: await _getSingleInt(
          session,
          "SELECT COUNT(*) FROM prescriptions WHERE prescription_date >= CURRENT_DATE - INTERVAL '7 days'",
        ),
        month: await _getSingleInt(
          session,
          "SELECT COUNT(*) FROM prescriptions WHERE prescription_date >= DATE_TRUNC('month', CURRENT_DATE)",
        ),
        year: await _getSingleInt(
          session,
          "SELECT COUNT(*) FROM prescriptions WHERE prescription_date >= DATE_TRUNC('year', CURRENT_DATE)",
        ),
      );

      // ---------- MONTHLY BREAKDOWN WITH REVENUE ----------
      final monthlyRows = await session.db.unsafeQuery('''
  SELECT 
    EXTRACT(MONTH FROM tr.created_at)::INT AS month,
    COUNT(*)::INT AS total,
    SUM(CASE WHEN tr.patient_type='STUDENT' THEN 1 ELSE 0 END)::INT AS student,
    SUM(CASE WHEN tr.patient_type='TEACHER' THEN 1 ELSE 0 END)::INT AS teacher,
    SUM(CASE WHEN tr.patient_type='OUTSIDE' THEN 1 ELSE 0 END)::INT AS outside,
    COALESCE(SUM(
      CASE tr.patient_type
        WHEN 'STUDENT' THEN lt.student_fee
        WHEN 'TEACHER' THEN lt.teacher_fee
        WHEN 'OUTSIDE' THEN lt.outside_fee
      END
    ),0) AS revenue
  FROM test_results tr
  LEFT JOIN lab_tests lt ON tr.test_id = lt.test_id
  GROUP BY month
  ORDER BY month
''');

      final monthlyBreakdown = monthlyRows.map((r) {
        final m = r.toColumnMap();
        return MonthlyBreakdown(
          month: _toInt(m['month']),
          total: _toInt(m['total']),
          student: _toInt(m['student']),
          teacher: _toInt(m['teacher']),
          outside: _toInt(m['outside']),
          revenue: m['revenue'] != null
              ? double.parse(m['revenue'].toString())
              : 0.0,
        );
      }).toList();

      // ---------- TOP MEDICINES ----------
      final topMedRows = await session.db.unsafeQuery('''
        SELECT medicine_name, SUM(quantity)::INT AS used
        FROM dispensed_items
        GROUP BY medicine_name
        ORDER BY used DESC
        LIMIT 5
      ''');

      final topMedicines = topMedRows.map((r) {
        final m = r.toColumnMap();
        return TopMedicine(
          medicineName: m['medicine_name'].toString(),
          used: _toInt(m['used']),
        );
      }).toList();

      // ---------- STOCK REPORT ----------
      final stockRows = await session.db.unsafeQuery('''
        WITH bounds AS (
          SELECT
            DATE_TRUNC('month', CURRENT_DATE)::timestamp AS month_start,
            ((DATE_TRUNC('month', CURRENT_DATE)::date - 1)::timestamp) AS used_start,
            ((CURRENT_DATE + 1)::timestamp) AS used_end
        )
        SELECT
          i.item_name,
          COALESCE((
            SELECT a.new_quantity
            FROM inventory_audit_log a
            JOIN bounds b ON TRUE
            WHERE a.item_id = i.item_id
              AND a.changed_at < b.month_start
            ORDER BY a.changed_at DESC, a.audit_id DESC
            LIMIT 1
          ), 0)::INT AS previous,
          COALESCE(s.current_quantity, 0)::INT AS current,
          COALESCE((
            SELECT SUM(t.quantity)
            FROM inventory_transaction t
            JOIN bounds b ON TRUE
            WHERE t.item_id = i.item_id
              AND t.transaction_type = 'OUT'
              AND t.created_at >= b.used_start
              AND t.created_at < b.used_end
          ), 0)::INT AS used
        FROM inventory_item i
        LEFT JOIN inventory_stock s ON i.item_id = s.item_id
      ''');

      final stockReport = stockRows.map((r) {
        final m = r.toColumnMap();
        return StockReport(
          itemName: m['item_name'].toString(),
          previous: _toInt(m['previous']),
          current: _toInt(m['current']),
          used: _toInt(m['used']),
        );
      }).toList();

      // ---------- FINAL RETURN ----------
      return DashboardAnalytics(
        totalPatients: totalPatients,
        outPatients: outPatients,
        totalPrescriptions: totalPrescriptions,
        medicinesDispensed: medicinesDispensed,
        doctorCount: doctorCount,
        patientCount: totalPatients,
        prescriptionStats: prescriptionStats,
        monthlyBreakdown: monthlyBreakdown,
        topMedicines: topMedicines,
        stockReport: stockReport,
      );
    } catch (e, st) {
      session.log(
        'Dashboard analytics error: $e',
        level: LogLevel.error,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Medicine usage report within a dispensed date range.
  ///
  /// Expected semantics: [from] is inclusive, [to] is exclusive (recommended).
  Future<List<TopMedicine>> getMedicineUsageByDateRange(
    Session session,
    DateTime from,
    DateTime to,
  ) async {
    try {
      final rows = await session.db.unsafeQuery(
        '''
        SELECT di.medicine_name, SUM(di.quantity)::INT AS used
        FROM dispensed_items di
        JOIN prescription_dispense pd ON pd.dispense_id = di.dispense_id
        WHERE pd.dispensed_at >= @from AND pd.dispensed_at < @to
        GROUP BY di.medicine_name
        ORDER BY used DESC
        ''',
        parameters: QueryParameters.named({'from': from, 'to': to}),
      );

      return rows.map((r) {
        final m = r.toColumnMap();
        return TopMedicine(
          medicineName: m['medicine_name'].toString(),
          used: _toInt(m['used']),
        );
      }).toList();
    } catch (e, st) {
      session.log(
        'getMedicineUsageByDateRange failed: $e',
        level: LogLevel.error,
        stackTrace: st,
      );
      return [];
    }
  }

  /// Medicine usage + stock snapshot report within a date range.
  ///
  /// Semantics: [from] is inclusive start (usually 00:00), [toExclusive] is
  /// exclusive end (usually next-day 00:00).
  ///
  /// Returns rows per medicine used in the range with:
  /// - fromQuantity: last known stock at or before [from]
  /// - used: total dispensed within [from, toExclusive)
  /// - toQuantity: last known stock at or before [toExclusive]
  Future<List<MedicineStockRangeRow>> getMedicineStockUsageByDateRange(
    Session session,
    DateTime from,
    DateTime toExclusive,
  ) async {
    try {
      final rows = await session.db.unsafeQuery(
        '''
        WITH used AS (
          SELECT
            di.item_id AS item_id,
            di.medicine_name AS medicine_name,
            SUM(di.quantity)::INT AS used
          FROM dispensed_items di
          JOIN prescription_dispense pd ON pd.dispense_id = di.dispense_id
          WHERE pd.dispensed_at >= @from AND pd.dispensed_at < @to
          GROUP BY di.item_id, di.medicine_name
        )
        SELECT
          u.medicine_name,
          u.used,
          COALESCE((
            SELECT a.new_quantity
            FROM inventory_audit_log a
            WHERE a.item_id = u.item_id AND a.changed_at <= @from
            ORDER BY a.changed_at DESC, a.audit_id DESC
            LIMIT 1
          ), 0) AS from_quantity,
          COALESCE((
            SELECT a.new_quantity
            FROM inventory_audit_log a
            WHERE a.item_id = u.item_id AND a.changed_at <= @to
            ORDER BY a.changed_at DESC, a.audit_id DESC
            LIMIT 1
          ), 0) AS to_quantity
        FROM used u
        ORDER BY u.used DESC
        ''',
        parameters: QueryParameters.named({'from': from, 'to': toExclusive}),
      );

      return rows.map((r) {
        final m = r.toColumnMap();
        return MedicineStockRangeRow(
          medicineName: m['medicine_name'].toString(),
          fromQuantity: _toInt(m['from_quantity']),
          used: _toInt(m['used']),
          toQuantity: _toInt(m['to_quantity']),
        );
      }).toList();
    } catch (e, st) {
      session.log(
        'getMedicineStockUsageByDateRange failed: $e',
        level: LogLevel.error,
        stackTrace: st,
      );
      return [];
    }
  }

  /// Returns the list of dates (date-only, midnight) that have dispensed items.
  /// Useful for disabling dates that have no data.
  Future<List<DateTime>> getDispensedAvailableDates(Session session) async {
    try {
      final rows = await session.db.unsafeQuery(
        '''
        SELECT DISTINCT DATE(pd.dispensed_at) AS d
        FROM prescription_dispense pd
        JOIN dispensed_items di ON di.dispense_id = pd.dispense_id
        ORDER BY d ASC
        ''',
      );

      return rows.map((r) {
        final m = r.toColumnMap();
        final d = m['d'] as DateTime;
        return DateTime(d.year, d.month, d.day);
      }).toList();
    } catch (e, st) {
      session.log(
        'getDispensedAvailableDates failed: $e',
        level: LogLevel.error,
        stackTrace: st,
      );
      return [];
    }
  }

  /// Lab test summary within a date range.
  ///
  /// Semantics: [from] is inclusive start, [toExclusive] is exclusive end.
  Future<List<LabTestRangeRow>> getLabTestTotalsByDateRange(
    Session session,
    DateTime from,
    DateTime toExclusive,
  ) async {
    try {
      final rows = await session.db.unsafeQuery(
        '''
        SELECT
          COALESCE(lt.test_name, 'Unknown') AS test_name,
          COUNT(*)::INT AS test_count,
          COALESCE(SUM(
            CASE tr.patient_type
              WHEN 'STUDENT' THEN lt.student_fee
              WHEN 'TEACHER' THEN lt.teacher_fee
              WHEN 'OUTSIDE' THEN lt.outside_fee
              ELSE 0
            END
          ), 0) AS total_amount
        FROM test_results tr
        LEFT JOIN lab_tests lt ON lt.test_id = tr.test_id
        WHERE tr.created_at >= @from AND tr.created_at < @to
        GROUP BY test_name
        ORDER BY total_amount DESC, test_count DESC, test_name ASC
        ''',
        parameters: QueryParameters.named({'from': from, 'to': toExclusive}),
      );

      return rows.map((r) {
        final m = r.toColumnMap();
        return LabTestRangeRow(
          testName: m['test_name'].toString(),
          count: _toInt(m['test_count']),
          totalAmount: m['total_amount'] != null
              ? double.parse(m['total_amount'].toString())
              : 0.0,
        );
      }).toList();
    } catch (e, st) {
      session.log(
        'getLabTestTotalsByDateRange failed: $e',
        level: LogLevel.error,
        stackTrace: st,
      );
      return [];
    }
  }

  // ---------- HELPERS ----------

  // Robust integer parsing from Dynamic DB values
  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  Future<int> _getSingleInt(Session session, String query) async {
    final res = await session.db.unsafeQuery(query);
    if (res.isEmpty) return 0;
    final val = res.first.toColumnMap().values.first;
    return _toInt(val);
  }
}
