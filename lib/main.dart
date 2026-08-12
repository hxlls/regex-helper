import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/tester_screen.dart';

void main() {
  runApp(const RegexHelperApp());
}

class RegexHelperApp extends StatelessWidget {
  const RegexHelperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '正则助手',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3B5BDB)),
        useMaterial3: true,
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/tester':
            return MaterialPageRoute(
              builder: (_) => TesterScreen(
                initialPattern: (settings.arguments as String?) ?? '',
              ),
            );
          default:
            return MaterialPageRoute(builder: (_) => const HomeScreen());
        }
      },
    );
  }
}
