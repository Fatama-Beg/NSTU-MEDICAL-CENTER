import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:bangla_pdf_fixer/bangla_pdf_fixer.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:dishari/src/doctor/dosage_times.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:backend_client/backend_client.dart';
import 'package:printing/printing.dart';

import '../routing/route_refresh.dart';

class PatientPrescriptions extends StatefulWidget {
  const PatientPrescriptions({super.key});

  @override
  State<PatientPrescriptions> createState() => _PatientPrescriptionsPageState();
}

class _PatientPrescriptionsPageState extends State<PatientPrescriptions>
    with RouteRefreshMixin<PatientPrescriptions> {
  Uint8List? _logoBytes;
  bool _isLoading = true;
  bool _isDisposed = false;
  pw.Font? _englishFont;

  // ব্যাকেন্ড থেকে আসা প্রেসক্রিপশন লিস্ট
  List<PrescriptionList> _prescriptions = [];

  @override
  void initState() {
    super.initState();
    _loadResourcesAndData();
  }

  @override
  Future<void> refreshOnFocus() async {
    await _fetchPrescriptions();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (!_isDisposed && mounted) setState(fn);
  }

  // রিসোর্স লোড এবং ব্যাকেন্ড থেকে ডাটা আনা
  Future<void> _loadResourcesAndData() async {
    try {
      await Future.wait([
        BanglaFontManager().initialize(),
        _loadLogo(),
        _loadEnglishFont(),
      ]);
      await _fetchPrescriptions();
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      _safeSetState(() => _isLoading = false);
    }
  }

  // SharedPreferences থেকে ID নিয়ে সরাসরি প্রেসক্রিপশন লোড করা
  Future<void> _fetchPrescriptions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedUserId = prefs.getString('user_id');
      int? patientId = storedUserId != null ? int.tryParse(storedUserId) : null;
      // ignore: avoid_print
      print("Fetching data for Patient ID: $patientId"); // Debugging er jonno

      if (patientId != null) {
        final list = await client.patient.getPrescriptionsByPatientId(
          patientId,
        );

        print("Data found: ${list.length}"); // Check korun data asche kina

        // Sort by date descending (latest first). Handle possible null dates safely.
        list.sort((a, b) {
          final da = a.date;
          final db = b.date;
          return db.compareTo(da); // b vs a => descending
        });

        if (mounted) {
          setState(() {
            _prescriptions = list;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Fetch error: $e");
    }
  }

  Future<Uint8List?> _loadNetworkImage(String? url) async {
    if (url == null || url.isEmpty) return null;
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        debugPrint('Failed to load image: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error loading signature image: $e');
      return null;
    }
  }

  // ১. PDF এর জন্য ফুল ডিটেইলস নিয়ে আসা
  Future<void> _handleDownload(PrescriptionList item) async {
    _safeSetState(() => _isLoading = true);
    try {
      // ব্যাকেন্ড থেকে ফুল ডিটেইল আনা
      final detail = await client.patient.getPrescriptionDetail(
        item.prescriptionId,
      );
      if (detail != null) {
        await _downloadPrescriptionPDF(detail);
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      _safeSetState(() => _isLoading = false);
    }
  }

  // ২. আপনার বিদ্যমান স্ট্রাকচারে PDF জেনারেট করা
  Future<void> _downloadPrescriptionPDF(PrescriptionDetail detail) async {
    final pdf = pw.Document();
    final baseTextStyle = pw.TextStyle(
      fontSize: 12,
      font: _englishFont ?? pw.Font.helvetica(),
    );
    Uint8List? signatureBytes;
    if (detail.doctorSignatureUrl != null) {
      signatureBytes = await _loadNetworkImage(detail.doctorSignatureUrl);
    }

    // Pass it to _buildSignature via a parameter
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(baseTextStyle),
              pw.Divider(thickness: 1, color: PdfColors.grey400),
              _buildPatientInfo(detail, baseTextStyle),
              pw.Divider(thickness: 1, color: PdfColors.grey400),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildLeftSection(detail, baseTextStyle),
                  pw.VerticalDivider(thickness: 1, color: PdfColors.black),
                  _buildRxSection(detail, baseTextStyle),
                ],
              ),
              pw.Spacer(),
              _buildSignature(detail, baseTextStyle, signatureBytes),
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();
    final fileName = "Prescription_${detail.prescription.id}.pdf";

    // Use Printing to let users download/share reliably on mobile.
    await Printing.sharePdf(bytes: bytes, filename: fileName);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Prescription ready to save/share.')),
    );
  }

  pw.Widget _buildHeader(pw.TextStyle style) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        if (_logoBytes != null)
          pw.Image(pw.MemoryImage(_logoBytes!), width: 70, height: 70),
        pw.SizedBox(width: 10),
        pw.Column(
          children: [
            BanglaText('মেডিকেল সেন্টার', fontSize: 12),
            BanglaText(
              'নোয়াখালী বিজ্ঞান ও প্রযুক্তি বিশ্ববিদ্যালয়',
              fontSize: 14,
            ),
            pw.Text(
              "Noakhali Science and Technology University",
              style: style.copyWith(
                fontWeight: pw.FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildPatientInfo(PrescriptionDetail detail, pw.TextStyle style) {
    final date = detail.prescription.prescriptionDate;
    final dateStr = date != null
        ? "${date.day}/${date.month}/${date.year}"
        : "";

    final p = detail.prescription;

    final name = p.name ?? '';
    final age = p.age?.toString() ?? '';
    final gender = p.gender ?? '';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              "Name: $name",
              style: style.copyWith(fontWeight: pw.FontWeight.bold),
            ),
            pw.Text("Date: $dateStr", style: style),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              "Mobile: ${p.mobileNumber ?? ''}",
              style: style.copyWith(fontWeight: pw.FontWeight.bold),
            ),
            pw.Text("Age: $age", style: style),
            pw.Text("Gender: $gender", style: style),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildLeftSection(PrescriptionDetail detail, pw.TextStyle style) {
    final sections = <pw.Widget>[];

    void addSection(String title, String? value) {
      if (value != null && value.trim().isNotEmpty) {
        sections.add(_sectionTitle(title, style));
        sections.add(_contentBox(value, style));
      }
    }

    addSection("C/C:", detail.prescription.cc);
    addSection("O/E:", detail.prescription.oe);
    addSection("Advice:", detail.prescription.advice);
    addSection("Inv:", detail.prescription.test);

    return pw.Expanded(
      flex: 2,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: sections,
      ),
    );
  }

  pw.Widget _buildRxSection(PrescriptionDetail detail, pw.TextStyle style) {
    return pw.Expanded(
      flex: 5,
      child: pw.Padding(
        padding: const pw.EdgeInsets.only(left: 10),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              "Rx:",
              style: style.copyWith(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            ...detail.items.map(
              (item) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Row(
                  children: [
                    // Medicine Name: Bangla check
                    pw.Expanded(
                      child: () {
                        final medName = item.medicineName;
                        if (_hasBangla(medName)) {
                          return BanglaText(medName, fontSize: 11);
                        }
                        return pw.Text(
                          medName,
                          style: style.copyWith(fontSize: 11),
                        );
                      }(),
                    ),
                    // Dosage Times: Bangla check
                    pw.Expanded(
                      child: () {
                        final raw = item.dosageTimes ?? '';
                        final dosage = isDosageFourTimes(raw.trim())
                            ? 'দিনে ৪ বার'
                            : dosageTimesDisplayBangla(raw);
                        if (_hasBangla(dosage)) {
                          return BanglaText(dosage, fontSize: 11);
                        }
                        return pw.Text(
                          dosage,
                          style: style.copyWith(fontSize: 11),
                        );
                      }(),
                    ),
                    // Meal Timing: Bangla check
                    pw.Expanded(
                      child: () {
                        final meal = item.mealTiming ?? '';
                        if (meal.isEmpty) return pw.SizedBox();
                        if (_hasBangla(meal)) {
                          return BanglaText(meal, fontSize: 11);
                        }
                        return pw.Text(
                          meal,
                          style: style.copyWith(fontSize: 11),
                        );
                      }(),
                    ),

                    // Safely convert duration to String before checking for Bangla text
                    pw.Expanded(
                      child: () {
                        final String durationStr = item.duration == null
                            ? ''
                            : item.duration.toString();
                        if (_hasBangla(durationStr)) {
                          return BanglaText(durationStr, fontSize: 11);
                        }
                        // If empty, render an empty box-friendly text; otherwise show as e.g. '10 Days'
                        final display = durationStr.isEmpty
                            ? ''
                            : '$durationStr Days';
                        return pw.Text(
                          display,
                          style: style.copyWith(fontSize: 11),
                        );
                      }(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildSignature(
    PrescriptionDetail detail,
    pw.TextStyle style,
    Uint8List? signatureBytes,
  ) {
    final nextVisit = detail.prescription.nextVisit;

    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          // 🟦 LEFT: Next Visit (Bangla / English)
          if (nextVisit != null && nextVisit.trim().isNotEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6,
              ),
              decoration: pw.BoxDecoration(
                color: PdfColors.lightBlue100,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: _hasBangla(nextVisit)
                  ? BanglaText(
                      "পরবর্তী সাক্ষাৎ: $nextVisit",
                      fontSize: 11,
                      color: PdfColors.blue900,
                    )
                  : pw.Text(
                      "Next Visit: $nextVisit",
                      style: style.copyWith(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
            ),

          // ✍️ RIGHT: Doctor Signature
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (signatureBytes != null)
                pw.Image(
                  pw.MemoryImage(signatureBytes),
                  width: 120,
                  height: 50,
                ),
              pw.SizedBox(height: 4),
              pw.Container(width: 120, height: 1, color: PdfColors.grey700),
              pw.SizedBox(height: 4),
              pw.Text(
                "Doctor Name: ${detail.doctorName ?? ""}",
                style: style.copyWith(fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- UI Build (লিস্ট ভিউ) ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("My Prescriptions"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue,
      ),
      body: _isLoading && _prescriptions.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: refreshFromPull,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: _prescriptions.length,
                itemBuilder: (context, index) {
                  final item = _prescriptions[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: InkWell(
                      onTap: () => _handleDownload(item),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            // Serial number avatar
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.blue.shade50,
                              child: Text(
                                "${index + 1}",
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Main info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Dr. ${item.doctorName}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (item.revisedFromPrescriptionId != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        () {
                                          final type =
                                              (item.sourceReportType ?? '')
                                                  .trim();
                                          if (type.isNotEmpty) {
                                            return 'Updated for: $type';
                                          }
                                          final rid = item.sourceReportId;
                                          if (rid != null) {
                                            return 'Updated for Report #$rid';
                                          }
                                          return 'Updated prescription';
                                        }(),
                                        style: TextStyle(
                                          color: Colors.deepPurple.shade600,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Date: ${item.date.day}/${item.date.month}/${item.date.year}",
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Action button (keeps existing behavior)
                            ElevatedButton.icon(
                              onPressed: () => _handleDownload(item),
                              icon: const Icon(
                                Icons.download,
                                size: 18,
                                color: Colors.white,
                              ),
                              label: const Text(
                                "PDF",
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  // --- সাধারণ হেল্পার ফাংশন ---

  pw.Widget _sectionTitle(String title, pw.TextStyle style) =>
      pw.Text(title, style: style.copyWith(fontWeight: pw.FontWeight.bold));

  pw.Widget _contentBox(String? text, pw.TextStyle style) {
    if (text == null || text.isEmpty) return pw.SizedBox(height: 10);
    // Check if text contains Bangla
    if (_hasBangla(text)) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 10, left: 4),
        child: BanglaText(text, fontSize: 11),
      );
    } else {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 10, left: 4),
        child: pw.Text(text, style: style.copyWith(fontSize: 11)),
      );
    }
  }

  bool _hasBangla(String? s) =>
      s != null && RegExp(r'[\u0980-\u09FF]').hasMatch(s);

  Future<void> _loadLogo() async {
    final bytes = await rootBundle.load('assets/images/nstu_logo.jpg');
    _logoBytes = bytes.buffer.asUint8List();
  }

  Future<void> _loadEnglishFont() async {
    final data = await rootBundle.load(
      'assets/fonts/OpenSans-VariableFont.ttf',
    );
    _englishFont = pw.Font.ttf(data);
  }
}
