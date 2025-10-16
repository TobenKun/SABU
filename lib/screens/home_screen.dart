import 'package:flutter/material.dart';
import '../models/user_progress.dart';
import '../services/database_service.dart';
import '../services/logger_service.dart';
import '../services/feedback_service.dart';
import '../widgets/progress_display.dart';
import '../widgets/savings_button.dart';
import '../widgets/milestone_celebration.dart';
import '../utils/korean_number_formatter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _databaseService = DatabaseService();
  UserProgress _progress = UserProgress(
    totalSavings: 0,
    totalSessions: 0,
    todaySessionCount: 0,
    currentStreak: 0,
    longestStreak: 0,
    lastSaveDate: DateTime.now(),
    milestones: [],
  );
  bool _isLoading = false;
  String? _errorMessage;
  int? _currentMilestone; // Track current milestone being shown

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    try {
      LoggerService.debug('Loading user progress');
      final progress = await _databaseService.getCurrentProgress();
      setState(() {
        _progress = progress;
      });
      LoggerService.info('Progress loaded successfully - Total: ₩${progress.totalSavings}');
    } catch (e) {
      LoggerService.error('Failed to load progress', e);
      setState(() {
        _errorMessage = 'Failed to load progress';
      });
    }
  }

  Future<void> _handleSave() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      LoggerService.info('Starting save operation');
      final result = await _databaseService.saveMoney();
      
      if (result.success) {
        // Reload full progress data to ensure streak information is updated
        if (mounted) {
          await _loadProgress();
        }

        // Log success
        LoggerService.logSaveSuccess(result.newTotal, result.todayCount);

        // Provide feedback
        await FeedbackService.saveSuccess();

        // Check for milestones
        LoggerService.logDatabaseOperation('Checking milestones from saveMoney result', {
          'milestonesHit': result.milestonesHit,
          'milestonesHitLength': result.milestonesHit.length,
        });
        
        if (result.milestonesHit.isNotEmpty) {
          LoggerService.logMilestone(result.milestonesHit);
          
          // Show milestone celebration for the highest milestone
          final highestMilestone = result.milestonesHit.reduce((a, b) => a > b ? a : b);
          LoggerService.logDatabaseOperation('Setting milestone celebration', {
            'highestMilestone': highestMilestone,
            'currentMilestone': _currentMilestone,
          });
          
          if (mounted) {
            setState(() {
              _currentMilestone = highestMilestone;
            });
          }
          
          // Start enhanced milestone feedback synchronized with animation
          FeedbackService.milestoneWithAnimation(
            animationDuration: const Duration(milliseconds: 2300),
          );
        } else {
          // No milestones hit
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
      LoggerService.error('Unexpected error during save operation', e);
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

  Widget _buildStatColumn(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 24,
          color: Colors.grey[600],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('One-Touch Savings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  children: [
                        // Enhanced Progress Display with Animation
                        ProgressDisplay(
                          currentAmount: _progress.totalSavings,
                          targetAmount: _progress.nextMilestone,
                          progressPercentage: _progress.progressToNextMilestone,
                          showAnimation: true,
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Quick Stats Card
                        Card(
                          child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatColumn(
                                '오늘',
                                '${_progress.todaySessionCount}회',
                                Icons.today,
                              ),
                              _buildStatColumn(
                                '총 저축',
                                '${_progress.totalSessions}회',
                                Icons.savings,
                              ),
                              _buildStatColumn(
                                '연속 기록',
                                '${_progress.currentStreak}일',
                                Icons.local_fire_department,
                              ),
                            ],
                          ),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Progress Message
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            KoreanNumberFormatter.formatProgressMessageFromProgress(
                              _progress.progressToNextMilestone,
                              _progress.amountToNextMilestone,
                            ),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.blue,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        
                        const SizedBox(height: 40), // Replace Spacer

                        // Error Message
                        if (_errorMessage != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error, color: Colors.red),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_errorMessage!)),
                              ],
                            ),
                          ),

                        // Save Button
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
                       
                       const SizedBox(height: 50), // Replace Spacer with SizedBox
                     ],
                   ),
                 ),
               ),
             
             // Milestone Celebration Overlay
             if (_currentMilestone != null)
               MilestoneCelebration(
                 milestoneAmount: _currentMilestone!,
                  onComplete: () {
                    if (mounted) {
                      setState(() {
                        _currentMilestone = null;
                      });
                    }
                  },
               ),
           ],
         ),
       ),
     );
   }
}