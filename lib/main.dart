import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const CRManagerApp());
}

class CRManagerApp extends StatelessWidget {
  const CRManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CR Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
