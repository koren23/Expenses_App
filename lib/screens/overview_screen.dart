import 'package:flutter/material.dart';

import '../data/store.dart';
import '../logic/summary.dart';
import '../models/expense.dart';
import 'widgets.dart';

/// All months next to each other: total spent, income and profit.
class OverviewScreen extends StatelessWidget {
  final Store store;
  final ValueChanged<MonthKey> onOpenMonth;

  const OverviewScreen({super.key, required this.store, required this.onOpenMonth});

  Future<void> _editIncome(BuildContext context, MonthKey k) async {
    final controller = TextEditingController(text: formatAmount(store.incomeFor(k)));
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('הכנסה - ${monthLabel(k)}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
              helperText: 'ברירת מחדל: ${formatAmount(store.defaultIncome)}'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'open'),
            child: const Text('פתח חודש'),
          ),
          if (store.hasIncomeOverride(k))
            TextButton(
              onPressed: () => Navigator.pop(context, 'reset'),
              child: const Text('אפס לברירת מחדל'),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'save'),
            child: const Text('שמור'),
          ),
        ],
      ),
    );
    switch (result) {
      case 'open':
        onOpenMonth(k);
      case 'reset':
        await store.setIncomeOverride(k, null);
      case 'save':
        final v = parseAmount(controller.text);
        if (v != null) await store.setIncomeOverride(k, v);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final months = store.months.reversed.toList();
        final rows = <List<String>>[];
        final profits = <double>[];
        var sumTotal = 0.0, sumIncome = 0.0;
        for (final k in months) {
          final total = monthTotal(store.expensesFor(k));
          final income = store.totalIncomeFor(k);
          sumTotal += total;
          sumIncome += income;
          profits.add(income - total);
          rows.add([
            monthLabel(k),
            formatAmount(total),
            formatAmount(income) +
                (store.hasIncomeOverride(k) ? '*' : '') +
                (store.extrasFor(k).isNotEmpty ? '+' : ''),
            formatAmount(income - total),
          ]);
        }
        profits.add(sumIncome - sumTotal);
        rows.add([
          'סך הכל',
          formatAmount(sumTotal),
          formatAmount(sumIncome),
          formatAmount(sumIncome - sumTotal),
        ]);
        return Scaffold(
          appBar: AppBar(title: const Text('סיכום חודשים')),
          body: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              SheetTable(
                headers: const ['חודש', 'הוצאות', 'הכנסה', 'רווח'],
                flex: const [3, 2, 2, 2],
                rows: rows,
                onRowTap: (i) {
                  if (i < months.length) _editIncome(context, months[i]);
                },
                cellColor: (r, c) {
                  if (c != 3) return null;
                  return profits[r] < 0 ? Colors.red.shade700 : Colors.green.shade800;
                },
              ),
              const SizedBox(height: 12),
              Text(
                'לחיצה על חודש: שינוי הכנסה לאותו חודש או מעבר אליו.\n'
                '* = הכנסה שונה מברירת המחדל\n'
                '+ = כולל הכנסה נוספת',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      },
    );
  }
}
