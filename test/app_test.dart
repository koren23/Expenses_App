import 'package:expenses_app/data/store.dart';
import 'package:expenses_app/main.dart';
import 'package:expenses_app/models/expense.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('month screen shows expenses, category summary and profit',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = await Store.load();
    final now = MonthKey.now();
    await store.setDefaultIncome(1000);
    await store.upsert(Expense(
        id: '1', year: now.year, month: now.month, day: 1,
        description: 'מים', amount: 4.5, category: 'שתיה'));
    await store.upsert(Expense(
        id: '2', year: now.year, month: now.month, day: 2,
        description: 'פיצה', amount: 45.5, category: 'אוכל'));

    await store.upsertExtra(ExtraIncome(
        id: 'x', year: now.year, month: now.month,
        description: 'בונוס', amount: 100));

    tester.view.physicalSize = const Size(1080, 4000);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ExpensesApp(store: store));
    await tester.pumpAndSettle();

    expect(find.text('מים'), findsOneWidget);
    expect(find.text('50'), findsNWidgets(2)); // total row + expenses cell
    expect(find.text('9.000%'), findsOneWidget);
    expect(find.text('91.000%'), findsOneWidget);
    expect(find.text('בונוס'), findsOneWidget);
    expect(find.text('1050'), findsOneWidget); // profit incl. extra income
  });
}
