import 'dart:typed_data';
import 'package:backend_client/backend_client.dart';

class ServerUpload {
  /// Base URL of the Serverpod web server that serves uploaded files.
  /// Change this for production deployment.
  static String fileServerUrl = 'http://localhost:8082';

  /// Upload bytes to the backend. Returns the full accessible URL on success.
  static Future<String?> uploadBytes({
    required Uint8List bytes,
    required String folder,
    required String fileName,
    bool isPdf = false,
  }) async {
    try {
      final safeName = fileName.trim().isEmpty
          ? 'upload_${DateTime.now().millisecondsSinceEpoch}'
          : fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');

      final byteData = ByteData.view(
        bytes.buffer,
        bytes.offsetInBytes,
        bytes.lengthInBytes,
      );

      final relativePath = await client.fileUpload.uploadFile(
        byteData,
        folder,
        safeName,
      );
      if (relativePath == null) return null;

      return '$fileServerUrl/$relativePath';
    } catch (_) {
      return null;
    }
  }
}
