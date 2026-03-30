import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:flutter/material.dart';
// Clipboard
import 'package:backend_client/backend_client.dart'; // আপনার ক্লায়েন্ট ইমপোর্ট করুন
import 'dart:async';
// import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'pdf_view_page.dart'; // Abstraction
import '../core/download_pdf_image_from_link.dart';
import '../core/platform_temp_file.dart';
import '../routing/route_refresh.dart';
import 'dosage_times.dart';

class TestReportsView extends StatefulWidget {
  final int doctorId;
  final int? highlightReportId;
  final bool highlightAllUnreviewed;
  final DateTime? highlightUnreviewedSinceUtc;

  const TestReportsView({
    super.key,
    required this.doctorId,
    this.highlightReportId,
    this.highlightAllUnreviewed = false,
    this.highlightUnreviewedSinceUtc,
  });

  @override
  State<TestReportsView> createState() => _TestReportsViewState();
}

class _TestReportsViewState extends State<TestReportsView>
    with RouteRefreshMixin<TestReportsView> {
  List<PatientExternalReport> _reports = [];
  bool _isLoading = true;
  String? _error;
  final ScrollController _scrollController = ScrollController();
  int? _highlightReportId;
  late bool _highlightAllUnreviewed;
  DateTime? _highlightUnreviewedSinceUtc;
  final Map<int, GlobalKey> _reportItemKeys = <int, GlobalKey>{};
  bool sheetOpen = true;
  bool isPrefillLoading = true;
  bool isSubmitting = false;
  final TextEditingController adviceController = TextEditingController();
  final List<Map<String, dynamic>> itemCtrls = [];
  List<String?> nameErrors = [];
  List<String?> durationErrors = [];

  @override
  void initState() {
    super.initState();
    _highlightReportId = widget.highlightReportId;
    _highlightAllUnreviewed = widget.highlightAllUnreviewed;
    _highlightUnreviewedSinceUtc = widget.highlightUnreviewedSinceUtc;
    _fetchReports();
  }

  @override
  void didUpdateWidget(covariant TestReportsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.highlightReportId != widget.highlightReportId ||
        oldWidget.highlightAllUnreviewed != widget.highlightAllUnreviewed ||
        oldWidget.highlightUnreviewedSinceUtc !=
            widget.highlightUnreviewedSinceUtc) {
      _highlightReportId = widget.highlightReportId;
      _highlightAllUnreviewed = widget.highlightAllUnreviewed;
      _highlightUnreviewedSinceUtc = widget.highlightUnreviewedSinceUtc;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToHighlighted();
      });
    }
  }

  @override
  Future<void> refreshOnFocus() async {
    if (isSubmitting) return;
    await _fetchReports();
  }

  @override
  void dispose() {
    adviceController.dispose();

    _scrollController.dispose();

    for (final m in itemCtrls) {
      (m['name'] as TextEditingController?)?.dispose();
      (m['duration'] as TextEditingController?)?.dispose();
      (m['mealTime'] as TextEditingController?)?.dispose();
      (m['dosage'] as TextEditingController?)?.dispose();
      (m['mealTiming'] as ValueNotifier<String?>?)?.dispose();
    }

    super.dispose();
  }

  GlobalKey _keyForReportId(int reportId) {
    return _reportItemKeys.putIfAbsent(reportId, () => GlobalKey());
  }

  void _scrollToHighlighted() {
    int? targetReportId = _highlightReportId;

    if (targetReportId == null) {
      if (_highlightAllUnreviewed) {
        for (final r in _reports) {
          final id = r.reportId;
          if (id == null) continue;
          if (r.reviewed == true) continue;
          targetReportId = id;
          break;
        }
      }

      final since = _highlightUnreviewedSinceUtc;
      if (targetReportId == null && since != null) {
        for (final r in _reports) {
          final id = r.reportId;
          if (id == null) continue;
          if (r.reviewed == true) continue;
          final createdAt = r.createdAt;
          if (createdAt == null) continue;
          if (createdAt.toUtc().isBefore(since)) continue;
          targetReportId = id;
          break;
        }
      }
    }

    if (targetReportId == null) return;
    final key =
        _reportItemKeys[targetReportId] ?? _keyForReportId(targetReportId);
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      alignment: 0.25,
    );
  }

  bool _isPdf(String url) {
    return url.toLowerCase().endsWith('.pdf');
  }

  bool _isImage(String url) {
    return url.toLowerCase().endsWith('.jpg') ||
        url.toLowerCase().endsWith('.jpeg') ||
        url.toLowerCase().endsWith('.png') ||
        url.toLowerCase().endsWith('.webp');
  }

  Future<void> _openPdfInApp(String url) async {
    if (kIsWeb) {
      await launchUrl(Uri.parse(url));
      return;
    }
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Failed to load PDF');
      }

      final filePath = await writeTempFile(
        response.bodyBytes,
        fileName: 'report.pdf',
      );

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PdfViewPage(filePath: filePath)),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to open PDF: $e')));
    }
  }

  Future<void> _fetchReports() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Backend resolves doctorId from authenticated session
      final list = await client.doctor.getReportsForDoctor(0);
      if (!mounted) return;
      setState(() {
        _reports = List<PatientExternalReport>.from(list);
        _sortReports();
        _isLoading = false;
      });

      // After list is rendered, scroll & highlight the selected item (if any).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToHighlighted();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _sortReports() {
    _reports.sort((a, b) {
      final aReviewed = a.reviewed == true;
      final bReviewed = b.reviewed == true;
      if (aReviewed != bReviewed) {
        // Unreviewed first.
        return aReviewed ? 1 : -1;
      }

      final aCreated = a.createdAt;
      final bCreated = b.createdAt;
      if (aCreated != null && bCreated != null) {
        final cmp = bCreated.compareTo(aCreated); // newest first
        if (cmp != 0) return cmp;
      } else if (aCreated != null) {
        return -1;
      } else if (bCreated != null) {
        return 1;
      }

      final aId = a.reportId ?? -1;
      final bId = b.reportId ?? -1;
      return bId.compareTo(aId);
    });
  }

  // review a click korle bottom sheet UI (interactive)
  Widget _sectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: Colors.blue.shade700),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
      ],
    );
  }

  Future<void> _onReviewReport(PatientExternalReport report) async {
    if (report.reportId != null && report.reviewed != true) {
      if (mounted) {
        setState(() {
          report.reviewed = true;
          _sortReports();
        });
      }
      unawaited(
        // ignore: body_might_complete_normally_catch_error
        client.doctor.markReportReviewed(report.reportId!).catchError((_) {}),
      );
    }

    sheetOpen = true;
    isPrefillLoading = true;
    isSubmitting = false;
    itemCtrls.clear();
    if (report.prescriptionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This report has no prescription linked.'),
        ),
      );
      return;
    }

    void addEmptyRow() {
      setState(() {
        itemCtrls.add({
          'name': TextEditingController(),
          'duration': TextEditingController(),
          'mealTime': TextEditingController(),
          'mealTiming': ValueNotifier<String?>(null),
          'dosage': TextEditingController(),
        });
        nameErrors.add(null);
        durationErrors.add(null);
      });
    }

    // ensure at least one row exists so submit doesn't send empty list unintentionally
    void ensureAtLeastOneRow() {
      if (itemCtrls.isEmpty) addEmptyRow();
    }

    String normalizeWhitespace(String input) {
      return input.replaceAll(RegExp(r'\s+'), ' ').trim();
    }

    String normalizeDosageForStorage(String raw) {
      final normalized = raw.trim();
      if (normalized.isEmpty) return '';

      // Allow quick entry: "4" means special 4 times.
      if (normalized == '4') return '1+1+1+1';
      if (isDosageFourTimes(normalized)) return '1+1+1+1';

      // Convert Bangla/English text (e.g., "সকাল, রাত") to numeric storage format.
      final map = decodeDosageTimesToBanglaMap(normalized);
      final encoded = encodeDosageTimesFromBanglaMap(map);

      // If nothing selected (0+0+0), treat as empty.
      if (encoded == '0+0+0') return '';
      return encoded;
    }

    String buildSnapshotKey() {
      final advice = normalizeWhitespace(adviceController.text);

      final parts = <String>[];
      for (final m in itemCtrls) {
        final name = normalizeWhitespace(
          (m['name'] as TextEditingController).text,
        );
        if (name.isEmpty) continue;

        final durationText = normalizeWhitespace(
          (m['duration'] as TextEditingController).text,
        );
        final duration = int.tryParse(durationText);

        final dosage = normalizeWhitespace(
          (m['dosage'] as TextEditingController).text,
        );
        final dosageStorage = normalizeDosageForStorage(dosage);

        final mealTiming = (m['mealTiming'] as ValueNotifier<String?>).value;
        final mealTime = normalizeWhitespace(
          (m['mealTime'] as TextEditingController).text,
        );

        final normalizedTiming = (mealTiming != null && mealTiming.isNotEmpty)
            ? mealTiming
            : (mealTime.isNotEmpty ? 'before' : null);

        final combinedMealTiming =
            (normalizedTiming == null || normalizedTiming.isEmpty)
            ? ''
            : (mealTime.isEmpty
                  ? normalizedTiming
                  : '${mealTime.toLowerCase()} ${normalizedTiming.toLowerCase()}');

        parts.add(
          '${name.toLowerCase()}|${duration ?? -1}|${dosageStorage.toLowerCase()}|$combinedMealTiming',
        );
      }
      parts.sort();

      return '$advice||${parts.join('||')}';
    }

    String? initialSnapshotKey;

    List<PrescribedItem> buildItems(int prescriptionId) {
      final items = <PrescribedItem>[];

      for (final m in itemCtrls) {
        final name = (m['name'] as TextEditingController).text.trim();
        final durationText = (m['duration'] as TextEditingController).text
            .trim();
        final dosageTimesRaw = (m['dosage'] as TextEditingController).text
            .trim();
        final dosageTimes = normalizeDosageForStorage(dosageTimesRaw);
        final mealTiming = (m['mealTiming'] as ValueNotifier<String?>).value;
        final mealTime = (m['mealTime'] as TextEditingController).text.trim();

        if (name.isEmpty) continue;

        final duration = durationText.isEmpty
            ? null
            : int.tryParse(durationText);
        if (duration == null) {
          // skip invalid item (validation happens before submit too)
          continue;
        }

        // Combine time + before/after (like prescription_page.dart)
        // Combine time before/after (never save null if user provided time)
        String? combinedMealTiming;

        // if checkbox not selected but time is given -> default to 'before'
        final normalizedTiming = (mealTiming != null && mealTiming.isNotEmpty)
            ? mealTiming
            : (mealTime.isNotEmpty ? 'before' : null);

        if (normalizedTiming != null && normalizedTiming.isNotEmpty) {
          combinedMealTiming = mealTime.isEmpty
              ? normalizedTiming
              : '$mealTime $normalizedTiming';
        }

        // IMPORTANT: backend creates a NEW prescription id; do not bind items to old id from client.
        items.add(
          PrescribedItem(
            prescriptionId: 0,
            medicineName: name,
            dosageTimes: dosageTimes.isEmpty ? null : dosageTimes,
            mealTiming: combinedMealTiming,
            duration: duration,
          ),
        );
      }

      return items;
    }

    Future<void> prefillFromExisting(StateSetter setSheetState) async {
      try {
        debugPrint('Prefill prescriptionId=${report.prescriptionId}');

        final detail = await client.doctor.getPrescriptionDetails(
          prescriptionId: report.prescriptionId!,
        );

        if (detail == null) {
          setSheetState(() {
            addEmptyRow();
          });
          initialSnapshotKey = buildSnapshotKey();
          return;
        }

        final existingAdvice = (detail.advice ?? '').trim();
        setSheetState(() {
          adviceController.text = existingAdvice;
          itemCtrls.clear();
        });

        for (final item in detail.items) {
          final dosageText = item.dosageTimes ?? '';
          // UI should always show numeric storage pattern like 1+0+1 (or 1+1+1+1)
          // even if legacy records contain text like "সকাল, রাত".
          final dosageDisplay = normalizeDosageForStorage(dosageText);

          final raw = (item.mealTiming ?? '').trim();
          final lower = raw.toLowerCase();

          String? selectedTiming;
          String timePart = raw;

          if (lower.contains('before') || lower.contains('আগে')) {
            selectedTiming = 'before';
            timePart = raw
                .replaceAll(RegExp('before', caseSensitive: false), '')
                .replaceAll('আগে', '')
                .trim();
          } else if (lower.contains('after') || lower.contains('পরে')) {
            selectedTiming = 'after';
            timePart = raw
                .replaceAll(RegExp('after', caseSensitive: false), '')
                .replaceAll('পরে', '')
                .trim();
          }

          timePart = timePart
              .replaceAll(',', ' ')
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();
          debugPrint('DB mealTiming raw="${item.mealTiming}"');
          debugPrint(
            'Parsed selectedTiming="$selectedTiming", timePart="$timePart"',
          );
          setSheetState(() {
            itemCtrls.add({
              'name': TextEditingController(text: item.medicineName),
              'duration': TextEditingController(
                text: item.duration?.toString() ?? '',
              ),
              'mealTime': TextEditingController(text: timePart),
              'mealTiming': ValueNotifier<String?>(selectedTiming),
              'dosage': TextEditingController(text: dosageDisplay),
            });
          });
        }

        if (itemCtrls.isEmpty) {
          setSheetState(() => addEmptyRow());
        }

        // Capture initial state after prefill so we can block submitting when unchanged
        initialSnapshotKey = buildSnapshotKey();
      } catch (e) {
        debugPrint('Prefill error: $e');
        setSheetState(() {
          addEmptyRow();
        });
        initialSnapshotKey = buildSnapshotKey();
      }
    }

    // --- Only DB stored URL ---
    String? previewUrl;

    void loadDbUrl(StateSetter setSheetState) {
      if (previewUrl != null) return;
      previewUrl = report.filePath; // direct DB value
      if (!sheetOpen) return;
      setSheetState(() {});
    }

    Widget buildReportPreview(String url) {
      if (url.isEmpty) {
        return const Text('No file available');
      }

      // IMAGE PREVIEW (tappable -> full screen)
      if (_isImage(url)) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 300,
            width: double.infinity,
            child: GestureDetector(
              onTap: () {
                if (!mounted) return;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FullScreenImagePage(imageUrl: url),
                  ),
                );
              },
              child: Hero(
                tag: url,
                child: InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 5.0,
                  panEnabled: true,
                  scaleEnabled: true,
                  clipBehavior: Clip.hardEdge,
                  child: Image.network(
                    url,
                    fit: BoxFit.fitWidth,
                    loadingBuilder: (c, w, p) {
                      if (p == null) return w;
                      return const Center(child: CircularProgressIndicator());
                    },
                    // ignore: unnecessary_underscores
                    errorBuilder: (_, __, ___) =>
                        const Center(child: Text('Failed to load image')),
                  ),
                ),
              ),
            ),
          ),
        );
      }

      // PDF PREVIEW (same pattern as prescription)
      if (_isPdf(url)) {
        return InkWell(
          onTap: () {
            _openPdfInApp(url);
          },
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              color: const Color(0x1AFF0000),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.picture_as_pdf, size: 48, color: Colors.red),
                SizedBox(height: 10),
                Text(
                  'Tap to open PDF',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        );
      }
      return Container(
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        child: const Text(
          'Unsupported file format',
          style: TextStyle(color: Colors.red),
        ),
      );
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          // kick off prefill once
          if (isPrefillLoading) {
            isPrefillLoading = false;
            prefillFromExisting(setSheetState).whenComplete(() {
              if (!sheetOpen) return;
              setSheetState(() {});
            });
          }

          if (previewUrl == null) {
            loadDbUrl(setSheetState);
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header card (improved)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0F000000),
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.shade600,
                                Colors.blue.shade300,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.fact_check,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Review Report',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                report.type,
                                style: TextStyle(
                                  color: Colors.blueGrey.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            sheetOpen = false;
                            Navigator.of(sheetContext).pop();
                          },

                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.close, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Preview spot now shows link only
                  if (previewUrl != null) ...[
                    buildReportPreview(previewUrl!),
                    const SizedBox(height: 8),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () async {
                          final raw = previewUrl!;
                          final suggestedName =
                              Uri.tryParse(
                                    raw,
                                  )?.pathSegments.last.trim().isNotEmpty ==
                                  true
                              ? Uri.parse(raw).pathSegments.last
                              : 'report_${DateTime.now().millisecondsSinceEpoch}';

                          try {
                            await downloadPdfImageFromLink(
                              url: raw,
                              fileName: suggestedName,
                              context: context,
                            );

                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Saved to Downloads (or browser downloads).',
                                ),
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            if (e is CloudinaryPdfDeliveryBlockedException) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Cloudinary blocked this PDF. If you are on a Free plan, enable “Allow delivery of PDF and ZIP files” in Cloudinary Console → Settings → Security, or upgrade your plan.',
                                  ),
                                ),
                              );
                              return;
                            }

                            if (e is DownloadHttpException &&
                                e.statusCode == 401) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Unauthorized (401). If this is a Cloudinary PDF, check Cloudinary Security settings (PDF delivery can be blocked on Free plan).',
                                  ),
                                ),
                              );
                              return;
                            }

                            final msg = e.toString();
                            if (msg.contains('401') ||
                                msg.toLowerCase().contains('unauthorized')) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Unauthorized (401). Please login again.',
                                  ),
                                ),
                              );
                              return;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Download failed: $e')),
                            );
                          }
                        },
                        icon: const Icon(Icons.download),
                        label: const Text('Download'),
                      ),
                    ),

                    const SizedBox(height: 12),
                  ],

                  const SizedBox(height: 14),

                  // Prescription editor section
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0B000000),
                          blurRadius: 10,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _sectionTitle(Icons.edit_note, 'Update prescription'),
                        const SizedBox(height: 12),
                        TextField(
                          controller: adviceController,
                          onChanged: (_) => setSheetState(() {}),
                          decoration: InputDecoration(
                            labelText: 'New Advice',
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade200,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade200,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.blue.shade400,
                                width: 1.5,
                              ),
                            ),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 14),
                        _sectionTitle(
                          Icons.medication_outlined,
                          'Medicines (edit + add)',
                        ),
                        const SizedBox(height: 10),

                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: itemCtrls.length,
                          itemBuilder: (context, index) {
                            final row = itemCtrls[index];
                            final nameCtrl =
                                row['name'] as TextEditingController;
                            final durationCtrl =
                                row['duration'] as TextEditingController;
                            final mealTimeCtrl =
                                row['mealTime'] as TextEditingController;
                            final mealTiming =
                                row['mealTiming'] as ValueNotifier<String?>;
                            final dosageCtrl =
                                row['dosage'] as TextEditingController;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 30,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withValues(
                                            alpha: 0.12,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${index + 1}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              color: Colors.blue.shade700,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Medicine #${index + 1}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Remove',
                                        onPressed: itemCtrls.length <= 1
                                            ? null
                                            : () {
                                                setSheetState(() {
                                                  itemCtrls.removeAt(index);
                                                });
                                              },
                                        icon: Icon(
                                          Icons.delete_outline,
                                          color: itemCtrls.length <= 1
                                              ? Colors.grey
                                              : Colors.red.shade400,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  TextField(
                                    controller: nameCtrl,
                                    onChanged: (_) => setSheetState(() {}),
                                    decoration: InputDecoration(
                                      labelText: 'Medication Name',
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: dosageCtrl,
                                          onChanged: (_) =>
                                              setSheetState(() {}),
                                          decoration: InputDecoration(
                                            labelText: 'Dosage Times',
                                            filled: true,
                                            fillColor: Colors.white,
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      SizedBox(
                                        width: 120,
                                        child: TextField(
                                          controller: durationCtrl,
                                          keyboardType: TextInputType.number,
                                          onChanged: (_) =>
                                              setSheetState(() {}),
                                          decoration: InputDecoration(
                                            labelText: 'Duration',
                                            filled: true,
                                            fillColor: Colors.white,
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 120,
                                        child: TextField(
                                          controller: mealTimeCtrl,
                                          onChanged: (_) =>
                                              setSheetState(() {}),
                                          decoration: InputDecoration(
                                            labelText: 'Time',
                                            filled: true,
                                            fillColor: Colors.white,
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ValueListenableBuilder<String?>(
                                          valueListenable: mealTiming,
                                          builder: (context, val, child) {
                                            return Wrap(
                                              spacing: 12,
                                              runSpacing: 6,
                                              children: [
                                                InkWell(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  onTap: () {
                                                    mealTiming.value =
                                                        val == 'before'
                                                        ? null
                                                        : 'before';
                                                    setSheetState(() {});
                                                  },
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Checkbox(
                                                        value: val == 'before',
                                                        onChanged: (v) {
                                                          mealTiming.value =
                                                              v == true
                                                              ? 'before'
                                                              : null;
                                                          setSheetState(() {});
                                                        },
                                                      ),
                                                      const Text('খাবার আগে'),
                                                    ],
                                                  ),
                                                ),
                                                InkWell(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  onTap: () {
                                                    mealTiming.value =
                                                        val == 'after'
                                                        ? null
                                                        : 'after';
                                                    setSheetState(() {});
                                                  },
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Checkbox(
                                                        value: val == 'after',
                                                        onChanged: (v) {
                                                          mealTiming.value =
                                                              v == true
                                                              ? 'after'
                                                              : null;
                                                          setSheetState(() {});
                                                        },
                                                      ),
                                                      const Text('খাবার পরে'),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () {
                              setSheetState(() {
                                addEmptyRow();
                              });
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Add medicine'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.blue.shade700,
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),
                        Builder(
                          builder: (_) {
                            final snap = initialSnapshotKey;
                            if (snap == null) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  'Loading prescription…',
                                  style: TextStyle(
                                    color: Colors.blueGrey.shade700,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }

                            final hasChanges = buildSnapshotKey() != snap;
                            if (!hasChanges) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  'Update advice/medicines to Submit.',
                                  style: TextStyle(
                                    color: Colors.red.shade400,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }

                            return const SizedBox.shrink();
                          },
                        ),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed:
                                (isSubmitting ||
                                    initialSnapshotKey == null ||
                                    buildSnapshotKey() == initialSnapshotKey)
                                ? null
                                : () async {
                                    final advice = adviceController.text.trim();

                                    if (advice.isEmpty) {
                                      ScaffoldMessenger.of(
                                        sheetContext,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Advice is required'),
                                        ),
                                      );
                                      return;
                                    }

                                    ensureAtLeastOneRow();

                                    // extra validation: at least one medicine with valid duration
                                    final hasAnyMedicine = itemCtrls.any((m) {
                                      final name =
                                          (m['name'] as TextEditingController)
                                              .text
                                              .trim();
                                      return name.isNotEmpty;
                                    });
                                    if (!hasAnyMedicine) {
                                      ScaffoldMessenger.of(
                                        sheetContext,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Please add at least 1 medicine',
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    // Build items (backend will attach to new prescription id)
                                    final items = buildItems(
                                      report.prescriptionId!,
                                    );
                                    if (items.isEmpty) {
                                      ScaffoldMessenger.of(
                                        sheetContext,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Please provide valid duration for medicines',
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    final rootMessenger = ScaffoldMessenger.of(
                                      context,
                                    );
                                    final sheetMessenger = ScaffoldMessenger.of(
                                      sheetContext,
                                    );
                                    final navigator = Navigator.of(
                                      sheetContext,
                                    );

                                    setSheetState(() => isSubmitting = true);
                                    try {
                                      final newId = await client.doctor
                                          .revisePrescription(
                                            originalPrescriptionId:
                                                report.prescriptionId!,
                                            newAdvice: advice,
                                            newItems: items,
                                          );

                                      if (!mounted) return;

                                      if (newId <= 0) {
                                        setSheetState(
                                          () => isSubmitting = false,
                                        );
                                        sheetMessenger.showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Failed to save revised prescription',
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      navigator.pop();
                                      rootMessenger.showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Prescription revised successfully',
                                          ),
                                        ),
                                      );
                                      _fetchReports();
                                    } catch (e) {
                                      setSheetState(() => isSubmitting = false);
                                      sheetMessenger.showSnackBar(
                                        SnackBar(content: Text('Failed: $e')),
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: isSubmitting
                                  ? const SizedBox(
                                      key: ValueKey('loading'),
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Text(
                                      'Submit',
                                      key: ValueKey('submit'),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).whenComplete(() {
      sheetOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text(
          'Review Test Reports',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () async {
              await Navigator.pushNamed(context, '/notifications');
            },
          ),
        ],
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue,
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Failed to load reports',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _fetchReports,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : _reports.isEmpty
          ? const Center(child: Text('No reports found'))
          : RefreshIndicator(
              onRefresh: _fetchReports,
              child: ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                itemCount: _reports.length,
                // ignore: unnecessary_underscores
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final report = _reports[index];
                  final reportId = report.reportId;
                  final createdAt = report.createdAt;
                  final isReviewed = report.reviewed == true;
                  final byIdHighlight =
                      reportId != null && reportId == _highlightReportId;

                  final byAllUnreviewedHighlight =
                      _highlightAllUnreviewed && !isReviewed;

                  final since = _highlightUnreviewedSinceUtc;
                  final byUnreviewedHighlight =
                      since != null &&
                      !isReviewed &&
                      createdAt != null &&
                      createdAt.toUtc().isAfter(since);

                  final isHighlighted =
                      byIdHighlight ||
                      byAllUnreviewedHighlight ||
                      byUnreviewedHighlight;
                  final dateText = createdAt == null
                      ? '-'
                      : '${createdAt.year.toString().padLeft(4, '0')}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';

                  final isPdf = report.filePath.toLowerCase().endsWith('.pdf');

                  return InkWell(
                    key: reportId == null ? null : _keyForReportId(reportId),
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _onReviewReport(report),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isHighlighted
                            ? const Color(0xFFFFF7ED)
                            : (isReviewed
                                  ? const Color(0xFFF1FBF4)
                                  : Colors.white),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isHighlighted
                              ? Colors.orange.shade400
                              : (isReviewed
                                    ? Colors.green.shade200
                                    : Colors.grey.shade200),
                          width: isHighlighted ? 1.6 : 1.0,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0B000000),
                            blurRadius: 10,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: isReviewed
                                  ? const Color(0x1A2E7D32)
                                  : (isPdf
                                        ? const Color(0x1AFF0000)
                                        : const Color(0x1A607D8B)),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              isPdf
                                  ? Icons.picture_as_pdf
                                  : Icons.insert_drive_file,
                              color: isReviewed
                                  ? Colors.green
                                  : (isPdf ? Colors.red : Colors.blueGrey),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  report.type,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Date: $dateText',
                                  style: TextStyle(
                                    color: Colors.blueGrey.shade700,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  (isReviewed
                                      ? Colors.green.shade700
                                      : Colors.blue.shade600),
                                  (isReviewed
                                      ? Colors.green.shade500
                                      : Colors.blue.shade400),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              isReviewed ? 'Reviewed' : 'Review',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class FullScreenImagePage extends StatefulWidget {
  final String imageUrl;
  const FullScreenImagePage({super.key, required this.imageUrl});

  @override
  State<FullScreenImagePage> createState() => _FullScreenImagePageState();
}

class _FullScreenImagePageState extends State<FullScreenImagePage>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();
  AnimationController? _animationController;
  Animation<Matrix4>? _animation;
  TapDownDetails? _doubleTapDetails;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animationController!.addListener(() {
      if (_animation != null) {
        _transformationController.value = _animation!.value;
      }
    });
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    final position = _doubleTapDetails?.localPosition ?? Offset.zero;
    final current = _transformationController.value;
    final identity = Matrix4.identity();

    if (!mounted) return;

    // If currently zoomed, animate back to identity
    if (current != identity) {
      _animation = Matrix4Tween(begin: current, end: identity).animate(
        CurveTween(curve: Curves.easeOut).animate(_animationController!),
      );
      _animationController!.forward(from: 0);
      return;
    }

    // Otherwise zoom in centered on the tapped position
    const double zoom = 3.0;
    final renderBox = context.findRenderObject() as RenderBox?;
    final _ = renderBox?.size ?? MediaQuery.of(context).size;
    final dx = position.dx;
    final dy = position.dy;

    // Compute translation so the tapped point stays roughly under the finger when scaled
    final translateX = -dx * (zoom - 1);
    final translateY = -dy * (zoom - 1);

    final Matrix4 target = Matrix4.identity()
      // ignore: deprecated_member_use
      ..translate(translateX, translateY)
      // ignore: deprecated_member_use
      ..scale(zoom);

    _animation = Matrix4Tween(
      begin: current,
      end: target,
    ).animate(CurveTween(curve: Curves.easeOut).animate(_animationController!));
    _animationController!.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Fullscreen InteractiveViewer
            Positioned.fill(
              child: GestureDetector(
                onDoubleTapDown: (details) => _doubleTapDetails = details,
                onDoubleTap: _handleDoubleTap,
                child: Hero(
                  tag: widget.imageUrl,
                  child: InteractiveViewer(
                    transformationController: _transformationController,
                    minScale: 1.0,
                    maxScale: 5.0,
                    panEnabled: true,
                    scaleEnabled: true,
                    boundaryMargin: const EdgeInsets.all(double.infinity),
                    child: SizedBox.expand(
                      child: FittedBox(
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                        child: Image.network(
                          widget.imageUrl,
                          // set a reasonable width/height so FittedBox can size correctly
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height,
                          loadingBuilder: (c, w, p) {
                            if (p == null) return w;
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                          // ignore: unnecessary_underscores
                          errorBuilder: (_, __, ___) => const Center(
                            child: Text(
                              'Failed to load image',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Close button overlay (top-left)
            Positioned(
              left: 12,
              top: 12,
              child: Material(
                color: Colors.black38,
                shape: const CircleBorder(),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
