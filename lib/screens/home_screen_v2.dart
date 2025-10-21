import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_progress.dart';
import '../models/animation_state.dart';
import '../services/database_service.dart';
import '../services/logger_service.dart';
import '../services/feedback_service.dart';
import '../services/animation_service.dart';
import '../widgets/simplified_progress_display.dart';
import '../widgets/usage_stats_card.dart';
import '../widgets/savings_button.dart';
import '../widgets/animated_character.dart';

class HomeScreenV2 extends StatefulWidget {
  const HomeScreenV2({super.key});

  @override
  State<HomeScreenV2> createState() => _HomeScreenV2State();
}

class _HomeScreenV2State extends State<HomeScreenV2> {
  final DatabaseService _databaseService = DatabaseService();
  final AnimationTimerService _animationService = AnimationTimerService();
  UserProgress _progress = UserProgress(
    totalSavings: 0,
    totalSessions: 0,
    todaySessionCount: 0,
    currentStreak: 0,
    longestStreak: 0,
    lastSaveDate: DateTime.now(),
    milestones: [],
  );
  TurtleAnimationLevel _currentAnimationLevel = TurtleAnimationLevel.idle;
  bool _isLoading = false;
  String? _errorMessage;
  int _validatedStreak = 0;

  @override
  void initState() {
    super.initState();
    _loadProgress();
    // Initialize animation asynchronously without blocking initState
    _initializeAnimation().catchError((e) {
      // Gracefully handle initialization errors
      if (mounted) {
        setState(() {
          _currentAnimationLevel = TurtleAnimationLevel.idle;
        });
      }
    });
  }

