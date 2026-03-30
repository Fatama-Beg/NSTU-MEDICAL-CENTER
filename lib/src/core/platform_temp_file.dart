import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:universal_io/io.dart' as uio;

/// Writes bytes into a temporary file and returns its file path.
///
/// On web this is unsupported; callers should open URL directly.
Future<String> writeTempFile(
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
