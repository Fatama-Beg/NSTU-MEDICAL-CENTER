import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:backend_client/backend_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:printing/printing.dart';

import '../core/download_pdf_image_from_link.dart';
import '../core/date_time_utils.dart';
import '../routing/route_refresh.dart';

class PatientReports extends StatefulWidget {
  const PatientReports({super.key});

  @override
  State<PatientReports> createState() => _PatientReportsState();
}

class _PatientReportsState extends State<PatientReports>
    with RouteRefreshMixin<PatientReports> {
  final Color kPrimaryColor = const Color(0xFF00796B);

  bool isLoading = true;
  List<PatientReportDto> reports = [];

  @override
  void initState() {
    super.initState();
    loadReports();
  }

  @override
  Future<void> refreshOnFocus() async {
    await loadReports(showSpinner: false);
  }

  Future<void> loadReports({bool showSpinner = true}) async {
    try {
      if (showSpinner && mounted) {
        setState(() => isLoading = true);
      }
      final prefs = await SharedPreferences.getInstance();

      // SAME key as dashboard
      final storedUserId = prefs.getString('user_id');

      if (storedUserId == null || storedUserId.isEmpty) {
        debugPrint("User not logged in (no user_id)");
        return;
      }

      final int? userId = int.tryParse(storedUserId);
      if (userId == null) {
        debugPrint("Invalid user_id format");
        return;
      }

      final data = await client.patient.getMyLabReports();
      setState(() {
        reports = data;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Failed to load reports: $e");
      setState(() => isLoading = false);
    }
  }

  String _inferExtensionFromUrl(String url) {
    try {
      final last = Uri.parse(url).pathSegments.isEmpty
          ? ''
          : Uri.parse(url).pathSegments.last;
      final i = last.lastIndexOf('.');
      if (i > 0 && i < last.length - 1) {
        return last.substring(i + 1).toLowerCase();
      }
    } catch (_) {
      // ignore
    }
    return 'pdf';
  }

  Future<void> downloadReportFromLink({
    required String url,
    required String suggestedBaseName,
  }) async {
    try {
      final ext = _inferExtensionFromUrl(url);
      final safeBase = suggestedBaseName.trim().isEmpty
          ? 'report_${DateTime.now().millisecondsSinceEpoch}'
          : suggestedBaseName.trim();
      final fileName = safeBase.contains('.') ? safeBase : '$safeBase.$ext';

      final result = await downloadBytesFromLink(url: url, fileName: fileName);

      await Printing.sharePdf(bytes: result.bytes, filename: result.fileName);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report ready to save/share.')),
      );
    } on CloudinaryPdfDeliveryBlockedException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cloudinary blocked this PDF. If you are on a Free plan, enable “Allow delivery of PDF and ZIP files” in Cloudinary Console → Settings → Security, or upgrade your plan.',
          ),
        ),
      );
      return;
    } on DownloadHttpException catch (e) {
      if (e.statusCode == 401) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unauthorized (401). If this is a Cloudinary PDF, check Cloudinary Security settings (PDF delivery can be blocked on Free plan).',
            ),
          ),
        );
        return;
      }
      rethrow;
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('401') || msg.toLowerCase().contains('unauthorized')) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unauthorized (401). Please login again.'),
          ),
        );
        return;
      }

      // Fallback: open in external app/browser.
      final dl = buildCloudinaryAttachmentUrl(url);
      await launchUrl(Uri.parse(dl), mode: LaunchMode.externalApplication);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Download fallback used: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "My Reports",
          style: TextStyle(color: Colors.blueAccent),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: refreshFromPull,
              child: reports.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      children: const [
                        SizedBox(height: 80),
                        Center(child: Text("No reports found")),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(15),
                      itemCount: reports.length,
                      itemBuilder: (context, index) {
                        final report = reports[index];

                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.only(bottom: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        report.testName,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_month_outlined,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          AppDateTime.formatDateOnly(
                                            report.date,
                                            pattern: 'yyyy-MM-dd',
                                          ),
                                          style: TextStyle(
                                            color: kPrimaryColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Text(
                                  report.isUploaded
                                      ? "Report available"
                                      : "Report not uploaded yet",
                                  style: TextStyle(
                                    color: report.isUploaded
                                        ? Colors.green
                                        : Colors.red,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                const SizedBox(height: 15),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed:
                                            report.isUploaded &&
                                                report.fileUrl != null
                                            ? () => downloadReportFromLink(
                                                url: report.fileUrl!,
                                                suggestedBaseName:
                                                    'Report_${report.testName}_${AppDateTime.formatDateOnly(report.date, pattern: 'yyyyMMdd')}',
                                              )
                                            : null,
                                        icon: const Icon(
                                          Icons.download,
                                          size: 18,
                                        ),
                                        label: const Text("Download"),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: kPrimaryColor,
                                          foregroundColor: Colors.white,
                                          disabledBackgroundColor: Colors.grey,
                                        ),
                                      ),
                                    ],
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
