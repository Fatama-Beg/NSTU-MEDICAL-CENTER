import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class CloudinaryUpload {
  /// Cloudinary cloud name (public).
  static const String cloudName = 'dfrzizwb1';

  /// Unsigned upload preset (public).
  /// Configure this preset in Cloudinary to allow unsigned uploads.
  static const String uploadPreset = 'sabbir';

  static Uri _uploadUri() =>
      Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/auto/upload');

  static bool _isPdfName(String fileName) =>
      fileName.toLowerCase().trim().endsWith('.pdf');

  static MediaType _contentTypeForName(String fileName, {required bool isPdf}) {
    if (isPdf) return MediaType('application', 'pdf');
    final name = fileName.toLowerCase().trim();
    if (name.endsWith('.png')) return MediaType('image', 'png');
    if (name.endsWith('.jpg') || name.endsWith('.jpeg')) {
      return MediaType('image', 'jpeg');
    }
    // Cloudinary can still detect, but default to jpeg for images.
    return MediaType('image', 'jpeg');
  }

  static String _sanitizeFileName(String fileName) {
    final trimmed = fileName.trim();
    if (trimmed.isEmpty) {
      return 'upload_${DateTime.now().millisecondsSinceEpoch}';
    }
    return trimmed.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  }

  /// Convenience: infer `isPdf` + content-type from `fileName`.
  static Future<String?> uploadAuto({
    required Uint8List bytes,
    required String folder,
    required String fileName,
  }) {
    final safeName = _sanitizeFileName(fileName);
    return uploadBytes(
      bytes: bytes,
      folder: folder,
      fileName: safeName,
      isPdf: _isPdfName(safeName),
    );
  }

  /// Universal uploader for image/PDF bytes.
  /// Upload happens from the frontend (no apiSecret in app).
  static Future<String?> uploadBytes({
    required Uint8List bytes,
    required String folder,
    required String fileName,
    bool isPdf = false,
  }) async {
    try {
      final safeName = _sanitizeFileName(fileName);
      final inferredIsPdf = isPdf || _isPdfName(safeName);
      final request = http.MultipartRequest('POST', _uploadUri())
        ..fields['upload_preset'] = uploadPreset
        ..fields['folder'] = folder
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: safeName,
            contentType: _contentTypeForName(safeName, isPdf: inferredIsPdf),
          ),
        );

      final streamed = await request.send();
      final resp = await http.Response.fromStream(streamed);

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final data = jsonDecode(resp.body);
        final secureUrl = data['secure_url'];
        return secureUrl?.toString();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Convenience: upload base64 string (with or without data-url prefix).
  static Future<String?> uploadBase64({
    required String base64Data,
    required String folder,
    required String fileName,
    bool isPdf = false,
  }) async {
    var s = base64Data.trim();
    if (s.isEmpty) return null;
    if (s.contains(',')) {
      s = s.split(',').last;
    }
    s = s.replaceAll(RegExp(r'\s+'), '');
    try {
      final bytes = base64Decode(s);
      return uploadBytes(
        bytes: bytes,
        folder: folder,
        fileName: fileName,
        isPdf: isPdf,
      );
    } catch (_) {
      return null;
    }
  }
}
