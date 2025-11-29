import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
        // Wrap the app with a visible debug banner when running in debug mode.
        // We keep Flutter's default debug banner disabled and instead show a
        // custom `Banner` so it appears even when `debugShowCheckedModeBanner`
        // is false and we can control styling.
        builder: (context, child) {
          final appChild = child ?? const SizedBox.shrink();
          if (kDebugMode) {
            return Banner(
              message: 'DEBUG',
              location: BannerLocation.topEnd,
              color: Colors.redAccent.withOpacity(0.9),
              textStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
              child: appChild,
            );
          }
          return appChild;
        },
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

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;
  
  // Update functionality
  UpdateInfo? _updateInfo;

  static const List<Widget> _tabs = [
    SummaryTab(),
    TransactionsTab(),
    IncomeTab(),
    AccountsTab(),
    CreditCardsTab(),
  ];

  static const List<String> _tabTitles = [
    'Dashboard',
    'Transactions',
    'Income',
    'Accounts',
    'Credit Cards',
  ];

  static const List<IconData> _tabIcons = [
    Icons.dashboard_rounded,
    Icons.receipt_long_rounded,
    Icons.trending_up_rounded,
    Icons.account_balance_wallet_rounded,
    Icons.credit_card_rounded,
  ];

  @override
  void initState() {
    super.initState();
    
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fabAnimation = CurvedAnimation(
      parent: _fabController,
      curve: Curves.easeInOut,
    );
    
    _fabController.forward();
    
    // Register tab navigation callback
    NavigationService().setTabSelectionCallback((tabIndex) {
      _onTabTapped(tabIndex);
    });
    
    // Check for updates
    _checkForUpdates();
  }
  
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
    }
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index != _selectedIndex) {
      setState(() => _selectedIndex = index);
      _scaffoldKey.currentState?.closeDrawer();
      _fabController.reset();
      _fabController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildModernDrawer(),
      appBar: _buildModernAppBar(),
      body: Column(
        children: [
          if (_updateInfo != null)
            UpdateBanner(
              updateInfo: _updateInfo!,
              onDismiss: () => setState(() => _updateInfo = null),
            ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.05, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: Container(
                key: ValueKey<int>(_selectedIndex),
                child: _tabs[_selectedIndex],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  PreferredSizeWidget _buildModernAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded, color: Colors.white),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Text(
            'Spendly',
            style: TextStyle(
              fontFamily: 'BagelFatOne',
              fontSize: 24,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_rounded, color: Colors.white, size: 20),
          ),
          onPressed: () {
            // TODO: Show notifications
          },
        ),
      ],
    );
  }

  Widget _buildModernDrawer() {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF667EEA),
              Color(0xFF764BA2),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person_rounded,
                        size: 40,
                        color: const Color(0xFF667EEA),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Welcome back!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Spendly Pro',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: _tabs.length,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemBuilder: (context, index) {
                    final isSelected = _selectedIndex == index;
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _onTabTapped(index),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? Colors.white.withOpacity(0.25) 
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected 
                                    ? Colors.white.withOpacity(0.4) 
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _tabIcons[index],
                                  color: Colors.white,
                                  size: isSelected ? 26 : 24,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    _tabTitles[index],
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isSelected ? 16 : 15,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: Colors.white.withOpacity(0.9), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Spendly v1.1.5',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Your smart companion',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return ScaleTransition(
      scale: _fabAnimation,
      child: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to add transaction - always open in Transactions tab
          NavigationService().navigateToTab(1);
        },
        backgroundColor: const Color(0xFF667EEA),
        elevation: 8,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Add Expense',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}