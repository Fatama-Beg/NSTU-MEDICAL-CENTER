import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

/// Processes a signature image so that only the ink remains:
/// - converts paper/shadow background to transparency (when needed)
/// - optionally crops tightly around the ink
///
/// Always returns a PNG (with alpha).
Future<Uint8List> processSignatureToTransparentPng(
  Uint8List inputBytes, {
  bool adaptive = true,
  int backgroundTolerance = 65,
  int softRange = 90,
  int whiteThreshold = 240,
  bool crop = true,
  int cropPaddingPx = 10,
  int cropMinAlpha = 12,
}) async {
  final codec = await ui.instantiateImageCodec(inputBytes);
  final frame = await codec.getNextFrame();
  final image = frame.image;

  final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (rgba == null) return inputBytes;
  final data = rgba.buffer.asUint8List();

  // If the image already contains transparency, assume it is already ink-only
  // (eg. from the signature pad) and skip background removal.
  final hasAnyTransparency = _hasAnyTransparency(data);
  final processedRgba = hasAnyTransparency
      ? data
      : _removeBackgroundToAlpha(
          data,
          width: image.width,
          height: image.height,
          adaptive: adaptive,
          backgroundTolerance: backgroundTolerance,
          softRange: softRange,
          whiteThreshold: whiteThreshold,
        );

  final maybeCroppedRgba = crop
      ? _cropToAlphaBounds(
          processedRgba,
          width: image.width,
          height: image.height,
          minAlpha: cropMinAlpha,
          paddingPx: cropPaddingPx,
        )
      : _CroppedRgba(
          rgba: processedRgba,
          width: image.width,
          height: image.height,
        );

  final outImage = await _rgbaToImage(
    maybeCroppedRgba.rgba,
    width: maybeCroppedRgba.width,
    height: maybeCroppedRgba.height,
  );
  final png = await outImage.toByteData(format: ui.ImageByteFormat.png);
  if (png == null) return inputBytes;
  return png.buffer.asUint8List();
}

/// Removes a background by converting it to transparency.
///
/// This is tuned for doctor signatures captured from paper where the ink is dark
/// and the background is lighter (often not pure white due to shadows).
///
/// By default it estimates the background color from the image border and
/// removes pixels that are close to that background color.
///
/// - [backgroundTolerance]: RGB distance below which pixels become transparent.
/// - [softRange]: extra distance range used to fade alpha smoothly.
///
/// Legacy params:
/// - [whiteThreshold]: used only when [adaptive] is false.
///
/// Returns a PNG (with alpha) regardless of input encoding.
Future<Uint8List> removeLightBackgroundToTransparent(
  Uint8List inputBytes, {
  bool adaptive = true,
  int backgroundTolerance = 60,
  int softRange = 80,
  int whiteThreshold = 240,
}) async {
  final codec = await ui.instantiateImageCodec(inputBytes);
  final frame = await codec.getNextFrame();
  final image = frame.image;
  final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (rgba == null) return inputBytes;
  final data = rgba.buffer.asUint8List();

  final processed = _removeBackgroundToAlpha(
    data,
    width: image.width,
    height: image.height,
    adaptive: adaptive,
    backgroundTolerance: backgroundTolerance,
    softRange: softRange,
    whiteThreshold: whiteThreshold,
  );

  final outImage = await _rgbaToImage(
    processed,
    width: image.width,
    height: image.height,
  );
  final png = await outImage.toByteData(format: ui.ImageByteFormat.png);
  if (png == null) return inputBytes;
  return png.buffer.asUint8List();
}

