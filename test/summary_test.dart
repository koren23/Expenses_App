import 'dart:io';

import 'package:expenses_app/logic/summary.dart';
import 'package:expenses_app/models/expense.dart';
import 'package:expenses_app/pdf/pdf_export.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;

Expense _e(String desc, int day, double amt, String cat) => Expense(
    id: '$desc$day$amt', year: 2026, month: 9, day: day,
    description: desc, amount: amt, category: cat);

// Category totals from the Sept sheet.
final sept = [
  _e('a', 1, 120.13, 'מחלקה'),
  _e('b', 2, 41.55, 'גלי'),
  _e('c', 3, 199.64, 'אוכל'),
  _e('d', 4, 227.05, 'בגדים'),
  _e('e', 5, 6.28, 'לעצמי'),
  _e('f', 6, 86, 'חול'),
  _e('g', 7, 10.5, 'שתיה'),
  _e('h', 8, 424.96, 'ספרים'),
  _e('i', 28, 850, 'גאורגיה'),
  _e('j', 30, 878.95, ' גאורגיה '),
];

void main() {
  test('totals and percentages match the sheet', () {
    expect(monthTotal(sept), 2845.06);
    final sums = {for (final s in categorySums(sept)) s.category: s};
    expect(sums.length, 9);
    expect(sums['גאורגיה']!.sum, 1728.95);
    expect(formatPercent(sums['גאורגיה']!.fraction), '60.770%');
    expect(formatPercent(sums['מחלקה']!.fraction), '4.222%');
    expect(formatPercent(sums['שתיה']!.fraction), '0.369%');
    expect(formatPercent(sums['ספרים']!.fraction), '14.937%');
  });

  test('profit like the sheet', () {
    expect(formatAmount(1456.8 - monthTotal(sept)), '-1388.26');
  });

  test('pdf round trip keeps the data', () async {
    pw.Font font(String n) => pw.Font.ttf(
        File('assets/fonts/$n.ttf').readAsBytesSync().buffer.asByteData());
    final he = font('NotoSansHebrew-Regular');
    final bytes = await buildMonthPdf(
      MonthBackup(const MonthKey(2026, 9), sept, 1456.8, 1456.8),
      theme: pw.ThemeData.withFont(
          base: font('NotoSans-Regular'), bold: font('NotoSans-Regular'), fontFallback: [he]),
    );
    final back = parseMonthPdf(bytes)!;
    expect(back.month, const MonthKey(2026, 9));
    expect(back.incomeOverride, 1456.8);
    expect(back.expenses.map((e) => e.toJson()).toList(),
        sept.map((e) => e.toJson()).toList());
    File('build/test_sept.pdf')
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes);
  });
}
