import 'package:expenses_app/data/store.dart';
import 'package:expenses_app/models/expense.dart';
import 'package:expenses_app/screens/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('numbers are detected for left-to-right layout', () {
    for (final s in ['-1388.26', '1050', '9.000%', '-5.500%', '2000*+', '0']) {
      expect(isNumericCell(s), isTrue, reason: s);
    }
    for (final s in ['סך הכל', 'מים', 'ספטמבר 2026', '']) {
      expect(isNumericCell(s), isFalse, reason: s);
    }
  });

  testWidgets('negative amounts are rendered LTR (minus in front)', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: SheetTable(headers: ['רווח'], rows: [['-1388.26']]),
        ),
      ),
    ));
    final text = tester.widget<Text>(find.text('-1388.26'));
    expect(text.textDirection, TextDirection.ltr);
  });

  test('one pending PDF per changed month, deleted when emptied', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await Store.load();
    final k = MonthKey(2026, 9);
    final e = Expense(
        id: '1', year: 2026, month: 9, day: 1,
        description: 'מים', amount: 4.5, category: 'שתיה');
    await store.upsert(e);
    expect(store.pendingExports(), [k]);

    await store.markExported(k);
    expect(store.pendingExports(), isEmpty);

    await store.remove(e);
    expect(store.hasData(k), isFalse);
    expect(store.pendingExports(), [k]); // stale PDF must be deleted
    await store.clearExported(k);
    expect(store.pendingExports(), isEmpty);
  });

  test('a month with only an income gets no PDF', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await Store.load();
    final k = MonthKey(2026, 8);
    await store.setIncomeOverride(k, 5000);
    expect(store.hasData(k), isFalse);
    expect(store.pendingExports(), isNot(contains(k)));
  });
}
