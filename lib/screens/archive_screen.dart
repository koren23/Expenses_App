import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../data/store.dart';
import '../models/expense.dart';
import '../pdf/pdf_export.dart';
import '../pdf/pdf_storage.dart';

/// Lists the monthly PDFs saved on the phone and opens them.
class ArchiveScreen extends StatefulWidget {
  final Store store;
  const ArchiveScreen({super.key, required this.store});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  late Future<List<SavedPdf>> _files;

  @override
  void initState() {
    super.initState();
    _files = PdfStorage.list();
    // Refresh whenever something was exported.
    widget.store.addListener(_reload);
  }

  @override
  void dispose() {
    widget.store.removeListener(_reload);
    super.dispose();
  }

  void _reload() => setState(() => _files = PdfStorage.list());

  void _open(String name, Uint8List bytes) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PdfViewerScreen(store: widget.store, name: name, bytes: bytes),
    ));
  }

  Future<void> _pick() async {
    final bytes = await PdfStorage.pick();
    if (bytes != null && mounted) _open('PDF', bytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ארכיון PDF')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pick,
        icon: const Icon(Icons.folder_open),
        label: const Text('פתח קובץ'),
      ),
      body: FutureBuilder<List<SavedPdf>>(
        future: _files,
        builder: (context, snap) {
          final files = snap.data ?? const [];
          if (files.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  PdfStorage.canSaveSilently
                      ? 'עדיין אין קבצי PDF שמורים.'
                      : 'לחץ "פתח קובץ" ובחר PDF ששמרת בטלפון.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            itemCount: files.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final f = files[i];
              return ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: Text(_title(f.name)),
                subtitle: Text(f.name),
                onTap: () async => _open(f.name, await PdfStorage.read(f)),
              );
            },
          );
        },
      ),
    );
  }

  /// expenses_2026_09.pdf -> "ספטמבר 2026"
  String _title(String name) {
    final m = RegExp(r'(\d{4})_(\d{2})').firstMatch(name);
    if (m == null) return name;
    return monthLabel(MonthKey(int.parse(m[1]!), int.parse(m[2]!)));
  }
}

class PdfViewerScreen extends StatelessWidget {
  final Store store;
  final String name;
  final Uint8List bytes;

  const PdfViewerScreen({
    super.key,
    required this.store,
    required this.name,
    required this.bytes,
  });

  Future<void> _import(BuildContext context, MonthBackup b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('שחזור ${monthLabel(b.month)}'),
        content: Text('הנתונים של ${monthLabel(b.month)} באפליקציה יוחלפו '
            'בנתונים מהקובץ (${b.expenses.length} הוצאות, '
            '${b.extras.length} הכנסות נוספות). להמשיך?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ביטול'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('שחזר'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await store.importMonth(b.month, b.expenses, b.extras, b.incomeOverride);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('הנתונים שוחזרו')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final backup = parseMonthPdf(bytes);
    return Scaffold(
      appBar: AppBar(
        title: Text(backup == null ? name : monthLabel(backup.month)),
        actions: [
          if (backup != null)
            IconButton(
              tooltip: 'שחזר נתונים לאפליקציה',
              icon: const Icon(Icons.restore),
              onPressed: () => _import(context, backup),
            ),
        ],
      ),
      body: PdfPreview(
        build: (_) async => bytes,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        allowPrinting: false,
        pdfFileName: name,
      ),
    );
  }
}
