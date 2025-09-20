import 'package:flutter/material.dart';

class PushEffectButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Duration animationDuration;
  final double scaleDownFactor;

  const PushEffectButton({
    super.key,
    required this.child,
    this.onPressed,
    this.animationDuration = const Duration(milliseconds: 150),
    this.scaleDownFactor = 0.85,
  });

  @override
  State<PushEffectButton> createState() => _PushEffectButtonState();
}

class _PushEffectButtonState extends State<PushEffectButton>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleDownFactor,
    ).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      setState(() {
        _isPressed = true;
      });
      _scaleController.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (_isPressed) {
      widget.onPressed?.call();
    }
    _resetButton();
  }

  void _onTapCancel() {
    _resetButton();
  }

  void _resetButton() {
    setState(() {
      _isPressed = false;
    });

    // Animate back smoothly with delay
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        _scaleController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}