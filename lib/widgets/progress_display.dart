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
  final bool isCompact; // For small screen layouts
  final bool ultraCompact; // For very small screens - V2 style

  const ProgressDisplay({
    super.key,
    required this.currentAmount,
    required this.targetAmount,
    this.progressPercentage,
    this.showAnimation = true,
    this.animationDuration = const Duration(milliseconds: 600), // Reduced for better performance
    this.onAnimationComplete,
    this.isCompact = false, // Default to normal size
    this.ultraCompact = false, // Default to normal size
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
    // V2-style ultra compact mode for very small screens
    if (widget.ultraCompact) {
      return RepaintBoundary(
        child: Container(
          key: const Key('progress_display'),
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
                      key: const Key('progress_counter'),
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

    // Ultra compact mode dimensions for small screens (800x480)
    final double padding = widget.isCompact ? 8 : 24;
    final double counterHeight = widget.isCompact ? 24 : 50;
    final double counterFontSize = widget.isCompact ? 18 : 36;
    final double targetHeight = widget.isCompact ? 14 : 25;
    final double targetFontSize = widget.isCompact ? 10 : 16;
    final double spacingLarge = widget.isCompact ? 6 : 20;
    final double spacingSmall = widget.isCompact ? 2 : 8;
    final double spacingMedium = widget.isCompact ? 3 : 12;
    final double progressBarHeight = widget.isCompact ? 6 : 12;
    final double percentageHeight = widget.isCompact ? 16 : 30;
    final double percentageFontSize = widget.isCompact ? 12 : 20;
    final double borderRadius = widget.isCompact ? 8 : 16;
    
    return RepaintBoundary(
      child: SizedBox(
        width: double.infinity,
        child: Container(
          key: const Key('progress_display'),
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                spreadRadius: widget.isCompact ? 1 : 2,
                blurRadius: widget.isCompact ? 4 : 8,
                offset: Offset(0, widget.isCompact ? 1 : 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Optimized animated counter with RepaintBoundary
              RepaintBoundary(
                child: SizedBox(
                  height: counterHeight,
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
                        style: TextStyle(
                          fontSize: counterFontSize,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF4CAF50),
                        ),
                      );
                    },
                  ),
                ),
              ),
            
            SizedBox(height: spacingSmall),
            
              // Static target display (no need to rebuild)
              SizedBox(
                height: targetHeight,
                child: Text(
                  _cachedTargetText!,
                  key: const Key('target_display'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: targetFontSize,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            
            SizedBox(height: spacingLarge),
            
            // Optimized progress bar with RepaintBoundary
            RepaintBoundary(
              child: Container(
                key: const Key('progress_container'),
                height: progressBarHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(progressBarHeight / 2),
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
                          borderRadius: BorderRadius.circular(progressBarHeight / 2),
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
            
            SizedBox(height: spacingMedium),
            
              // Optimized percentage display
              RepaintBoundary(
                child: SizedBox(
                  height: percentageHeight,
                  child: AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      final percentage = (_progressAnimation.value * 100).toStringAsFixed(1);
                      return Text(
                        '$percentage%',
                        key: const Key('percentage_display'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: percentageFontSize,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF4CAF50),
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