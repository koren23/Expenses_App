import '../models/expense.dart';

class CategorySum {
  final String category;
  final double sum;
  final double fraction;
  const CategorySum(this.category, this.sum, this.fraction);
}

double round2(double v) => (v * 100).roundToDouble() / 100;

double monthTotal(Iterable<Expense> expenses) =>
    round2(expenses.fold(0.0, (s, e) => s + e.amount));

/// Sum per category in order of first appearance (like the sheet).
List<CategorySum> categorySums(List<Expense> expenses) {
  final total = monthTotal(expenses);
  final sums = <String, double>{};
  for (final e in expenses) {
    final c = e.category.trim();
    sums[c] = (sums[c] ?? 0) + e.amount;
  }
  return [
    for (final entry in sums.entries)
      CategorySum(entry.key, round2(entry.value),
          total == 0 ? 0 : entry.value / total),
  ];
}

/// Same format as the sheet's TEXT(x, "0.000%").
String formatPercent(double fraction) =>
    '${(fraction * 100).toStringAsFixed(3)}%';

String formatAmount(double v) {
  final r = round2(v);
  if (r == r.truncateToDouble()) return r.toInt().toString();
  return r.toStringAsFixed(2).replaceFirst(RegExp(r'0$'), '');
}
