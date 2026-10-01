import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/expense.dart';

/// All app data, persisted locally as JSON (localStorage on web).
class Store extends ChangeNotifier {
  static const _key = 'expenses_app_v1';

  final SharedPreferences _prefs;
  final List<Expense> _expenses = [];
  double defaultIncome = 0;
  final Map<String, double> _incomeOverrides = {};
  final Map<String, int> _modifiedAt = {};
  final Map<String, int> _exportedAt = {};

  Store._(this._prefs);

  static Future<Store> load() async {
    final s = Store._(await SharedPreferences.getInstance());
    final raw = s._prefs.getString(_key);
    if (raw != null) s._fromJson(jsonDecode(raw) as Map<String, dynamic>);
    return s;
  }

  void _fromJson(Map<String, dynamic> j) {
    _expenses
      ..clear()
      ..addAll((j['expenses'] as List)
          .map((e) => Expense.fromJson(e as Map<String, dynamic>)));
    defaultIncome = (j['defaultIncome'] as num?)?.toDouble() ?? 0;
    _incomeOverrides
      ..clear()
      ..addAll((j['income'] as Map? ?? {})
          .map((k, v) => MapEntry(k as String, (v as num).toDouble())));
    _modifiedAt
      ..clear()
      ..addAll((j['modified'] as Map? ?? {}).cast<String, int>());
    _exportedAt
      ..clear()
      ..addAll((j['exported'] as Map? ?? {}).cast<String, int>());
  }

  Future<void> _save() async {
    notifyListeners();
    await _prefs.setString(
        _key,
        jsonEncode({
          'expenses': _expenses.map((e) => e.toJson()).toList(),
          'defaultIncome': defaultIncome,
          'income': _incomeOverrides,
          'modified': _modifiedAt,
          'exported': _exportedAt,
        }));
  }

  void _touch(MonthKey k) =>
      _modifiedAt[k.toString()] = DateTime.now().millisecondsSinceEpoch;

  List<Expense> expensesFor(MonthKey k) => _expenses
      .where((e) => e.year == k.year && e.month == k.month)
      .toList()
    ..sort((a, b) => a.day.compareTo(b.day));

  /// Every month that has expenses, plus the current month, ascending.
  List<MonthKey> get months {
    final set = {
      for (final e in _expenses) MonthKey(e.year, e.month),
      for (final k in _incomeOverrides.keys) MonthKey.parse(k),
      MonthKey.now(),
    };
    return set.toList()..sort();
  }

  /// Previously used categories, most frequent first (for autocomplete).
  List<String> get categories {
    final counts = <String, int>{};
    for (final e in _expenses) {
      final c = e.category.trim();
      if (c.isNotEmpty) counts[c] = (counts[c] ?? 0) + 1;
    }
    return counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
  }

  double incomeFor(MonthKey k) => _incomeOverrides[k.toString()] ?? defaultIncome;
  bool hasIncomeOverride(MonthKey k) => _incomeOverrides.containsKey(k.toString());

  Future<void> setIncomeOverride(MonthKey k, double? value) {
    if (value == null) {
      _incomeOverrides.remove(k.toString());
    } else {
      _incomeOverrides[k.toString()] = value;
    }
    _touch(k);
    return _save();
  }

  Future<void> setDefaultIncome(double v) {
    defaultIncome = v;
    return _save();
  }

  Future<void> upsert(Expense e) {
    final i = _expenses.indexWhere((x) => x.id == e.id);
    if (i >= 0) {
      _expenses[i] = e;
    } else {
      _expenses.add(e);
    }
    _touch(MonthKey(e.year, e.month));
    return _save();
  }

  Future<void> remove(Expense e) {
    _expenses.removeWhere((x) => x.id == e.id);
    _touch(MonthKey(e.year, e.month));
    return _save();
  }

  /// Replaces a month's data with what was read from a PDF backup.
  Future<void> importMonth(
      MonthKey k, List<Expense> expenses, double? incomeOverride) {
    _expenses.removeWhere((e) => e.year == k.year && e.month == k.month);
    _expenses.addAll(expenses);
    if (incomeOverride != null) _incomeOverrides[k.toString()] = incomeOverride;
    _touch(k);
    return _save();
  }

  /// Past months whose PDF is missing or older than their data.
  List<MonthKey> get pendingAutoExports {
    final now = MonthKey.now();
    return months.where((k) {
      if (k.compareTo(now) >= 0) return false;
      if (expensesFor(k).isEmpty) return false;
      final exported = _exportedAt[k.toString()];
      final modified = _modifiedAt[k.toString()] ?? 0;
      return exported == null || exported < modified;
    }).toList();
  }

  DateTime? exportedAt(MonthKey k) {
    final t = _exportedAt[k.toString()];
    return t == null ? null : DateTime.fromMillisecondsSinceEpoch(t);
  }

  Future<void> markExported(MonthKey k) {
    _exportedAt[k.toString()] = DateTime.now().millisecondsSinceEpoch;
    return _save();
  }
}
