import 'package:flutter/material.dart';
import '../utils/korean_number_formatter.dart';
import '../services/performance_service.dart';

class ProgressDisplay extends StatefulWidget {
  final int currentAmount;
  final int targetAmount;
  final double? progressPercentage; // 0.0 to 1.0, if provided will override calculation
  final bool showAnimation;
  final Duration animationDuration;
  final VoidCallback? onAnimationComplete;

  const ProgressDisplay({
    super.key,
    required this.currentAmount,
    required this.targetAmount,
    this.progressPercentage,
    this.showAnimation = true,
    this.animationDuration = const Duration(milliseconds: 600), // Reduced for better performance
    this.onAnimationComplete,
  });

  @override
  State<ProgressDisplay> createState() => _ProgressDisplayState();
}

class _ProgressDisplayState extends State<ProgressDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  late Animation<int> _counterAnimation;
  String? _cachedCounterText;
  String? _cachedTargetText;
  
  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    // Cache static text values
    _cachedTargetText = 'Target: ${_formatCurrency(widget.targetAmount)}';
    
    _initializeAnimations();
    
    if (widget.showAnimation) {
      _startAnimation();
    } else {
      _controller.value = 1.0;
    }
  }
  
  void _initializeAnimations() {
    final targetPercentage = widget.progressPercentage ?? 
        (widget.targetAmount > 0 
            ? (widget.currentAmount / widget.targetAmount).clamp(0.0, 1.0)
            : 0.0);
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: targetPercentage,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuart, // More performant curve
    ));
    
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
      'ProgressDisplay.animation', 
      stopwatch.elapsed,
    );
  }
  
  @override
  void didUpdateWidget(ProgressDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.currentAmount != widget.currentAmount ||
        oldWidget.targetAmount != widget.targetAmount ||
        oldWidget.progressPercentage != widget.progressPercentage) {
      // Update cached text
      _cachedTargetText = 'Target: ${_formatCurrency(widget.targetAmount)}';
      _updateAnimations();
    }
  }
  
  void _updateAnimations() {
    final targetPercentage = widget.progressPercentage ?? 
        (widget.targetAmount > 0 
            ? (widget.currentAmount / widget.targetAmount).clamp(0.0, 1.0)
            : 0.0);
    
    _progressAnimation = Tween<double>(
      begin: _progressAnimation.value,
      end: targetPercentage,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuart,
    ));
    
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

  // Optimized build method with RepaintBoundary for performance
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: double.infinity,
        child: Container(
          key: const Key('progress_display'),
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
              // Optimized animated counter with RepaintBoundary
              RepaintBoundary(
                child: SizedBox(
                  height: 50, // Fixed height for consistent sizing
                  child: AnimatedBuilder(
                    animation: _counterAnimation,
                    builder: (context, child) {
                      final currentValue = _counterAnimation.value;
                      // Cache formatted text to avoid re-computation
                      if (_cachedCounterText == null || 
                          !_cachedCounterText!.contains(currentValue.toString())) {
                        _cachedCounterText = _formatCurrency(currentValue);
                      }
                      
                      return Text(
                        _cachedCounterText!,
                        key: const Key('progress_counter'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4CAF50),
                        ),
                      );
                    },
                  ),
                ),
              ),
            
            const SizedBox(height: 8),
            
              // Static target display (no need to rebuild)
              SizedBox(
                height: 25, // Fixed height for consistent sizing
                child: Text(
                  _cachedTargetText!,
                  key: const Key('target_display'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            
            const SizedBox(height: 20),
            
            // Optimized progress bar with RepaintBoundary
            RepaintBoundary(
              child: Container(
                key: const Key('progress_container'),
                height: 12,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.grey[200],
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
                          borderRadius: BorderRadius.circular(6),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
              // Optimized percentage display
              RepaintBoundary(
                child: SizedBox(
                  height: 30, // Fixed height for consistent sizing
                  child: AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      final percentage = (_progressAnimation.value * 100).toStringAsFixed(1);
                      return Text(
                        '$percentage%',
                        key: const Key('percentage_display'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
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