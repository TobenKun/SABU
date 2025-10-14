import 'package:flutter/material.dart';
import '../widgets/savings_button.dart';
import '../services/database_service.dart';
import '../services/feedback_service.dart';
import '../services/logger_service.dart';
import '../models/user_progress.dart';
import '../models/savings_result.dart';

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
          await FeedbackService.milestone();
          _showMilestoneDialog(result.milestonesHit);
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

  void _showMilestoneDialog(List<int> milestones) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Milestone Achieved!'),
        content: Text(
          'Congratulations! You\'ve reached ${milestones.map((m) => '₩${m.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}').join(', ')}!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Awesome!'),
          ),
        ],
      ),
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Progress Display
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Progress',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total Saved'),
                              Text(
                                '₩${_progress.totalSavings.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Today'),
                              Text(
                                '${_progress.todaySessionCount} saves',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
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
                _isLoading ? 'Saving...' : 'Tap to save ₩1,000',
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
    );
  }
}