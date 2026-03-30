import 'dart:math' as math;

import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:backend_client/backend_client.dart';

class ExportService {
  static const String _dash = '—';

  static String _two(int n) => n.toString().padLeft(2, '0');

  static String _fmtDate(DateTime d) => () {
    final local = d.toLocal();
    return '${local.year}-${_two(local.month)}-${_two(local.day)}';
  }();

  static String _fmtDateTime(DateTime d) {
    final local = d.toLocal();
    return '${local.year}-${_two(local.month)}-${_two(local.day)} '
        '${_two(local.hour)}:${_two(local.minute)}';
  }

  /// UI-only helper model for Inventory Transactions PDF export.
  ///
  /// Note: This is intentionally not a Serverpod protocol type.
  /// It is built client-side from existing endpoints.
  static InventoryTransactionReportRow inventoryTxRow({
    required DateTime time,
    required String itemName,
    required String unit,
    required String type,
    required int quantity,
  }) {
    return InventoryTransactionReportRow(
      time: time,
      itemName: itemName,
      unit: unit,
      type: type,
      quantity: quantity,
    );
  }

  static Future<void> exportInventoryTransactionsRangeAsPDF({
    required List<InventoryTransactionReportRow> rows,
    required DateTime from,
    required DateTime to,
    required pw.Font font,
  }) async {
    final pdf = pw.Document();

    final baseStyle = pw.TextStyle(font: font);
    final h1 = baseStyle.copyWith(fontSize: 20, fontWeight: pw.FontWeight.bold);
    final h2 = baseStyle.copyWith(fontSize: 14, fontWeight: pw.FontWeight.bold);
    final smallMuted = baseStyle.copyWith(
      fontSize: 9,
      color: PdfColors.grey600,
    );

    pw.Widget tableCell(String text, {bool isHeader = false}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.all(8),
        child: pw.Text(
          text,
          style: isHeader
              ? baseStyle.copyWith(fontWeight: pw.FontWeight.bold)
              : baseStyle.copyWith(fontSize: 10),
        ),
      );
    }

    final safeRows = List<InventoryTransactionReportRow>.from(rows)
      ..sort((a, b) => b.time.compareTo(a.time));

    final Map<String, _InventoryAgg> byItem = {};
    for (final r in safeRows) {
      final name = r.itemName.trim().isEmpty ? _dash : r.itemName.trim();
      final unit = r.unit.trim().isEmpty ? _dash : r.unit.trim();
      final key = '$name|$unit';
      final agg = byItem.putIfAbsent(
        key,
        () => _InventoryAgg(name: name, unit: unit),
      );
      final t = r.type.toUpperCase().trim();
      if (t == 'IN') {
        agg.totalIn += r.quantity;
      } else if (t == 'OUT') {
        agg.totalOut += r.quantity;
      }
      agg.entries += 1;
    }

