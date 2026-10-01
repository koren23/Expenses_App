import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/store.dart';
import 'models/expense.dart';
import 'pdf/exporter.dart';
import 'pdf/pdf_storage.dart';
import 'screens/archive_screen.dart';
import 'screens/month_screen.dart';
import 'screens/overview_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await Store.load();
  runApp(ExpensesApp(store: store));
}



class ExpensesApp extends StatelessWidget {
  final Store store;
  const ExpensesApp({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'הוצאות',
      debugShowCheckedModeBanner: false,
      locale: const Locale('he'),
      supportedLocales: const [Locale('he')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: sheetGreen),
        fontFamily: 'NotoSansHebrew',
        fontFamilyFallback: const ['NotoSans'],
        appBarTheme: const AppBarTheme(
          backgroundColor: sheetGreen,
          foregroundColor: Colors.white,
        ),
      ),
      home: HomeShell(store: store),
    );
  }
}

class HomeShell extends StatefulWidget {
  final Store store;
  const HomeShell({super.key, required this.store});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int _tab = 0;
  MonthKey _month = MonthKey.now();
  bool _bannerShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoExport());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _autoExport();
  }

  /// When a month has ended, save its final PDF. On Android this happens
  /// silently; browsers can't write files on their own, so ask on web.
  Future<void> _autoExport() async {
    final pending = widget.store.pendingAutoExports;
    if (pending.isEmpty || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (PdfStorage.canSaveSilently) {
      for (final k in pending) {
        await exportMonth(widget.store, k);
      }
      messenger.showSnackBar(SnackBar(
          content: Text('נשמר PDF עבור: ${pending.map(monthLabel).join(', ')}')));
      return;
    }
    if (_bannerShown) return;
    _bannerShown = true;
    messenger.showMaterialBanner(MaterialBanner(
      content: Text('חודש הסתיים - לשמור PDF? (${pending.map(monthLabel).join(', ')})'),
      actions: [
        TextButton(
          onPressed: () {
            messenger.hideCurrentMaterialBanner();
            _bannerShown = false;
          },
          child: const Text('אחר כך'),
        ),
        FilledButton(
          onPressed: () async {
            messenger.hideCurrentMaterialBanner();
            for (final k in pending) {
              await exportMonth(widget.store, k);
            }
            _bannerShown = false;
          },
          child: const Text('שמור'),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      MonthScreen(
        store: widget.store,
        month: _month,
        onMonthChanged: (k) => setState(() => _month = k),
      ),
      OverviewScreen(
        store: widget.store,
        onOpenMonth: (k) => setState(() {
          _month = k;
          _tab = 0;
        }),
      ),
      ArchiveScreen(store: widget.store),
      SettingsScreen(store: widget.store),
    ];
    return Scaffold(
      body: IndexedStack(index: _tab, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.receipt_long), label: 'חודש'),
          NavigationDestination(icon: Icon(Icons.table_chart), label: 'סיכום'),
          NavigationDestination(icon: Icon(Icons.picture_as_pdf), label: 'ארכיון'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'הגדרות'),
        ],
      ),
    );
  }
}
