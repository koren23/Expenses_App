import 'dart:convert';

import 'package:expenses_app/data/store.dart';
import 'package:expenses_app/models/expense.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('data saved by an older version survives the update', () async {
    // What the first versions stored: no extras, no history.
    SharedPreferences.setMockInitialValues({
      'expenses_app_v1': jsonEncode({
        'expenses': [
          {'id': '1', 'y': 2026, 'm': 9, 'd': 3, 'desc': 'מים', 'amt': 4.5, 'cat': 'שתיה'},
          {'id': '2', 'y': 2026, 'm': 9, 'd': 7, 'desc': 'פיצה', 'amt': 45.5, 'cat': 'אוכל'},
        ],
        'defaultIncome': 5000,
        'income': {'2026-09': 6000},
        'modified': {'2026-09': 1},
        'exported': {'2026-09': 2},
      }),
    });
    final store = await Store.load();
    const k = MonthKey(2026, 9);
    expect(store.expensesFor(k).map((e) => e.description), ['מים', 'פיצה']);
    expect(store.defaultIncome, 5000);
    expect(store.incomeFor(k), 6000);
    expect(store.versionsFor(k), isEmpty);

    // Still there after the new version writes its own format and reloads.
    await store.upsert(Expense(
        id: '3', year: 2026, month: 9, day: 9,
        description: 'ספר', amount: 10, category: 'ספרים'));
    final again = await Store.load();
    expect(again.expensesFor(k).length, 3);
    expect(again.incomeFor(k), 6000);
  });
}
