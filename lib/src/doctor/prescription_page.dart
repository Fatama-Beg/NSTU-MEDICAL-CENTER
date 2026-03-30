import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:backend_client/backend_client.dart';
import 'package:bangla_pdf_fixer/bangla_pdf_fixer.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dosage_times.dart';

// DESIGN: central theme colors and typography for this page
const Color _accent = Color(0xFF0EA5A5); // teal-ish
const Color _muted = Color(0xFF6B7280);

TextStyle _titleStyle = const TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.w700,
  color: Colors.black87,
);
TextStyle _sectionLabel = const TextStyle(
  fontWeight: FontWeight.w600,
  color: Colors.black87,
);
InputDecoration _roundedInputDecoration([String? hint]) => InputDecoration(
  hintText: hint,
  filled: true,
  fillColor: Colors.grey.shade50,
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: Colors.grey.shade200),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: _accent),
  ),
);

class Medicine {
  TextEditingController nameController = TextEditingController();
  TextEditingController durationController = TextEditingController();
  TextEditingController mealTimeController = TextEditingController();

  Map<String, bool> times = {'সকাল': true, 'দুপুর': true, 'রাত': true};
  bool isFourTimes = false;

  // only before / after
  String? mealTiming = 'after';

  // UI only
  String durationUnit = 'দিন';
}

class PrescriptionPage extends StatefulWidget {
  final String? initialPatientName;
  final String? initialPatientNumber;
  final String? initialPatientGender;
  final int? initialPatientAge;
  final List<PatientPrescribedItem>? initialPrescribedItems;

  const PrescriptionPage({
    super.key,
    this.initialPatientName,
    this.initialPatientNumber,
    this.initialPatientGender,
    this.initialPatientAge,
    this.initialPrescribedItems,
  });

  @override
  State<PrescriptionPage> createState() => _PrescriptionPageState();
}

class _PrescriptionPageState extends State<PrescriptionPage> {
  // patient controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _rollController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  String? _selectedGender;

  bool _isNormalizingPhone = false;

  // whether the current prescription has been successfully saved
  bool _isSaved = false;

  // Validation error messages for patient fields
  String? _nameError;
  String? _numberError;
  String? _ageError;
  String? _genderError;

  // Per-medicine validation errors (parallel to _medicineRows)
  List<String?> _medicineNameErrors = [];
  List<String?> _medicineDurationErrors = [];
  List<String?> _medicineDosageErrors = [];
  List<String?> _medicineMealErrors = [];

  // Doctor info for signature display
  String? _doctorSignatureUrl;
  String? _doctorName;
  bool _loadingDoctorInfo = true;

  // clinical notes
  final TextEditingController _complainController = TextEditingController();
  final TextEditingController _examinationController = TextEditingController();
  final TextEditingController _adviceController = TextEditingController();
  final TextEditingController _testsController = TextEditingController();

  // prescriptions
  final List<Medicine> _medicineRows = [];

  // misc
  final TextEditingController _nextVisitController = TextEditingController();
  bool _isOutside = false;
  DateTime selectedDate = DateTime.now();

  // PDF assets/cache (used by print)
  Uint8List? _pdfLogoBytes;
  pw.Font? _pdfEnglishFont;
  bool _pdfAssetsReady = false;