Uint8List _removeBackgroundToAlpha(
  Uint8List rgba, {
  required int width,
  required int height,
  required bool adaptive,
  required int backgroundTolerance,
  required int softRange,
  required int whiteThreshold,
}) {
  var tol = backgroundTolerance;
  var soft = softRange;
  if (tol < 0) tol = 0;
  if (soft < 1) soft = 1;
  final wt = whiteThreshold.clamp(0, 255);

  final out = Uint8List.fromList(rgba);

  final bgCandidates = adaptive
      ? _estimateBackgroundCandidatesRgba(out, width: width, height: height)
      : const <(int, int, int)>[];

  // Ink extraction: use both luminance difference and RGB distance.
  // This tends to preserve the stroke while removing uneven paper shading.
  final fadeDenom = math.max(1, soft);
  for (int i = 0; i < out.lengthInBytes; i += 4) {
    final a = out[i + 3];
    if (a == 0) continue;
    final r = out[i];
    final g = out[i + 1];
    final b = out[i + 2];
    final lum = _luminance(r, g, b);

    if (adaptive && bgCandidates.isNotEmpty) {
      // Pick the best-matching background color for this pixel.
      (int, int, int)? bestBg;
      int bestDist2 = 0x7fffffff;
      for (final bg in bgCandidates) {
        final dr = r - bg.$1;
        final dg = g - bg.$2;
        final db = b - bg.$3;
        final d2 = dr * dr + dg * dg + db * db;
        if (d2 < bestDist2) {
          bestDist2 = d2;
          bestBg = bg;
        }
      }

      final chosen = bestBg ?? (255, 255, 255);
      final bgLum = _luminance(chosen.$1, chosen.$2, chosen.$3);
      final deltaLum = bgLum - lum; // >0 means darker than background

      // Keep very dark pixels fully opaque.
      if (lum <= 75.0 || deltaLum >= 22.0) {
        continue;
      }

      // Shadow/grey paper: bump tolerance depending on chosen background.
      final effectiveTolerance = (tol + ((255.0 - bgLum) * 0.45).round()).clamp(
        0,
        255,
      );
      final tol2 = effectiveTolerance * effectiveTolerance;
      final fadeMax = effectiveTolerance + soft;
      final fadeMax2 = fadeMax * fadeMax;

      // If close to background (or not darker than it), drop alpha.
      if (bestDist2 <= tol2 || deltaLum <= 2.5) {
        out[i + 3] = 0;
        continue;
      }

      if (bestDist2 <= fadeMax2) {
        final dist = math.sqrt(bestDist2.toDouble());
        final t = (dist - effectiveTolerance) / fadeDenom;
        final scale = math.max(0.0, math.min(1.0, t));
        out[i + 3] = (a * scale).round();
      }
      continue;
    }

    // Non-adaptive: near-white removal.
    if (lum <= wt) continue;
    final fullTransparentLum = math.min(255, wt + soft);
    if (lum >= fullTransparentLum) {
      out[i + 3] = 0;
      continue;
    }
    final denom = math.max(1, fullTransparentLum - wt);
    final t = (lum - wt) / denom;
    final scale = 1.0 - t;
    out[i + 3] = (a * math.max(0.0, math.min(1.0, scale))).round();
  }

  // Cleanup: tiny leftover alpha from paper noise should not affect cropping.
  for (int i = 3; i < out.lengthInBytes; i += 4) {
    final a = out[i];
    if (a != 0 && a < 10) out[i] = 0;
  }

  return out;
}

/// Returns multiple candidates for background color:
/// - overall border median
/// - each corner region median (helps with uneven shadow in a corner)
List<(int, int, int)> _estimateBackgroundCandidatesRgba(
  Uint8List rgba, {
  required int width,
  required int height,
}) {
  final candidates = <(int, int, int)>[];
  candidates.add(
    _estimateBackgroundColorRgba(rgba, width: width, height: height),
  );

  final cornerSize = math.max(8, (math.min(width, height) * 0.10).round());
  candidates.add(
    _estimateRegionMedianRgba(
      rgba,
      width: width,
      height: height,
      left: 0,
      top: 0,
      regionWidth: cornerSize,
      regionHeight: cornerSize,
    ),
  );
  candidates.add(
    _estimateRegionMedianRgba(
      rgba,
      width: width,
      height: height,
      left: math.max(0, width - cornerSize),
      top: 0,
      regionWidth: cornerSize,
      regionHeight: cornerSize,
    ),
  );
  candidates.add(
    _estimateRegionMedianRgba(
      rgba,
      width: width,
      height: height,
      left: 0,
      top: math.max(0, height - cornerSize),
      regionWidth: cornerSize,
      regionHeight: cornerSize,
    ),
  );
  candidates.add(
    _estimateRegionMedianRgba(
      rgba,
      width: width,
      height: height,
      left: math.max(0, width - cornerSize),
      top: math.max(0, height - cornerSize),
      regionWidth: cornerSize,
      regionHeight: cornerSize,
    ),
  );

  // Deduplicate near-identical colors.
  final unique = <(int, int, int)>[];
  const dedupeDist2 = 8 * 8; // within ~8 RGB units
  for (final c in candidates) {
    var exists = false;
    for (final u in unique) {
      final dr = c.$1 - u.$1;
      final dg = c.$2 - u.$2;
      final db = c.$3 - u.$3;
      if (dr * dr + dg * dg + db * db <= dedupeDist2) {
        exists = true;
        break;
      }
    }
    if (!exists) unique.add(c);
  }
  return unique;
}

(int, int, int) _estimateRegionMedianRgba(
  Uint8List rgba, {
  required int width,
  required int height,
  required int left,
  required int top,
  required int regionWidth,
  required int regionHeight,
}) {
  final rs = <int>[];
  final gs = <int>[];
  final bs = <int>[];

  // int.clamp() returns num, so cast back to int.
  final x0 = left.clamp(0, math.max(0, width - 1)).toInt();
  final y0 = top.clamp(0, math.max(0, height - 1)).toInt();
  final x1 = math.min(width, x0 + regionWidth);
  final y1 = math.min(height, y0 + regionHeight);

  for (int y = y0; y < y1; y++) {
    for (int x = x0; x < x1; x++) {
      final idx = (y * width + x) * 4;
      final a = rgba[idx + 3];
      if (a == 0) continue;
      rs.add(rgba[idx]);
      gs.add(rgba[idx + 1]);
      bs.add(rgba[idx + 2]);
    }
  }

  if (rs.isEmpty) return (255, 255, 255);
  rs.sort();
  gs.sort();
  bs.sort();
  final mid = rs.length ~/ 2;
  return (rs[mid], gs[mid], bs[mid]);
}

