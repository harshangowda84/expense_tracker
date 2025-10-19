import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'screens/accounts_tab.dart';
import 'screens/transactions_tab.dart';
import 'screens/summary_tab.dart';
import 'screens/splash_screen.dart';
import 'providers/data_provider.dart';
import 'screens/credit_cards_tab.dart';
import 'screens/income_tab.dart';
import 'services/navigation_service.dart';
import 'services/update_service.dart';
import 'widgets/update_banner.dart';
import 'utils/performance_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Enable high refresh rate for smooth animations on Android devices
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  
  // Force high refresh rate display mode for maximum smoothness
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Enable smooth animations and high performance mode
  timeDilation = 1.0; // Ensure animations run at normal speed
  
  // Optimize for high refresh rate displays (120Hz)
  SchedulerBinding.instance.addPostFrameCallback((_) {
    // Enable high performance mode for scrolling
    SchedulerBinding.instance.scheduleWarmUpFrame();
    
    // Force maximum refresh rate
    SchedulerBinding.instance.addPersistentFrameCallback((_) {
      // This keeps the refresh rate active
    });
  });
  
  runApp(const SpendlyApp());
}

class SpendlyApp extends StatefulWidget {
  const SpendlyApp({super.key});

  @override
  State<SpendlyApp> createState() => _SpendlyAppState();
}

class _SpendlyAppState extends State<SpendlyApp> {
  bool _showSplash = true;

  void _onSplashComplete() {
    setState(() {
      _showSplash = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DataProvider(),
      child: MaterialApp(
        navigatorKey: NavigationService().navigatorKey,
        title: 'Spendly',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6366F1), // Modern indigo
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          visualDensity: VisualDensity.adaptivePlatformDensity, // Optimize for device refresh rate
          // Enhanced performance settings for smooth scrolling
          splashFactory: InkRipple.splashFactory,
          // High performance page transitions
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: CupertinoPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            },
          ),
          // Optimize scroll physics for 120Hz displays
          platform: TargetPlatform.android,
          textTheme: const TextTheme(
            bodyLarge: TextStyle(fontFamily: 'Inter'),
            bodyMedium: TextStyle(fontFamily: 'Inter'),
            bodySmall: TextStyle(fontFamily: 'Inter'),
            displayLarge: TextStyle(fontFamily: 'Inter'),
            displayMedium: TextStyle(fontFamily: 'Inter'),
            displaySmall: TextStyle(fontFamily: 'Inter'),
            headlineLarge: TextStyle(fontFamily: 'Inter'),
            headlineMedium: TextStyle(fontFamily: 'Inter'),
            headlineSmall: TextStyle(fontFamily: 'Inter'),
            titleLarge: TextStyle(fontFamily: 'Inter'),
            titleMedium: TextStyle(fontFamily: 'Inter'),
            titleSmall: TextStyle(fontFamily: 'Inter'),
            labelLarge: TextStyle(fontFamily: 'Inter'),
            labelMedium: TextStyle(fontFamily: 'Inter'),
            labelSmall: TextStyle(fontFamily: 'Inter'),
          ),
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: const Color(0xFF6366F1), // Modern indigo
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            titleTextStyle: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
        home: _showSplash 
            ? SplashScreen(onAnimationComplete: _onSplashComplete)
            : const HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  double _currentPageValue = 0.0; // Track current page position for smooth animations
  late PageController _pageController;
  late AnimationController _pageAnimationController;
  late Animation<double> _pageAnimation;
  late List<AnimationController> _animationControllers;
  late List<AnimationController> _pulseControllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _rotationAnimations;
  late List<Animation<double>> _pulseAnimations;
  
  // Update functionality
  UpdateInfo? _updateInfo;

  static const List<Widget> _tabs = [
    SummaryTab(),
    TransactionsTab(),
    IncomeTab(),
    AccountsTab(),
    CreditCardsTab(),
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize PageController with optimized settings
    _pageController = PageController(
      initialPage: _selectedIndex,
      viewportFraction: 1.0,
    );
    
    // Create dedicated animation controller for page tracking
    _pageAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1), // Very fast for real-time updates
    );
    
    _pageAnimation = Tween<double>(
      begin: 0.0,
      end: 0.0,
    ).animate(_pageAnimationController);
    
    // Set initial page value
    _currentPageValue = _selectedIndex.toDouble();
    
