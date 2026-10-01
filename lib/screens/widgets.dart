import 'package:flutter/material.dart';

const sheetGreen = Color(0xFF2E6B4F);

/// A simple sheet-like table: green header, striped rows.
class SheetTable extends StatelessWidget {
  final List<String> headers;
  final List<List<String>> rows;
  final List<int>? flex;
  final void Function(int row)? onRowTap;
  final Color? Function(int row, int col)? cellColor;
  final bool boldFirstRow;

  const SheetTable({
    super.key,
    required this.headers,
    required this.rows,
    this.flex,
    this.onRowTap,
    this.cellColor,
    this.boldFirstRow = false,
  });

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
        _row(headers,
            bg: sheetGreen,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

double? parseAmount(String s) => double.tryParse(s.trim().replaceAll(',', '.'));