  @override
  void initState() {
    super.initState();

    // Build medicine rows first (either from existing record, or at least one empty row)
    if (widget.initialPrescribedItems != null &&
        widget.initialPrescribedItems!.isNotEmpty) {
      _seedMedicinesFromExisting(widget.initialPrescribedItems!);
    } else {
      _addMedicineRow();
    }

    // Optional prefill (used when creating prescription from patient records)
    final name = widget.initialPatientName?.trim();
    if (name != null && name.isNotEmpty) {
      _nameController.text = name;
    }

    final number = widget.initialPatientNumber?.trim();
    if (number != null && number.isNotEmpty) {
      _rollController.text = number;
      // Prefill can come from search (may include +88/spaces/etc). Normalize once.
      _normalizePhoneNumber();
    }

    final age = widget.initialPatientAge;
    if (age != null) {
      _ageController.text = age.toString();
    }

    final genderRaw = widget.initialPatientGender?.trim();
    if (genderRaw != null && genderRaw.isNotEmpty) {
      final g = genderRaw.toLowerCase();
      if (g == 'male' || g == 'm' || g.startsWith('male')) {
        _selectedGender = 'Male';
        _genderController.text = 'Male';
      } else if (g == 'female' || g == 'f' || g.startsWith('female')) {
        _selectedGender = 'Female';
        _genderController.text = 'Female';
      }
    }

    // mark unsaved when any main field changes
    _nameController.addListener(_markUnsaved);
    _rollController.addListener(_markUnsaved);
    _rollController.addListener(_normalizePhoneNumber);
    _ageController.addListener(_markUnsaved);
    _genderController.addListener(_markUnsaved);
    _complainController.addListener(_markUnsaved);
    _examinationController.addListener(_markUnsaved);
    _adviceController.addListener(_markUnsaved);
    _testsController.addListener(_markUnsaved);
    _nextVisitController.addListener(_markUnsaved);
    // Load doctor info (name + signature) for display
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDoctorInfo();
    });
  }

  void _normalizePhoneNumber() {
    if (_isNormalizingPhone) return;
    _isNormalizingPhone = true;

    try {
      final raw = _rollController.text;
      final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
      final normalized = digits.length <= 11
          ? digits
          : digits.substring(digits.length - 11);

      if (normalized == raw) return;

      _rollController.value = TextEditingValue(
        text: normalized,
        selection: TextSelection.collapsed(offset: normalized.length),
      );
    } finally {
      _isNormalizingPhone = false;
    }
  }

  void _seedMedicinesFromExisting(List<PatientPrescribedItem> items) {
    // Avoid setState inside initState; just initialize lists.
    _medicineRows.clear();
    _medicineNameErrors.clear();
    _medicineDurationErrors.clear();
    _medicineDosageErrors.clear();
    _medicineMealErrors.clear();

    for (final it in items) {
      final m = Medicine();
      m.nameController.text = it.medicineName;
      if (it.duration != null) {
        m.durationController.text = it.duration.toString();
      }

      final dosageRaw = (it.dosageTimes ?? '').toString();
      if (dosageRaw.isNotEmpty) {
        if (isDosageFourTimes(dosageRaw)) {
          m.isFourTimes = true;
          m.times = {'সকাল': false, 'দুপুর': false, 'রাত': false};
        } else {
          m.times = decodeDosageTimesToBanglaMap(dosageRaw);
        }
        // If nothing matched:
        // - for numeric patterns like 0+0+0: keep as-is (so validation can catch it)
        // - for legacy/free-text patterns: default to all true
        final looksNumeric = RegExp(
          r'^\s*[01]\s*\+\s*[01]\s*\+\s*[01]\s*$',
        ).hasMatch(dosageRaw.trim());
        if (!m.isFourTimes && !m.times.values.any((v) => v) && !looksNumeric) {
          m.times = {'সকাল': true, 'দুপুর': true, 'রাত': true};
        }
      }

      final mealRaw = (it.mealTiming ?? '').toString().trim();
      if (mealRaw.isNotEmpty) {
        final lower = mealRaw.toLowerCase();
        if (lower.contains('before') || mealRaw.contains('আগে')) {
          m.mealTiming = 'before';
        } else if (lower.contains('after') || mealRaw.contains('পরে')) {
          m.mealTiming = 'after';
        }

        // Best-effort: keep any time portion in the UI field
        var timePart = mealRaw
            .replaceAll('before', '')
            .replaceAll('after', '')
            .replaceAll('খাবার আগে', '')
            .replaceAll('খাবার পরে', '')
            .replaceAll('আগে', '')
            .replaceAll('পরে', '')
            .trim();
        if (timePart.isNotEmpty) {
          m.mealTimeController.text = timePart;
        }
      }

      _medicineRows.add(m);
      _medicineNameErrors.add(null);
      _medicineDurationErrors.add(null);
      _medicineDosageErrors.add(null);
      _medicineMealErrors.add(null);

      m.nameController.addListener(_markUnsaved);
      m.durationController.addListener(_markUnsaved);
      m.mealTimeController.addListener(_markUnsaved);
    }

    if (_medicineRows.isEmpty) {
      _addMedicineRow();
    }
  }

  Future<void> _loadDoctorInfo() async {
    try {
      // Backend resolves doctorId from authenticated session
      final info = await client.doctor.getDoctorInfo();
      setState(() {
        _doctorName = info['name'] ?? '';
        // server returns signature under key 'signature' (prescription_page.dart uses this)
        _doctorSignatureUrl =
            info['signature'] ?? info['signatureUrl'] ?? info['signature_url'];
      });
    } catch (e) {
      debugPrint('Failed to load doctor info: $e');
    } finally {
      if (mounted) setState(() => _loadingDoctorInfo = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rollController.dispose();
    _ageController.dispose();
    _genderController.dispose();
    _complainController.dispose();
    _examinationController.dispose();
    _adviceController.dispose();
    _testsController.dispose();
    _nextVisitController.dispose();
    for (var m in _medicineRows) {
      m.nameController.dispose();
      m.durationController.dispose();
      m.mealTimeController.dispose();
    }
    super.dispose();
  }

  void _addMedicineRow() {
    setState(() {
      _medicineRows.add(Medicine());
      // keep error arrays in sync
      _medicineNameErrors.add(null);
      _medicineDurationErrors.add(null);
      _medicineDosageErrors.add(null);
      _medicineMealErrors.add(null);
      // listen to medicine fields to mark unsaved
      final m = _medicineRows.last;
      m.nameController.addListener(_markUnsaved);
      m.durationController.addListener(_markUnsaved);
      m.mealTimeController.addListener(_markUnsaved);
    });
  }

  void _clearForm() {
    setState(() {
      _nameController.clear();
      _rollController.clear();
      _ageController.clear();
      _genderController.clear();
      _selectedGender = null;
      // clear patient errors
      _nameError = null;
      _numberError = null;
      _ageError = null;
      _genderError = null;

      _complainController.clear();
      _examinationController.clear();
      _adviceController.clear();
      _testsController.clear();
      _nextVisitController.clear();
      for (var m in _medicineRows) {
        m.nameController.clear();
        m.durationController.clear();
        m.times = {'সকাল': true, 'দুপুর': true, 'রাত': true};
        m.isFourTimes = false;
        m.mealTiming = 'after';
        m.mealTimeController.clear();
        m.durationUnit = 'দিন';
      }
      // reset medicine errors
      _medicineNameErrors = List<String?>.filled(_medicineRows.length, null);
      _medicineDurationErrors = List<String?>.filled(
        _medicineRows.length,
        null,
      );
      _medicineDosageErrors = List<String?>.filled(_medicineRows.length, null);
      _medicineMealErrors = List<String?>.filled(_medicineRows.length, null);
      if (_medicineRows.isEmpty) _addMedicineRow();
      // clearing makes the form unsaved
      _isSaved = false;
    });
  }

  bool _hasBangla(String? s) =>
      s != null && RegExp(r'[\u0980-\u09FF]').hasMatch(s);

  Future<void> _ensurePdfAssetsReady() async {
    if (_pdfAssetsReady) return;
    await BanglaFontManager().initialize();

    try {
      final logo = await rootBundle.load('assets/images/nstu_logo.jpg');
      _pdfLogoBytes = logo.buffer.asUint8List();
    } catch (_) {
      _pdfLogoBytes = null;
    }

    try {
      final fontData = await rootBundle.load(
        'assets/fonts/OpenSans-VariableFont.ttf',
      );
      _pdfEnglishFont = pw.Font.ttf(fontData);
    } catch (_) {
      _pdfEnglishFont = null;
    }

    _pdfAssetsReady = true;
  }

  pw.Widget _pdfSectionTitle(String title, pw.TextStyle style) =>
      pw.Text(title, style: style.copyWith(fontWeight: pw.FontWeight.bold));

  pw.Widget _pdfContentBox(String? text, pw.TextStyle style) {
    if (text == null || text.trim().isEmpty) return pw.SizedBox(height: 10);
    if (_hasBangla(text)) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 10, left: 4),
        child: BanglaText(text, fontSize: 11),
      );
    }
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10, left: 4),
      child: pw.Text(text, style: style.copyWith(fontSize: 11)),
    );
  }

  pw.Widget _pdfHeader(pw.TextStyle style) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        if (_pdfLogoBytes != null)
          pw.Image(pw.MemoryImage(_pdfLogoBytes!), width: 70, height: 70),
        pw.SizedBox(width: 10),
        pw.Column(
          children: [
            BanglaText('মেডিকেল সেন্টার', fontSize: 12),
            BanglaText(
              'নোয়াখালী বিজ্ঞান ও প্রযুক্তি বিশ্ববিদ্যালয়',
              fontSize: 14,
            ),
            pw.Text(
              'Noakhali Science and Technology University',
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

  pw.Widget _pdfPatientInfo(pw.TextStyle style) {
    final dateStr =
        '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}';

    final name = _nameController.text.trim();
    final age = _ageController.text.trim();
    final gender = _selectedGender ?? '';
    final mobile = _rollController.text.trim();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Name: $name',
              style: style.copyWith(fontWeight: pw.FontWeight.bold),
            ),
            pw.Text('Date: $dateStr', style: style),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Mobile: +88$mobile',
              style: style.copyWith(fontWeight: pw.FontWeight.bold),
            ),
            pw.Text('Age: $age', style: style),
            pw.Text('Gender: $gender', style: style),
          ],
        ),
      ],
    );
  }

  pw.Widget _pdfLeftSection(pw.TextStyle style) {
    final sections = <pw.Widget>[];

    void addSection(String title, String? value) {
      if (value != null && value.trim().isNotEmpty) {
        sections.add(_pdfSectionTitle(title, style));
        sections.add(_pdfContentBox(value, style));
      }
    }

    addSection('C/C:', _complainController.text.trim());
    addSection('O/E:', _examinationController.text.trim());
    addSection('Advice:', _adviceController.text.trim());
    addSection('Inv:', _testsController.text.trim());

    return pw.Expanded(
      flex: 2,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: sections,
      ),
    );
  }

  pw.Widget _pdfRxSection(pw.TextStyle style) {
    String mealTimingToDisplay(String? mealTiming) {
      final raw = (mealTiming ?? '').trim();
      if (raw.isEmpty) return '';
      if (raw == 'before') return 'খাবার আগে';
      if (raw == 'after') return 'খাবার পরে';
      return raw;
    }

    return pw.Expanded(
      flex: 5,
      child: pw.Padding(
        padding: const pw.EdgeInsets.only(left: 10),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Rx:',
              style: style.copyWith(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            ..._medicineRows.asMap().entries.map((entry) {
              final m = entry.value;
              final medName = m.nameController.text.trim();
              final four = m.isFourTimes;
              final dosageRaw = m.times.entries
                  .where((e) => e.value)
                  .map((e) => e.key)
                  .join(', ');
              final dosage = four
                  ? '4'
                  : (dosageRaw.isNotEmpty ? dosageRaw : '-');

              final timePart = m.mealTimeController.text.trim();
              final timing = mealTimingToDisplay(m.mealTiming);
              final meal = [
                if (timePart.isNotEmpty) timePart,
                if (timing.isNotEmpty) timing,
              ].join(' ');

              final durationVal = m.durationController.text.trim();
              final durationDays = durationVal.isEmpty
                  ? ''
                  : durationVal; // keep same as patient format => show as Days

              pw.Widget t(String value) {
                if (value.trim().isEmpty) return pw.SizedBox();
                if (_hasBangla(value)) return BanglaText(value, fontSize: 11);
                return pw.Text(value, style: style.copyWith(fontSize: 11));
              }

              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Row(
                  children: [
                    pw.Expanded(child: t(medName)),
                    pw.Expanded(child: t(dosage)),
                    pw.Expanded(child: t(meal)),
                    pw.Expanded(
                      child: () {
                        if (durationDays.isEmpty) return pw.SizedBox();
                        final display = '$durationDays Days';
                        return t(display);
                      }(),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<Uint8List> _buildPrescriptionPdfBytesLikePatient() async {
    await _ensurePdfAssetsReady();

    Uint8List? signatureBytes;
    final sig = _doctorSignatureUrl;
    if (sig != null && sig.startsWith('http')) {
      try {
        signatureBytes = (await networkImage(sig)) as Uint8List?;
      } catch (_) {
        signatureBytes = null;
      }
    }

    final pdf = pw.Document();
    final baseTextStyle = pw.TextStyle(
      fontSize: 12,
      font: _pdfEnglishFont ?? pw.Font.helvetica(),
    );

    final nextVisit = _nextVisitController.text.trim();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _pdfHeader(baseTextStyle),
              pw.Divider(thickness: 1, color: PdfColors.grey400),
              _pdfPatientInfo(baseTextStyle),
              pw.Divider(thickness: 1, color: PdfColors.grey400),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _pdfLeftSection(baseTextStyle),
                  pw.VerticalDivider(thickness: 1, color: PdfColors.black),
                  _pdfRxSection(baseTextStyle),
                ],
              ),
              pw.Spacer(),
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 20),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    if (nextVisit.isNotEmpty)
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
                                'পরবর্তী সাক্ষাৎ: $nextVisit',
                                fontSize: 11,
                                color: PdfColors.blue900,
                              )
                            : pw.Text(
                                'Next Visit: $nextVisit',
                                style: baseTextStyle.copyWith(
                                  fontSize: 11,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.blue900,
                                ),
                              ),
                      ),
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
                        pw.Container(
                          width: 120,
                          height: 1,
                          color: PdfColors.grey700,
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Doctor Name: ${_doctorName ?? ''}',
                          style: baseTextStyle.copyWith(
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<int> _submitPrescriptionToServer() async {
    if (!_validateForm()) return 0;

    // 1. Process Next Visit Text
    final rawNext = _nextVisitController.text.trim();
    String? formattedNextVisit = rawNext.isEmpty ? null : rawNext;

    // 2. Create Prescription Object
    final prescription = Prescription(
      // Backend takes doctor id from authenticated session
      doctorId: 0,
      name: _nameController.text.trim(),
      age: int.tryParse(_ageController.text.trim()),
      mobileNumber: '+88${_rollController.text.trim()}',
      gender: _selectedGender,
      prescriptionDate: DateTime.now(),
      cc: _complainController.text.trim(),
      oe: _examinationController.text.trim(),
      advice: _adviceController.text.trim(),
      test: _testsController.text.trim(),
      nextVisit: formattedNextVisit,
      isOutside: _isOutside,
    );

    // 3. Process Medicine Items
    final items = <PrescribedItem>[];
    for (var m in _medicineRows) {
      if (m.nameController.text.trim().isEmpty) continue;

      // Combine time and timing (e.g., "30 min before")
      String? mealTiming;
      if (m.mealTiming != null) {
        final timeVal = m.mealTimeController.text.trim();
        mealTiming = timeVal.isEmpty
            ? m.mealTiming
            : '$timeVal ${m.mealTiming}';
      }

      // Calculate duration in days (DB expects INTEGER)
      int? durationInDays = int.tryParse(m.durationController.text.trim());
      if (durationInDays != null && m.durationUnit == 'মাস') {
        durationInDays = durationInDays * 30;
      }

      // Format Dosage (DB storage format: 1+0+1)
      final dosage = encodeDosageTimes(times: m.times, four: m.isFourTimes);

      items.add(
        PrescribedItem(
          prescriptionId: 0,
          medicineName: m.nameController.text.trim(),
          dosageTimes: dosage,
          mealTiming: mealTiming,
          duration: durationInDays,
        ),
      );
    }

    // 4. Send to Backend
    return client.doctor.createPrescription(
      prescription,
      items,
      _rollController.text.trim(),
    );
  }

  Future<void> _handlePrint() async {
    try {
      // 1) Save first
      final resultId = await _submitPrescriptionToServer();
      if (resultId <= 0) return;

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saved. Opening print...')));

      // 2) Build PDF (patient_prescriptions.dart format)
      final bytes = await _buildPrescriptionPdfBytesLikePatient();
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: 'Prescription_$resultId.pdf',
      );

      // 3) Clear after print
      _clearForm();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Print failed: $e')));
    }
  }

  void _markUnsaved() {
    if (_isSaved) {
      setState(() {
        _isSaved = false;
      });
    }
  }

  /// Validate the form. Returns true if valid, otherwise sets error messages and returns false.
  bool _validateForm() {
    bool ok = true;

    // reset errors
    _nameError = null;
    _numberError = null;
    _ageError = null;
    _genderError = null;
    _medicineNameErrors = List<String?>.filled(_medicineRows.length, null);
    _medicineDurationErrors = List<String?>.filled(_medicineRows.length, null);
    _medicineDosageErrors = List<String?>.filled(_medicineRows.length, null);
    _medicineMealErrors = List<String?>.filled(_medicineRows.length, null);

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _nameError = 'Name is required';
      ok = false;
    }

    // Inside _validateForm()
    final number = _rollController.text.trim(); // should be 11 digits
    if (number.isEmpty) {
      _numberError = 'Number is required';
      ok = false;
    } else if (number.length != 11) {
      _numberError = 'Number must be 11 digits';
      ok = false;
    } else if (!number.startsWith('01')) {
      _numberError = 'Number must start with 01';
      ok = false;
    }

    final age = _ageController.text.trim();
    if (age.isEmpty) {
      _ageError = 'Age is required';
      ok = false;
    }

    if (_selectedGender == null || _selectedGender!.isEmpty) {
      _genderError = 'Gender is required';
      ok = false;
    }

    // At least one medicine with a name
    bool hasMedicine = false;
    for (var i = 0; i < _medicineRows.length; i++) {
      final m = _medicineRows[i];
      final mName = m.nameController.text.trim();
      if (mName.isNotEmpty) hasMedicine = true;

      if (mName.isEmpty) {
        _medicineNameErrors[i] = 'Medicine name is required';
        ok = false;
      }

      // duration required
      final dur = m.durationController.text.trim();
      if (dur.isEmpty) {
        _medicineDurationErrors[i] = 'Duration is required';
        ok = false;
      } else if (int.tryParse(dur) == null) {
        _medicineDurationErrors[i] = 'Duration must be a number';
        ok = false;
      }

      // meal timing required (khabar age/por)
      if (m.mealTiming == null || m.mealTiming!.isEmpty) {
        _medicineMealErrors[i] = 'Select খাবার আগে/পরে';
        ok = false;
      }

      // dosage times required: either 4-times selected OR at least one of সকাল/দুপুর/রাত
      final hasAnyDose = m.isFourTimes || m.times.values.any((v) => v == true);
      if (!hasAnyDose) {
        _medicineDosageErrors[i] = 'Select সকাল/দুপুর/রাত';
        ok = false;
      }
    }

    if (!hasMedicine) {
      // mark first medicine name error as general
      if (_medicineRows.isNotEmpty) {
        _medicineNameErrors[0] = 'Add at least one medicine';
      }
      ok = false;
    }

    setState(() {});
    return ok;
  }

  void _savePrescription() async {
    try {
      final resultId = await _submitPrescriptionToServer();

      if (resultId > 0) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prescription saved successfully!')),
        );
        _clearForm();
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all required fields')),
        );
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _buildLargeCard({required String title, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(colors: [Colors.white, Colors.grey.shade50]),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: Colors.white,
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _accent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(title, style: _titleStyle),
                ],
              ),
            ),
            Padding(padding: const EdgeInsets.all(14), child: child),
          ],
        ),
      ),
    );
  }

  Widget _buildTextArea(TextEditingController controller, {String hint = ''}) {
    return TextField(
      controller: controller,
      maxLines: null,
      scrollPadding: const EdgeInsets.only(bottom: 220),
      decoration: _roundedInputDecoration(hint),
    );
  }

  // Modified to accept an optional index and display a small numbered badge
  Widget _buildMedicineCard(Medicine medicine, [int? index]) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (index != null)
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _accent.withAlpha(31),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _accent,
                      ),
                    ),
                  ),
                ),
              if (index != null) const SizedBox(width: 12),
              Text('Medication Name', style: _sectionLabel),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: medicine.nameController,
            scrollPadding: const EdgeInsets.only(bottom: 220),
            decoration: _roundedInputDecoration('Medicine name'),
          ),
          if (_medicineNameErrors[index ?? 0] != null) ...[
            const SizedBox(height: 6),
            Text(
              _medicineNameErrors[index ?? 0]!,
              style: TextStyle(color: Colors.red.shade600, fontSize: 12),
            ),
          ],
          const SizedBox(height: 10),
          Text('Dosage Times', style: _sectionLabel),
          const SizedBox(height: 6),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: Checkbox(
                      value: medicine.isFourTimes,
                      onChanged: (v) => setState(() {
                        medicine.isFourTimes = v ?? false;
                        if (medicine.isFourTimes) {
                          medicine.times = {
                            'সকাল': false,
                            'দুপুর': false,
                            'রাত': false,
                          };
                        }
                        _markUnsaved();
                      }),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('4', style: TextStyle(color: _muted)),
                ],
              ),
              ...medicine.times.keys.map((key) {
                final enabled = !medicine.isFourTimes;
                return Opacity(
                  opacity: enabled ? 1 : 0.45,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 15,
                        child: Checkbox(
                          value: medicine.times[key],
                          onChanged: enabled
                              ? (v) => setState(() {
                                  medicine.isFourTimes = false;
                                  medicine.times[key] = v ?? false;
                                  _markUnsaved();
                                })
                              : null,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(key, style: const TextStyle(color: _muted)),
                    ],
                  ),
                );
              }),
            ],
          ),
          if (_medicineDosageErrors[index ?? 0] != null) ...[
            const SizedBox(height: 6),
            Text(
              _medicineDosageErrors[index ?? 0]!,
              style: TextStyle(color: Colors.red.shade600, fontSize: 12),
            ),
          ],
          const SizedBox(height: 10),
          // Insert a small "time" input field (hint: "time") before meal timing radios
          Row(
            children: [
              SizedBox(
                width: 110,
                child: TextField(
                  controller: medicine.mealTimeController,
                  scrollPadding: const EdgeInsets.only(bottom: 220),
                  decoration: InputDecoration(
                    hintText: 'time',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: _accent),
                    ),
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Radio<String>(
                            value: 'before',
                            groupValue: medicine.mealTiming,
                            onChanged: (v) => setState(() {
                              medicine.mealTiming = v;
                              _markUnsaved();
                            }),
                          ),
                          const Text('খাবার আগে'),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Radio<String>(
                            value: 'after',
                            groupValue: medicine.mealTiming,
                            onChanged: (v) => setState(() {
                              medicine.mealTiming = v;
                              _markUnsaved();
                            }),
                          ),
                          const Text('খাবার পরে'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_medicineMealErrors[index ?? 0] != null) ...[
            const SizedBox(height: 6),
            Text(
              _medicineMealErrors[index ?? 0]!,
              style: TextStyle(color: Colors.red.shade600, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 110,
                child: TextField(
                  controller: medicine.durationController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  scrollPadding: const EdgeInsets.only(bottom: 220),
                  decoration: _roundedInputDecoration('Duration'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Radio<String>(
                            value: 'দিন',
                            groupValue: medicine.durationUnit,
                            onChanged: (v) => setState(() {
                              medicine.durationUnit = v ?? 'দিন';
                              _markUnsaved();
                            }),
                          ),
                          const Text('দিন'),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Radio<String>(
                            value: 'মাস',
                            groupValue: medicine.durationUnit,
                            onChanged: (v) => setState(() {
                              medicine.durationUnit = v ?? 'দিন';
                              _markUnsaved();
                            }),
                          ),
                          const Text('মাস'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_medicineDurationErrors[index ?? 0] != null) ...[
            const SizedBox(height: 6),
            Text(
              _medicineDurationErrors[index ?? 0]!,
              style: TextStyle(color: Colors.red.shade600, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobileLayout = !kIsWeb && screenWidth < 600;
    final keyboardBottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text(
          'Prescription',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue,
        elevation: 1,
        actions: [
          IconButton(
            onPressed: _handlePrint,
            icon: const Icon(Icons.print),
            tooltip: 'Print',
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: keyboardBottomInset),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // University Logo
                      Image.asset(
                        'assets/images/nstu_logo.jpg',
                        height: screenWidth * 0.1,
                        width: screenWidth * 0.098,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.local_hospital, size: 40),
                      ),
                      const SizedBox(width: 8),

                      // University Text
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            "মেডিকেল সেন্টার",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "নোয়াখালী বিজ্ঞান ও প্রযুক্তি বিশ্ববিদ্যালয়",
                            style: TextStyle(fontSize: 14),
                          ),
                          Text(
                            "Noakhali Science and Technology University",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Patient Information card only contains patient fields and validation messages
                _buildLargeCard(
                  title: 'Patient Information',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔹 Row 1: Patient Name + Date
                      Row(
                        children: [
                          const Text(
                            'Patient Name:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            flex: 3,
                            child: TextField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                hintText: 'Enter patient name',
                                border: UnderlineInputBorder(),
                                contentPadding: EdgeInsets.only(bottom: 4),
                                isDense: true,
                              ),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Date:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            flex: 1,
                            child: Container(
                              padding: const EdgeInsets.only(bottom: 4),
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: Colors.black26),
                                ),
                              ),
                              child: Text(
                                "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      // Mobile: row2 number, row3 age+gender
                      // Web/desktop: keep existing one-row layout
                      if (isMobileLayout) ...[
                        // 🔹 Row 2 (Mobile): Number
                        Row(
                          children: [
                            const Text(
                              'Mobile No:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _rollController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                scrollPadding: const EdgeInsets.only(
                                  bottom: 220,
                                ),
                                decoration: InputDecoration(
                                  prefixText: "+88 ",
                                  prefixStyle: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  border: const UnderlineInputBorder(),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.only(
                                    bottom: 4,
                                  ),
                                ),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 15),

                        // 🔹 Row 3 (Mobile): Age + Gender
                        Row(
                          children: [
                            const Text(
                              'Age:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 70,
                              child: TextField(
                                controller: _ageController,
                                scrollPadding: const EdgeInsets.only(
                                  bottom: 220,
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'Age',
                                  border: UnderlineInputBorder(),
                                  contentPadding: EdgeInsets.only(bottom: 4),
                                  isDense: true,
                                ),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Text(
                              'Gender:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Wrap(
                                spacing: 12,
                                runSpacing: 6,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: Radio<String>(
                                          value: 'Male',
                                          groupValue: _selectedGender,
                                          onChanged: (v) {
                                            setState(() {
                                              _selectedGender = v;
                                              _genderController.text = v ?? '';
                                              _markUnsaved();
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text('M'),
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: Radio<String>(
                                          value: 'Female',
                                          groupValue: _selectedGender,
                                          onChanged: (v) {
                                            setState(() {
                                              _selectedGender = v;
                                              _genderController.text = v ?? '';
                                              _markUnsaved();
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text('F'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        // 🔹 Row 2 (Web/desktop): Number + Age + Gender
                        Row(
                          children: [
                            const Text(
                              'Mobile No:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              flex: 3,
                              child: TextField(
                                controller: _rollController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                scrollPadding: const EdgeInsets.only(
                                  bottom: 220,
                                ),
                                decoration: InputDecoration(
                                  prefixText: "+88 ",
                                  prefixStyle: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  border: const UnderlineInputBorder(),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.only(
                                    bottom: 4,
                                  ),
                                ),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Age:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              flex: 1,
                              child: TextField(
                                controller: _ageController,
                                scrollPadding: const EdgeInsets.only(
                                  bottom: 220,
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'Age',
                                  border: UnderlineInputBorder(),
                                  contentPadding: EdgeInsets.only(bottom: 4),
                                  isDense: true,
                                ),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Gender:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              flex: 2,
                              child: Wrap(
                                spacing: 12,
                                runSpacing: 6,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: Radio<String>(
                                          value: 'Male',
                                          groupValue: _selectedGender,
                                          onChanged: (v) {
                                            setState(() {
                                              _selectedGender = v;
                                              _genderController.text = v ?? '';
                                              _markUnsaved();
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text('M'),
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: Radio<String>(
                                          value: 'Female',
                                          groupValue: _selectedGender,
                                          onChanged: (v) {
                                            setState(() {
                                              _selectedGender = v;
                                              _genderController.text = v ?? '';
                                              _markUnsaved();
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text('F'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                      // Show patient validation errors (if any)
                      if (_nameError != null ||
                          _numberError != null ||
                          _ageError != null ||
                          _genderError != null) ...[
                        const SizedBox(height: 6),
                        if (_nameError != null)
                          Text(
                            _nameError!,
                            style: TextStyle(
                              color: Colors.red.shade600,
                              fontSize: 12,
                            ),
                          ),
                        if (_numberError != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _numberError!,
                            style: TextStyle(
                              color: Colors.red.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        if (_ageError != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _ageError!,
                            style: TextStyle(
                              color: Colors.red.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        if (_genderError != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _genderError!,
                            style: TextStyle(
                              color: Colors.red.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Clinical Details card (separate)
                _buildLargeCard(
                  title: 'Clinical Details',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔹 C/C Section
                      const Text(
                        'C/C',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildTextArea(
                        _complainController,
                        hint: 'Chief complaint',
                      ),
                      const SizedBox(height: 12),

                      // 🔹 O/E Section
                      const Text(
                        'O/E',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildTextArea(
                        _examinationController,
                        hint: 'On examination',
                      ),
                      const SizedBox(height: 12),

                      // 🔹 Advice Section
                      const Text(
                        'Adv',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildTextArea(_adviceController, hint: 'Advice'),
                      const SizedBox(height: 12),

                      // 🔹 Investigations Section
                      const Text(
                        'Inv',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildTextArea(_testsController, hint: 'Investigations'),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Rx full-width card (separate)
                _buildLargeCard(
                  title: 'Rx',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: _medicineRows
                            .asMap()
                            .entries
                            .map((e) => _buildMedicineCard(e.value, e.key))
                            .toList(),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ElevatedButton.icon(
                          onPressed: _addMedicineRow,
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('Add Medicine'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Signature & options (aligned underlines)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Left side: Outside checkbox + Next visit (underline)
                    Row(
                      children: [
                        Checkbox(
                          value: _isOutside,
                          onChanged: (v) => setState(() {
                            _isOutside = v ?? false;
                            _markUnsaved();
                          }),
                        ),
                        const SizedBox(width: 6),
                        const Text('Outside'),
                        const SizedBox(width: 12),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 100,
                              child: TextField(
                                controller: _nextVisitController,
                                keyboardType: TextInputType.number,
                                scrollPadding: const EdgeInsets.only(
                                  bottom: 260,
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'Next visit',
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 6,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: 100,
                              height: 1,
                              color: Colors.black,
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Right side: Signature with same underline width
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: 150,
                          height: 60,
                          child: _loadingDoctorInfo
                              ? const Center(
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : (_doctorSignatureUrl != null &&
                                    _doctorSignatureUrl!.startsWith('http'))
                              ? Image.network(
                                  _doctorSignatureUrl!,
                                  fit: BoxFit.contain,
                                  // ignore: unnecessary_underscores
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Text('Invalid signature'),
                                  ),
                                )
                              : const Center(
                                  child: Text('No signature uploaded'),
                                ),
                        ),
                        const SizedBox(height: 6),
                        // show doctor name under signature (if available)
                        SizedBox(
                          width: 160,
                          child: Text(
                            'Name: ${_doctorName ?? ''}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    ElevatedButton(
                      onPressed: _savePrescription,
                      style: ElevatedButton.styleFrom(
                        // Blue when saved, red when not saved
                        backgroundColor: _isSaved ? Colors.blue : Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        child: Text(
                          'Save',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: _clearForm,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: _accent),
                        foregroundColor: _accent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Text('Clear'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
