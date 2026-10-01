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
    store.extrasFor(k),
  ));
  final where = await PdfStorage.save(k.fileName, bytes);
  await store.markExported(k);
  return where;
}

/// Brings the month's single PDF in line with the data: rewritten when the
/// month has data, deleted when it became empty.
Future<void> syncMonth(Store store, MonthKey k) async {
  if (store.hasData(k)) {
    await exportMonth(store, k);
  } else {
    await PdfStorage.delete(k.fileName);
    await store.clearExported(k);
  }
}
