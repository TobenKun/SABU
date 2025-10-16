import 'dart:async';
import 'package:flutter/material.dart';
import '../models/animation_state.dart';

class AnimatedTurtleSprite extends StatefulWidget {
  final TurtleAnimationLevel level;
  final double width;
  final double height;

  const AnimatedTurtleSprite({
    super.key,
    required this.level,
    this.width = 300.0,
    this.height = 300.0,
  });

  @override
  State<AnimatedTurtleSprite> createState() => _AnimatedTurtleSpriteState();
}

class _AnimatedTurtleSpriteState extends State<AnimatedTurtleSprite>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  List<String> _currentFrames = [];
  Map<String, List<String>> _preloadedFrames = {};
  Timer? _idleTimer;

  @override
  void initState() {
    super.initState();
    _preloadFrames();
    _initializeAnimation();
  }

  @override
  void didUpdateWidget(AnimatedTurtleSprite oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.level != widget.level) {
      _updateAnimationForLevel();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _idleTimer?.cancel();
    super.dispose();
  }

  void _preloadFrames() {
    _preloadedFrames = {
      'idle': List.generate(
          10, (i) => 'assets/images/characters/turtle/idle/frame_$i.png'),
      'walking': List.generate(
          6, (i) => 'assets/images/characters/turtle/walking/frame_$i.png'),
      'running': List.generate(
          3, (i) => 'assets/images/characters/turtle/running/frame_$i.png'),
    };
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      duration: _getDurationForLevel(widget.level),
      vsync: this,
    );

    _updateAnimationForLevel();
  }

  void _updateAnimationForLevel() {
    final frames = _getFramesForLevel(widget.level);
    final duration = _getDurationForLevel(widget.level);

    setState(() {
      _currentFrames = frames;
    });

    _animationController.duration = duration;

    if (widget.level == TurtleAnimationLevel.idle) {
      // For idle, play once then wait 3 seconds before repeating
      _startIdleAnimation();
    } else {
      // For walking/running, loop continuously
      _idleTimer?.cancel();
      _animationController.repeat();
    }
  }

  List<String> _getFramesForLevel(TurtleAnimationLevel level) {
    switch (level) {
      case TurtleAnimationLevel.idle:
        return _preloadedFrames['idle']!;
      case TurtleAnimationLevel.walkSlow:
      case TurtleAnimationLevel.walkFast:
        return _preloadedFrames['walking']!;
      case TurtleAnimationLevel.runSlow:
      case TurtleAnimationLevel.runFast:
        return _preloadedFrames['running']!;
    }
  }

  Duration _getDurationForLevel(TurtleAnimationLevel level) {
    switch (level) {
      case TurtleAnimationLevel.idle:
        return const Duration(seconds: 2); // Slow idle animation
      case TurtleAnimationLevel.walkSlow:
        return const Duration(milliseconds: 800); // Slow walk
      case TurtleAnimationLevel.walkFast:
        return const Duration(milliseconds: 500); // Fast walk
      case TurtleAnimationLevel.runSlow:
        return const Duration(milliseconds: 300); // Slow run
      case TurtleAnimationLevel.runFast:
        return const Duration(milliseconds: 150); // Fast run
    }
  }

  void _startIdleAnimation() {
    _idleTimer?.cancel();
    _animationController.reset();
    _animationController.forward().then((_) {
      if (mounted && widget.level == TurtleAnimationLevel.idle) {
        _animationController.reset();
        // Wait 3 seconds before starting the next cycle
        _idleTimer = Timer(const Duration(seconds: 3), () {
          if (mounted && widget.level == TurtleAnimationLevel.idle) {
            _startIdleAnimation();
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentFrames.isEmpty) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
      );
    }

    return RepaintBoundary(
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            final frameIndex =
                (_animationController.value * _currentFrames.length).floor() %
                    _currentFrames.length;
            return Image.asset(
              _currentFrames[frameIndex],
              width: widget.width,
              height: widget.height,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.none,
              errorBuilder: (context, error, stackTrace) {
                // Fallback to idle frame 0 if there's an error loading
                return Image.asset(
                  'assets/images/characters/turtle/idle/frame_0.png',
                  width: widget.width,
                  height: widget.height,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.none,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
