# Quickstart Guide: V2 Implementation

**Generated**: October 16, 2025  
**Target**: Development team implementing V2 simplified interface with animated turtle character

## Overview

This guide provides step-by-step implementation instructions for adding V2 interface alongside existing V1 functionality. Implementation preserves all existing V1 features while adding simplified V2 option with animated turtle character.

## Phase 1: Foundation Setup (2-3 hours)

### 1.1 Asset Migration
```bash
# Assets already converted from sprite sheets to individual frames
# Current structure:
# assets/images/characters/turtle/
# ├── idle/frame_0.png → frame_5.png (6 frames)
# ├── walking/frame_0.png → frame_5.png (6 frames)  
# └── running/frame_0.png → frame_2.png (3 frames)
```

Add to `pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/images/characters/turtle/idle/
    - assets/images/characters/turtle/walking/
    - assets/images/characters/turtle/running/
```

### 1.2 Core Models Implementation
Create new files:

**lib/models/animation_state.dart**:
```dart
enum TurtleAnimationLevel {
  idle(1),
  walkSlow(2), 
  walkFast(3),
  runSlow(4),
  runFast(5);
  
  const TurtleAnimationLevel(this.value);
  final int value;
}

class AnimationState {
  final TurtleAnimationLevel level;
  final DateTime lastActivityTimestamp;
  final int totalActivityCount;
  
  AnimationState({
    required this.level,
    required this.lastActivityTimestamp,
    this.totalActivityCount = 0,
  });
}
```

**lib/models/design_version_setting.dart**:
```dart
enum DesignVersion { v1, v2 }

class DesignVersionSetting {
  final DesignVersion currentVersion;
  final DateTime lastChanged;
  final bool hasSeenV2Introduction;
  
  DesignVersionSetting({
    required this.currentVersion,
    required this.lastChanged,
    this.hasSeenV2Introduction = false,
  });
}
```

## Phase 2: Service Layer (3-4 hours)

### 2.1 Animation Service
**lib/services/animation_service.dart**:
```dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/animation_state.dart';

class AnimationTimerService extends ChangeNotifier {
  TurtleAnimationLevel _currentLevel = TurtleAnimationLevel.idle;
  Timer? _updateTimer;
  
  TurtleAnimationLevel get currentLevel => _currentLevel;
  
  void startPeriodicUpdates() {
    _updateTimer = Timer.periodic(const Duration(minutes: 30), (_) {
      _checkAnimationStepdown();
    });
    _loadCurrentState();
  }
  
  Future<void> onUserSavingsAction() async {
    _currentLevel = TurtleAnimationLevel.runFast;
    await _persistState();
    notifyListeners();
  }
  
  Future<void> _loadCurrentState() async {
    // Implementation based on contracts/animation_service.md
    final prefs = await SharedPreferences.getInstance();
    final lastActivity = prefs.getInt('last_activity_timestamp');
    if (lastActivity != null) {
      _currentLevel = _calculateLevelFromTimestamp(lastActivity);
      notifyListeners();
    }
  }
  
  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }
}
```

### 2.2 Design Version Service  
**lib/services/design_version_service.dart**:
```dart
import 'package:shared_preferences/shared_preferences.dart';
import '../models/design_version_setting.dart';

class DesignVersionService {
  static const String _versionKey = 'design_version_preference';
  
  Future<DesignVersion> getCurrentDesignVersion() async {
    final prefs = await SharedPreferences.getInstance();
    final versionString = prefs.getString(_versionKey);
    
    if (versionString == null) {
      // Default logic: V1 for existing users, V2 for new users
      final isFirstTime = await _isFirstTimeUser();
      return isFirstTime ? DesignVersion.v2 : DesignVersion.v1;
    }
    
    return DesignVersion.values.firstWhere(
      (v) => v.name == versionString,
      orElse: () => DesignVersion.v1,
    );
  }
  
  Future<void> setDesignVersion(DesignVersion version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_versionKey, version.name);
    await prefs.setInt('last_version_switch', DateTime.now().millisecondsSinceEpoch);
  }
  
  Future<bool> _isFirstTimeUser() async {
    // Check if any savings data exists
    // Implementation references existing DatabaseService
    return false; // Placeholder
  }
}
```

## Phase 3: Widget Implementation (4-5 hours)

