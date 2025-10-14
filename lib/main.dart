import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const SavingsApp());
}

class SavingsApp extends StatelessWidget {
  const SavingsApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'One-Touch Savings',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(200, 60),
            textStyle: const TextStyle(fontSize: 18),
          ),
        ),
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}