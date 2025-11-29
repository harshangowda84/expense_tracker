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
import 'providers/theme_provider.dart';
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DataProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            navigatorKey: NavigationService().navigatorKey,
            title: 'Spendly',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
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
                seedColor: const Color(0xFF667EEA),
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              visualDensity: VisualDensity.adaptivePlatformDensity,
              splashFactory: InkRipple.splashFactory,
              scaffoldBackgroundColor: const Color(0xFFF8F9FD),
              cardTheme: const CardThemeData(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
                color: Colors.white,
              ),
              appBarTheme: const AppBarTheme(
                elevation: 0,
                centerTitle: false,
              ),
              pageTransitionsTheme: const PageTransitionsTheme(
                builders: {
                  TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                  TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                },
              ),
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
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF667EEA),
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              visualDensity: VisualDensity.adaptivePlatformDensity,
              splashFactory: InkRipple.splashFactory,
              scaffoldBackgroundColor: const Color(0xFF121212),
              cardTheme: const CardThemeData(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
                color: Color(0xFF1E1E1E),
              ),
              appBarTheme: const AppBarTheme(
                elevation: 0,
                centerTitle: false,
              ),
              pageTransitionsTheme: const PageTransitionsTheme(
                builders: {
                  TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                  TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                },
              ),
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
            ),
            themeAnimationDuration: const Duration(milliseconds: 300),
            themeAnimationCurve: Curves.easeInOut,
            home: _showSplash 
                ? SplashScreen(onAnimationComplete: _onSplashComplete)
                : const HomeScreen(),
          );
        },
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
  late TabController _tabController;
  
  // Update functionality
  UpdateInfo? _updateInfo;

  static const List<Widget> _tabs = [
    SummaryTab(),
    TransactionsTab(),
    IncomeTab(),
  ];

  static const List<_TabData> _tabData = [
    _TabData(icon: Icons.analytics_outlined, activeIcon: Icons.analytics, label: 'Analytics'),
    _TabData(icon: Icons.receipt_outlined, activeIcon: Icons.receipt, label: 'Expenses'),
    _TabData(icon: Icons.trending_up_outlined, activeIcon: Icons.trending_up, label: 'Income'),
  ];

  @override
  void initState() {
    super.initState();
    
    _tabController = TabController(length: _tabs.length, vsync: this);
    
    // Register tab navigation callback
    NavigationService().setTabSelectionCallback((tabIndex) {
      _tabController.animateTo(tabIndex);
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
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8F9FD),
      drawer: _buildDrawer(context),
      body: Column(
        children: [
          _buildHeader(),
          if (_updateInfo != null)
            UpdateBanner(
              updateInfo: _updateInfo!,
              onDismiss: () => setState(() => _updateInfo = null),
            ),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const BouncingScrollPhysics(),
              children: _tabs,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [
                    const Color(0xFF1E1E1E),
                    const Color(0xFF2D2D2D),
                  ]
                : [
                    const Color(0xFF667EEA),
                    const Color(0xFF764BA2),
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDarkMode
                              ? [const Color(0xFF667EEA), const Color(0xFF764BA2)]
                              : [const Color(0xFF3B82F6), const Color(0xFF8B5CF6)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3B82F6).withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.account_circle,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'User Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'user@spendly.app',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24, height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _buildDrawerItem(
                      icon: Icons.dashboard_rounded,
                      title: 'Dashboard',
                      onTap: () {
                        Navigator.pop(context);
                        _tabController.animateTo(0);
                      },
                    ),
                    const Divider(color: Colors.white24, height: 24),
                    _buildDrawerItem(
                      icon: Icons.account_balance_outlined,
                      title: 'Accounts',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AccountsTab()),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.credit_card_outlined,
                      title: 'Credit Cards',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CreditCardsTab()),
                        );
                      },
                    ),
                    const Divider(color: Colors.white24, height: 24),
                    _buildDrawerItem(
                      icon: Icons.settings_rounded,
                      title: 'Settings',
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.backup_rounded,
                      title: 'Backup & Restore',
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.help_rounded,
                      title: 'Help & Support',
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                    const Divider(color: Colors.white24, height: 32),
                    _buildDrawerItem(
                      icon: Icons.info_rounded,
                      title: 'About',
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Version 1.1.5',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white, size: 24),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      hoverColor: Colors.white.withOpacity(0.1),
    );
  }

  Widget _buildHeader() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [
                  const Color(0xFF1E1E1E),
                  const Color(0xFF2D2D2D),
                ]
              : [
                  const Color(0xFF667EEA),
                  const Color(0xFF764BA2),
                ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Row(
            children: [
              Builder(
                builder: (BuildContext context) {
                  return Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Scaffold.of(context).openDrawer();
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Center(
                          child: Container(
                            width: 20,
                            height: 14,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  height: 2.5,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                Container(
                                  height: 2.5,
                                  width: 16,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                Container(
                                  height: 2.5,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const Expanded(
                child: Center(
                  child: Text(
                    'Spendly',
                    style: TextStyle(
                      fontFamily: 'BagelFatOne',
                      fontSize: 26,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 44),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: 60,
      color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF667EEA).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
        padding: EdgeInsets.zero,
        labelColor: Colors.white,
        unselectedLabelColor: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        tabs: _tabData.map((tab) {
          return Tab(
            height: 44,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(tab.icon, size: 20),
                  const SizedBox(width: 8),
                  Text(tab.label),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TabData {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  
  const _TabData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}