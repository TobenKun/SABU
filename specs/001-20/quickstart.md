# Quickstart Guide: One-Touch Savings App

**Target Audience**: Flutter developers implementing the savings app  
**Prerequisites**: Flutter 3.16+, Dart 3.0+, basic SQLite knowledge

## Project Setup

### 1. Create Flutter Project
```bash
flutter create one_touch_savings
cd one_touch_savings
```

### 2. Add Dependencies
```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  sqflite: ^2.3.0
  flutter_animate: ^4.2.0+1
  intl: ^0.18.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  sqflite_common_ffi: ^2.3.0+2
  integration_test:
    sdk: flutter
```

### 3. Project Structure
```
lib/
├── main.dart
├── models/
│   ├── savings_session.dart
│   └── user_progress.dart  
├── services/
│   ├── database_service.dart
│   ├── feedback_service.dart
│   └── savings_service.dart
├── screens/
│   └── home_screen.dart
└── widgets/
    ├── savings_button.dart
    └── progress_display.dart

test/
├── widget_test/
├── unit_test/
└── integration_test/
```

## Core Implementation

### 1. Database Service Setup
```dart
// lib/services/database_service.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static Database? _database;
  
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  static Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'savings.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE savings_sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            amount INTEGER NOT NULL CHECK (amount = 1000),
            timestamp INTEGER NOT NULL
          )
        ''');
        
        await db.execute('''
          CREATE TABLE user_progress (
            id INTEGER PRIMARY KEY CHECK (id = 1),
            total_savings INTEGER NOT NULL DEFAULT 0,
            total_sessions INTEGER NOT NULL DEFAULT 0,
            today_session_count INTEGER NOT NULL DEFAULT 0,
            last_save_date INTEGER NOT NULL DEFAULT 0,
            current_streak INTEGER NOT NULL DEFAULT 0,
            longest_streak INTEGER NOT NULL DEFAULT 0
          )
        ''');
        
        await db.execute(
          'CREATE INDEX idx_savings_timestamp ON savings_sessions(timestamp)'
        );
        
        // Initialize progress row
        await db.insert('user_progress', {
          'id': 1,
          'last_save_date': DateTime.now().millisecondsSinceEpoch,
        });
      },
      onOpen: (db) async {
        await db.execute('PRAGMA journal_mode = WAL');
        await db.execute('PRAGMA synchronous = NORMAL');
      },
    );
  }
}
```

### 2. Savings Service Core Logic
```dart
// lib/services/savings_service.dart
import 'database_service.dart';
import '../models/user_progress.dart';

class SavingsService {
  Future<SavingsResult> saveMoney() async {
    final db = await DatabaseService.database;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    try {
      await db.transaction((txn) async {
        // Insert new session
        await txn.insert('savings_sessions', {
          'amount': 1000,
          'timestamp': timestamp,
        });
        
        // Update progress
        await txn.rawUpdate('''
          UPDATE user_progress 
          SET 
            total_savings = total_savings + 1000,
            total_sessions = total_sessions + 1,
            today_session_count = CASE 
              WHEN date(last_save_date/1000, 'unixepoch') = date('now') 
              THEN today_session_count + 1 
              ELSE 1 
            END,
            last_save_date = ?
          WHERE id = 1
        ''', [timestamp]);
      });
      
      // Get updated progress
      final progress = await getCurrentProgress();
      
      // Check for milestones
      final milestones = _detectMilestones(
        progress.totalSavings - 1000, 
        progress.totalSavings
      );
      
      return SavingsResult(
        newTotal: progress.totalSavings,
        todayCount: progress.todaySessionCount,
        milestonesHit: milestones,
        success: true,
      );
      
    } catch (e) {
      return SavingsResult(
        newTotal: 0,
        todayCount: 0,
        milestonesHit: [],
        success: false,
        error: e.toString(),
      );
    }
  }
  
  List<int> _detectMilestones(int oldTotal, int newTotal) {
    final oldMilestones = (oldTotal / 10000).floor();
    final newMilestones = (newTotal / 10000).floor();
    
    if (newMilestones > oldMilestones) {
      return List.generate(
        newMilestones - oldMilestones,
        (i) => (oldMilestones + i + 1) * 10000
      );
    }
    return [];
  }
}

class SavingsResult {
  final int newTotal;
  final int todayCount;
  final List<int> milestonesHit;
  final bool success;
  final String? error;
  
  SavingsResult({
    required this.newTotal,
    required this.todayCount,
    required this.milestonesHit,
    required this.success,
    this.error,
  });
}
```

