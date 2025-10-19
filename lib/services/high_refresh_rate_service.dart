import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';

class HighRefreshRateService {
  static const platform = MethodChannel('com.spendly.app/refresh_rate');
  static bool _isEnabled = false;
  static Map<String, dynamic>? _displayInfo;

  /// Initialize high refresh rate service
  static Future<void> initialize() async {
    try {
      // Get display information
      _displayInfo = await platform.invokeMethod('getDisplayInfo');
      print('Display Info: $_displayInfo');
      
      // Try to enable high refresh rate via platform channel
      final success = await platform.invokeMethod('enableHighRefreshRate');
      _isEnabled = success == true;
      
      if (_isEnabled) {
        print('High refresh rate enabled successfully');
        // Keep frame rate active with persistent callback
        SchedulerBinding.instance.addPersistentFrameCallback(_frameCallback);
      } else {
        print('High refresh rate not available or failed to enable');
      }
      
    } catch (e) {
      print('High refresh rate service initialization failed: $e');
    }
  }

  /// Get display information
  static Map<String, dynamic>? get displayInfo => _displayInfo;

  /// Get current refresh rate
  static double? get currentRefreshRate {
    return _displayInfo?['currentRefreshRate']?.toDouble();
  }

  /// Check if device supports high refresh rate
  static bool get supportsHighRefreshRate {
    final modes = _displayInfo?['supportedModes'] as List?;
    if (modes != null) {
      return modes.any((mode) => ((mode['refreshRate'] as double?) ?? 0) > 60);
    }
    return false;
  }

  /// Frame callback to maintain high refresh rate
  static void _frameCallback(Duration timestamp) {
    // This keeps the refresh rate active by continuously requesting frames
    // Only when needed to avoid battery drain
    if (_isEnabled) {
      SchedulerBinding.instance.scheduleFrame();
    }
  }

  /// Enable high refresh rate manually
  static Future<void> enableHighRefreshRate() async {
    if (!_isEnabled) {
      await initialize();
    }
  }

  /// Disable high refresh rate to save battery
  static void disableHighRefreshRate() {
    _isEnabled = false;
  }

  /// Check if high refresh rate is currently enabled
  static bool get isEnabled => _isEnabled;

  /// Force refresh rate update
  static void forceRefreshRateUpdate() {
    if (_isEnabled) {
      SchedulerBinding.instance.scheduleFrame();
      SchedulerBinding.instance.scheduleWarmUpFrame();
    }
  }
}

/// Widget to wrap scrollable content with high refresh rate optimization
class HighRefreshRateWrapper extends StatefulWidget {
  final Widget child;
  final bool enableOnScroll;

  const HighRefreshRateWrapper({
    Key? key,
    required this.child,
    this.enableOnScroll = true,
  }) : super(key: key);

  @override
  State<HighRefreshRateWrapper> createState() => _HighRefreshRateWrapperState();
}

class _HighRefreshRateWrapperState extends State<HighRefreshRateWrapper> {
  @override
  void initState() {
    super.initState();
    if (widget.enableOnScroll) {
      HighRefreshRateService.enableHighRefreshRate();
    }
  }

  @override
  void dispose() {
    if (widget.enableOnScroll) {
      HighRefreshRateService.disableHighRefreshRate();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (widget.enableOnScroll) {
          // Force high refresh rate during scrolling
          HighRefreshRateService.forceRefreshRateUpdate();
        }
        return false;
      },
      child: widget.child,
    );
  }
}