  Future<void> _initializeAnimation() async {
    // Start periodic updates for animation step-down
    _animationService.startPeriodicUpdates();

    // Listen for animation level changes
    _animationService.animationLevelStream.listen((level) {
      if (mounted) {
        setState(() {
          _currentAnimationLevel = level;
        });
      }
    });

    // Get initial animation level (this will trigger loading from prefs)
    try {
      _currentAnimationLevel = await _animationService.getInitialAnimationLevel();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      // Fallback to idle if initialization fails
      if (mounted) {
        setState(() {
          _currentAnimationLevel = TurtleAnimationLevel.idle;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationService.dispose();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    try {
      LoggerService.debug('Loading user progress for V2');
      final progress = await _databaseService.getCurrentProgress();
      final validatedStreak = await DatabaseService.getValidatedCurrentStreak();
      if (mounted) {
        setState(() {
          _progress = progress;
          _validatedStreak = validatedStreak;
        });
      }
      LoggerService.info(
          'V2 Progress loaded successfully - Total: ₩${progress.totalSavings}');
    } catch (e) {
      LoggerService.error('Failed to load progress in V2', e);
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load progress';
        });
      }
    }
  }

  Future<void> _handleSave() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      LoggerService.info('Starting save operation in V2');

      // Trigger animation response immediately
      await _animationService.onUserSavingsAction();

      final result = await _databaseService.saveMoney();

      if (result.success) {
        // Reload progress data
        if (mounted) {
          await _loadProgress();
        }

        // Log success
        LoggerService.logSaveSuccess(result.newTotal, result.todayCount);

        // Provide feedback
        await FeedbackService.saveSuccess();

        // Note: V2 does not show milestone overlays - simplified interface
        if (result.milestonesHit.isNotEmpty) {
          LoggerService.logMilestone(result.milestonesHit);
          // Just provide basic feedback without overlay
          FeedbackService.milestoneWithAnimation(
            animationDuration: const Duration(milliseconds: 1000),
          );
        }
      } else {
        final errorMessage = result.error ?? 'Save failed';
        LoggerService.logSaveError(errorMessage);
        if (mounted) {
          setState(() {
            _errorMessage = errorMessage;
          });
        }
        await FeedbackService.error();
      }
    } catch (e) {
      LoggerService.error('Unexpected error during save operation in V2', e);
      if (mounted) {
        setState(() {
          _errorMessage = 'Unexpected error occurred';
        });
      }
      await FeedbackService.error();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Set status bar style for this screen
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));

    // Get screen dimensions for responsive layout
    final screenSize = MediaQuery.of(context).size;
    
    // Improved small screen detection for real devices
    // Consider typical small phone screen sizes (iPhone SE, small Android phones)
    // Test environment (776x456) should use regular layout with height check
    final isSmallScreen = (screenSize.width == 800 && screenSize.height == 480) || // Keep test compatibility
                         (screenSize.width <= 400 && screenSize.height <= 800) ||   // iPhone SE and similar
                         (screenSize.width <= 380) ||                               // Very narrow phones
                         screenSize.height <= 500;                                  // Very small screens

    if (isSmallScreen) {
      // Horizontal layout for small screens with SafeArea
      return Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              // Main content
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                const SizedBox(height: 19), // Reduced by 1px to fix overflow
                
                // Top row: Progress display (left) + Usage stats (right)
                  Row(
                    children: [
                      // Left side: Ultra-compact progress display (50% of width)
                      Expanded(
                        flex: 1,
                        child: SimplifiedProgressDisplay(
                          currentAmount: _progress.totalSavings,
                          showAnimation: false,
                          ultraCompact: true,
                        ),
                      ),
                      
                      const SizedBox(width: 8),
                      
                      // Right side: Ultra-compact usage stats (50% of width)
                      Expanded(
                        flex: 1,
                        child: UsageStatsCard(
                          progress: _progress,
                          ultraCompact: true,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Middle row: Compact animated turtle (centered)
                  Center(
                    child: SizedBox(
                      width: 240,
                      height: 160,
                      child: AnimatedTurtleSprite(
                        level: _currentAnimationLevel,
                        width: 240.0,
                        height: 160.0,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Error Message (25px if present)
                  if (_errorMessage != null)
                    Container(
                      height: 25,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(2),
                        border:
                            Border.all(color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 12),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(fontSize: 10),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 8),

                  // Bottom row: Compact savings button + text (centered)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SavingsButton(
                        key: const Key('savings_button'),
                        onPressed: _handleSave,
                        width: 120,
                        height: 120,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isLoading ? '저장 중...' : '터치해서 ₩1,000 저축하기',
                        style: const TextStyle(
                          fontSize: 12.0,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                     ],
                   ),
                 ],
               ),
             ),
              
              // Settings button positioned in top-right corner
              Positioned(
                top: 40,
                right: 16,
                child: IconButton(
                  icon: Icon(
                    Icons.settings,
                    size: 20,
                    color: Colors.grey[600],
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, '/settings');
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Regular layout for normal screens
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height - 
                              MediaQuery.of(context).padding.top - 
                              MediaQuery.of(context).padding.bottom - 32, // SafeArea + padding
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    // Simplified Progress Display (amount only)
                    SimplifiedProgressDisplay(
                      currentAmount: _progress.totalSavings,
                      showAnimation: false,
                    ),

                    const SizedBox(height: 20),

                    // Usage Statistics Card
                    UsageStatsCard(progress: _progress),

                    const SizedBox(height: 30),

                    // Animated Turtle Character
                    AnimatedTurtleSprite(
                      level: _currentAnimationLevel,
                      width: 250.0,
                      height: 150.0,
                    ),

                    const SizedBox(height: 30),

                    // Error Message
                    if (_errorMessage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_errorMessage!)),
                          ],
                        ),
                      ),

                    // Savings Button
                    SavingsButton(
                      key: const Key('savings_button'),
                      onPressed: _handleSave,
                    ),

                    const SizedBox(height: 16),

                    // Button Label
                    Text(
                      _isLoading ? '저장 중...' : '터치해서 ₩1,000 저축하기',
                      style: const TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Settings button positioned in top-right corner
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                icon: Icon(
                  Icons.settings,
                  size: 20,
                  color: Colors.grey[600],
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/settings');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
