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
  late List<AnimationController> _animationControllers;
  late List<AnimationController> _pulseControllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _rotationAnimations;
  late List<Animation<double>> _pulseAnimations;

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
    
    // Register tab navigation callback with the navigation service
    NavigationService().setTabSelectionCallback((tabIndex) {
      _onTabTapped(tabIndex);
    });
    
    // Initialize main animation controllers
    _animationControllers = List.generate(
      5,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 400),
        vsync: this,
      ),
    );
    
    // Initialize pulse controllers for continuous pulse effect
    _pulseControllers = List.generate(
      5,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 1200),
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
  }

  @override
  void dispose() {
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
      
      // Stop previous tab animations
      _animationControllers[_selectedIndex].reverse();
      _pulseControllers[_selectedIndex].stop();
      
      setState(() => _selectedIndex = index);
      
      // Start new tab animations
      _animationControllers[index].forward();
      _pulseControllers[index].repeat(reverse: true);
    } else {
      // Add haptic feedback for same tab bounce
      PerformanceUtils.enableHapticFeedback();
      
      // Create a strong bounce effect for same tab
      _animationControllers[index].reverse().then((_) {
        _animationControllers[index].forward();
      });
    }
  }

  Widget _buildAnimatedIcon(IconData iconData, int index) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _scaleAnimations[index],
        _rotationAnimations[index],
        _pulseAnimations[index],
      ]),
      builder: (context, child) {
        final isSelected = _selectedIndex == index;
        final scale = isSelected 
            ? _scaleAnimations[index].value * _pulseAnimations[index].value
            : 1.0;
        final rotation = isSelected ? _rotationAnimations[index].value : 0.0;
        
        return Container(
          decoration: isSelected ? BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ) : null,
          child: Transform.rotate(
            angle: rotation,
            child: Transform.scale(
              scale: scale,
              child: Icon(
                iconData,
                color: isSelected 
                    ? const Color(0xFF6366F1) 
                    : Colors.grey,
                size: 24,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _selectedIndex == 0, // Can only pop when on summary tab (index 0)
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _selectedIndex != 0) {
          // If not on summary tab, navigate to summary tab first
          _onTabTapped(0);
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
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.3, 0),
              end: Offset.zero,
            ).animate(animation),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        child: OptimizedAnimatedWidget(
          key: ValueKey(_selectedIndex),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          child: _tabs[_selectedIndex],
        ),
      ),
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onTabTapped,
          items: [
            BottomNavigationBarItem(
              icon: _buildAnimatedIcon(Icons.bar_chart, 0), 
              label: 'Summary'
            ),
            BottomNavigationBarItem(
              icon: _buildAnimatedIcon(Icons.list_alt, 1), 
              label: 'Transactions'
            ),
            BottomNavigationBarItem(
              icon: _buildAnimatedIcon(Icons.trending_up, 2), 
              label: 'Income'
            ),
            BottomNavigationBarItem(
              icon: _buildAnimatedIcon(Icons.account_balance_wallet, 3), 
              label: 'Accounts'
            ),
            BottomNavigationBarItem(
              icon: _buildAnimatedIcon(Icons.credit_card, 4), 
              label: 'Credit Card'
            ),
          ],
          selectedItemColor: const Color(0xFF6366F1), // Modern indigo
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
        ),
      ),
    );
  }
}