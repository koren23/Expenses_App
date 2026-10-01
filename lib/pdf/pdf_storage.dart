import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'pdf_storage_io.dart' if (dart.library.js_interop) 'pdf_storage_web.dart'
    as impl;

class SavedPdf {
  final String name;
  final String path;
  final DateTime modified;
  const SavedPdf(this.name, this.path, this.modified);
}

/// Where monthly PDFs live on the phone.
/// Android: written silently into the app's folder on device storage.
/// Web/PWA (iPhone): handed to the share sheet -> "Save to Files".
abstract final class PdfStorage {
  static bool get canSaveSilently => impl.canSaveSilently;

  /// Saves (overwrites) [fileName]. Returns a human readable location.
  static Future<String> save(String fileName, Uint8List bytes) =>
      impl.save(fileName, bytes);

  /// PDFs already saved by the app (empty on web).
  static Future<List<SavedPdf>> list() => impl.list();

  static Future<Uint8List> read(SavedPdf f) => impl.read(f);

  /// Lets the user pick any PDF from the phone.
  static Future<Uint8List?> pick() async {
    final r = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    return r?.files.single.bytes;
  }
}