bool _hasAnyTransparency(Uint8List rgba) {
  // Sample a subset for speed.
  final step = math.max(4, (rgba.lengthInBytes / 12000).round() * 4);
  for (int i = 3; i < rgba.lengthInBytes; i += step) {
    if (rgba[i] < 250) return true;
  }
  return false;
}

class _CroppedRgba {
  final Uint8List rgba;
  final int width;
  final int height;

  const _CroppedRgba({
    required this.rgba,
    required this.width,
    required this.height,
  });
}

_CroppedRgba _cropToAlphaBounds(
  Uint8List rgba, {
  required int width,
  required int height,
  required int minAlpha,
  required int paddingPx,
}) {
  final bounds = _findAlphaBounds(
    rgba,
    width: width,
    height: height,
    minAlpha: minAlpha,
  );
  if (bounds == null) {
    return _CroppedRgba(rgba: rgba, width: width, height: height);
  }

  final left = math.max(0, bounds.left - paddingPx);
  final top = math.max(0, bounds.top - paddingPx);
  final right = math.min(width - 1, bounds.right + paddingPx);
  final bottom = math.min(height - 1, bounds.bottom + paddingPx);

  final cropW = right - left + 1;
  final cropH = bottom - top + 1;
  if (cropW <= 1 || cropH <= 1) {
    return _CroppedRgba(rgba: rgba, width: width, height: height);
  }

  final out = Uint8List(cropW * cropH * 4);
  for (int y = 0; y < cropH; y++) {
    final srcRowStart = ((top + y) * width + left) * 4;
    final dstRowStart = (y * cropW) * 4;
    out.setRange(dstRowStart, dstRowStart + cropW * 4, rgba, srcRowStart);
  }

  return _CroppedRgba(rgba: out, width: cropW, height: cropH);
}

class _AlphaBounds {
  final int left;
  final int top;
  final int right;
  final int bottom;

  const _AlphaBounds(this.left, this.top, this.right, this.bottom);
}

_AlphaBounds? _findAlphaBounds(
  Uint8List rgba, {
  required int width,
  required int height,
  required int minAlpha,
}) {
  var minX = width;
  var minY = height;
  var maxX = -1;
  var maxY = -1;

  for (int y = 0; y < height; y++) {
    int rowIdx = (y * width) * 4;
    for (int x = 0; x < width; x++) {
      final a = rgba[rowIdx + 3];
      if (a >= minAlpha) {
        if (x < minX) minX = x;
        if (y < minY) minY = y;
        if (x > maxX) maxX = x;
        if (y > maxY) maxY = y;
      }
      rowIdx += 4;
    }
  }

  if (maxX < 0 || maxY < 0) return null;
  return _AlphaBounds(minX, minY, maxX, maxY);
}

Future<ui.Image> _rgbaToImage(
  Uint8List rgba, {
  required int width,
  required int height,
}) {
  final completer = Completer<ui.Image>();
  ui.decodeImageFromPixels(
    rgba,
    width,
    height,
    ui.PixelFormat.rgba8888,
    completer.complete,
  );
  return completer.future;
}

/// Returns a robust estimate of the background color (R,G,B) by sampling border pixels.
///
/// Uses per-channel median to reduce impact of ink and noise.
(int, int, int) _estimateBackgroundColorRgba(
  Uint8List rgba, {
  required int width,
  required int height,
}) {
  // Sample thickness: ~4% of the smallest dimension, at least 2px.
  final thickness = math.max(2, (math.min(width, height) * 0.04).round());

  final rs = <int>[];
  final gs = <int>[];
  final bs = <int>[];

  void addPixel(int x, int y) {
    final idx = (y * width + x) * 4;
    if (idx < 0 || idx + 3 >= rgba.lengthInBytes) return;
    final a = rgba[idx + 3];
    if (a == 0) return;
    rs.add(rgba[idx]);
    gs.add(rgba[idx + 1]);
    bs.add(rgba[idx + 2]);
  }

  // Top/bottom rows.
  for (int y = 0; y < thickness; y++) {
    for (int x = 0; x < width; x++) {
      addPixel(x, y);
      addPixel(x, height - 1 - y);
    }
  }
  // Left/right cols.
  for (int x = 0; x < thickness; x++) {
    for (int y = 0; y < height; y++) {
      addPixel(x, y);
      addPixel(width - 1 - x, y);
    }
  }

  if (rs.isEmpty) return (255, 255, 255);

  rs.sort();
  gs.sort();
  bs.sort();
  final mid = rs.length ~/ 2;
  return (rs[mid], gs[mid], bs[mid]);
}

double _luminance(int r, int g, int b) {
  // Relative luminance (sRGB-ish).
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}
