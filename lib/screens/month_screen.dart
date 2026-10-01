import 'package:flutter/material.dart';

import '../data/store.dart';
import '../logic/summary.dart';
import '../models/expense.dart';
import '../pdf/exporter.dart';
import 'widgets.dart';

class MonthScreen extends StatelessWidget {
  final Store store;
  final MonthKey month;
  final ValueChanged<MonthKey> onMonthChanged;

  const MonthScreen({
    super.key,
    required this.store,
    required this.month,
    required this.onMonthChanged,
  });

  Future<void> _export(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final where = await exportMonth(store, month);
      messenger.showSnackBar(SnackBar(content: Text('PDF נשמר: $where')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('שגיאה בשמירה: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final expenses = store.expensesFor(month);
        final total = monthTotal(expenses);
        final sums = categorySums(expenses);
        final income = store.incomeFor(month);
        final exported = store.exportedAt(month);
        return Scaffold(
          appBar: AppBar(
            title: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => onMonthChanged(month.previous),
              ),
              Text(monthLabel(month)),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => onMonthChanged(month.next),
              ),
            ]),
            centerTitle: true,
            actions: [
              IconButton(
                tooltip: 'ייצוא ל-PDF',
                icon: const Icon(Icons.picture_as_pdf),
                onPressed: () => _export(context),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _edit(context, null),
            child: const Icon(Icons.add),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
            children: [
              if (expenses.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('אין הוצאות בחודש הזה. לחץ + להוספה.',
                      textAlign: TextAlign.center),
                )
              else
                SheetTable(
                  headers: const ['הסבר', 'תאריך', 'סכום', 'סוג הוצאה'],
                  flex: const [3, 2, 2, 3],
                  rows: [
                    for (final e in expenses)
                      [e.description, '${e.day}', formatAmount(e.amount), e.category],
                  ],
                  onRowTap: (i) => _edit(context, expenses[i]),
                ),
              const SizedBox(height: 24),
              SheetTable(
                headers: const ['סוג', 'סכום', 'אחוז'],
                boldFirstRow: true,
                rows: [
                  ['סך הכל', formatAmount(total), formatPercent(total == 0 ? 0 : 1)],
                  for (final s in sums)
                    [s.category, formatAmount(s.sum), formatPercent(s.fraction)],
                ],
              ),
              const SizedBox(height: 24),
              SheetTable(
                headers: const ['הכנסה', 'הוצאות', 'רווח'],
                rows: [
                  [formatAmount(income), formatAmount(total), formatAmount(income - total)],
                ],
                cellColor: (_, c) =>
                    c == 2 && income - total < 0 ? Colors.red.shade700 : null,
              ),
              const SizedBox(height: 12),
              Text(
                exported == null
                    ? 'עדיין לא נשמר PDF לחודש הזה'
                    : 'PDF נשמר לאחרונה: ${exported.day}/${exported.month} '
                        '${exported.hour}:${exported.minute.toString().padLeft(2, '0')}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _edit(BuildContext context, Expense? existing) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ExpenseForm(store: store, month: month, existing: existing),
    );
  }
}

class _ExpenseForm extends StatefulWidget {
  final Store store;
  final MonthKey month;
  final Expense? existing;
  const _ExpenseForm({required this.store, required this.month, this.existing});

  @override
  State<_ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<_ExpenseForm> {
  final _form = GlobalKey<FormState>();
  late final _desc = TextEditingController(text: widget.existing?.description);
  late final _amount = TextEditingController(
      text: widget.existing == null ? '' : formatAmount(widget.existing!.amount));
  late final _day =
      TextEditingController(text: '${widget.existing?.day ?? _defaultDay()}');
  late String _category = widget.existing?.category ?? '';

  int _defaultDay() {
    final now = DateTime.now();
    return MonthKey(now.year, now.month) == widget.month ? now.day : 1;
  }

  @override
  void dispose() {
    _desc.dispose();
    _amount.dispose();
    _day.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final e = Expense(
      id: widget.existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      year: widget.month.year,
      month: widget.month.month,
      day: int.parse(_day.text.trim()),
      description: _desc.text.trim(),
      amount: parseAmount(_amount.text)!,
      category: _category.trim(),
    );
    await widget.store.upsert(e);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    await widget.store.remove(widget.existing!);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.store.categories;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.existing == null ? 'הוצאה חדשה' : 'עריכת הוצאה',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextFormField(
              controller: _desc,
              autofocus: widget.existing == null,
              decoration: const InputDecoration(labelText: 'הסבר'),
              textInputAction: TextInputAction.next,
            ),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _amount,
                  decoration: const InputDecoration(labelText: 'סכום'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      parseAmount(v ?? '') == null ? 'סכום לא תקין' : null,
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 90,
                child: TextFormField(
                  controller: _day,
                  decoration: const InputDecoration(labelText: 'תאריך (יום)'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final d = int.tryParse(v?.trim() ?? '');
                    return d == null || d < 1 || d > widget.month.daysInMonth
                        ? 'יום לא תקין'
                        : null;
                  },
                ),
              ),
            ]),
            Autocomplete<String>(
              initialValue: TextEditingValue(text: _category),
              optionsBuilder: (v) => categories
                  .where((c) => c.contains(v.text.trim()) && c != v.text.trim()),
              onSelected: (v) => _category = v,
              fieldViewBuilder: (context, controller, focus, onSubmit) =>
                  TextFormField(
                controller: controller,
                focusNode: focus,
                decoration: const InputDecoration(labelText: 'סוג הוצאה'),
                onChanged: (v) => _category = v,
                onFieldSubmitted: (_) => _save(),
                validator: (v) => (v ?? '').trim().isEmpty ? 'חובה' : null,
              ),
            ),
            const SizedBox(height: 20),
            Row(children: [
              if (widget.existing != null)
                TextButton.icon(
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('מחק'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              const Spacer(),
              FilledButton(onPressed: _save, child: const Text('שמור')),
            ]),
          ],
        ),
      ),
    );
  }
}