### 3. Savings Button Widget
```dart
// lib/widgets/savings_button.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SavingsButton extends StatefulWidget {
  final VoidCallback onPressed;
  
  const SavingsButton({required this.onPressed, Key? key}) : super(key: key);
  
  @override
  State<SavingsButton> createState() => _SavingsButtonState();
}

class _SavingsButtonState extends State<SavingsButton> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPressed = false;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void _handleTap() async {
    if (_isPressed) return; // Prevent double-tap
    
    setState(() => _isPressed = true);
    
    // Immediate haptic feedback
    HapticFeedback.lightImpact();
    
    // Animate button press
    await _controller.forward();
    await _controller.reverse();
    
    // Call save function
    widget.onPressed();
    
    setState(() => _isPressed = false);
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 75),
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: _isPressed ? Colors.green : Colors.blue,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.add,
            size: 60,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
```

### 4. Progress Display Widget
```dart
// lib/widgets/progress_display.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProgressDisplay extends StatelessWidget {
  final int totalSavings;
  final int todayCount;
  
  const ProgressDisplay({
    required this.totalSavings,
    required this.todayCount,
    Key? key,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###', 'ko_KR');
    
    return Column(
      children: [
        Text(
          '총 저축액',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 800),
          tween: Tween(begin: 0, end: totalSavings.toDouble()),
          builder: (context, value, child) {
            return Text(
              '${formatter.format(value.toInt())}원',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Text(
          '오늘 ${todayCount}번 저축',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }
}
```

### 5. Main App Structure
```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const SavingsApp());
}

class SavingsApp extends StatelessWidget {
  const SavingsApp({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'One-Touch Savings',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
```

## Testing Setup

### 1. Widget Tests
```dart
// test/widget_test/savings_button_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/widgets/savings_button.dart';

void main() {
  testWidgets('SavingsButton triggers callback on tap', (tester) async {
    bool callbackTriggered = false;
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SavingsButton(
            onPressed: () => callbackTriggered = true,
          ),
        ),
      ),
    );
    
    await tester.tap(find.byType(SavingsButton));
    await tester.pumpAndSettle();
    
    expect(callbackTriggered, isTrue);
  });
}
```

### 2. Database Tests
```dart
// test/unit_test/database_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../lib/services/database_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });
  
  test('DatabaseService initializes correctly', () async {
    final db = await DatabaseService.database;
    expect(db.isOpen, isTrue);
    
    // Test initial data
    final progress = await db.query('user_progress');
    expect(progress.length, equals(1));
    expect(progress.first['total_savings'], equals(0));
  });
}
```

## Performance Testing

### Frame Rate Monitoring
```dart
// Add to main.dart for debug builds
void main() {
  if (kDebugMode) {
    WidgetsBinding.instance.addTimingsCallback((timings) {
      for (final timing in timings) {
        if (timing.totalSpan.inMilliseconds > 16) {
          print('Frame drop: ${timing.totalSpan.inMilliseconds}ms');
        }
      }
    });
  }
  runApp(const SavingsApp());
}
```

## Development Tips

### 1. Hot Reload Considerations
- Database schema changes require app restart
- SQLite connections persist across hot reload
- Use `flutter clean` for major changes

### 2. Platform-Specific Setup
```yaml
# android/app/build.gradle
android {
    compileSdkVersion 34
    minSdkVersion 21  # For SQLite support
}

# ios/Runner.xcworkspace
# Ensure iOS deployment target is 12.0+
```

### 3. Performance Optimization
- Use `const` constructors for static widgets
- Implement proper `dispose()` methods
- Monitor memory usage with Flutter DevTools
- Test on actual devices, not just simulators

## Next Steps

1. **Implement core features** following the contracts
2. **Add comprehensive testing** for all user scenarios  
3. **Optimize performance** with Flutter DevTools profiling
4. **Test on target devices** (Android 7+, iOS 12+)
5. **Prepare for user testing** with analytics integration

This quickstart provides the foundation for the one-touch savings app. Follow the contracts in the `/contracts/` directory for detailed implementation requirements.