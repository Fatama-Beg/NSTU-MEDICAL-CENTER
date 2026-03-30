import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:backend_client/backend_client.dart';

import '../core/server_upload.dart';
import '../routing/route_refresh.dart';

enum UploadStatus { idle, success, failure }

class PatientReportUpload extends StatefulWidget {
  const PatientReportUpload({super.key});

  @override
  State<PatientReportUpload> createState() => _PatientReportUploadState();
}

class _PatientReportUploadState extends State<PatientReportUpload>
    with RouteRefreshMixin<PatientReportUpload> {
  final _formKey = GlobalKey<FormState>();
  final Color kPrimaryColor = const Color(0xFF00796B);

  // Upload status for UI feedback
  UploadStatus _uploadStatus = UploadStatus.idle;

  // Control whether validators should show error messages in the UI.
  // We enable this only for normal uploads (not for replace operations).
  bool _showValidationErrors = false;

  // State Variables
  List<PrescriptionList> _prescriptions = [];
  List<PatientExternalReport> _myPastReports = []; // আগের আপলোড করা রিপোর্ট

  int? _selectedPrescriptionId;
  String? _selectedType;
  File? _selectedFile;
  String? _selectedFileName;
  Uint8List? _fileBytes;

  bool _isLoading = false;
  bool _isUploading = false;

  final List<String> _reportTypes = [
    "Blood Test",
    "Urine Test",
    "Liver Function Test",
    "Kidney Function Test",
    "Sugar Test",
    "Other",
  ];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  @override
  Future<void> refreshOnFocus() async {
    if (_isUploading) return;

    // Don't wipe in-progress form values.
    final hasDraft =
        _selectedPrescriptionId != null ||
        _selectedType != null ||
        _selectedFile != null ||
        _fileBytes != null;
    if (hasDraft) return;

    await _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    await Future.wait([_fetchPrescriptions(), _fetchMyPastReports()]);
    setState(() => _isLoading = false);
  }

  // ১. প্রেসক্রিপশন লিস্ট আনা
  Future<void> _fetchPrescriptions() async {
    try {
      final list = await client.patient.getMyPrescriptionList();
      _prescriptions = list;
    } catch (e) {
      debugPrint("Prescription fetch error: $e");
    }
  }

  // ২. আগের আপলোড করা রিপোর্টগুলো আনা (Serverpod backend থেকে)
  Future<void> _fetchMyPastReports() async {
    try {
      // দ্রষ্টব্য: আপনার ব্যাকএন্ডে এই মেথডটি থাকতে হবে যা PatientExternalReport রিটার্ন করে
      final reports = await client.patient.getMyExternalReports();
      _myPastReports = reports;
    } catch (e) {
      debugPrint("Past reports fetch error: $e");
    }
  }

  // ৩. ফাইল পিক করা
  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ["pdf", "jpg", "jpeg", "png"],
      withData: true,
    );
    if (result != null) {
      // Use in-memory bytes (works for web and mobile). Only set _selectedFile
      // when a real path is available (mobile/desktop). Avoid creating File('')
      // which will throw on web.
      final picked = result.files.first;
      setState(() {
        _fileBytes = picked.bytes; // may be null on some platforms
        _selectedFileName = picked.name;
        if (picked.path != null && picked.path!.isNotEmpty) {
          _selectedFile = File(picked.path!);
        } else {
          _selectedFile = null;
        }
      });
    }
  }

  // ৪. আপলোড ফাংশন (নতুন আপলোড বা রিপ্লেস উভয়ের জন্যই কাজ করবে)
  Future<void> _onUpload({int? replacePrescriptionId}) async {
    // Reset status when starting a new upload
    setState(() => _uploadStatus = UploadStatus.idle);
    // For new uploads (not replacements) we must validate the form and show errors.
    // For replacements we skip validate() to avoid showing validator error text in UI.
    if (replacePrescriptionId == null) {
      // Enable validation display for normal uploads
      setState(() => _showValidationErrors = true);
      if (!_formKey.currentState!.validate()) {
        return;
      }
    }
    // Ensure a prescription selection exists when not replacing a specific report
    if (replacePrescriptionId == null && _selectedPrescriptionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a prescription to link this report.'),
        ),
      );
      return;
    }
    // Require at least one source of bytes (in-memory or file path)
    if (_fileBytes == null && _selectedFile == null) return;

    setState(() => _isUploading = true);
    try {
      // Prefer in-memory bytes if available (works on web). Otherwise read from file.
      final bytes = _fileBytes ?? await _selectedFile!.readAsBytes();

      // Prevent uploading excessively large files that could break requests
      // Serverpod default request limit is ~512KB; use 500KB client-side cap to avoid 413 errors.
      const int maxBytes = 2 * 1024 * 1024;
      if (bytes.lengthInBytes > maxBytes) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'File too large. Maximum allowed is 2 MB. Please choose a smaller file or compress the image.',
            ),
          ),
        );
        setState(() => _isUploading = false);
        return;
      }
      // Determine file name: prefer picked filename (works on web), else file path
      String fileName;
      if (_selectedFileName != null && _selectedFileName!.isNotEmpty) {
        fileName = _selectedFileName!;
      } else if (_selectedFile != null) {
        final parts = _selectedFile!.path.split(RegExp(r'[\\/]+'));
        fileName = parts.isNotEmpty
            ? parts.last
            : 'upload_${DateTime.now().millisecondsSinceEpoch}';
      } else {
        fileName = 'upload_${DateTime.now().millisecondsSinceEpoch}';
      }
      fileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9.]'), '_');

      final isPdf = fileName.toLowerCase().endsWith('.pdf');
      final uploadedUrl = await ServerUpload.uploadBytes(
        bytes: bytes,
        folder: 'patient_external_reports',
        fileName: fileName,
        isPdf: isPdf,
      );
      if (uploadedUrl == null) {
        setState(() => _uploadStatus = UploadStatus.failure);
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Upload failed'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isUploading = false);
        return;
      }

      // এপিআই কল
      dynamic success;
      try {
        // assign to outer variable (don't redeclare)
        success = await client.patient.finalizeReportUpload(
          prescriptionId: replacePrescriptionId ?? _selectedPrescriptionId!,
          reportType: _selectedType ?? "Other",
          fileUrl: uploadedUrl,
        );
      } catch (e) {
        // network/backend error
        debugPrint('finalizeReportUpload exception: $e');
        setState(() => _uploadStatus = UploadStatus.failure);
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload error: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isUploading = false);
        return;
      }

      if (success != true) {
        // Server returned false or unexpected result
        debugPrint('finalizeReportUpload returned false');
        setState(() => _uploadStatus = UploadStatus.failure);
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Upload failed: server rejected the file'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isUploading = false);
        return;
      }

      if (success == true) {
        if (!mounted) return;

        setState(() {
          // Clear fields
          _selectedFile = null;
          _selectedFileName = null;
          _fileBytes = null;
          _selectedPrescriptionId = null;
          _selectedType = null;

          // Mark upload success
          _uploadStatus = UploadStatus.success;
          // Hide validation errors after success
          _showValidationErrors = false;
        });

        // Show snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Upload successful"),
            backgroundColor: Colors.green,
          ),
        );

        // 1 second পরে status reset করে idle করে দিন, যাতে button আবার normal দেখায়
        Future.delayed(const Duration(seconds: 1), () {
          if (!mounted) return;
          setState(() {
            _uploadStatus = UploadStatus.idle;
          });
        });

        // Refresh past reports list
        // Call only getMyExternalReports (via _fetchMyPastReports) once after upload/replace
        await _fetchMyPastReports();
        if (!mounted) return;
        setState(() {});
      }
    } catch (e) {
      debugPrint('Unexpected upload error: $e');
      String message = e.toString();
      if (e is UnsupportedError) {
        message = 'Operation not supported on this platform.';
      } else if (e is FormatException) {
        message = 'Invalid file format.';
      }
      setState(() => _uploadStatus = UploadStatus.failure);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $message'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  // ৫. ১২ ঘণ্টা চেক করার লজিক
  bool _canReplace(DateTime? createdAt) {
    if (createdAt == null) return false;
    final difference = DateTime.now().difference(createdAt);
    return difference.inHours < 12; // ১২ ঘণ্টার কম হলে true
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reports Management"),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: refreshFromPull,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUploadForm(),
                    const Divider(height: 40),
                    const Center(
                      child: Text(
                        "Previous Uploads (Changeable for 12h)",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 10),
                    _buildPastReportsList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildUploadForm() {
    return Form(
      key: _formKey,
      autovalidateMode: _showValidationErrors
          ? AutovalidateMode.always
          : AutovalidateMode.disabled,
      child: Column(
        children: [
          DropdownButtonFormField<int>(
            decoration: _inputDecoration(
              "Link to Prescription",
              Icons.assignment,
            ),
            items: _prescriptions.map((p) {
              final d = p.date;
              final dateText =
                  '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

              return DropdownMenuItem(
                value: p.prescriptionId,
                child: Text("${p.doctorName} ($dateText)"),
              );
            }).toList(),

            onChanged: (val) => setState(() => _selectedPrescriptionId = val),
            validator: (v) => v == null ? 'Select Prescription' : null,
          ),
          const SizedBox(height: 15),
          DropdownButtonFormField<String>(
            decoration: _inputDecoration("Report Type", Icons.science),
            items: _reportTypes
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (val) => setState(() => _selectedType = val),
            validator: (v) => v == null ? 'Select Type' : null,
          ),
          const SizedBox(height: 15),
          InkWell(
            onTap: _pickFile,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.teal),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _selectedFile == null
                        ? Icons.upload_file
                        : Icons.check_circle,
                    color: kPrimaryColor,
                  ),
                  const SizedBox(width: 10),
                  Text(_selectedFile == null ? "Select File" : "File Selected"),
                ],
              ),
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isUploading ? null : () => _onUpload(),
              style: ElevatedButton.styleFrom(
                backgroundColor: _uploadStatus == UploadStatus.success
                    ? Colors.green
                    : _uploadStatus == UploadStatus.failure
                    ? Colors.red
                    : kPrimaryColor,
              ),
              child: _isUploading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("UPLOAD", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPastReportsList() {
    if (_myPastReports.isEmpty) {
      return const Center(
        child: Text(
          "No reports uploaded yet.",
          style: TextStyle(fontSize: 16, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _myPastReports.length,
      itemBuilder: (context, index) {
        final report = _myPastReports[index];
        bool changeable = _canReplace(report.createdAt);

        return Card(
          child: ListTile(
            leading: Icon(
              Icons.description,
              color: changeable ? Colors.green : Colors.grey,
            ),
            title: Text(report.type),
            subtitle: Text(
              "Uploaded: ${report.createdAt?.hour}:${report.createdAt?.minute}\nDate: ${report.createdAt?.day}/${report.createdAt?.month}",
            ),
            trailing: changeable
                ? ElevatedButton(
                    onPressed: () async {
                      // Disable validator display during replace flow
                      setState(() => _showValidationErrors = false);
                      _selectedType = report.type;
                      await _pickFile();
                      if (_fileBytes != null || _selectedFile != null) {
                        await _onUpload(
                          replacePrescriptionId: report.prescriptionId,
                        );
                      } else {
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Please select a file to replace the report.",
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: const Text("Replace"),
                  )
                : const Icon(Icons.lock_outline, color: Colors.red),
          ),
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: kPrimaryColor),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
