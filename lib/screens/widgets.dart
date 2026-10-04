import 'package:flutter/material.dart';

const sheetGreen = Color(0xFF2E6B4F);

final _numeric = RegExp(r'^-?[\d.,]+%?[*+]*$');

/// Numbers are laid out left-to-right so "-12.5" keeps its minus in front
/// inside the Hebrew (RTL) UI.
bool isNumericCell(String s) => _numeric.hasMatch(s);

/// A simple sheet-like table: green header, striped rows.
class SheetTable extends StatelessWidget {
  final List<String> headers;
  final List<List<String>> rows;
  final List<int>? flex;
  final void Function(int row)? onRowTap;
  final Color? Function(int row, int col)? cellColor;
  final bool boldFirstRow;

  /// Makes the headers tappable (for sorting).
  final void Function(int col)? onHeaderTap;

  /// Header that gets a small sort arrow.
  final int? sortColumn;
  final bool sortAscending;

  const SheetTable({
    super.key,
    required this.headers,
    required this.rows,
    this.flex,
    this.onRowTap,
    this.cellColor,
    this.boldFirstRow = false,
    this.onHeaderTap,
    this.sortColumn,
    this.sortAscending = true,
  });

  Widget _header() {
    const style = TextStyle(color: Colors.white, fontWeight: FontWeight.bold);
    return Container(
      color: sheetGreen,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(children: [
        for (var i = 0; i < headers.length; i++)
          Expanded(
            flex: flex?[i] ?? 1,
            child: InkWell(
              onTap: onHeaderTap == null ? null : () => onHeaderTap!(i),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(headers[i],
                          textAlign: TextAlign.center, style: style),
                    ),
                    if (sortColumn == i)
                      Icon(
                        sortAscending
                            ? Icons.arrow_drop_up
                            : Icons.arrow_drop_down,
                        size: 18,
                        color: Colors.white,
                      ),
                  ],
                ),
              ),
            ),
          ),
      ]),
    );
  }

  Widget _row(
    List<String> cells, {
    required Color bg,
    TextStyle? style,
    Color? Function(int col)? color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: bg,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(children: [
          for (var i = 0; i < cells.length; i++)
            Expanded(
              flex: flex?[i] ?? 1,
              child: Text(
                cells[i],
                textAlign: TextAlign.center,
                textDirection: isNumericCell(cells[i]) ? TextDirection.ltr : null,
                style: (style ?? const TextStyle()).copyWith(color: color?.call(i)),
              ),
            ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.black26)),
      child: Column(children: [
        _header(),
        for (var r = 0; r < rows.length; r++)
          _row(
            rows[r],
            bg: r.isOdd ? const Color(0xFFF3F5F4) : Colors.white,
            style: boldFirstRow && r == 0
                ? const TextStyle(fontWeight: FontWeight.bold)
                : null,
            color: cellColor == null ? null : (c) => cellColor!(r, c),
            onTap: onRowTap == null ? null : () => onRowTap!(r),
          ),
      ]),
    );
  }
}

/// Asks before deleting [what]; true only if the user confirmed.
Future<bool> confirmDelete(BuildContext context, String what) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('מחיקה'),
      content: Text('למחוק את $what?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('ביטול'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('מחק'),
        ),
      ],
    ),
  );
  return ok ?? false;
}

double? parseAmount(String s) => double.tryParse(s.trim().replaceAll(',', '.'));
