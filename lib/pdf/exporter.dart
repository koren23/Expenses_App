import '../data/store.dart';
import '../models/expense.dart';
import 'pdf_export.dart';
import 'pdf_storage.dart';

/// Writes (or overwrites) the month's PDF and records the export time.
Future<String> exportMonth(Store store, MonthKey k) async {
  final bytes = await buildMonthPdf(MonthBackup(
    k,
    store.expensesFor(k),
    store.incomeFor(k),
    store.hasIncomeOverride(k) ? store.incomeFor(k) : null,
  ));
  final where = await PdfStorage.save(k.fileName, bytes);
  await store.markExported(k);
  return where;
}