    final perItem = byItem.values.toList()
      ..sort((a, b) {
        final outCmp = b.totalOut.compareTo(a.totalOut);
        if (outCmp != 0) return outCmp;
        final inCmp = b.totalIn.compareTo(a.totalIn);
        if (inCmp != 0) return inCmp;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    int totalIn = 0;
    int totalOut = 0;
    for (final r in safeRows) {
      if (r.type.toUpperCase() == 'IN') {
        totalIn += r.quantity;
      } else if (r.type.toUpperCase() == 'OUT') {
        totalOut += r.quantity;
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(54),
          theme: pw.ThemeData.withFont(base: font, bold: font),
        ),
        header: (_) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Dishari - Inventory Transactions',
              style: baseStyle.copyWith(fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Generated: ${_fmtDate(DateTime.now())}',
              style: smallMuted,
            ),
          ],
        ),
        build: (_) {
          return [
            pw.SizedBox(height: 12),
            pw.Text('Inventory Transactions (Date Range)', style: h1),
            pw.SizedBox(height: 6),
            pw.Text(
              'From: ${_fmtDate(from)}    To: ${_fmtDate(to)}',
              style: smallMuted,
            ),
            pw.SizedBox(height: 16),
            pw.Text('Summary', style: h2),
            pw.SizedBox(height: 6),
            pw.Text(
              'Total entries: ${safeRows.length}',
              style: baseStyle.copyWith(fontSize: 11),
            ),
            pw.Text(
              'Total IN: $totalIn    Total OUT: $totalOut    Net: ${totalIn - totalOut}',
              style: baseStyle.copyWith(fontSize: 11),
            ),
            pw.SizedBox(height: 14),
            pw.Text('Per-item Summary', style: h2),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(2.8),
                1: const pw.FlexColumnWidth(1.0),
                2: const pw.FlexColumnWidth(0.9),
                3: const pw.FlexColumnWidth(0.9),
                4: const pw.FlexColumnWidth(0.9),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    tableCell('Item', isHeader: true),
                    tableCell('Unit', isHeader: true),
                    tableCell('IN', isHeader: true),
                    tableCell('OUT', isHeader: true),
                    tableCell('NET', isHeader: true),
                  ],
                ),
                ...perItem.map((a) {
                  final net = a.totalIn - a.totalOut;
                  return pw.TableRow(
                    children: [
                      tableCell(a.name),
                      tableCell(a.unit),
                      tableCell(a.totalIn.toString()),
                      tableCell(a.totalOut.toString()),
                      tableCell(net.toString()),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 14),
            pw.Text('Transactions', style: h2),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.35),
                1: const pw.FlexColumnWidth(2.6),
                2: const pw.FlexColumnWidth(0.85),
                3: const pw.FlexColumnWidth(0.9),
                4: const pw.FlexColumnWidth(1.0),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    tableCell('Date/Time', isHeader: true),
                    tableCell('Item', isHeader: true),
                    tableCell('Type', isHeader: true),
                    tableCell('Qty', isHeader: true),
                    tableCell('Unit', isHeader: true),
                  ],
                ),
                ...safeRows.map((r) {
                  final type = r.type.toUpperCase();
                  final qty = r.quantity;
                  return pw.TableRow(
                    children: [
                      tableCell(_fmtDateTime(r.time)),
                      tableCell(r.itemName.isEmpty ? _dash : r.itemName),
                      tableCell(type.isEmpty ? _dash : type),
                      tableCell(qty.toString()),
                      tableCell(r.unit.isEmpty ? _dash : r.unit),
                    ],
                  );
                }),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  static Future<void> exportMedicineStockUsageRangeAsPDF({
    required List<MedicineStockRangeRow> items,
    List<LabTestRangeRow>? labTests,
    required DateTime from,
    required DateTime to,
    required pw.Font font,
  }) async {
    final pdf = pw.Document();

    final baseStyle = pw.TextStyle(font: font);
    final h1 = baseStyle.copyWith(fontSize: 20, fontWeight: pw.FontWeight.bold);
    final h2 = baseStyle.copyWith(fontSize: 14, fontWeight: pw.FontWeight.bold);
    final smallMuted = baseStyle.copyWith(
      fontSize: 9,
      color: PdfColors.grey600,
    );

    String fmt(DateTime d) => _fmtDate(d);

    pw.Widget tableCell(String text, {bool isHeader = false}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.all(8),
        child: pw.Text(
          text,
          style: isHeader
              ? baseStyle.copyWith(fontWeight: pw.FontWeight.bold)
              : baseStyle.copyWith(fontSize: 11),
        ),
      );
    }

    final safeItems = List<MedicineStockRangeRow>.from(items)
      ..sort((a, b) => b.used.compareTo(a.used));

    final safeLabTests = List<LabTestRangeRow>.from(labTests ?? const [])
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    final labTotalCount = safeLabTests.fold<int>(0, (p, e) => p + e.count);
    final labTotalAmount = safeLabTests.fold<double>(
      0,
      (p, e) => p + e.totalAmount,
    );

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(54),
          theme: pw.ThemeData.withFont(base: font, bold: font),
        ),
        header: (_) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Dishari - Date Range Report',
              style: baseStyle.copyWith(fontWeight: pw.FontWeight.bold),
            ),
            pw.Text('Generated: ${fmt(DateTime.now())}', style: smallMuted),
          ],
        ),
        build: (_) {
          return [
            pw.SizedBox(height: 12),
            pw.Text('Medicine Stock (Date Range)', style: h1),
            pw.SizedBox(height: 6),
            pw.Text('From: ${fmt(from)}    To: ${fmt(to)}', style: smallMuted),
            pw.SizedBox(height: 16),
            pw.Text('Summary', style: h2),
            pw.SizedBox(height: 6),
            pw.Text(
              'Total unique medicines: ${safeItems.length}',
              style: baseStyle.copyWith(fontSize: 11),
            ),
            pw.SizedBox(height: 14),
            pw.Text('Medicines', style: h2),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: const {
                0: pw.FlexColumnWidth(3.2),
                1: pw.FlexColumnWidth(1.3),
                2: pw.FlexColumnWidth(1.8),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    tableCell('Medicine', isHeader: true),
                    tableCell('Current', isHeader: true),
                    tableCell('Date Range Used', isHeader: true),
                  ],
                ),
                ...safeItems.map(
                  (m) => pw.TableRow(
                    children: [
                      tableCell(m.medicineName),
                      tableCell(m.toQuantity.toString()),
                      tableCell(m.used.toString()),
                    ],
                  ),
                ),
              ],
            ),

            if (safeLabTests.isNotEmpty) ...[
              pw.SizedBox(height: 20),
              pw.Text('Lab Tests (Date Range)', style: h1),
              pw.SizedBox(height: 6),
              pw.Text(
                'From: ${fmt(from)}    To: ${fmt(to)}',
                style: smallMuted,
              ),
              pw.SizedBox(height: 16),
              pw.Text('Summary', style: h2),
              pw.SizedBox(height: 6),
              pw.Text(
                'Total tests: $labTotalCount   Total amount: ${labTotalAmount.toStringAsFixed(0)} taka',
                style: baseStyle.copyWith(fontSize: 11),
              ),
              pw.SizedBox(height: 14),
              pw.Text('Tests', style: h2),
              pw.SizedBox(height: 6),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey100,
                    ),
                    children: [
                      tableCell('Test', isHeader: true),
                      tableCell('Count', isHeader: true),
                      tableCell('Total (taka)', isHeader: true),
                    ],
                  ),
                  ...safeLabTests.map(
                    (t) => pw.TableRow(
                      children: [
                        tableCell(t.testName),
                        tableCell(t.count.toString()),
                        tableCell('${t.totalAmount.toStringAsFixed(0)} taka'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ];
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  static Future<void> exportMedicineUsageRangeAsPDF({
    required List<TopMedicine> items,
    required DateTime from,
    required DateTime to,
    required pw.Font font,
  }) async {
    final pdf = pw.Document();

    final baseStyle = pw.TextStyle(font: font);
    final h1 = baseStyle.copyWith(fontSize: 20, fontWeight: pw.FontWeight.bold);
    final h2 = baseStyle.copyWith(fontSize: 14, fontWeight: pw.FontWeight.bold);
    final smallMuted = baseStyle.copyWith(
      fontSize: 9,
      color: PdfColors.grey600,
    );

    String fmt(DateTime d) => _fmtDate(d);

    pw.Widget tableCell(String text, {bool isHeader = false}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.all(8),
        child: pw.Text(
          text,
          style: isHeader
              ? baseStyle.copyWith(fontWeight: pw.FontWeight.bold)
              : baseStyle.copyWith(fontSize: 11),
        ),
      );
    }

    final safeItems = List<TopMedicine>.from(items)
      ..sort((a, b) => b.used.compareTo(a.used));

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(54),
          theme: pw.ThemeData.withFont(base: font, bold: font),
        ),
        header: (_) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Dishari - Medicine Usage Report',
              style: baseStyle.copyWith(fontWeight: pw.FontWeight.bold),
            ),
            pw.Text('Generated: ${fmt(DateTime.now())}', style: smallMuted),
          ],
        ),
        build: (_) {
          return [
            pw.SizedBox(height: 12),
            pw.Text('Medicine Usage (Date Range)', style: h1),
            pw.SizedBox(height: 6),
            pw.Text('From: ${fmt(from)}    To: ${fmt(to)}', style: smallMuted),
            pw.SizedBox(height: 16),
            pw.Text('Summary', style: h2),
            pw.SizedBox(height: 6),
            pw.Text(
              'Total unique medicines: ${safeItems.length}',
              style: baseStyle.copyWith(fontSize: 11),
            ),
            pw.SizedBox(height: 14),
            pw.Text('Medicines', style: h2),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    tableCell('Medicine', isHeader: true),
                    tableCell('Used Qty', isHeader: true),
                  ],
                ),
                ...safeItems.map(
                  (m) => pw.TableRow(
                    children: [
                      tableCell(m.medicineName),
                      tableCell(m.used.toString()),
                    ],
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  static Future<void> exportDashboardAsPDF({
    required DashboardAnalytics analytics,
    required pw.Font font,
    required int selectedMonthIndex,
    required List<String> months,
  }) async {
    final pdf = pw.Document();
    final monthData = analytics.monthlyBreakdown[selectedMonthIndex];

    // Colors and styles
    const primary = PdfColors.indigo;
    const success = PdfColors.teal;
    const muted = PdfColors.grey600;

    final baseStyle = pw.TextStyle(font: font);
    final h2 = baseStyle.copyWith(fontSize: 16, fontWeight: pw.FontWeight.bold);
    final body = baseStyle.copyWith(fontSize: 11, color: PdfColors.black);
    final smallMuted = baseStyle.copyWith(fontSize: 9, color: muted);
    pw.Widget buildWatermark() {
      return pw.Center(
        child: pw.Transform.rotate(
          angle: math.pi / 4,
          child: pw.Opacity(
            opacity: 0.10,
            child: pw.Text(
              'NSTU MEDICAL CENTER REPORT',
              style: pw.TextStyle(
                fontSize: 40,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey600,
              ),
            ),
          ),
        ),
      );
    }

    pw.Widget sectionTitle(String title) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: h2),
          pw.SizedBox(height: 4),
          // pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 8),
        ],
      );
    }

    pw.Widget tableCell(String text, {bool isHeader = false}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.all(8),
        child: pw.Text(
          text,
          style: isHeader
              ? baseStyle.copyWith(fontWeight: pw.FontWeight.bold)
              : body,
          textAlign: pw.TextAlign.center,
        ),
      );
    }

    final diseasesData = [
      {'label': 'Flu', 'value': 35.0, 'color': PdfColors.blue},
      {'label': 'Fever', 'value': 25.0, 'color': PdfColors.orange},
      {'label': 'Cold', 'value': 20.0, 'color': PdfColors.teal},
      {'label': 'Others', 'value': 20.0, 'color': PdfColors.red},
    ];

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(70),
          theme: pw.ThemeData.withFont(base: font, bold: font),
          buildBackground: (context) =>
              pw.FullPage(ignoreMargins: true, child: buildWatermark()),
        ),
        header: (ctx) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Dishari - Admin Dashboard',
                style: baseStyle.copyWith(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                'Report Generated: ${_fmtDate(DateTime.now())}',
                style: smallMuted,
              ),
            ],
          ),
        ),
        build: (context) {
          final ratio =
              (analytics.patientCount /
                      (analytics.doctorCount == 0 ? 1 : analytics.doctorCount))
                  .toStringAsFixed(0);

          return [
            // 1. Header Banner
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: primary,
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Dashboard Analytics',
                        style: baseStyle.copyWith(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.Text(
                        'Overview of patients, activity and inventory',
                        style: baseStyle.copyWith(
                          color: PdfColors.white,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  pw.Text(
                    'Month: ${months[selectedMonthIndex]}',
                    style: baseStyle.copyWith(
                      color: PdfColors.white,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // 2. Key Metrics
            // 2. Key Metrics (CHANGED TO TABLE)
            sectionTitle('Key Metrics'),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                // Header Row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    tableCell('Total Patients', isHeader: true),
                    tableCell('Outpatients', isHeader: true),
                    tableCell('Medicines Dispensed', isHeader: true),
                    tableCell('Prescriptions', isHeader: true),
                  ],
                ),
                // Data Row
                pw.TableRow(
                  children: [
                    tableCell('${analytics.totalPatients}'),
                    tableCell('${analytics.outPatients}'),
                    tableCell('${analytics.medicinesDispensed}'),
                    tableCell('${analytics.totalPrescriptions}'),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // 3. Prescription Activity (CHANGED TO TABLE)
            sectionTitle('Prescription Activity'),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                // Header Row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    tableCell('Today', isHeader: true),
                    tableCell('This Week', isHeader: true),
                    tableCell('This Month', isHeader: true),
                    tableCell('This Year', isHeader: true),
                  ],
                ),
                // Data Row
                pw.TableRow(
                  children: [
                    tableCell('${analytics.prescriptionStats.today}'),
                    tableCell('${analytics.prescriptionStats.week}'),
                    tableCell('${analytics.prescriptionStats.month}'),
                    tableCell('${analytics.prescriptionStats.year}'),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 25),

            // 4. Doctor-Patient Ratio
            sectionTitle('Doctor-Patient Ratio'),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total Doctors: ${analytics.doctorCount}', style: body),
                pw.Text(
                  'Total Patients: ${analytics.patientCount}',
                  style: body,
                ),
                pw.Text(
                  'Ratio: 1 : $ratio',
                  style: body.copyWith(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.amber800,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Container(
              height: 10,
              width: double.infinity,
              decoration: pw.BoxDecoration(
                borderRadius: pw.BorderRadius.circular(5),
                color: PdfColors.grey200,
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    flex: analytics.doctorCount,
                    child: pw.Container(
                      decoration: pw.BoxDecoration(
                        color: PdfColors.indigo,
                        borderRadius: pw.BorderRadius.circular(5),
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: analytics.patientCount,
                    child: pw.Container(
                      decoration: pw.BoxDecoration(
                        color: success,
                        borderRadius: pw.BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 25),

            // 5. Monthly Breakdown
            sectionTitle('Lab Tests Breakdown (${months[selectedMonthIndex]})'),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'Category',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'Count / Total (taka)',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                ...[
                  ['Student', monthData.student],
                  ['Teacher/Family', monthData.teacher],
                  ['Outside', monthData.outside],
                  ['Total Patients', monthData.total],
                  [
                    'Total (taka)',
                    '${monthData.revenue.toStringAsFixed(0)} taka',
                  ],
                ].map(
                  (r) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(r[0].toString(), style: body),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(r[1].toString(), style: body),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 25),

            // 6. Top Diseases
            sectionTitle('Disease Trending'),
            pw.Row(
              children: [
                pw.SizedBox(
                  width: 100,
                  height: 100,
                  child: pw.Chart(
                    grid: pw.PieGrid(),
                    datasets: diseasesData
                        .map(
                          (e) => pw.PieDataSet(
                            value: e['value'] as double,
                            color: e['color'] as PdfColor,
                            drawSurface: true,
                          ),
                        )
                        .toList(),
                  ),
                ),
                pw.SizedBox(width: 40),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: diseasesData
                      .map(
                        (e) => pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 2),
                          child: pw.Row(
                            children: [
                              pw.Container(
                                width: 8,
                                height: 8,
                                decoration: pw.BoxDecoration(
                                  color: e['color'] as PdfColor,
                                  shape: pw.BoxShape.circle,
                                ),
                              ),
                              pw.SizedBox(width: 8),
                              pw.Text(
                                '${e['label']}: ${e['value']}%',
                                style: body,
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
            pw.SizedBox(height: 25),

            // 7. Stock Report
            sectionTitle('Stock Report'),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'Medicine',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'Current',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'Used',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'Status',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                ...analytics.stockReport.map((item) {
                  final denom = (item.used + item.current).toDouble();
                  final double usedRate = denom <= 0
                      ? 0.0
                      : (item.used / denom) * 100;
                  final bool isOut = item.current <= 0;
                  final bool isLow = !isOut && usedRate >= 70;
                  final statusText = isOut ? 'Out' : (isLow ? 'Low' : 'Good');
                  final statusColor = isOut
                      ? PdfColors.grey
                      : (isLow ? PdfColors.red : PdfColors.green);

                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(item.itemName, style: body),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('${item.current}', style: body),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('${item.used}', style: body),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          '$statusText (${usedRate.toStringAsFixed(0)}%)',
                          style: body.copyWith(color: statusColor),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
}

class InventoryTransactionReportRow {
  InventoryTransactionReportRow({
    required this.time,
    required this.itemName,
    required this.unit,
    required this.type,
    required this.quantity,
  });

  final DateTime time;
  final String itemName;
  final String unit;
  final String type;
  final int quantity;
}

class _InventoryAgg {
  _InventoryAgg({required this.name, required this.unit});

  final String name;
  final String unit;
  int totalIn = 0;
  int totalOut = 0;
  int entries = 0;
}
