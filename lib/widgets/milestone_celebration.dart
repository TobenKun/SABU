import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:one_touch_savings/utils/korean_number_formatter.dart';

class MilestoneCelebration extends StatefulWidget {
  final int milestoneAmount;
  final VoidCallback onComplete;

  const MilestoneCelebration({
    Key? key,
    required this.milestoneAmount,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<MilestoneCelebration> createState() => _MilestoneCelebrationState();
}

class _MilestoneCelebrationState extends State<MilestoneCelebration>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _colorController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _colorController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _colorAnimation = ColorTween(
      begin: Colors.blue[600],
      end: Colors.green[600],
    ).animate(CurvedAnimation(
      parent: _colorController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _startCelebration();
  }

  void _startCelebration() async {
    // Start scale and color animations simultaneously
    final scaleAnimation = _scaleController.forward();
    final colorAnimation = _colorController.forward();

    // Wait for animations to complete
    await Future.wait([
      scaleAnimation,
      colorAnimation,
    ]);

    // Hold the celebration for a moment
    await Future.delayed(const Duration(milliseconds: 500));

    // Fade out
    await _scaleController.reverse();

    // Call completion callback
    widget.onComplete();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${KoreanNumberFormatter.formatCurrency(widget.milestoneAmount)} milestone achieved',
      child: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([_scaleController, _colorController]),
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: AnimatedContainer(
                key: const Key('celebration_scale_animation'),
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: _colorAnimation.value?.withOpacity(0.9) ?? Colors.blue.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (_colorAnimation.value ?? Colors.blue).withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  key: const Key('celebration_color_animation'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.celebration,
                      size: 64,
                      color: Colors.white,
                    ).animate().scale(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.elasticOut,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      KoreanNumberFormatter.formatCurrency(widget.milestoneAmount),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        decoration: TextDecoration.none,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ).animate().slideY(
                      begin: 1,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'milestone achieved!',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.none,
                      ),
                    ).animate().fadeIn(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 200),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '축하합니다! 🎉',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                        decoration: TextDecoration.none,
                      ),
                    ).animate().fadeIn(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 400),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ).animate().fadeIn(
      duration: const Duration(milliseconds: 300),
    );
  }
}

// Enhanced milestone celebration overlay that can be shown over other content
class MilestoneCelebrationOverlay extends StatelessWidget {
  final int milestoneAmount;
  final VoidCallback onComplete;

  const MilestoneCelebrationOverlay({
    Key? key,
    required this.milestoneAmount,
    required this.onComplete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.7),
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
    Key? key,
    required this.isActive,
    required this.milestoneAmount,
  }) : super(key: key);

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