import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

Future<Uint8List?> showSignaturePadDialog(
  BuildContext context, {
  String title = 'Draw signature',
  double width = 380,
  double height = 160,
}) {
  return showDialog<Uint8List?>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return _SignaturePadDialog(title: title, width: width, height: height);
    },
  );
}

class _SignaturePadDialog extends StatefulWidget {
  final String title;
  final double width;
  final double height;

  const _SignaturePadDialog({
    required this.title,
    required this.width,
    required this.height,
  });

  @override
  State<_SignaturePadDialog> createState() => _SignaturePadDialogState();
}

class _SignaturePadDialogState extends State<_SignaturePadDialog> {
  final List<Offset?> _points = <Offset?>[];
  Size _padSize = const Size(320, 160);

  static const double _strokeWidth = 3.0;

  void _clear() {
    setState(() {
      _points.clear();
    });
  }

  bool get _hasInk => _points.any((p) => p != null);

  Future<Uint8List> _exportPng(Size size, {required double pixelRatio}) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    final paint = ui.Paint()
      ..color = const Color(0xFF111827)
      ..strokeCap = ui.StrokeCap.round
      ..strokeJoin = ui.StrokeJoin.round
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;

    for (int i = 0; i < _points.length - 1; i++) {
      final p1 = _points[i];
      final p2 = _points[i + 1];
      if (p1 == null || p2 == null) continue;
      canvas.drawLine(p1, p2, paint);
    }

    final picture = recorder.endRecording();

    // Render at higher pixel ratio for crisp signatures.
    final pr = pixelRatio.clamp(1.0, 3.0);
    final img = await picture.toImage(
      (size.width * pr).round(),
      (size.height * pr).round(),
    );

    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      // Fallback: empty transparent PNG isn't trivial here, so just throw.
      throw StateError('Failed to export signature');
    }
    return byteData.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: widget.width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Draw with mouse/finger. Background will be transparent.',
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final padSize = Size(constraints.maxWidth, widget.height);
                _padSize = padSize;
                return Container(
                  height: widget.height,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: GestureDetector(
                      onPanStart: (d) {
                        setState(() {
                          _points.add(d.localPosition);
                        });
                      },
                      onPanUpdate: (d) {
                        setState(() {
                          _points.add(d.localPosition);
                        });
                      },
                      onPanEnd: (_) {
                        setState(() {
                          _points.add(null);
                        });
                      },
                      child: CustomPaint(
                        painter: _SignaturePainter(_points),
                        size: padSize,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _hasInk ? _clear : null,
          child: const Text('Clear'),
        ),
        ElevatedButton(
          onPressed: _hasInk
              ? () async {
                  // Export at the actual pad size.
                  final exportSize = _padSize;
                  try {
                    final pngBytes = await _exportPng(
                      exportSize,
                      pixelRatio: pixelRatio,
                    );
                    if (!mounted) return;
                    Navigator.of(context).pop(pngBytes);
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Export failed: $e')),
                    );
                  }
                }
              : null,
          child: const Text('Use signature'),
        ),
      ],
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<Offset?> points;

  _SignaturePainter(this.points);

  @override
  void paint(ui.Canvas canvas, Size size) {
    final paint = ui.Paint()
      ..color = const Color(0xFF111827)
      ..strokeCap = ui.StrokeCap.round
      ..strokeJoin = ui.StrokeJoin.round
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 3.0;

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      if (p1 == null || p2 == null) continue;
      canvas.drawLine(p1, p2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
