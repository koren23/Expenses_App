import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'pdf_export.dart';
import 'pdf_storage.dart';

const canSaveSilently = true;

bool get hasPublicFolder => Platform.isAndroid;

/// Visible folder in the phone's internal storage: Documents/expenses_app.
const publicFolder = '/storage/emulated/0/Documents/expenses_app';

/// Matches the only file names the app writes: one PDF per month.
final _monthFile = RegExp(r'^expenses_\d{4}_\d{2}\.pdf$');

Future<bool> hasPublicAccess() async {
  if (!Platform.isAndroid) return false;
  return await Permission.manageExternalStorage.isGranted ||
      await Permission.storage.isGranted;
}

/// Asks for "All files access" (Android 11+) or storage (Android 10 and older).
Future<bool> requestPublicAccess() async {
  if (!Platform.isAndroid) return false;
  final status = await Permission.manageExternalStorage.request();
  if (status.isGranted) return true;
  if (status.isRestricted) return (await Permission.storage.request()).isGranted;
  return false;
}

/// App-private folder used before the public one (and if access is denied).
Future<Directory> _privateDir() async {
  final base = Platform.isAndroid
      ? (await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory())
      : await getApplicationDocumentsDirectory();
  return Directory('${base.path}${Platform.pathSeparator}ExpensesPDF');
}

bool _migrated = false;

Future<Directory> _dir() async {
  if (await hasPublicAccess()) {
    final d = Directory(publicFolder);
    if (!await d.exists()) await d.create(recursive: true);
    if (!_migrated) {
      _migrated = true;
      await _moveOldFiles(d);
    }
    return d;
  }
  final d = await _privateDir();
  if (!await d.exists()) await d.create(recursive: true);
  return d;
}

/// Moves PDFs saved by older versions into the public folder.
Future<void> _moveOldFiles(Directory to) async {
  final old = await _privateDir();
  if (!await old.exists()) return;
  for (final f in old.listSync().whereType<File>()) {
    final name = f.uri.pathSegments.last;
    if (_monthFile.hasMatch(name)) await f.copy('${to.path}/$name');
  }
  await old.delete(recursive: true);
}

Future<String> folderPath() async => (await _dir()).path;

Future<String> save(String fileName, Uint8List bytes) async {
  final f = File('${(await _dir()).path}${Platform.pathSeparator}$fileName');
  await f.writeAsBytes(bytes, flush: true);
  return f.path;
}

Future<void> delete(String fileName) async {
  final f = File('${(await _dir()).path}${Platform.pathSeparator}$fileName');
  if (await f.exists()) await f.delete();
}

Future<List<SavedPdf>> list() async {
  final files = <SavedPdf>[];
  for (final f in (await _dir()).listSync().whereType<File>()) {
    final name = f.uri.pathSegments.last;
    if (!_monthFile.hasMatch(name)) continue;
    // Months without expenses or additional income don't belong in the
    // archive; such files (e.g. from older versions) are removed.
    final b = parseMonthPdf(await f.readAsBytes());
    if (b != null && b.expenses.isEmpty && b.extras.isEmpty) {
      await f.delete();
      continue;
    }
    files.add(SavedPdf(name, f.path, f.lastModifiedSync()));
  }
  return files..sort((a, b) => b.name.compareTo(a.name));
}

Future<Uint8List> read(SavedPdf f) => File(f.path).readAsBytes();
