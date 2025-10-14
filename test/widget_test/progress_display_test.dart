import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Mock ProgressDisplay widget that will be implemented in T024
class ProgressDisplay extends StatefulWidget {
  final int currentAmount;
  final int targetAmount;
  final bool showAnimation;
  final Duration animationDuration;
  final VoidCallback? onAnimationComplete;

  const ProgressDisplay({
    super.key,
    required this.currentAmount,
    required this.targetAmount,
    this.showAnimation = true,
    this.animationDuration = const Duration(milliseconds: 800),
    this.onAnimationComplete,
  });

  @override
  State<ProgressDisplay> createState() => _ProgressDisplayState();
}

class _ProgressDisplayState extends State<ProgressDisplay>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _counterController;
  late Animation<double> _progressAnimation;
  late Animation<int> _counterAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _progressController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _counterController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    final targetPercentage = widget.targetAmount > 0 
        ? (widget.currentAmount / widget.targetAmount).clamp(0.0, 1.0)
        : 0.0;
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: targetPercentage,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    ));
    
    _counterAnimation = IntTween(
      begin: 0,
      end: widget.currentAmount,
    ).animate(CurvedAnimation(
      parent: _counterController,
      curve: Curves.easeOutCubic,
    ));
    
    if (widget.showAnimation) {
      _startAnimations();
    } else {
      _progressController.value = 1.0;
      _counterController.value = 1.0;
    }
  }
  
  void _startAnimations() async {
    await Future.wait([
      _progressController.forward(),
      _counterController.forward(),
    ]);
    widget.onAnimationComplete?.call();
  }
  
  @override
  void didUpdateWidget(ProgressDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.currentAmount != widget.currentAmount ||
        oldWidget.targetAmount != widget.targetAmount) {
      _updateAnimations();
    }
  }
  
  void _updateAnimations() {
    final targetPercentage = widget.targetAmount > 0 
        ? (widget.currentAmount / widget.targetAmount).clamp(0.0, 1.0)
        : 0.0;
    
    _progressAnimation = Tween<double>(
      begin: _progressAnimation.value,
      end: targetPercentage,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    ));
    
    _counterAnimation = IntTween(
      begin: _counterAnimation.value,
      end: widget.currentAmount,
    ).animate(CurvedAnimation(
      parent: _counterController,
      curve: Curves.easeOutCubic,
    ));
    
    _progressController.reset();
    _counterController.reset();
    
    if (widget.showAnimation) {
      _startAnimations();
    } else {
      _progressController.value = 1.0;
      _counterController.value = 1.0;
    }
  }
  
  String _formatCurrency(int amount) {
    final formatter = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formattedAmount = amount.toString().replaceAllMapped(
      formatter, 
      (Match match) => '${match[1]},'
    );
    return '₩$formattedAmount';
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Animated counter
        AnimatedBuilder(
          animation: _counterAnimation,
          builder: (context, child) {
            return Text(
              _formatCurrency(_counterAnimation.value),
              key: const Key('progress_counter'),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            );
          },
        ),
        
        const SizedBox(height: 16),
        
        // Progress bar
        Container(
          key: const Key('progress_container'),
          height: 20,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.grey[300],
          ),
          child: AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _progressAnimation.value,
                child: Container(
                  key: const Key('progress_bar'),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.green,
                  ),
                ),
              );
            },
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Target display
        Text(
          'Target: ${_formatCurrency(widget.targetAmount)}',
          key: const Key('target_display'),
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        
        // Percentage display
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            final percentage = (_progressAnimation.value * 100).toStringAsFixed(1);
            return Text(
              '$percentage%',
              key: const Key('percentage_display'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            );
          },
        ),
      ],
    );
  }
  
  @override
  void dispose() {
    _progressController.dispose();
    _counterController.dispose();
    super.dispose();
  }
}

