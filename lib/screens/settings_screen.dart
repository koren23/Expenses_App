import 'package:flutter/material.dart';

import '../data/store.dart';
import '../logic/summary.dart';
import '../pdf/pdf_storage.dart';
import 'widgets.dart';

class SettingsScreen extends StatefulWidget {
  final Store store;
  const SettingsScreen({super.key, required this.store});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final _income =
      TextEditingController(text: formatAmount(widget.store.defaultIncome));

  @override
  void dispose() {
    _income.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final v = parseAmount(_income.text);
    final messenger = ScaffoldMessenger.of(context);
    if (v == null) {
      messenger.showSnackBar(const SnackBar(content: Text('סכום לא תקין')));
      return;
    }
    await widget.store.setDefaultIncome(v);
    messenger.showSnackBar(const SnackBar(content: Text('נשמר')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('הגדרות')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _income,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'הכנסה חודשית (ברירת מחדל)',
              helperText: 'אפשר לשנות לחודש מסוים במסך הסיכום',
            ),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FilledButton(onPressed: _save, child: const Text('שמור')),
          ),
          const SizedBox(height: 32),
          Text(
            PdfStorage.canSaveSilently
                ? 'קובץ PDF אחד לכל חודש נשמר אוטומטית אחרי כל שינוי, '
                    'בתיקייה Documents/expenses_app בטלפון '
                    '(למשל expenses_2026_09.pdf).'
                : 'בדפדפן/אייפון: בלחיצה על כפתור ה-PDF נפתח חלון שיתוף - '
                    'בחר "שמור בקבצים". בסוף חודש תופיע תזכורת לשמירה.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