### 3.1 Animated Turtle Widget
**lib/widgets/animated_character.dart**:
```dart
import 'package:flutter/material.dart';
import '../models/animation_state.dart';

class AnimatedTurtleSprite extends StatefulWidget {
  final TurtleAnimationLevel level;
  final double size;
  
  const AnimatedTurtleSprite({
    super.key,
    required this.level,
    this.size = 100.0,
  });
  
  @override
  State<AnimatedTurtleSprite> createState() => _AnimatedTurtleSpriteState();
}

class _AnimatedTurtleSpriteState extends State<AnimatedTurtleSprite>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<Image> _preloadedFrames = [];
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: _getDurationForLevel(widget.level),
      vsync: this,
    );
    _preloadFrames();
    _controller.repeat();
  }
  
  void _preloadFrames() {
    final framePaths = _getFramePaths();
    _preloadedFrames = framePaths.map((path) => 
      Image.asset(path, width: widget.size, height: widget.size)
    ).toList();
  }
  
  Duration _getDurationForLevel(TurtleAnimationLevel level) {
    switch (level) {
      case TurtleAnimationLevel.idle: return const Duration(seconds: 2);
      case TurtleAnimationLevel.walkSlow: return const Duration(milliseconds: 1200);
      case TurtleAnimationLevel.walkFast: return const Duration(milliseconds: 800);
      case TurtleAnimationLevel.runSlow: return const Duration(milliseconds: 600);
      case TurtleAnimationLevel.runFast: return const Duration(milliseconds: 400);
    }
  }
  
  List<String> _getFramePaths() {
    switch (widget.level) {
      case TurtleAnimationLevel.idle:
        return List.generate(6, (i) => 
          'assets/images/characters/turtle/idle/frame_$i.png');
      case TurtleAnimationLevel.walkSlow:
      case TurtleAnimationLevel.walkFast:
        return List.generate(6, (i) => 
          'assets/images/characters/turtle/walking/frame_$i.png');
      case TurtleAnimationLevel.runSlow:
      case TurtleAnimationLevel.runFast:
        return List.generate(3, (i) => 
          'assets/images/characters/turtle/running/frame_$i.png');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final frameIndex = (_controller.value * _preloadedFrames.length).floor() 
            % _preloadedFrames.length;
          
          return Transform.scale(
            scale: 1.0 + (_controller.value * 0.05), // Subtle bounce
            child: _preloadedFrames[frameIndex],
          );
        },
      ),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

### 3.2 Design Version Toggle
**lib/widgets/design_version_toggle.dart**:
```dart
import 'package:flutter/material.dart';
import '../models/design_version_setting.dart';

class DesignVersionToggle extends StatelessWidget {
  final DesignVersion currentVersion;
  final ValueChanged<DesignVersion> onVersionChanged;
  
