import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import 'pdf_storage.dart';

const canSaveSilently = true;

Future<Directory> _dir() async {
  final base = Platform.isAndroid
      ? (await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory())
      : await getApplicationDocumentsDirectory();
  final d = Directory('${base.path}${Platform.pathSeparator}ExpensesPDF');
  if (!await d.exists()) await d.create(recursive: true);
  return d;
}

Future<String> save(String fileName, Uint8List bytes) async {
  final f = File('${(await _dir()).path}${Platform.pathSeparator}$fileName');
  await f.writeAsBytes(bytes, flush: true);
  return f.path;
}

Future<List<SavedPdf>> list() async {
  final files = (await _dir())
      .listSync()
      .whereType<File>()
      .where((f) => f.path.toLowerCase().endsWith('.pdf'))
      .map((f) => SavedPdf(
            f.uri.pathSegments.last,
            f.path,
            f.lastModifiedSync(),
          ))
      .toList()
    ..sort((a, b) => b.name.compareTo(a.name));
  return files;
}

Future<Uint8List> read(SavedPdf f) => File(f.path).readAsBytes();
