import 'package:flutter/material.dart';

import '../data/store.dart';
import '../logic/summary.dart';
import '../models/expense.dart';
import '../pdf/pdf_export.dart';
import 'archive_screen.dart';

/// Previous versions of one month: how it looked before each change.
class VersionsScreen extends StatelessWidget {
  final Store store;
  final MonthKey month;

  const VersionsScreen({super.key, required this.store, required this.month});

  Future<void> _open(BuildContext context, MonthVersion v) async {
    final navigator = Navigator.of(context);
    final bytes = await buildMonthPdf(MonthBackup(
      month,
      v.expenses,
      v.incomeOverride ?? store.defaultIncome,
      v.incomeOverride,
      v.extras,
    ));
    navigator.push(MaterialPageRoute(
      builder: (_) => PdfViewerScreen(
        store: store,
        name: month.fileName,
        bytes: bytes,
        showHistory: false,
      ),
    ));
  }

  String _when(DateTime t) =>
      '${t.day}/${t.month}/${t.year} ${t.hour}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final versions = store.versionsFor(month);
        return Scaffold(
          appBar: AppBar(title: Text('גרסאות קודמות - ${monthLabel(month)}')),
          body: versions.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'אין גרסאות קודמות לחודש הזה.\n'
                      'לפני כל שינוי נשמרת גרסה, עד ${Store.maxVersions} אחרונות.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: versions.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final v = versions[i];
                    return ListTile(
                      leading: const Icon(Icons.history),
                      title: Text(_when(v.savedAt)),
                      subtitle: Text('${v.expenses.length} הוצאות, '
                          'סך הכל ${formatAmount(monthTotal(v.expenses))}'),
                      onTap: () => _open(context, v),
                    );
                  },
                ),
        );
      },
    );
  }
}
