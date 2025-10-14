import 'package:flutter/material.dart';
import '../widgets/savings_button.dart';
import '../widgets/progress_display.dart';
import '../widgets/milestone_celebration.dart';
import '../services/database_service.dart';
import '../services/feedback_service.dart';
import '../services/logger_service.dart';
import '../models/user_progress.dart';
import '../models/savings_result.dart';
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
  bool _showingCelebration = false;
  int? _celebrationMilestone;

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
        // Update progress state
        setState(() {
          _progress = _progress.copyWith(
            totalSavings: result.newTotal,
            totalSessions: _progress.totalSessions + 1,
            todaySessionCount: result.todayCount,
          );
        });

        // Log success
        LoggerService.logSaveSuccess(result.newTotal, result.todayCount);

        // Provide feedback
        await FeedbackService.saveSuccess();

        // Check for milestones
        if (result.milestonesHit.isNotEmpty) {
          LoggerService.logMilestone(result.milestonesHit);
          
          // Get the highest milestone for celebration
          final highestMilestone = result.milestonesHit.reduce((a, b) => a > b ? a : b);
          
          // Show celebration overlay first
          _showMilestoneCelebration(highestMilestone);
          
          // Start enhanced milestone feedback synchronized with animation
          FeedbackService.milestoneWithAnimation(
            animationDuration: const Duration(milliseconds: 2300),
          );
        }
      } else {
        final errorMessage = result.error ?? 'Save failed';
        LoggerService.logSaveError(errorMessage);
        setState(() {
          _errorMessage = errorMessage;
        });
        await FeedbackService.error();
      }
    } catch (e) {
      LoggerService.error('Unexpected error during save operation', e);
      setState(() {
        _errorMessage = 'Unexpected error occurred';
      });
      await FeedbackService.error();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showMilestoneCelebration(int milestoneAmount) {
    setState(() {
      _showingCelebration = true;
      _celebrationMilestone = milestoneAmount;
    });
  }

  void _onCelebrationComplete() {
    setState(() {
      _showingCelebration = false;
      _celebrationMilestone = null;
    });
  }

  void _showMilestoneDialog(List<int> milestones) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 목표 달성!'),
        content: Text(
          '축하합니다! ${milestones.map((m) => KoreanNumberFormatter.formatMilestoneMessage(m)).join('\n')}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('훌륭해요!'),
          ),
        ],
      ),
    );
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
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('One-Touch Savings'),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Enhanced Progress Display with Animation
                  ProgressDisplay(
                    currentAmount: _progress.totalSavings,
                    targetAmount: KoreanNumberFormatter.getNextMilestone(_progress.totalSavings),
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
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Text(
                      KoreanNumberFormatter.formatProgressMessage(
                        _progress.totalSavings,
                        KoreanNumberFormatter.getNextMilestone(_progress.totalSavings),
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  const Spacer(),

                  // Error Message
                  if (_errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
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
                  
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
        
        // Milestone Celebration Overlay
        if (_showingCelebration && _celebrationMilestone != null)
          MilestoneCelebrationOverlay(
            milestoneAmount: _celebrationMilestone!,
            onComplete: _onCelebrationComplete,
          ),
      ],
    );
  }
}