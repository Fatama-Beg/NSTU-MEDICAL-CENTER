import 'dart:typed_data';

import 'package:backend_client/backend_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
// import 'package:media_store_plus/media_store_plus.dart'; // Removed for web compat
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;
import 'package:universal_io/io.dart' as uio;

import 'media_store_interface.dart'; // Added interface

class DownloadHttpException implements Exception {
  final int statusCode;
  final String url;
  final String? details;

  DownloadHttpException({
    required this.statusCode,
    required this.url,
    this.details,
  });

  @override
  String toString() {
    final d = (details == null || details!.trim().isEmpty) ? '' : ' ($details)';
    return 'HTTP $statusCode for $url$d';
  }
}

class CloudinaryPdfDeliveryBlockedException implements Exception {
  final String url;
  final int statusCode;

  CloudinaryPdfDeliveryBlockedException({
    required this.url,
    required this.statusCode,
  });

  @override
  String toString() {
    return 'Cloudinary blocked PDF delivery (HTTP $statusCode) for $url';
  }
}

/// Converts a Cloudinary URL into an attachment download URL.
///
/// Supports `/raw/upload/` and `/image/upload/` URLs.
String buildCloudinaryAttachmentUrl(String url) {
  if (url.isEmpty) return url;

  if (url.contains('/raw/upload/fl_attachment/') ||
      url.contains('/image/upload/fl_attachment/') ||
      url.contains('/upload/fl_attachment/')) {
    return url;
  }

  if (url.contains('/raw/upload/')) {
    return url.replaceFirst('/raw/upload/', '/raw/upload/fl_attachment/');
  }

  if (url.contains('/image/upload/')) {
    return url.replaceFirst('/image/upload/', '/image/upload/fl_attachment/');
  }

  if (url.contains('/upload/')) {
    return url.replaceFirst('/upload/', '/upload/fl_attachment/');
  }

  return url;
}

String _inferFileNameFromUrl(String url) {
  try {
    final uri = Uri.parse(url);
    if (uri.pathSegments.isNotEmpty) {
      final last = uri.pathSegments.last.trim();
      if (last.isNotEmpty && last.contains('.')) return last;
    }
  } catch (_) {
    // ignore
  }
  return 'download_${DateTime.now().millisecondsSinceEpoch}';
}

String _sanitizeFileName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return _inferFileNameFromUrl(name);
  final replaced = trimmed.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  return replaced.isEmpty
      ? 'download_${DateTime.now().millisecondsSinceEpoch}'
      : replaced;
}

bool _hasExtension(String fileName) {
  final base = fileName.trim();
  final lastDot = base.lastIndexOf('.');
  return lastDot > 0 && lastDot < base.length - 1;
}

String _extensionFromContentType(String? contentType) {
  final ct = (contentType ?? '').toLowerCase();
  if (ct.contains('application/pdf')) return 'pdf';
  if (ct.contains('image/png')) return 'png';
  if (ct.contains('image/webp')) return 'webp';
  if (ct.contains('image/jpeg') || ct.contains('image/jpg')) return 'jpg';
  if (ct.contains('image/gif')) return 'gif';
  return '';
}

bool _isCloudinaryHost(String url) {
  try {
    final u = Uri.parse(url);
    final host = u.host.toLowerCase();
    return host == 'res.cloudinary.com' || host.endsWith('.cloudinary.com');
  } catch (_) {
    return false;
  }
}

bool _looksLikePdfRequest({required String url, required String fileName}) {
  final u = url.toLowerCase();
  final f = fileName.toLowerCase();
  return u.contains('.pdf') || f.endsWith('.pdf');
}

Future<String?> _tryGetContentType(Dio dio, String url) async {
  try {
    final resp = await dio.head(url);
    return resp.headers.value('content-type');
  } catch (_) {
    return null;
  }
}

String? _serverpodHostString() {
  try {
    final v = (client as dynamic).host;
    if (v is String && v.trim().isNotEmpty) return v;
  } catch (_) {
    // ignore
  }
  try {
    final v = (client as dynamic).serverUrl;
    if (v is String && v.trim().isNotEmpty) return v;
  } catch (_) {
    // ignore
  }
  return null;
}

bool _isBackendHost(String url) {
  try {
    final serverHost = _serverpodHostString();
    if (serverHost == null) return false;
    final serverUri = Uri.parse(serverHost);
    final u = Uri.parse(url);
    return u.scheme == serverUri.scheme &&
        u.host == serverUri.host &&
        u.port == serverUri.port;
  } catch (_) {
    return false;
  }
}

Future<Map<String, String>?> _authHeadersForUrl(String url) async {
  if (!_isBackendHost(url)) return null;
  // ignore: deprecated_member_use
  final key = await client.authenticationKeyManager?.get();
  // ignore: deprecated_member_use
  final headerValue = await client.authenticationKeyManager?.toHeaderValue(key);
  if (headerValue == null || headerValue.isEmpty) return null;
  return {'Authorization': headerValue};
}

