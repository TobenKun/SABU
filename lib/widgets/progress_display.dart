import 'package:flutter/material.dart';
import '../utils/korean_number_formatter.dart';

class ProgressDisplay extends StatefulWidget {
  final int currentAmount;
  final int targetAmount;
  final bool showAnimation;
  final Duration animationDuration;
  final VoidCallback? onAnimationComplete;

  const ProgressDisplay({
    Key? key,
    required this.currentAmount,
    required this.targetAmount,
    this.showAnimation = true,
    this.animationDuration = const Duration(milliseconds: 800),
    this.onAnimationComplete,
  }) : super(key: key);

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
    return KoreanNumberFormatter.formatCurrency(amount);
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('progress_display'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated counter
          AnimatedBuilder(
            animation: _counterAnimation,
            builder: (context, child) {
              return Text(
                _formatCurrency(_counterAnimation.value),
                key: const Key('progress_counter'),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4CAF50),
                ),
              );
            },
          ),
          
          const SizedBox(height: 8),
          
          // Target display
          Text(
            'Target: ${_formatCurrency(widget.targetAmount)}',
            key: const Key('target_display'),
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Progress bar
          Container(
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
          
          const SizedBox(height: 12),
          
          // Percentage display
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              final percentage = (_progressAnimation.value * 100).toStringAsFixed(1);
              return Text(
                '$percentage%',
                key: const Key('percentage_display'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4CAF50),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _progressController.dispose();
    _counterController.dispose();
    super.dispose();
  }
}