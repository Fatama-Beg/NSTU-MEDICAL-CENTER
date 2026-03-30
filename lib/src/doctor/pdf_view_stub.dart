import 'package:flutter/material.dart';

class PdfViewPage extends StatelessWidget {
  final String filePath;

  const PdfViewPage({super.key, required this.filePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report PDF')),
      body: const Center(
        child: Text('PDF viewer not available on this platform'),
      ),
    );
  }
}
