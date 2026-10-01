import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  Timer? _debounce;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.store.addListener(_onStoreChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _askForFolderAccess();
      await _autoExport();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.store.removeListener(_onStoreChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _autoExport();
    // Leaving the app: don't wait for the debounce.
    if (state == AppLifecycleState.paused) _autoExport();
  }

  /// Every change is saved to the month's PDF ~2 seconds after the last edit.
  void _onStoreChanged() {
    if (!PdfStorage.canSaveSilently) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), _autoExport);
  }

  /// Explains once why the app wants access to Documents/expenses_app.
  Future<void> _askForFolderAccess() async {
    if (!PdfStorage.hasPublicFolder || await PdfStorage.hasPublicAccess()) return;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('asked_folder_access') ?? false) return;
    await prefs.setBool('asked_folder_access', true);
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('שמירת PDF בטלפון'),
        content: const Text(
            'כדי לשמור קובץ PDF לכל חודש בתיקייה Documents/expenses_app '
            'צריך לאשר גישה לקבצים. במסך הבא הפעל את האפשרות עבור "הוצאות".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('לא עכשיו'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('אישור'),
          ),
        ],
      ),
    );
    if (ok == true) await PdfStorage.requestPublicAccess();
  }

  /// Android: silently keeps one PDF per month in sync with the data.
  /// Browsers can't write files on their own, so on web only ask when a
  /// month has ended.
  Future<void> _autoExport() async {
    _debounce?.cancel();
    if (_syncing || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (PdfStorage.canSaveSilently) {
      _syncing = true;
      try {
        for (final k in widget.store.pendingExports()) {
          await syncMonth(widget.store, k);
        }
      } catch (e) {
        messenger.showSnackBar(SnackBar(content: Text('שגיאה בשמירת PDF: $e')));
      } finally {
        _syncing = false;
      }
      return;
    }
    final pending =
        widget.store.pendingExports(pastOnly: true).where(widget.store.hasData);
    if (pending.isEmpty || _bannerShown) return;
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
            for (final k in pending.toList()) {
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