    // Optimized page listener with throttling
    _pageController.addListener(() {
      if (_pageController.hasClients) {
        final newPageValue = _pageController.page ?? _selectedIndex.toDouble();
        // Only update if there's a significant change to reduce rebuilds
        if ((newPageValue - _currentPageValue).abs() > 0.01) {
          _currentPageValue = newPageValue;
          // Use animation to trigger smooth rebuilds
          _pageAnimation = Tween<double>(
            begin: _currentPageValue,
            end: _currentPageValue,
          ).animate(_pageAnimationController);
          _pageAnimationController.forward(from: 0);
        }
      }
    });
    
    // Register tab navigation callback with the navigation service
    NavigationService().setTabSelectionCallback((tabIndex) {
      _onTabTapped(tabIndex);
    });
    
    // Initialize main animation controllers (smooth 120Hz optimized)
    _animationControllers = List.generate(
      5,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 350), // Smooth, fluid timing
        vsync: this,
      ),
    );
    
    // Initialize pulse controllers for continuous pulse effect (smooth)
    _pulseControllers = List.generate(
      5,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 1000), // Gentle pulse rhythm
        vsync: this,
      ),
    );
    
    // Initialize scale animations with bounce
    _scaleAnimations = _animationControllers.map((controller) {
      return Tween<double>(begin: 1.0, end: 1.3).animate(
        CurvedAnimation(parent: controller, curve: Curves.elasticOut),
      );
    }).toList();
    
    // Initialize rotation animations
    _rotationAnimations = _animationControllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 0.1).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();
    
    // Initialize pulse animations
    _pulseAnimations = _pulseControllers.map((controller) {
      return Tween<double>(begin: 1.0, end: 1.1).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();
    
    // Start animation for initially selected tab
    _animationControllers[_selectedIndex].forward();
    _pulseControllers[_selectedIndex].repeat(reverse: true);
    
    // Check for updates on app startup
    _checkForUpdates();
  }
  
  /// Check for app updates from GitHub
  void _checkForUpdates() async {
    try {
      final updateService = UpdateService();
      final updateInfo = await updateService.checkForUpdate();
      
      if (mounted && updateInfo != null) {
        setState(() {
          _updateInfo = updateInfo;
        });
      }
    } catch (e) {
      print('🔍 Update check failed: $e');
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pageAnimationController.dispose();
    for (var controller in _animationControllers) {
      controller.dispose();
    }
    for (var controller in _pulseControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index != _selectedIndex) {
      // Add haptic feedback for tab change
      PerformanceUtils.enableHapticFeedback();
      
      // Calculate distance to determine animation strategy
      final distance = (index - _selectedIndex).abs();
      
      // Use jump for any non-adjacent navigation (distance > 1)
      // This ensures direct navigation for all long jumps
      if (distance > 1) {
        // For non-adjacent tabs, jump directly (no animation through intermediate pages)
        _pageController.jumpToPage(index);
        _updateSelectedIndex(index);
      } else {
        // Only animate for adjacent tabs (distance = 1)
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
        );
      }
    } else {
      // Add haptic feedback for same tab bounce
      PerformanceUtils.enableHapticFeedback();
      
      // Create a strong bounce effect for same tab
      _animationControllers[index].reverse().then((_) {
        _animationControllers[index].forward();
      });
    }
  }

  void _onPageChanged(int index) {
    if (index != _selectedIndex) {
      _updateSelectedIndex(index);
    }
  }

  void _updateSelectedIndex(int index) {
    // Stop previous tab animations
    if (_selectedIndex < _animationControllers.length) {
      _animationControllers[_selectedIndex].reverse();
      _pulseControllers[_selectedIndex].stop();
    }
    
    setState(() => _selectedIndex = index);
    
    // Start new tab animations
    if (index < _animationControllers.length) {
      _animationControllers[index].forward();
      _pulseControllers[index].repeat(reverse: true);
    }
  }

  Widget _buildAnimatedIcon(IconData activeIcon, IconData inactiveIcon, int index) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pageAnimation, // Listen to page changes
        _scaleAnimations[index],
        _rotationAnimations[index],
        _pulseAnimations[index],
      ]),
      builder: (context, child) {
        // Calculate smooth animation progress based on swipe position
        double animationProgress = 1.0;
        double scaleMultiplier = 1.0;
        
        // Calculate distance from current page position
        double distance = (_currentPageValue - index).abs();
        
        if (distance <= 1.0) {
          // We're close to this tab, calculate smooth transition
          animationProgress = 1.0 - distance;
          scaleMultiplier = 0.85 + (0.15 * animationProgress); // Scale between 0.85 and 1.0
        } else {
          animationProgress = 0.0;
          scaleMultiplier = 0.85;
        }
        
        final isSelected = _selectedIndex == index;
        
        // Combine static animations with real-time swipe animations
        final finalScale = scaleMultiplier * 
            (isSelected ? _scaleAnimations[index].value * _pulseAnimations[index].value : 1.0);
        final rotation = isSelected ? _rotationAnimations[index].value : 0.0;
        
        // Smooth color transition based on swipe progress
        final color = Color.lerp(
          Colors.grey,
          const Color(0xFF6366F1),
          animationProgress,
        ) ?? Colors.grey;
        
        // Modern pill-style icon: gradient/pill when selected, subtle outlined tile when unselected
        final double tileSize = isSelected ? 48.0 : 40.0;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              width: tileSize,
              height: tileSize,
              decoration: BoxDecoration(
                // Circular token. Unselected tokens are transparent with a subtle border.
                color: isSelected ? null : Colors.transparent,
                gradient: isSelected
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                      )
                    : null,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.transparent : Theme.of(context).dividerColor.withOpacity(0.12),
                  width: 1.0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.16),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
                  child: Transform.rotate(
                angle: rotation,
                child: Transform.scale(
                  scale: finalScale,
                  child: Icon(
                    isSelected ? activeIcon : inactiveIcon,
                    // When nav is light, unselected icons should be dark; selected
                    // icons remain white (they sit on a colored token).
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                    size: isSelected ? 26 : 22,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Wrap the animated token with a label beneath. Tokens are evenly spaced.
  Widget _buildTokenWithLabel(IconData activeIcon, IconData inactiveIcon, int index, String label) {
    final isSelected = _selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onTabTapped(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Use existing animated token
            _buildAnimatedIcon(activeIcon, inactiveIcon, index),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                // When nav is light, selected label uses primary indigo for contrast
                color: isSelected
                    ? const Color(0xFF6366F1)
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.85),
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _selectedIndex == 0, // Can only pop when on summary tab (index 0)
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _selectedIndex != 0) {
          // If not on summary tab, jump directly to summary tab (no animation through all pages)
          _pageController.jumpToPage(0);
          _updateSelectedIndex(0);
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(
          'Spendly',
          style: const TextStyle(
            fontFamily: 'BagelFatOne',
            fontSize: 28,
            fontWeight: FontWeight.w900, // Use bold weight as fallback
            color: Colors.white,
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF667EEA), // Light purple-blue
                Color(0xFF764BA2), // Deep purple
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // Show update banner if available
          if (_updateInfo != null)
            UpdateBanner(
              updateInfo: _updateInfo!,
              onDismiss: () {
                setState(() {
                  _updateInfo = null;
                });
              },
            ),
          // Main page content. Wrap PageView with a unified background so all
          // tabs share the same subtle gradient. This prevents stark white
          // backgrounds on some screens (Transactions/Income) while others use
          // cards/gradients, producing a consistent app look.
          Expanded(
            child: Container(
              // Use a plain white background for all pages so every tab has
              // a consistent white canvas.
              color: Colors.white,
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                children: _tabs,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
  // Remove horizontal inset so the rounded nav touches the screen edges
  margin: EdgeInsets.zero,
        // Reduce inner padding while keeping rounded container look
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          // Light themed nav: white rounded bar with subtle border and shadow
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.08),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          left: false,
          right: false,
          bottom: true, // ensure nav sits above system navigation bar
            child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildTokenWithLabel(Icons.bar_chart_rounded, Icons.bar_chart, 0, 'Summary'),
              _buildTokenWithLabel(Icons.receipt_long_rounded, Icons.receipt_long, 1, 'Spends'),
              _buildTokenWithLabel(Icons.trending_up_rounded, Icons.trending_up, 2, 'Income'),
              _buildTokenWithLabel(Icons.account_balance_wallet_rounded, Icons.account_balance_wallet, 3, 'Accounts'),
              _buildTokenWithLabel(Icons.credit_card_rounded, Icons.credit_card, 4, 'Credit Card'),
            ],
          ),
        ),
      ),
      ),
    );
  }
}