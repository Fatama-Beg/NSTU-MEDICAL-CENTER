import 'dart:io';
import 'dart:typed_data';
import 'package:serverpod/serverpod.dart';

class FileUploadEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  static const _allowedFolders = {
    'doctor_profiles',
    'doctor_signatures',
    'admin_profiles',
    'patient_profiles',
    'dispenser_profiles',
    'staff_profiles',
    'lab_reports',
    'patient_external_reports',
  };

  static const _maxImageBytes = 5 * 1024 * 1024; // 5 MB
  static const _maxPdfBytes = 10 * 1024 * 1024; // 10 MB

  /// Upload a file (image or PDF). Returns the relative URL path on success.
  Future<String?> uploadFile(
    Session session,
    ByteData bytes,
    String folder,
    String fileName,
  ) async {
    if (!_allowedFolders.contains(folder)) return null;

    final safeName = _sanitize(fileName);
    if (safeName.isEmpty) return null;

    final isPdf = safeName.toLowerCase().endsWith('.pdf');
    final limit = isPdf ? _maxPdfBytes : _maxImageBytes;
    if (bytes.lengthInBytes > limit) return null;

    final ts = DateTime.now().millisecondsSinceEpoch;
    final destName = '${ts}_$safeName';

    final dir = Directory('uploads/$folder');
    if (!dir.existsSync()) dir.createSync(recursive: true);

    await File('uploads/$folder/$destName').writeAsBytes(
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
    );

    return 'uploads/$folder/$destName';
  }

  static String _sanitize(String name) {
    final t = name.trim();
    if (t.isEmpty) return '';
    return t.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  }
}
