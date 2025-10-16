import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _loadProgress();
    _initializeAnimation();
  }

  void _initializeAnimation() async {
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
    _currentAnimationLevel = await _animationService.getInitialAnimationLevel();
    if (mounted) {
      setState(() {});
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
      if (mounted) {
        setState(() {
          _progress = progress;
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
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Simplified Progress Display (amount only)
                SimplifiedProgressDisplay(
                  currentAmount: _progress.totalSavings,
                  showAnimation: true,
                ),

                const SizedBox(height: 20),

                // Usage Statistics Card
                UsageStatsCard(
                  progress: _progress,
                ),

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
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 20),

                // DEBUG: Animation State Controls (TODO: Remove in production)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border:
                        Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'DEBUG',
                        style:
                            TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          _buildDebugButton('I', TurtleAnimationLevel.idle),
                          _buildDebugButton(
                              'WS', TurtleAnimationLevel.walkSlow),
                          _buildDebugButton(
                              'WF', TurtleAnimationLevel.walkFast),
                          _buildDebugButton('RS', TurtleAnimationLevel.runSlow),
                          _buildDebugButton('RF', TurtleAnimationLevel.runFast),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // DEBUG: Helper method for small debug buttons (TODO: Remove in production)
  Widget _buildDebugButton(String label, TurtleAnimationLevel level) {
    return SizedBox(
      width: 24,
      height: 24,
      child: ElevatedButton(
        onPressed: () => _animationService.setAnimationLevel(level),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              _currentAnimationLevel == level ? Colors.grey[400] : null,
          padding: EdgeInsets.zero,
          minimumSize: const Size(24, 24),
          textStyle: const TextStyle(fontSize: 8),
        ),
        child: Text(label),
      ),
    );
  }
}