void main() {
  group('ProgressDisplay Widget Tests', () {
    testWidgets('should display initial state correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProgressDisplay(
              currentAmount: 3000,
              targetAmount: 10000,
              showAnimation: false, // Disable animation for testing
            ),
          ),
        ),
      );

      // Should display formatted currency
      expect(find.text('₩3,000'), findsOneWidget);
      expect(find.text('Target: ₩10,000'), findsOneWidget);
      expect(find.text('30.0%'), findsOneWidget);
      
      // Should have progress bar
      expect(find.byKey(const Key('progress_bar')), findsOneWidget);
      expect(find.byKey(const Key('progress_container')), findsOneWidget);
    });

    testWidgets('should animate counter when enabled', (WidgetTester tester) async {
      bool animationCompleted = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProgressDisplay(
              currentAmount: 5000,
              targetAmount: 10000,
              showAnimation: true,
              animationDuration: const Duration(milliseconds: 500),
              onAnimationComplete: () => animationCompleted = true,
            ),
          ),
        ),
      );

      // Initially should show 0 (animation starts from 0)
      expect(find.text('₩0'), findsOneWidget);
      
      // Pump through animation
      await tester.pump(const Duration(milliseconds: 100));
      
      // Should be animating (somewhere between 0 and final value)
      final counterFinder = find.byKey(const Key('progress_counter'));
      expect(counterFinder, findsOneWidget);
      
      // Complete animation
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      
      // Should show final value
      expect(find.text('₩5,000'), findsOneWidget);
      expect(animationCompleted, isTrue);
    });

    testWidgets('should update when amount changes', (WidgetTester tester) async {
      int currentAmount = 2000;
      
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Column(
                  children: [
                    ProgressDisplay(
                      currentAmount: currentAmount,
                      targetAmount: 10000,
                      showAnimation: false,
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          currentAmount += 1000;
                        });
                      },
                      child: const Text('Add 1000'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      // Initial state
      expect(find.text('₩2,000'), findsOneWidget);
      expect(find.text('20.0%'), findsOneWidget);
      
      // Tap button to increase amount
      await tester.tap(find.text('Add 1000'));
      await tester.pumpAndSettle();
      
      // Should update display
      expect(find.text('₩3,000'), findsOneWidget);
      expect(find.text('30.0%'), findsOneWidget);
    });

    testWidgets('should handle zero and edge cases', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProgressDisplay(
              currentAmount: 0,
              targetAmount: 10000,
              showAnimation: false,
            ),
          ),
        ),
      );

      expect(find.text('₩0'), findsOneWidget);
      expect(find.text('0.0%'), findsOneWidget);
      expect(find.text('Target: ₩10,000'), findsOneWidget);
    });

    testWidgets('should handle 100% completion', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProgressDisplay(
              currentAmount: 10000,
              targetAmount: 10000,
              showAnimation: false,
            ),
          ),
        ),
      );

      expect(find.text('₩10,000'), findsOneWidget);
      expect(find.text('100.0%'), findsOneWidget);
      
      // Progress bar should be full width
      final progressBar = tester.widget<FractionallySizedBox>(
        find.descendant(
          of: find.byKey(const Key('progress_container')),
          matching: find.byType(FractionallySizedBox),
        ),
      );
      expect(progressBar.widthFactor, equals(1.0));
    });

    testWidgets('should handle over 100% correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProgressDisplay(
              currentAmount: 15000,
              targetAmount: 10000,
              showAnimation: false,
            ),
          ),
        ),
      );

      expect(find.text('₩15,000'), findsOneWidget);
      expect(find.text('100.0%'), findsOneWidget); // Should clamp to 100%
      
      // Progress bar should be full width (clamped)
      final progressBar = tester.widget<FractionallySizedBox>(
        find.descendant(
          of: find.byKey(const Key('progress_container')),
          matching: find.byType(FractionallySizedBox),
        ),
      );
      expect(progressBar.widthFactor, equals(1.0));
    });

    testWidgets('should handle zero target gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProgressDisplay(
              currentAmount: 5000,
              targetAmount: 0,
              showAnimation: false,
            ),
          ),
        ),
      );

      expect(find.text('₩5,000'), findsOneWidget);
      expect(find.text('0.0%'), findsOneWidget); // Should handle division by zero
      expect(find.text('Target: ₩0'), findsOneWidget);
    });

    testWidgets('should use correct animation curves', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProgressDisplay(
              currentAmount: 5000,
              targetAmount: 10000,
              showAnimation: true,
              animationDuration: Duration(milliseconds: 1000),
            ),
          ),
        ),
      );

      // Start animation
      await tester.pump();
      
      // Check at 25% of animation
      await tester.pump(const Duration(milliseconds: 250));
      
      // Because of easeOutCubic curve, progress should be more than 25% complete
      // This tests that the curve is being applied correctly
      final progressBar = tester.widget<FractionallySizedBox>(
        find.descendant(
          of: find.byKey(const Key('progress_container')),
          matching: find.byType(FractionallySizedBox),
        ),
      );
      
      // With easeOutCubic, at 25% time we should have more than 25% progress
      expect(progressBar.widthFactor, greaterThan(0.25));
    });

    testWidgets('should format large numbers correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProgressDisplay(
              currentAmount: 1234567,
              targetAmount: 2000000,
              showAnimation: false,
            ),
          ),
        ),
      );

      expect(find.text('₩1,234,567'), findsOneWidget);
      expect(find.text('Target: ₩2,000,000'), findsOneWidget);
      expect(find.text('61.7%'), findsOneWidget); // 1234567/2000000 ≈ 61.7%
    });

    testWidgets('should dispose controllers properly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProgressDisplay(
              currentAmount: 3000,
              targetAmount: 10000,
              showAnimation: true,
            ),
          ),
        ),
      );

      // Verify widget is built
      expect(find.byType(ProgressDisplay), findsOneWidget);
      
      // Remove widget to test disposal
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(),
          ),
        ),
      );

      // Should not throw any errors during disposal
      expect(tester.takeException(), isNull);
    });
  });

  group('ProgressDisplay Animation Performance', () {
    testWidgets('should handle rapid updates without performance issues', (WidgetTester tester) async {
      int currentAmount = 0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Column(
                  children: [
                    ProgressDisplay(
                      currentAmount: currentAmount,
                      targetAmount: 10000,
                      showAnimation: false, // Disable for rapid testing
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          currentAmount += 1000;
                        });
                      },
                      child: const Text('Rapid Add'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      // Perform rapid updates
      for (int i = 0; i < 10; i++) {
        await tester.tap(find.text('Rapid Add'));
        await tester.pump();
      }
      
      await tester.pumpAndSettle();
      
      // Should handle all updates correctly
      expect(find.text('₩10,000'), findsOneWidget);
      expect(find.text('100.0%'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}