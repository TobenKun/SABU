import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:one_touch_savings/utils/korean_number_formatter.dart';

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

  @override
  void initState() {
    super.initState();
    
    // Use a single controller for better performance
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2300),
      vsync: this,
    );

    // Define intervals for different animation phases
    const double scaleStart = 0.0;
    const double scaleEnd = 0.35;
    const double colorStart = 0.0;
    const double colorEnd = 0.43;
    const double holdEnd = 0.65;
    const double fadeStart = 0.65;
    const double fadeEnd = 1.0;

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: scaleEnd - scaleStart,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.2),
        weight: holdEnd - scaleEnd,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInBack)),
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

  void _startCelebration() {
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${KoreanNumberFormatter.formatCurrency(widget.milestoneAmount)} milestone achieved',
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
                        key: Key('celebration_icon'),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        KoreanNumberFormatter.formatCurrency(widget.milestoneAmount),
                        key: const Key('milestone_amount'),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          decoration: TextDecoration.none,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'milestone achieved!',
                        key: Key('milestone_text_en'),
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '축하합니다! 🎉',
                        key: Key('milestone_text_ko'),
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w400,
                          decoration: TextDecoration.none,
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
              fontFeatures: const [FontFeature.tabularFigures()],
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