  const DesignVersionToggle({
    super.key,
    required this.currentVersion,
    required this.onVersionChanged,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '인터페이스 버전',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            RadioListTile<DesignVersion>(
              title: const Text('V1 - 전체 기능'),
              subtitle: const Text('모든 차트와 통계 표시'),
              value: DesignVersion.v1,
              groupValue: currentVersion,
              onChanged: (value) => onVersionChanged(value!),
            ),
            RadioListTile<DesignVersion>(
              title: const Text('V2 - 간단한 화면'),
              subtitle: const Text('필수 기능만 + 귀여운 거북이'),
              value: DesignVersion.v2,
              groupValue: currentVersion,
              onChanged: (value) => onVersionChanged(value!),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Phase 4: Screen Implementation (3-4 hours)

### 4.1 V2 Home Screen
**lib/screens/home_screen_v2.dart**:
```dart
import 'package:flutter/material.dart';
import '../widgets/animated_character.dart';
import '../widgets/progress_display.dart';
import '../widgets/savings_button.dart';
import '../services/animation_service.dart';

class HomeScreenV2 extends StatefulWidget {
  const HomeScreenV2({super.key});
  
  @override
  State<HomeScreenV2> createState() => _HomeScreenV2State();
}

class _HomeScreenV2State extends State<HomeScreenV2> {
  late AnimationTimerService _animationService;
  TurtleAnimationLevel _currentLevel = TurtleAnimationLevel.idle;
  
  @override
  void initState() {
    super.initState();
    _animationService = AnimationTimerService();
    _animationService.addListener(_onAnimationChange);
    _animationService.startPeriodicUpdates();
  }
  
  void _onAnimationChange() {
    setState(() {
      _currentLevel = _animationService.currentLevel;
    });
  }
  
  Future<void> _handleSavingsAction() async {
    // Trigger animation update
    await _animationService.onUserSavingsAction();
    
    // Continue with existing savings logic...
    // (integrate with existing DatabaseService and ProgressService)
  }
  
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('One-Touch Savings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
          child: Column(
            children: [
              // Essential progress display (simplified)
              ProgressDisplay(
                currentAmount: 0, // Connect to existing progress service
                targetAmount: 10000,
                progressPercentage: 0.0,
                showAnimation: false, // Simplified for V2
              ),
              
              SizedBox(height: isSmallScreen ? 20 : 30),
              
              // Animated turtle character
              AnimatedTurtleSprite(
                level: _currentLevel,
                size: isSmallScreen ? 120 : 150,
              ),
              
              const SizedBox(height: 16),
              
              Text(
                _getEncouragementText(_currentLevel),
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: isSmallScreen ? 30 : 40),
              
              // Savings button (same functionality as V1)
              SavingsButton(
                onPressed: _handleSavingsAction,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _getEncouragementText(TurtleAnimationLevel level) {
    switch (level) {
      case TurtleAnimationLevel.runFast:
        return '와! 정말 열심히 저축하고 있네요! 🏃‍♂️💨';
      case TurtleAnimationLevel.runSlow:
        return '좋은 페이스예요! 계속 해봐요! 🏃‍♂️';
      case TurtleAnimationLevel.walkFast:
        return '꾸준히 잘 하고 있어요! 🚶‍♂️';
      case TurtleAnimationLevel.walkSlow:
        return '천천히 가도 괜찮아요 🐢';
      case TurtleAnimationLevel.idle:
        return '저축 버튼을 눌러보세요! 😊';
    }
  }
  
  @override
  void dispose() {
    _animationService.dispose();
    super.dispose();
  }
}
```

### 4.2 Home Screen Router Update
**lib/screens/home_screen.dart** - Add routing logic:
```dart
// Add to existing home_screen.dart
import '../services/design_version_service.dart';
import 'home_screen_v2.dart';

class HomeScreenRouter extends StatelessWidget {
  const HomeScreenRouter({super.key});
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DesignVersion>(
      future: DesignVersionService().getCurrentDesignVersion(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        final version = snapshot.data ?? DesignVersion.v1;
        
        switch (version) {
          case DesignVersion.v1:
            return const HomeScreen(); // Existing implementation
          case DesignVersion.v2:
            return const HomeScreenV2(); // New simplified implementation
        }
      },
    );
  }
}
```

## Phase 5: Integration & Testing (2-3 hours)

### 5.1 Settings Integration
Add to existing settings screen:
```dart
// In settings screen widget
DesignVersionToggle(
  currentVersion: currentDesignVersion,
  onVersionChanged: (newVersion) async {
    await DesignVersionService().setDesignVersion(newVersion);
    // Trigger app rebuild or navigation
    Navigator.of(context).pushReplacementNamed('/home');
  },
)
```

### 5.2 Main App Update
**lib/main.dart** - Update routing:
```dart
import 'screens/home_screen.dart';

// In MaterialApp
home: const HomeScreenRouter(), // Instead of HomeScreen()
```

### 5.3 Testing Checklist
```bash
# Run existing tests to ensure no regressions
flutter test

# Add new test files (see test structure in plan.md)
flutter test test/unit_test/animation_service_test.dart
flutter test test/widget_test/home_screen_v2_test.dart
flutter test test/integration_test/design_version_switching_test.dart
```

## Deployment Checklist

- [ ] All existing V1 functionality preserved
- [ ] V2 interface shows only essential elements
- [ ] Turtle animation responds to savings actions
- [ ] Settings toggle works correctly
- [ ] Data consistency between V1/V2
- [ ] Performance meets <200ms response time
- [ ] All tests passing
- [ ] Assets properly registered in pubspec.yaml

## Success Metrics

After implementation, verify:
- **Loading time**: V2 loads 40% faster than V1 (success criteria SC-002)
- **Animation response**: <200ms from button press to turtle animation change (SC-003)
- **Element reduction**: V2 shows 70% fewer UI elements than V1 (SC-006)
- **Screen compatibility**: All elements visible on 800x480 screens without scrolling (SC-008)

## Troubleshooting

**Common Issues**:
1. **Assets not loading**: Check pubspec.yaml asset paths
2. **Animation stuttering**: Verify RepaintBoundary usage
3. **State not persisting**: Check SharedPreferences implementation
4. **V1/V2 switching fails**: Verify router implementation

**Performance Issues**:
1. **Slow animation**: Use flutter analyze for performance warnings
2. **Memory leaks**: Ensure all controllers disposed properly
3. **Battery drain**: Verify timer cleanup in dispose methods

**Next Steps**: After Phase 5 completion, use `/speckit.tasks` to generate detailed implementation tasks for the development team.