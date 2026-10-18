import 'package:flutter/material.dart';

/// Provides a lightweight, high-performance staggered slide and fade micro-animation.
/// Ideal for grids, lists, cards, and modal dialogs on iOS, iPadOS, and macOS.
class StaggeredSlideFade extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration duration;
  final double slideOffset;
  final Axis direction;

  const StaggeredSlideFade({
    super.key,
    required this.child,
    required this.index,
    this.duration = const Duration(milliseconds: 300),
    this.slideOffset = 18.0,
    this.direction = Axis.vertical,
  });

  @override
  State<StaggeredSlideFade> createState() => _StaggeredSlideFadeState();
}

class _StaggeredSlideFadeState extends State<StaggeredSlideFade>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    final startOffset = widget.direction == Axis.vertical
        ? Offset(0, widget.slideOffset / 100)
        : Offset(widget.slideOffset / 100, 0);

    _slideAnimation = Tween<Offset>(
      begin: startOffset,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    // Stagger delay capped at 280ms to keep animations snappy
    final delay = Duration(milliseconds: (widget.index * 30).clamp(0, 280));
    Future.delayed(delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
