import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:backend_client/backend_client.dart'; // Serverpod client
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'export_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../core/date_time_utils.dart';
import '../routing/route_refresh.dart';

class ReportsAnalytics extends StatefulWidget {
  const ReportsAnalytics({super.key});

  @override
  State<ReportsAnalytics> createState() => _ReportsAnalyticsState();
}

class _ReportsAnalyticsState extends State<ReportsAnalytics>
    with RouteRefreshMixin<ReportsAnalytics> {
  int? _selectedMonthIndex = 0;
  DashboardAnalytics? _analytics;
  bool _loading = true;
  pw.Font? _englishFont;

  static const int _patientCountFetchLimit = 200000;

  DateTime? _medicineFromDate;
  DateTime? _medicineToDate;
  Set<DateTime>? _medicineAvailableDates;
  bool _medicineDatesLoading = false;

  final ScrollController _labMonthsScrollController = ScrollController();
  final ScrollController _labChartScrollController = ScrollController();
  final ScrollController _stockReportScrollController = ScrollController();

  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id'); // returns int? (nullable)
  }

  Future<void> _loadFont() async {
    final data = await rootBundle.load(
      'assets/fonts/OpenSans-VariableFont.ttf',
    );
    _englishFont = pw.Font.ttf(data);
  }

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
    _loadFont();
  }

  @override
  Future<void> refreshOnFocus() async {
    await _fetchAnalytics(silent: true);
  }

  DateTime _dateOnly(DateTime d) => AppDateTime.startOfLocalDay(d);

  String _fmtDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  Future<void> _ensureMedicineAvailableDatesLoaded() async {
    if (_medicineAvailableDates != null) return;
    if (_medicineDatesLoading) return;

    setState(() => _medicineDatesLoading = true);
    try {
      final dates = await client.adminReportEndpoints
          .getDispensedAvailableDates();
      final normalized = dates.map(_dateOnly).toSet();
      if (!mounted) return;
      setState(() {
        _medicineAvailableDates = normalized;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load available dates: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _medicineDatesLoading = false);
    }
  }

  Future<void> _pickMedicineFromDate() async {
    await _ensureMedicineAvailableDatesLoaded();
    final set = _medicineAvailableDates;
    if (set == null || set.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No medicine usage data found.')),
      );
      return;
    }

    final sorted = set.toList()..sort();
    final first = sorted.first;
    final last = sorted.last;
    final initial = _medicineFromDate ?? last;

    final picked = await showDatePicker(
      context: context,
      firstDate: first,
      lastDate: last,
      initialDate: initial.isBefore(first)
          ? first
          : (initial.isAfter(last) ? last : initial),
      selectableDayPredicate: (day) => set.contains(_dateOnly(day)),
    );
    if (picked == null) return;

    final from = _dateOnly(picked);
    setState(() {
      _medicineFromDate = from;
      if (_medicineToDate != null && _medicineToDate!.isBefore(from)) {
        _medicineToDate = from;
      }
    });
  }

  Future<void> _pickMedicineToDate() async {
    await _ensureMedicineAvailableDatesLoaded();
    final set = _medicineAvailableDates;
    if (set == null || set.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No medicine usage data found.')),
      );
      return;
    }

    final from = _medicineFromDate;
    if (from == null) return;

    final sorted = set.toList()..sort();
    final last = sorted.last;

    final picked = await showDatePicker(
      context: context,
      firstDate: from,
      lastDate: last,
      initialDate: (_medicineToDate ?? from).isAfter(last)
          ? last
          : (_medicineToDate ?? from),
      selectableDayPredicate: (day) {
        final d = _dateOnly(day);
        if (d.isBefore(from)) return false;
        return set.contains(d);
      },
    );
    if (picked == null) return;

    setState(() {
      _medicineToDate = _dateOnly(picked);
    });
  }

  @override
  void dispose() {
    _labMonthsScrollController.dispose();
    _labChartScrollController.dispose();
    _stockReportScrollController.dispose();
    super.dispose();
  }

  Future<void> _exportDashboardAsPDF() async {
    if (_analytics == null) return;

    if (_englishFont == null) {
      await _loadFont();
    }
    try {
      await ExportService.exportDashboardAsPDF(
        analytics: _analytics!,
        font: _englishFont!,
        selectedMonthIndex: _selectedMonthIndex ?? 0,
        months: _months,
      );

      final currentUser = await getCurrentUserId();
      if (currentUser != null) {
        final currentUserId = int.tryParse(currentUser);

        if (currentUserId != null) {
          await client.adminEndpoints.createAuditLog(
            adminId: currentUserId,
            action: 'EXPORT_PDF',
            targetId: currentUser,
          );
        }
        print("Current Admin ID: $currentUser");
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No current user ID found in SharedPreferences!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to export PDF: $e')));
      }
    }
  }

  Future<void> _exportMedicinesByDateRangeAsPDF() async {
    if (_englishFont == null) {
      await _loadFont();
    }

    final from = _medicineFromDate;
    final to = _medicineToDate;
    if (from == null || to == null) return;
    if (to.isBefore(from)) return;

    final fromLocal = _dateOnly(from);
    final toLocal = _dateOnly(to);
    final toExclusiveLocal = AppDateTime.startOfNextLocalDay(toLocal);

    // Backend should always receive UTC instants.
    final fromUtc = fromLocal.toUtc();
    final toExclusiveUtc = toExclusiveLocal.toUtc();

    try {
      final items = await client.adminReportEndpoints
          .getMedicineStockUsageByDateRange(fromUtc, toExclusiveUtc);

      final labTests = await _computeLabTestTotalsByDateRange(
        from: fromUtc,
        toExclusive: toExclusiveUtc,
      );

      await ExportService.exportMedicineStockUsageRangeAsPDF(
        items: items,
        labTests: labTests,
        from: fromLocal,
        to: toLocal,
        font: _englishFont!,
      );

      if (!mounted) return;
      setState(() {
        _medicineFromDate = null;
        _medicineToDate = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Date range report exported.')),
      );

      final currentUser = await getCurrentUserId();
      final currentUserId = int.tryParse(currentUser ?? '');
      if (currentUserId != null) {
        await client.adminEndpoints.createAuditLog(
          adminId: currentUserId,
          action: 'EXPORT_MEDICINE_RANGE_PDF',
          targetId:
              '${AppDateTime.utcIso(fromUtc)}..${AppDateTime.utcIso(toExclusiveUtc)}',
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export medicine report: $e')),
      );
    }
  }

  Future<List<LabTestRangeRow>> _computeLabTestTotalsByDateRange({
    required DateTime from,
    required DateTime toExclusive,
  }) async {
    final tests = await client.lab.getAllLabTests();
    final results = await client.lab.getAllTestResults();

    final Map<int, LabTests> byId = {
      for (final t in tests)
        if (t.id != null) t.id!: t,
    };

    double feeFor(LabTests test, String patientType) {
      final type = patientType.trim().toUpperCase();
      if (type == 'TEACHER') return test.teacherFee;
      if (type == 'OUTSIDE') return test.outsideFee;
      return test.studentFee;
    }

    final Map<int, int> counts = {};
    final Map<int, double> totals = {};

    for (final r in results) {
      final createdAt = r.createdAt;
      if (createdAt == null) continue;

      // createdAt is an instant; compare in UTC to avoid local timezone drift.
      final createdUtc = createdAt.toUtc();
      if (createdUtc.isBefore(from) || !createdUtc.isBefore(toExclusive)) {
        continue;
      }

      final test = byId[r.testId];
      if (test == null) continue;

      counts[r.testId] = (counts[r.testId] ?? 0) + 1;
      totals[r.testId] = (totals[r.testId] ?? 0) + feeFor(test, r.patientType);
    }

    final rows = <LabTestRangeRow>[];
    for (final entry in counts.entries) {
      final testId = entry.key;
      final test = byId[testId];
      final testName = test?.testName ?? 'Test #$testId';
      rows.add(
        LabTestRangeRow(
          testName: testName,
          count: entry.value,
          totalAmount: totals[testId] ?? 0,
        ),
      );
    }

    return rows;
  }

  // Future<void> _exportDashboardAsWord() async {
  //   if (_analytics == null) return;
  //
  //   await ExportService.exportDashboardAsWord(
  //     analytics: _analytics!,
  //     selectedMonthIndex: _selectedMonthIndex ?? 0,
  //     months: _months,
  //   );
  // }

  Future<int?> _tryCountUsersByRole(String role) async {
    try {
      final users = await client.adminEndpoints.listUsersByRole(
        role,
        _patientCountFetchLimit,
      );
      return users.length;
    } catch (e, st) {
      debugPrint('Failed to count users for role=$role: $e\n$st');
      return null;
    }
  }

  Future<int?> _computeTeacherStudentStaffTotalPatients() async {
    final counts = await Future.wait<int?>([
      _tryCountUsersByRole('STUDENT'),
      _tryCountUsersByRole('TEACHER'),
      _tryCountUsersByRole('STAFF'),
    ]);

    if (counts.any((c) => c == null)) return null;
    return (counts[0] ?? 0) + (counts[1] ?? 0) + (counts[2] ?? 0);
  }

  Future<void> _fetchAnalytics({bool silent = false}) async {
    try {
      if (!mounted) return;
      if (!silent) {
        setState(() => _loading = true);
      }

      final analyticsFuture = client.adminReportEndpoints
          .getDashboardAnalytics();
      final correctedTotalFuture = _computeTeacherStudentStaffTotalPatients();

      final data = await analyticsFuture;
      // debugPrint('Raw dashboard analytics: $data');
      // Fill missing months with zero
      // -------------------------
      final fullMonthlyBreakdown = List.generate(12, (i) {
        // i = 0 → Jan, i = 1 → Feb, ..., i = 11 → Dec
        final monthData = data.monthlyBreakdown.firstWhere(
          (m) => m.month == i + 1,
          orElse: () => MonthlyBreakdown(
            month: i + 1,
            total: 0,
            student: 0,
            teacher: 0,
            outside: 0,
            revenue: 0,
          ),
        );
        return monthData;
      });

      // Replace original monthlyBreakdown with full list
      data.monthlyBreakdown = fullMonthlyBreakdown;

      // UI-only correction:
      // Backend currently counts (Student + Teacher + Outside) as totalPatients.
      // For this page we want (Student + Teacher + Staff).
      final correctedTotal = await correctedTotalFuture;

      // Fallback: at minimum, exclude Outside when corrected total isn't available.
      var fallbackTeacherStudent = data.totalPatients - data.outPatients;
      if (fallbackTeacherStudent < 0) fallbackTeacherStudent = 0;

      final finalTotalPatients = correctedTotal ?? fallbackTeacherStudent;
      data.totalPatients = finalTotalPatients;
      data.patientCount = finalTotalPatients;

      if (!mounted) return;
      setState(() {
        _analytics = data;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error fetching analytics: $e');
      if (!mounted) return;
      if (!silent) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    const bg = Color(0xFFF6F8FC);
    const cardBg = Colors.white;

    BoxDecoration dashboardCardDecoration({
      required Color baseColor,
      Color? glow,
    }) {
      return BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: (glow ?? Colors.black).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      );
    }

    Widget dashboardCard({
      required Widget child,
      EdgeInsets padding = const EdgeInsets.all(16),
      VoidCallback? onTap,
    }) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Ink(
            decoration: dashboardCardDecoration(baseColor: cardBg),
            child: Padding(padding: padding, child: child),
          ),
        ),
      );
    }

    Color accentForIndex(int i) {
      const accents = [
        Color(0xFF2E7DFF),
        Color(0xFF7C4DFF),
        Color(0xFF00BFA6),
        Color(0xFFFF8F00),
      ];
      return accents[i % accents.length];
    }

    Widget statTile(
      int index,
      IconData icon,
      String title,
      String value, {
      String? trend,
      bool compact = false,
    }) {
      final accent = accentForIndex(index);

      // In the Key Metrics grid we must be extra compact to avoid any overflow
      // on narrow / short viewports.
      final effectiveTrend = compact ? null : trend;
      final iconSize = compact ? 18.0 : 20.0;
      final boxSize = compact ? 36.0 : 40.0;
      final tileHeight = compact ? 54.0 : 64.0;

      return dashboardCard(
        padding: EdgeInsets.all(compact ? 10 : 12),
        child: SizedBox(
          height: tileHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: boxSize,
                height: boxSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: [accent, accent.withValues(alpha: 0.65)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(icon, size: iconSize, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelLarge?.copyWith(
                        color: Colors.black.withValues(alpha: 0.62),
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                        fontSize: compact ? 11 : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.2,
                              height: 1.0,
                              fontSize: compact ? 14 : null,
                            ),
                          ),
                        ),
                        if (effectiveTrend != null) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Colors.green.withValues(alpha: 0.18),
                                ),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.trending_up,
                                      size: 14,
                                      color: Colors.green.shade700,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      effectiveTrend,
                                      style: textTheme.labelSmall?.copyWith(
                                        color: Colors.green.shade700,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget sectionTitle(String title, {String? subtitle}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: Colors.deepPurple,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle,
                style: textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.blueAccent,
                ),
              ),
          ],
        ),
      );
    }

    Widget chipStat({required String title, required String value}) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F7FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF2E7DFF).withValues(alpha: 0.20),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$title: ',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.black54,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      );
    }

    Widget ratioPill({
      required String label,
      required String value,
      required Color color,
    }) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.16)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.black54,
                ),
              ),
              Text(
                value,
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ---------------------- Month Breakdown ----------------------
    Widget monthBreakdownPanel() {
      if (_analytics == null) return const SizedBox.shrink();
      final i = _selectedMonthIndex ?? 0;
      if (i >= _analytics!.monthlyBreakdown.length) {
        return const SizedBox.shrink();
      }

      final b = _analytics!.monthlyBreakdown[i];
      final total = b.total;
      final student = b.student;
      final teacherFamily = b.teacher;
      final outside = b.outside;

      Widget pill(Color color, String label, String value) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.18)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                '$label: ',
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.black54,
                ),
              ),
              Text(
                value,
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        );
      }

      return Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              const Color(0xFF2E7DFF).withValues(alpha: 0.08),
              const Color(0xFF00BFA6).withValues(alpha: 0.08),
            ],
          ),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7DFF).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: const Color(0xFF2E7DFF).withValues(alpha: 0.18),
                    ),
                  ),
                  child: Text(
                    '${_months[i]} breakdown',
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Total: $total',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                pill(const Color(0xFF2E7DFF), 'Student', '$student'),
                pill(
                  const Color(0xFF7C4DFF),
                  'Teacher/Family',
                  '$teacherFamily',
                ),
                pill(const Color(0xFFFF8F00), 'Outside', '$outside'),
              ],
            ),
          ],
        ),
      );
    }

    // ---------------------- Bar Chart ----------------------
    Widget barChartInteractive() {
      if (_analytics == null) return const SizedBox.shrink();

      // Find max total amount for scaling
      final maxRevenue = _analytics!.monthlyBreakdown
          .map((m) => m.revenue.toDouble())
          .fold<double>(0, (prev, val) => val > prev ? val : prev);
      final yInterval = maxRevenue <= 0 ? 2.0 : (maxRevenue / 5);

      return BarChart(
        BarChartData(
          // gridData: FlGridData(show: false), // remove horizontal gridlines
          borderData: FlBorderData(show: false), // remove borders
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: yInterval,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()} taka',
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= 12) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _months[i],
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(12, (i) {
            final y = i < _analytics!.monthlyBreakdown.length
                ? _analytics!.monthlyBreakdown[i].revenue.toDouble()
                : 0.0;

            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: y,
                  width: 14,
                  color: const Color(0xFF2E7DFF),
                  borderRadius: BorderRadius.circular(
                    y >= maxRevenue * 0.95 ? 4 : 6,
                  ),
                ),
              ],
            );
          }),
          maxY: maxRevenue == 0 ? 10 : maxRevenue * 1.2,
          // 10% padding on top
        ),
      );
    }

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_analytics == null) {
      return const Scaffold(body: Center(child: Text('No data available')));
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ✅ Combined Key Metrics card (replaces 4 separate tiles)
            dashboardCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // REMOVED: Top export buttons from here
                  // const SizedBox(height: 18), // also removed the extra spacing
                  sectionTitle(
                    'Key Metrics',
                    subtitle:
                        'Patients, Outpatients, Dispensed & Prescriptions',
                  ),
                  const SizedBox(height: 10),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWideGrid = constraints.maxWidth >= 520;
                      return GridView.count(
                        crossAxisCount: isWideGrid ? 4 : 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        // Give a bit more height on narrow screens to fully avoid overflow
                        childAspectRatio: isWideGrid ? 2.9 : 2.0,
                        children: [
                          statTile(
                            0,
                            Icons.people,
                            'Total Patients',
                            _analytics!.totalPatients.toString(),
                            trend: '+12%',
                            compact: true,
                          ),
                          statTile(
                            1,
                            Icons.local_hospital,
                            'Outpatients',
                            _analytics!.outPatients.toString(),
                            trend: '+5%',
                            compact: true,
                          ),
                          statTile(
                            2,
                            Icons.medication,
                            'Medicines Dispensed',
                            _analytics!.medicinesDispensed.toString(),
                            trend: '+8%',
                            compact: true,
                          ),
                          statTile(
                            3,
                            Icons.receipt,
                            'Prescriptions',
                            _analytics!.totalPrescriptions.toString(),
                            compact: true,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),
            // Rest of your original UI (equalHeightRow, bar chart, pie chart, etc.)
            // Replace all static numbers with _analytics values similarly
            equalHeightRow(
              left: dashboardCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    sectionTitle(
                      'Prescription Activity',
                      subtitle: 'Quick overview of prescription trends',
                    ),
                    Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      children: [
                        chipStat(
                          title: 'Today',
                          value: _analytics!.prescriptionStats.today.toString(),
                        ),
                        chipStat(
                          title: 'This Week',
                          value: _analytics!.prescriptionStats.week.toString(),
                        ),
                        chipStat(
                          title: 'This Month',
                          value: _analytics!.prescriptionStats.month.toString(),
                        ),
                        chipStat(
                          title: 'This Year',
                          value: _analytics!.prescriptionStats.year.toString(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              right: dashboardCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    sectionTitle('Doctor–Patient Ratio'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ratioPill(
                          label: 'Doctors',
                          value: _analytics!.doctorCount.toString(),
                          color: const Color(0xFF2E7DFF),
                        ),
                        const SizedBox(width: 10),
                        ratioPill(
                          label: 'Patients',
                          value: _analytics!.patientCount.toString(),
                          color: const Color(0xFF00BFA6),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        'Ratio: 1 : ${(_analytics!.patientCount / _analytics!.doctorCount).round()}',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),
            dashboardCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  sectionTitle(
                    'Lab Tests',
                    subtitle: 'Click a month to see breakdown',
                  ),
                  SizedBox(
                    height: 320,
                    child: Scrollbar(
                      controller: _labChartScrollController,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: _labChartScrollController,
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: isWide
                              ? MediaQuery.of(context).size.width - 64
                              : 720,
                          height: 300,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: barChartInteractive(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedMonthIndex == null
                              ? 'Select a month'
                              : 'Selected: ${_months[_selectedMonthIndex!]}',
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 32,
                        width: isWide ? 320 : 220,
                        child: Scrollbar(
                          controller: _labMonthsScrollController,
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            controller: _labMonthsScrollController,
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: List.generate(12, (i) => _monthDot(i)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  monthBreakdownPanel(),
                ],
              ),
            ),

            const SizedBox(height: 18),
            dashboardCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  sectionTitle('Disease Trending'),
                  SizedBox(height: 240, child: pieChart()),
                ],
              ),
            ),

            // ---------------------- Dynamic Stock Report ----------------------
            dashboardCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  sectionTitle('Stock Report', subtitle: 'Current vs usage'),
                  const SizedBox(height: 6),
                  if (_analytics?.stockReport == null ||
                      _analytics!.stockReport.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text('No inventory data available'),
                      ),
                    )
                  else
                    Builder(
                      builder: (context) {
                        final stockRows = List<StockReport>.from(
                          _analytics!.stockReport,
                        );
                        int severity(StockReport s) {
                          if (s.current <= 0) return 0; // out of stock
                          final denom = (s.used + s.current).toDouble();
                          final usedRate = denom <= 0
                              ? 0.0
                              : (s.used / denom) * 100;
                          if (usedRate >= 70) {
                            return 1; // low (high usage vs remaining)
                          }
                          return 2; // good
                        }

                        stockRows.sort((a, b) {
                          final sa = severity(a);
                          final sb = severity(b);
                          if (sa != sb) return sa.compareTo(sb);
                          final c = a.current.compareTo(b.current);
                          if (c != 0) return c;
                          return a.itemName.toLowerCase().compareTo(
                            b.itemName.toLowerCase(),
                          );
                        });

                        return Scrollbar(
                          controller: _stockReportScrollController,
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            controller: _stockReportScrollController,
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: isWide
                                    ? MediaQuery.of(context).size.width - 64
                                    : 650,
                              ),
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(
                                  Colors.grey[50],
                                ),
                                columns: const [
                                  DataColumn(
                                    label: Text(
                                      'Inventory Item',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Current',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Used',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Status',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                                rows: stockRows.map((item) {
                                  final denom = (item.used + item.current)
                                      .toDouble();
                                  final double usedRate = denom <= 0
                                      ? 0.0
                                      : (item.used / denom) * 100;

                                  final bool isOut = item.current <= 0;
                                  final bool isLow = !isOut && usedRate >= 70;

                                  final Color statusColor = isOut
                                      ? Colors.grey
                                      : (isLow ? Colors.red : Colors.green);
                                  final String statusText = isOut
                                      ? 'Out'
                                      : (isLow ? 'Low' : 'Good');

                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Text(
                                          item.itemName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      DataCell(Text('${item.current}')),
                                      DataCell(Text('${item.used}')),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusColor.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            '$statusText (${usedRate.toStringAsFixed(0)}%)',
                                            style: TextStyle(
                                              color: statusColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),

            // NEW: Move Export buttons to bottom under Stock Report
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // 1st row: Export as PDF
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _exportDashboardAsPDF,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text(
                        'Export as PDF',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 2nd row: From date → To date
                  Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilledButton.icon(
                          onPressed: _medicineDatesLoading
                              ? null
                              : _pickMedicineFromDate,
                          icon: _medicineDatesLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.event),
                          label: Text(
                            _medicineFromDate == null
                                ? 'From date'
                                : 'From: ${_fmtDate(_medicineFromDate!)}',
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7DFF),
                            foregroundColor: Colors.white,
                          ),
                        ),
                        FilledButton.icon(
                          onPressed:
                              (_medicineFromDate == null ||
                                  _medicineDatesLoading)
                              ? null
                              : _pickMedicineToDate,
                          icon: const Icon(Icons.event_available),
                          label: Text(
                            _medicineToDate == null
                                ? 'To date'
                                : 'To: ${_fmtDate(_medicineToDate!)}',
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF00BFA6),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 3rd row: Date range export
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed:
                          (_medicineFromDate == null || _medicineToDate == null)
                          ? null
                          : _exportMedicinesByDateRangeAsPDF,
                      icon: const Icon(Icons.date_range),
                      label: const Text(
                        'Date Range (Medicines + Lab Tests)',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // fixed height row
  Widget equalHeightRow({required Widget left, required Widget right}) {
    final width = MediaQuery.of(context).size.width;

    if (width >= 740) {
      const h = 170.0;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SizedBox(height: h, child: left),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(height: h, child: right),
          ),
        ],
      );
    }

    return Column(children: [left, const SizedBox(height: 12), right]);
  }

  Widget _monthDot(int index) {
    final selected = _selectedMonthIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Tooltip(
        message: _months[index],
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => setState(() => _selectedMonthIndex = index),
          child: SizedBox(
            width: 28,
            height: 28,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                width: selected ? 20 : 14,
                height: selected ? 20 : 14,
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF00BFA6)
                      : Colors.black.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget pieChart() {
    const Map<String, double> data = {
      'Flu': 35,
      'Fever': 25,
      'Cold': 20,
      'Others': 20,
    };
    final total = data.values.fold<double>(0, (a, b) => a + b);
    PieChartSectionData sec(String label, double value, Color color) {
      final pct = total == 0 ? 0 : (value / total * 100).round();
      return PieChartSectionData(
        value: value,
        color: color,
        radius: 58,
        title: '$label\n$pct%',
        titleStyle: const TextStyle(
          fontWeight: FontWeight.w900,
          color: Colors.white,
          fontSize: 12,
          height: 1.1,
        ),
      );
    }

    return PieChart(
      PieChartData(
        sections: [
          sec('Flu', data['Flu']!, const Color(0xFF2E7DFF)),
          sec('Fever', data['Fever']!, const Color(0xFFFF8F00)),
          sec('Cold', data['Cold']!, const Color(0xFF00BFA6)),
          sec('Others', data['Others']!, const Color(0xFFE53935)),
        ],
        sectionsSpace: 2,
        centerSpaceRadius: 62,
      ),
    );
  }
}
