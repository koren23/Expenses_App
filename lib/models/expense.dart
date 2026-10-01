class Expense {
  final String id;
  final int year;
  final int month;
  final int day;
  final String description;
  final double amount;
  final String category;

  const Expense({
    required this.id,
    required this.year,
    required this.month,
    required this.day,
    required this.description,
    required this.amount,
    required this.category,
  });

  Expense copyWith({
    int? day,
    String? description,
    double? amount,
    String? category,
  }) =>
      Expense(
        id: id,
        year: year,
        month: month,
        day: day ?? this.day,
        description: description ?? this.description,
        amount: amount ?? this.amount,
        category: category ?? this.category,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'y': year,
        'm': month,
        'd': day,
        'desc': description,
        'amt': amount,
        'cat': category,
      };

  factory Expense.fromJson(Map<String, dynamic> j) => Expense(
        id: j['id'] as String,
        year: j['y'] as int,
        month: j['m'] as int,
        day: j['d'] as int,
        description: j['desc'] as String,
        amount: (j['amt'] as num).toDouble(),
        category: j['cat'] as String,
      );
}

/// Identifies a calendar month, e.g. 2026-09.
class MonthKey implements Comparable<MonthKey> {
  final int year;
  final int month;
  const MonthKey(this.year, this.month);

  factory MonthKey.now() {
    final n = DateTime.now();
    return MonthKey(n.year, n.month);
  }

  factory MonthKey.parse(String s) {
    final p = s.split('-');
    return MonthKey(int.parse(p[0]), int.parse(p[1]));
  }

  MonthKey get next =>
      month == 12 ? MonthKey(year + 1, 1) : MonthKey(year, month + 1);
  MonthKey get previous =>
      month == 1 ? MonthKey(year - 1, 12) : MonthKey(year, month - 1);

  int get daysInMonth => DateTime(year, month + 1, 0).day;

  @override
  String toString() => '$year-${month.toString().padLeft(2, '0')}';

  String get fileName => 'expenses_${year}_${month.toString().padLeft(2, '0')}.pdf';

  @override
  int compareTo(MonthKey o) =>
      year != o.year ? year.compareTo(o.year) : month.compareTo(o.month);

  @override
  bool operator ==(Object other) =>
      other is MonthKey && other.year == year && other.month == month;

  @override
  int get hashCode => year * 100 + month;
}

const hebrewMonths = [
  'ינואר', 'פברואר', 'מרץ', 'אפריל', 'מאי', 'יוני',
  'יולי', 'אוגוסט', 'ספטמבר', 'אוקטובר', 'נובמבר', 'דצמבר',
];

String monthLabel(MonthKey k) => '${hebrewMonths[k.month - 1]} ${k.year}';

/// Extra income for a month on top of the regular income (הכנסה נוספת).
class ExtraIncome {
  final String id;
  final int year;
  final int month;
  final String description;
  final double amount;

  const ExtraIncome({
    required this.id,
    required this.year,
    required this.month,
    required this.description,
    required this.amount,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'y': year,
        'm': month,
        'desc': description,
        'amt': amount,
      };

  factory ExtraIncome.fromJson(Map<String, dynamic> j) => ExtraIncome(
        id: j['id'] as String,
        year: j['y'] as int,
        month: j['m'] as int,
        description: j['desc'] as String,
        amount: (j['amt'] as num).toDouble(),
      );
}
