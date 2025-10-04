import 'package:flutter/material.dart';

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  // Global key for navigator
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  // Callback for tab navigation
  Function(int)? _onTabSelected;
  
  // Register the tab selection callback from HomeScreen
  void setTabSelectionCallback(Function(int) callback) {
    _onTabSelected = callback;
  }
  
  // Navigate to a specific tab
  void navigateToTab(int tabIndex) {
    if (_onTabSelected != null) {
      _onTabSelected!(tabIndex);
    }
  }
  
  // Get current context
  BuildContext? get context => navigatorKey.currentContext;
}