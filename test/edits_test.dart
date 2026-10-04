import 'package:expenses_app/data/store.dart';
import 'package:expenses_app/models/expense.dart';
import 'package:expenses_app/screens/month_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const k = MonthKey(2026, 9);

Expense exp(String id, int day, double amount, String category) => Expense(
    id: id, year: 2026, month: 9, day: day,
    description: id, amount: amount, category: category);

Future<Store> seeded() async {
  SharedPreferences.setMockInitialValues({});
  final store = await Store.load();
  await store.upsert(exp('aaa', 1, 5, 'ב'));
  await store.upsert(exp('bbb', 2, 50, 'א'));
  await store.upsert(exp('ccc', 3, 20, 'ב'));
  return store;
}

Future<void> pumpMonth(WidgetTester tester, Store store) async {
  tester.view.physicalSize = const Size(1080, 4000);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: MonthScreen(store: store, month: k, onMonthChanged: (_) {}),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  test('every change keeps a previous version, capped, restorable', () async {
    final store = await seeded();
    // Versions hold the state before each change; the first add had none.
    expect(store.versionsFor(k).length, 2);
    expect(store.versionsFor(k).first.expenses.length, 2); // newest first

    await store.remove(store.expensesFor(k).first);
    expect(store.expensesFor(k).length, 2);
    final before = store.versionsFor(k).first;
    expect(before.expenses.length, 3);

    await store.restoreVersion(k, before);
    expect(store.expensesFor(k).map((e) => e.id), ['aaa', 'bbb', 'ccc']);
    // The state before the restore is itself kept, so it can be undone.
    expect(store.versionsFor(k).first.expenses.length, 2);

    for (var i = 0; i < 20; i++) {
      await store.upsert(exp('n$i', 5, 1, 'ג'));
    }
    expect(store.versionsFor(k).length, Store.maxVersions);

    // Survives a reload from storage.
    final again = await Store.load();
    expect(again.versionsFor(k).length, Store.maxVersions);
  });

  testWidgets('deleting an expense asks for confirmation', (tester) async {
    final store = await seeded();
    await pumpMonth(tester, store);

    await tester.tap(find.text('ccc'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('מחק'));
    await tester.pumpAndSettle();
    expect(find.text('למחוק את ההוצאה "ccc"?'), findsOneWidget);

    await tester.tap(find.text('ביטול'));
    await tester.pumpAndSettle();
    expect(store.expensesFor(k).length, 3);

    await tester.tap(find.text('מחק'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('מחק').last); // the dialog's button
    await tester.pumpAndSettle();
    expect(store.expensesFor(k).map((e) => e.id), ['aaa', 'bbb']);
  });

  testWidgets('headers sort the expenses table', (tester) async {
    final store = await seeded();
    await pumpMonth(tester, store);

    List<String> order() {
      final ids = ['aaa', 'bbb', 'ccc'];
      ids.sort((a, b) => tester
          .getTopLeft(find.text(a))
          .dy
          .compareTo(tester.getTopLeft(find.text(b)).dy));
      return ids;
    }

    expect(order(), ['aaa', 'bbb', 'ccc']); // by date

    await tester.tap(find.text('סכום').first);
    await tester.pumpAndSettle();
    expect(order(), ['bbb', 'ccc', 'aaa']); // largest first

    await tester.tap(find.text('סכום').first);
    await tester.pumpAndSettle();
    expect(order(), ['aaa', 'ccc', 'bbb']);

    await tester.tap(find.text('סוג הוצאה'));
    await tester.pumpAndSettle();
    expect(order(), ['bbb', 'aaa', 'ccc']); // grouped by category

    // A row still opens its own expense after sorting.
    await tester.tap(find.text('bbb'));
    await tester.pumpAndSettle();
    expect(find.text('עריכת הוצאה'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'bbb'), findsOneWidget);
  });
}
