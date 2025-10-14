import 'dart:async';
import 'package:flutter/material.dart';
import '../services/feedback_service.dart';

class SavingsButton extends StatefulWidget {
  final VoidCallback onPressed;
  
  const SavingsButton({
    super.key,
    required this.onPressed,
  });

  @override
  State<SavingsButton> createState() => _SavingsButtonState();
}

class _SavingsButtonState extends State<SavingsButton>
    with TickerProviderStateMixin {
  bool _isPressed = false;
  bool _isProcessing = false;
  DateTime? _lastTapTime;
  Timer? _debounceTimer;
  
  // Aggressive debouncing for rapid taps while maintaining responsiveness
  static const Duration _minTapInterval = Duration(milliseconds: 150);
  static const Duration _debounceDelay = Duration(milliseconds: 50);

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (_isProcessing) return;
    
    setState(() {
      _isPressed = true;
    });
    FeedbackService.buttonPress();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
  }

  void _handleTapCancel() {
    setState(() {
      _isPressed = false;
    });
  }

  void _handleTap() {
    if (_isProcessing) return;
    
    final now = DateTime.now();
    
    // Check minimum interval between actual save operations
    if (_lastTapTime != null && 
        now.difference(_lastTapTime!) < _minTapInterval) {
      return;
    }
    
    // Cancel any pending debounced operation
    _debounceTimer?.cancel();
    
    // Debounce to handle rapid consecutive taps
    _debounceTimer = Timer(_debounceDelay, () {
      if (mounted) {
        _executeSave();
      }
    });
  }

  void _executeSave() async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });
    
    _lastTapTime = DateTime.now();
    
    try {
      widget.onPressed();
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: _handleTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.9 : 1.0,
          duration: const Duration(milliseconds: 100), // Faster for better responsiveness
          curve: Curves.easeOutQuart, // More performant curve
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isProcessing 
                ? Colors.grey 
                : (_isPressed ? Colors.green : Colors.blue),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _isProcessing
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
              : const Icon(
                  Icons.add,
                  size: 48,
                  color: Colors.white,
                ),
          ),
        ),
      ),
    );
  }
}