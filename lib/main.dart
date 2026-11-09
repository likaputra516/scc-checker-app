import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SccApp());
}

class SccApp extends StatelessWidget {
  const SccApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SCC Telkom Checker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD32F2F),
          primary: const Color(0xFFD32F2F),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
