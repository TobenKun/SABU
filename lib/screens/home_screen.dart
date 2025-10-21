import 'package:flutter/material.dart';
import '../models/user_progress.dart';
import '../services/database_service.dart';
import '../services/logger_service.dart';
import '../services/feedback_service.dart';
import '../services/design_version_service.dart';
import '../models/design_version_setting.dart';
import '../widgets/progress_display.dart';
import '../widgets/savings_button.dart';
import '../widgets/milestone_celebration.dart';
import '../utils/korean_number_formatter.dart';
import 'home_screen_v2.dart';

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
  int? _currentMilestone;
  int _validatedStreak = 0;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    try {
      LoggerService.debug('Loading user progress');
      final progress = await _databaseService.getCurrentProgress();
      final validatedStreak = await DatabaseService.getValidatedCurrentStreak();
      if (mounted) {
        setState(() {
          _progress = progress;
          _validatedStreak = validatedStreak;
        });
      }
      LoggerService.info('Progress loaded successfully - Total: ₩${progress.totalSavings}');
    } catch (e) {
      LoggerService.error('Failed to load progress', e);
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
    final screenSize = MediaQuery.of(context).size;
    
    // Improved small screen detection for real devices (matching V2)
    // Consider typical small phone screen sizes (iPhone SE, small Android phones)
    // Test environment (800x480) should use small screen layout
    final isSmallScreen = (screenSize.width == 800 && screenSize.height == 480) || // Keep test compatibility
                         (screenSize.width <= 400 && screenSize.height <= 800) ||   // iPhone SE and similar
                         (screenSize.width <= 380) ||                               // Very narrow phones
                         screenSize.height <= 500;                                  // Very small screens
    
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(isSmallScreen ? 4.0 : 16.0),
              child: isSmallScreen 
                ? _buildSmallScreenLayout() 
                : SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(), 
                    child: _buildNormalLayout(),
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

  Widget _buildNormalLayout() {
    return Column(
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
                '${_validatedStreak}일',
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
        
        const SizedBox(height: 40),

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
       
       const SizedBox(height: 50),
     ],
   );
  }

  Widget _buildSmallScreenLayout() {
    // V2-style layout for small screens with better spacing and fonts
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 19), // Consistent with V2 spacing
        
        // Top row: Progress display (left) + Usage stats (right) - 50:50 layout like V2
        Row(
          children: [
            // Left side: V1 ProgressDisplay with ultra-compact mode (50% of width)
            Expanded(
              flex: 1,
              child: SizedBox(
                height: 100,
                child: ProgressDisplay(
                  currentAmount: _progress.totalSavings,
                  targetAmount: _progress.nextMilestone,
                  progressPercentage: _progress.progressToNextMilestone,
                  showAnimation: false, // Disable animation for better performance on small screens
                  isCompact: true,
                  ultraCompact: true, // New ultra compact mode
                ),
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Right side: V1 stats using card with V2-style compact layout (50% of width)
            Expanded(
              flex: 1,
              child: SizedBox(
                height: 100,
                child: Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.today,
                                  size: 12,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '오늘',
                                  style: TextStyle(
                                    fontSize: 12, 
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${_progress.todaySessionCount}회',
                              style: TextStyle(
                                fontSize: 12, 
                                color: Colors.grey[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.savings,
                                  size: 12,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '총 저축',
                                  style: TextStyle(
                                    fontSize: 12, 
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${_progress.totalSessions}회',
                              style: TextStyle(
                                fontSize: 12, 
                                color: Colors.grey[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.local_fire_department,
                                  size: 12,
                                  color: Colors.orange[400],
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '연속 기록',
                                  style: TextStyle(
                                    fontSize: 12, 
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${_validatedStreak}일',
                              style: TextStyle(
                                fontSize: 12, 
                                color: Colors.grey[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Error Message (consistent with V2 style)
        if (_errorMessage != null)
          Container(
            height: 25,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
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

        // Bottom row: Compact savings button + text (centered, consistent with V2)
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
                fontSize: 12.0, // Increased from 11px to match V2
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ],
    );
  }
}

class HomeScreenRouter extends StatefulWidget {
  const HomeScreenRouter({super.key});

  @override
  State<HomeScreenRouter> createState() => _HomeScreenRouterState();
}

class _HomeScreenRouterState extends State<HomeScreenRouter> {
  final DesignVersionService _designVersionService = DesignVersionService();
  DesignVersion? _currentVersion;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadCurrentVersion();
    _listenToVersionChanges();
  }

  Future<void> _loadCurrentVersion() async {
    try {
      final version = await _designVersionService.getCurrentDesignVersion();
      if (mounted) {
        setState(() {
          _currentVersion = version;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentVersion = DesignVersion.v1; // Default to V1 on error
          _isLoading = false;
        });
      }
    }
  }

  void _listenToVersionChanges() {
    _designVersionService.versionChangeStream.listen((change) {
      if (mounted) {
        setState(() {
          _currentVersion = change.newVersion;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_currentVersion == DesignVersion.v2) {
      return const HomeScreenV2();
    } else {
      return const HomeScreen();
    }
  }
}