import 'package:flutter/material.dart';
import '../utils/korean_number_formatter.dart';
import '../services/performance_service.dart';

class SimplifiedProgressDisplay extends StatefulWidget {
  final int currentAmount;
  final bool showAnimation;
  final Duration animationDuration;
  final VoidCallback? onAnimationComplete;
  final bool ultraCompact;

  const SimplifiedProgressDisplay({
    super.key,
    required this.currentAmount,
    this.showAnimation = true,
    this.animationDuration = const Duration(milliseconds: 600),
    this.onAnimationComplete,
    this.ultraCompact = false,
  });

  @override
  State<SimplifiedProgressDisplay> createState() => _SimplifiedProgressDisplayState();
}

class _SimplifiedProgressDisplayState extends State<SimplifiedProgressDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _counterAnimation;
  String? _cachedCounterText;
  
  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _initializeAnimations();
    
    if (widget.showAnimation) {
      _startAnimation();
    } else {
      _controller.value = 1.0;
    }
  }
  
  void _initializeAnimations() {
    _counterAnimation = IntTween(
      begin: 0,
      end: widget.currentAmount,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuart,
    ));
  }
  
  void _startAnimation() async {
    final stopwatch = Stopwatch()..start();
    
    await _controller.forward();
    widget.onAnimationComplete?.call();
    
    stopwatch.stop();
    PerformanceService.trackAnimationFrame(
      'SimplifiedProgressDisplay.animation', 
      stopwatch.elapsed,
    );
  }
  
  @override
  void didUpdateWidget(SimplifiedProgressDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.currentAmount != widget.currentAmount) {
      _updateAnimations();
    }
  }
  
  void _updateAnimations() {
    _counterAnimation = IntTween(
      begin: _counterAnimation.value,
      end: widget.currentAmount,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuart,
    ));
    
    _controller.reset();
    
    if (widget.showAnimation) {
      _startAnimation();
    } else {
      _controller.value = 1.0;
    }
  }
  
  String _formatCurrency(int amount) {
    return KoreanNumberFormatter.formatCurrency(amount);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.ultraCompact) {
      // Ultra-compact version for small screens - vertical layout
      return RepaintBoundary(
        child: Container(
          key: const Key('simplified_progress_display'),
          height: 100,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '지금까지 저축한 금액',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: AnimatedBuilder(
                  animation: _counterAnimation,
                  builder: (context, child) {
                    final currentValue = _counterAnimation.value;
                    if (_cachedCounterText == null || 
                        !_cachedCounterText!.contains(currentValue.toString())) {
                      _cachedCounterText = _formatCurrency(currentValue);
                    }
                    
                    return Text(
                      _cachedCounterText!,
                      key: const Key('simplified_progress_counter'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4CAF50),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RepaintBoundary(
      child: SizedBox(
        width: double.infinity,
        child: Container(
          key: const Key('simplified_progress_display'),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                spreadRadius: 2,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '지금까지 저축한 금액',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),
              RepaintBoundary(
                child: SizedBox(
                  height: 60,
                  child: AnimatedBuilder(
                    animation: _counterAnimation,
                    builder: (context, child) {
                      final currentValue = _counterAnimation.value;
                      if (_cachedCounterText == null || 
                          !_cachedCounterText!.contains(currentValue.toString())) {
                        _cachedCounterText = _formatCurrency(currentValue);
                      }
                      
                      return Text(
                        _cachedCounterText!,
                        key: const Key('simplified_progress_counter'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4CAF50),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}