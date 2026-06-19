import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api/tracker_catalog.dart';
import 'app_shell.dart';
import 'state/api_scope.dart';
import 'theme/tokens.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Tokens.base,
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const PeriodApp());
}

class PeriodApp extends StatefulWidget {
  const PeriodApp({super.key});

  @override
  State<PeriodApp> createState() => _PeriodAppState();
}

class _PeriodAppState extends State<PeriodApp> {
  late final TrackerCatalogRepository _catalog;

  @override
  void initState() {
    super.initState();
    _catalog = TrackerCatalogRepository();
    // Kick off the first fetch in the next microtask so the UI paints first
    // (loading state) before the network round-trip resolves.
    Future.microtask(_catalog.refresh);
  }

  @override
  void dispose() {
    _catalog.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'period',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          primary: Tokens.ink,
          onPrimary: Tokens.paper,
          surface: Tokens.bg,
          onSurface: Tokens.ink,
        ),
        scaffoldBackgroundColor: Tokens.base,
        useMaterial3: true,
        textTheme: const TextTheme().apply(bodyColor: Tokens.ink),
      ),
      home: ApiScope(
        repository: _catalog,
        child: _MobileWebFrame(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: const AppShell(),
          ),
        ),
      ),
    );
  }
}

class _MobileWebFrame extends StatelessWidget {
  final Widget child;

  const _MobileWebFrame({required this.child});

  static const double maxPhoneWidth = 430;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Tokens.ink,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxPhoneWidth),
          child: ClipRect(child: child),
        ),
      ),
    );
  }
}
