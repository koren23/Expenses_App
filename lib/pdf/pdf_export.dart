import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../logic/summary.dart';
import '../models/expense.dart';

const _marker = 'EXPDATA1:';

class MonthBackup {
  final MonthKey month;
  final List<Expense> expenses;
  final double income;
  final double? incomeOverride;
  const MonthBackup(this.month, this.expenses, this.income, this.incomeOverride);
}

pw.ThemeData? _theme;

Future<pw.Font> _font(String name) async =>
    pw.Font.ttf(await rootBundle.load('assets/fonts/$name.ttf'));

/// Latin Noto Sans with Hebrew as fallback. (The other way around makes the
/// pdf package draw digits reversed.)
Future<pw.ThemeData> _loadTheme() async => _theme ??= pw.ThemeData.withFont(
      base: await _font('NotoSans-Regular'),
      bold: await _font('NotoSans-Bold'),
      fontFallback: [
        await _font('NotoSansHebrew-Regular'),
        await _font('NotoSansHebrew-Bold'),
      ],
    );

/// Builds the month report. The month's raw data is embedded in the PDF
/// keywords so the file can be imported back into the app.
Future<Uint8List> buildMonthPdf(MonthBackup b, {pw.ThemeData? theme}) async {
  final data = base64Encode(utf8.encode(jsonEncode({
    'v': 1,
    'month': b.month.toString(),
    'income': b.incomeOverride,
    'expenses': b.expenses.map((e) => e.toJson()).toList(),
  })));

  final doc = pw.Document(
    version: PdfVersion.pdf_1_4,
    title: 'הוצאות ${monthLabel(b.month)}',
    keywords: '$_marker$data',
    theme: theme ?? await _loadTheme(),
  );

  final total = monthTotal(b.expenses);
  final sums = categorySums(b.expenses);
  const header = PdfColor.fromInt(0xFF2E6B4F);
  final headerStyle = pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold);

  // Tables are laid out left to right, so reverse columns to read RTL.
  List<String> rtl(List<String> r) => r.reversed.toList();
  pw.Widget table(List<String> headers, List<List<String>> rows) => pw.TableHelper.fromTextArray(
        headers: rtl(headers),
        data: rows.map(rtl).toList(),
        headerDecoration: const pw.BoxDecoration(color: header),
        headerStyle: headerStyle,
        cellAlignment: pw.Alignment.center,
        oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
      );

  doc.addPage(pw.MultiPage(
    textDirection: pw.TextDirection.rtl,
    pageFormat: PdfPageFormat.a4,
    build: (_) => [
      pw.Header(
        level: 0,
        child: pw.Row(children: [
          pw.Text('הוצאות - ${hebrewMonths[b.month.month - 1]}',
              style: const pw.TextStyle(fontSize: 20)),
          pw.SizedBox(width: 8),
          pw.Text('${b.month.year}', style: const pw.TextStyle(fontSize: 20)),
        ]),
      ),
      table(
        ['הסבר', 'תאריך', 'סכום', 'סוג הוצאה'],
        [
          for (final e in b.expenses)
            [e.description, '${e.day}', formatAmount(e.amount), e.category],
        ],
      ),
      pw.SizedBox(height: 20),
      table(
        ['סוג', 'סכום', 'אחוז'],
        [
          ['סך הכל', formatAmount(total), formatPercent(total == 0 ? 0 : 1)],
          for (final s in sums)
            [s.category, formatAmount(s.sum), formatPercent(s.fraction)],
        ],
      ),
      pw.SizedBox(height: 20),
      table(
        ['הכנסה', 'הוצאות', 'רווח'],
        [
          [formatAmount(b.income), formatAmount(total), formatAmount(b.income - total)],
        ],
      ),
    ],
  ));
  return doc.save();
}

/// Reads the embedded data back from a PDF made by [buildMonthPdf].
/// Returns null if the file isn't one of ours.
MonthBackup? parseMonthPdf(Uint8List bytes) {
  final text = latin1.decode(bytes, allowInvalid: true);
  final start = text.indexOf(_marker);
  if (start < 0) return null;
  final m = RegExp(r'[A-Za-z0-9+/=]+').matchAsPrefix(text, start + _marker.length);
  if (m == null) return null;
  try {
    final j = jsonDecode(utf8.decode(base64Decode(m.group(0)!))) as Map<String, dynamic>;
    final income = (j['income'] as num?)?.toDouble();
    return MonthBackup(
      MonthKey.parse(j['month'] as String),
      (j['expenses'] as List)
          .map((e) => Expense.fromJson(e as Map<String, dynamic>))
          .toList(),
      income ?? 0,
      income,
    );
  } catch (_) {
    return null;
  }
}
