import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'screens/home_screen_v2.dart';
import 'screens/settings_screen.dart';
import 'services/performance_service.dart';
import 'services/logger_service.dart';
import 'services/design_version_service.dart';

void main() async {
  // Initialize Flutter bindings first
  WidgetsFlutterBinding.ensureInitialized();

  // Set status bar style to match app background
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));

  // Initialize logger with environment settings
  LoggerService.initialize();

  // Enable frame rate monitoring in debug mode
  PerformanceService.monitorFrameRate();

  // Start memory monitoring
  PerformanceService.startMemoryMonitoring();

  // Initialize design version settings for first-time users
  await DesignVersionService().performFirstRunSetup();

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
      home: const HomeScreenRouter(),
      routes: {
        '/v2': (context) => const HomeScreenV2(),
        '/settings': (context) => const SettingsScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
