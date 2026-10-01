import 'dart:js_interop';
import 'dart:typed_data';

import 'package:printing/printing.dart';
import 'package:web/web.dart' as web;

import 'pdf_storage.dart';

const canSaveSilently = false;

bool get hasPublicFolder => false;

Future<String> save(String fileName, Uint8List bytes) async {
  final file = web.File(
    [bytes.toJS].toJS,
    fileName,
    web.FilePropertyBag(type: 'application/pdf'),
  );
  final data = web.ShareData(files: [file].toJS);
  // iPhone / Android browsers: native share sheet ("Save to Files").
  if (web.window.navigator.canShare(data)) {
    try {
      await web.window.navigator.share(data).toDart;
      return 'שיתוף / שמירה בקבצים';
    } catch (_) {
      // Cancelled or not allowed: fall back to a download.
    }
  }
  await Printing.sharePdf(bytes: bytes, filename: fileName);
  return 'הורדות';
}

Future<List<SavedPdf>> list() async => const [];

Future<void> delete(String fileName) async {}

Future<bool> hasPublicAccess() async => false;

Future<bool> requestPublicAccess() async => false;

Future<String> folderPath() async => 'Files';

Future<Uint8List> read(SavedPdf f) => throw UnsupportedError('web');
