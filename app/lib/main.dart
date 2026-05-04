import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_shell.dart';
import 'theme/tokens.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Tokens.base,
    statusBarBrightness: Brightness.light,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const PeriodApp());
}

class PeriodApp extends StatelessWidget {
  const PeriodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'period',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: Tokens.ink,
          onPrimary: Tokens.paper,
          surface: Tokens.bg,
          onSurface: Tokens.ink,
        ),
        scaffoldBackgroundColor: Tokens.base,
        useMaterial3: true,
        textTheme: const TextTheme().apply(bodyColor: Tokens.ink),
      ),
      home: const Scaffold(
        backgroundColor: Tokens.base,
        body: SafeArea(child: AppShell()),
      ),
    );
  }
}