/// Downloads bytes from a URL (Cloudinary/back-end), with the same fallback logic as
/// [downloadPdfImageFromLink] but without saving to disk.
///
/// Returns:
/// - `bytes`: downloaded content bytes
/// - `contentType`: server-reported content type
/// - `usedUrl`: which URL worked (original or attachment URL)
/// - `fileName`: sanitized file name (with inferred extension if needed)
Future<({Uint8List bytes, String contentType, String usedUrl, String fileName})>
downloadBytesFromLink({required String url, String? fileName}) async {
  final dl = buildCloudinaryAttachmentUrl(url);
  final candidates = <String>{
    url,
    dl,
  }.where((e) => e.trim().isNotEmpty).toList();

  var safeName = _sanitizeFileName(
    (fileName == null || fileName.trim().isEmpty)
        ? _inferFileNameFromUrl(url)
        : fileName,
  );

  final dio = Dio(
    BaseOptions(
      followRedirects: true,
      validateStatus: (code) => code != null && code >= 200 && code < 400,
      receiveTimeout: const Duration(minutes: 2),
      connectTimeout: const Duration(seconds: 30),
    ),
  );

  // Some Cloudinary/raw URLs don't include an extension; try to infer it.
  if (!_hasExtension(safeName)) {
    String? ct;
    for (final u in candidates) {
      try {
        final headers = await _authHeadersForUrl(u);
        final resp = await dio.head(u, options: Options(headers: headers));
        ct = resp.headers.value('content-type');
      } catch (_) {
        ct = await _tryGetContentType(dio, u);
      }
      if (ct != null && ct.isNotEmpty) break;
    }
    final ext = _extensionFromContentType(ct);
    if (ext.isNotEmpty) safeName = '$safeName.$ext';
  }

  Object? lastError;
  DownloadHttpException? lastHttp;
  CloudinaryPdfDeliveryBlockedException? cloudinaryPdfBlocked;

  for (final u in candidates) {
    try {
      final headers = await _authHeadersForUrl(u);
      final resp = await dio.get<List<int>>(
        u,
        options: Options(responseType: ResponseType.bytes, headers: headers),
      );
      final bytes = Uint8List.fromList(resp.data ?? const <int>[]);
      if (bytes.isEmpty) throw Exception('Empty download');
      final contentType =
          resp.headers.value('content-type') ?? 'application/octet-stream';
      return (
        bytes: bytes,
        contentType: contentType,
        usedUrl: u,
        fileName: safeName,
      );
    } catch (e) {
      lastError = e;

      if (e is DioException) {
        final status = e.response?.statusCode;
        if (status != null) {
          lastHttp = DownloadHttpException(
            statusCode: status,
            url: u,
            details: e.message,
          );

          // Cloudinary-specific: Free plans can block PDF delivery unless enabled.
          if ((status == 401 || status == 403) &&
              _isCloudinaryHost(u) &&
              _looksLikePdfRequest(url: u, fileName: safeName)) {
            cloudinaryPdfBlocked ??= CloudinaryPdfDeliveryBlockedException(
              url: u,
              statusCode: status,
            );
          }
        }
      }
      continue;
    }
  }

  if (cloudinaryPdfBlocked != null) throw cloudinaryPdfBlocked;
  if (lastHttp != null) throw lastHttp;
  throw Exception('Download failed for all URLs: $lastError');
}

/// Downloads a Cloudinary-hosted PDF/image from a link.
///
/// Behavior:
/// - Web: triggers browser download (via `<a download>`), returns the download URL.
/// - Android: saves into device Downloads folder (using MediaStore), returns saved content URI string.
/// - iOS/desktop: saves into app Documents folder, returns local file path.
Future<Object?> downloadPdfImageFromLink({
  required String url,
  String? fileName,
  BuildContext? context,
}) async {
  final result = await downloadBytesFromLink(url: url, fileName: fileName);

  // Web: keep old contract (return the used URL) while triggering download.
  if (kIsWeb) {
    await saveBytesAsDownload(
      bytes: result.bytes,
      fileName: result.fileName,
      contentType: result.contentType,
    );
    return result.usedUrl;
  }

  return saveBytesAsDownload(
    bytes: result.bytes,
    fileName: result.fileName,
    contentType: result.contentType,
  );
}

/// Saves in-memory bytes as a downloadable file.
///
/// Behavior:
/// - Web: triggers browser download and returns `null`.
/// - Android: saves into device Downloads folder (MediaStore), returns saved content URI string.
/// - iOS/desktop: saves into app Documents folder, returns local file path.
Future<Object?> saveBytesAsDownload({
  required Uint8List bytes,
  required String fileName,
  String contentType = 'application/octet-stream',
}) async {
  final safeName = _sanitizeFileName(fileName);

  if (kIsWeb) {
    if (uio.Platform.isAndroid || uio.Platform.isIOS)
      return null; // Safety check
    final blob = html.Blob([bytes], contentType);
    final objectUrl = html.Url.createObjectUrlFromBlob(blob);
    final a = html.AnchorElement(href: objectUrl)
      ..style.display = 'none'
      ..setAttribute('download', safeName);
    html.document.body?.append(a);
    a.click();
    a.remove();
    html.Url.revokeObjectUrl(objectUrl);
    return null;
  }

  final tmpPath = await writeTempFileBytes(bytes, fileName: safeName);

  if (uio.Platform.isAndroid) {
    final uri = await saveFileToMediaStore(tmpPath);
    return uri;
  }

  final docs = await getApplicationDocumentsDirectory();

  final outPath = p.join(docs.path, safeName);
  await uio.File(tmpPath).copy(outPath);
  return outPath;
}

/// Writes bytes into a temporary file and returns its file path.
///
/// Web is unsupported.
Future<String> writeTempFileBytes(
  Uint8List bytes, {
  required String fileName,
}) async {
  if (kIsWeb) {
    throw UnsupportedError('Temporary file writing is not supported on Web');
  }
  final dir = await getTemporaryDirectory();
  final safe = fileName.trim().isEmpty ? 'temp.bin' : fileName.trim();
  final path = p.join(dir.path, safe);
  final file = uio.File(path);
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
