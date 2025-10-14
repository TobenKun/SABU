import 'package:flutter/material.dart';
import '../services/feedback_service.dart';

class SavingsButton extends StatefulWidget {
  final VoidCallback onPressed;
  
  const SavingsButton({
    Key? key,
    required this.onPressed,
  }) : super(key: key);

  @override
  State<SavingsButton> createState() => _SavingsButtonState();
}

class _SavingsButtonState extends State<SavingsButton>
    with TickerProviderStateMixin {
  bool _isPressed = false;
  DateTime? _lastTapTime;
  static const Duration _debounceDelay = Duration(milliseconds: 300);

  void _handleTapDown(TapDownDetails details) {
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
    final now = DateTime.now();
    
    // Debounce logic to prevent double-tap
    if (_lastTapTime != null && 
        now.difference(_lastTapTime!) < _debounceDelay) {
      return;
    }
    
    _lastTapTime = now;
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: _handleTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isPressed ? Colors.green : Colors.blue,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.add,
            size: 48,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}