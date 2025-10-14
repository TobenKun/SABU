import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:one_touch_savings/utils/korean_number_formatter.dart';
import '../services/performance_service.dart';

class MilestoneCelebration extends StatefulWidget {
  final int milestoneAmount;
  final VoidCallback onComplete;

  const MilestoneCelebration({
    super.key,
    required this.milestoneAmount,
    required this.onComplete,
  });

  @override
  State<MilestoneCelebration> createState() => _MilestoneCelebrationState();
}

class _MilestoneCelebrationState extends State<MilestoneCelebration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Color?> _colorAnimation;
  String? _cachedAmountText;

  @override
  void initState() {
    super.initState();
    
    // Cache formatted text once
    _cachedAmountText = KoreanNumberFormatter.formatCurrency(widget.milestoneAmount);
    
    // Use a single controller for better performance
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000), // Reduced for better performance
      vsync: this,
    );

    // Define intervals for different animation phases
    const double scaleStart = 0.0;
    const double scaleEnd = 0.3;
    const double colorStart = 0.0;
    const double colorEnd = 0.4;
    const double holdEnd = 0.6;
    const double fadeStart = 0.6;
    const double fadeEnd = 1.0;

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOutBack)), // More performant curve
        weight: scaleEnd - scaleStart,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.2),
        weight: holdEnd - scaleEnd,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInQuart)),
        weight: fadeEnd - holdEnd,
      ),
    ]).animate(_controller);

    _colorAnimation = TweenSequence<Color?>([
      TweenSequenceItem(
        tween: ColorTween(
          begin: Colors.blue[600],
          end: Colors.green[600],
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: colorEnd - colorStart,
      ),
      TweenSequenceItem(
        tween: ConstantTween<Color?>(Colors.green[600]),
        weight: fadeEnd - colorEnd,
      ),
    ]).animate(_controller);

    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: fadeStart,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: fadeEnd - fadeStart,
      ),
    ]).animate(_controller);

    // Listen for animation completion
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });

    // Start the celebration animation
    _startCelebration();
  }

  void _startCelebration() async {
    final stopwatch = Stopwatch()..start();
    
    await _controller.forward();
    
    stopwatch.stop();
    PerformanceService.trackAnimationFrame(
      'MilestoneCelebration.animation', 
      stopwatch.elapsed,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Semantics(
        label: '$_cachedAmountText milestone achieved',
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    key: const Key('celebration_container'),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: (_colorAnimation.value ?? Colors.blue).withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: (_colorAnimation.value ?? Colors.blue).withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.celebration,
                          size: 64,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '축하합니다!',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _cachedAmountText!,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '달성!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// Enhanced milestone celebration overlay that can be shown over other content
class MilestoneCelebrationOverlay extends StatelessWidget {
  final int milestoneAmount;
  final VoidCallback onComplete;

  const MilestoneCelebrationOverlay({
    super.key,
    required this.milestoneAmount,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.7),
        child: MilestoneCelebration(
          milestoneAmount: milestoneAmount,
          onComplete: onComplete,
        ),
      ),
    );
  }
}

// Compact milestone indicator for use in progress displays
class MilestoneIndicator extends StatelessWidget {
  final bool isActive;
  final int milestoneAmount;

  const MilestoneIndicator({
    super.key,
    required this.isActive,
    required this.milestoneAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('milestone_indicator'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green[100] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? Colors.green[600]! : Colors.grey[400]!,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: isActive ? Colors.green[600] : Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Text(
            KoreanNumberFormatter.formatCurrency(milestoneAmount),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isActive ? Colors.green[800] : Colors.grey[700],
            ),
          ),
        ],
      ),
    ).animate(target: isActive ? 1 : 0).scale(
      begin: const Offset(0.8, 0.8),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }
}