import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

/// Performance utilities for optimizing Flutter app performance on high refresh rate displays
class PerformanceUtils {
  
  /// Creates a high-performance scroll view optimized for 120Hz displays
  static Widget createOptimizedScrollView({
    required Widget child,
    ScrollController? controller,
    ScrollPhysics? physics,
    EdgeInsetsGeometry? padding,
    bool shrinkWrap = false,
  }) {
    return ScrollConfiguration(
      behavior: const HighPerformanceScrollBehavior(),
      child: SingleChildScrollView(
        controller: controller,
        physics: physics ?? const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: padding,
        child: RepaintBoundary(child: child), // Optimize repainting for 120Hz
      ),
    );
  }

  /// Creates an optimized ListView for better performance
  static Widget createOptimizedListView({
    required IndexedWidgetBuilder itemBuilder,
    required int itemCount,
    ScrollController? controller,
    EdgeInsetsGeometry? padding,
    ScrollPhysics? physics,
    bool shrinkWrap = false,
    double? itemExtent,
  }) {
    return ScrollConfiguration(
      behavior: const HighPerformanceScrollBehavior(),
      child: ListView.builder(
        controller: controller,
        physics: physics ?? const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: padding,
        shrinkWrap: shrinkWrap,
        itemExtent: itemExtent,
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return RepaintBoundary(
            child: itemBuilder(context, index),
          );
        },
        // Enable high performance scrolling for 120Hz
        cacheExtent: 500.0, // Increased cache for smoother scrolling
        addAutomaticKeepAlives: true,
        addRepaintBoundaries: true,
        addSemanticIndexes: false, // Disable for better performance
      ),
    );
  }

  /// Creates an optimized GridView for better performance
  static Widget createOptimizedGridView({
    required IndexedWidgetBuilder itemBuilder,
    required int itemCount,
    required SliverGridDelegate gridDelegate,
    ScrollController? controller,
    EdgeInsetsGeometry? padding,
    ScrollPhysics? physics,
    bool shrinkWrap = false,
  }) {
    return ScrollConfiguration(
      behavior: const HighPerformanceScrollBehavior(),
      child: GridView.builder(
        controller: controller,
        physics: physics ?? const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: padding,
        shrinkWrap: shrinkWrap,
        gridDelegate: gridDelegate,
        itemCount: itemCount,
        itemBuilder: itemBuilder,
        cacheExtent: 250.0,
      ),
    );
  }

  /// Enables haptic feedback for better user experience
  static void enableHapticFeedback() {
    HapticFeedback.lightImpact();
  }

  /// Heavy haptic feedback for important actions
  static void enableHeavyHapticFeedback() {
    HapticFeedback.heavyImpact();
  }
}

/// Custom scroll behavior optimized for high refresh rate displays
class HighPerformanceScrollBehavior extends ScrollBehavior {
  const HighPerformanceScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    // Use platform-specific scrollbars for better performance
    switch (getPlatform(context)) {
      case TargetPlatform.iOS:
        return CupertinoScrollbar(
          controller: details.controller,
          child: child,
        );
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        return Scrollbar(
          controller: details.controller,
          child: child,
        );
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return Scrollbar(
          controller: details.controller,
          child: child,
        );
    }
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    // Use platform-specific overscroll indicators
    switch (getPlatform(context)) {
      case TargetPlatform.iOS:
        return child; // iOS doesn't typically show overscroll indicators
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        return StretchingOverscrollIndicator(
          axisDirection: details.direction,
          child: child,
        );
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return GlowingOverscrollIndicator(
          axisDirection: details.direction,
          color: Theme.of(context).colorScheme.secondary,
          child: child,
        );
    }
  }
}

/// Widget for optimized animations
class OptimizedAnimatedWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;

  const OptimizedAnimatedWidget({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 200),
    this.curve = Curves.easeOutCubic,
  }) : super(key: key);

  @override
  State<OptimizedAnimatedWidget> createState() => _OptimizedAnimatedWidgetState();
}

class _OptimizedAnimatedWidgetState extends State<OptimizedAnimatedWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(_animation),
        child: widget.child,
      ),
    );
  }
}