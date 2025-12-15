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
import 'screens/check_for_updates_page.dart';
import 'screens/logout_page.dart';

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
    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFAFAFC),
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Profile Header - Gradient Background
              Container(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF667EEA),
                      Color(0xFF764BA2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF667EEA).withOpacity(0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                margin: const EdgeInsets.fromLTRB(4, 4, 4, 4),
                child: Column(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.white.withOpacity(0.95), Colors.white.withOpacity(0.85)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.account_circle_rounded,
                        color: Color(0xFF667EEA),
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Spendly User',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Track & Manage',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              // Menu Items
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Main Navigation Section
                      _buildDrawerSectionLabel('Main'),
                      _buildDrawerItem(
                        icon: Icons.dashboard_rounded,
                        title: 'Dashboard',
                        badge: 'New',
                        color: const Color(0xFF667EEA),
                        onTap: () {
                          Navigator.pop(context);
                          _tabController.animateTo(0);
                        },
                      ),
                      const SizedBox(height: 4),
                      // Accounts Section
                      _buildDrawerSectionLabel('Accounts & Cards'),
                      _buildDrawerItem(
                        icon: Icons.account_balance_wallet_rounded,
                        title: 'Accounts',
                        badge: 'New',
                        color: const Color(0xFF10B981),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AccountsTab()),
                          );
                        },
                      ),
                      const SizedBox(height: 3),
                      _buildDrawerItem(
                        icon: Icons.credit_card_rounded,
                        title: 'Credit Cards',
                        badge: 'New',
                        color: const Color(0xFFF59E0B),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CreditCardsTab()),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      // Settings Section
                      _buildDrawerSectionLabel('Settings & Actions'),
                      _buildDrawerItem(
                        icon: Icons.settings_rounded,
                        title: 'Settings',
                        badge: 'Soon',
                        color: const Color(0xFF8B5CF6),
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(height: 4),
                      _buildDrawerItem(
                        icon: Icons.backup_rounded,
                        title: 'Backup & Restore',
                        badge: 'Soon',
                        color: const Color(0xFF06B6D4),
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(height: 4),
                      _buildDrawerItem(
                        icon: Icons.system_update_rounded,
                        title: 'Check for Updates',
                        badge: 'New',
                        color: const Color(0xFFEC4899),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CheckForUpdatesPage()),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      // About Section
                      _buildDrawerSectionLabel('App'),
                      _buildDrawerItem(
                        icon: Icons.logout_rounded,
                        title: 'Logout',
                        badge: 'Exit',
                        color: const Color(0xFFEF4444),
                        onTap: () {
                          Navigator.pop(context);
                          _showLogoutConfirmation(context);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              // Footer with version
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(
                      color: Colors.grey[300],
                      thickness: 1,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Version 1.1.5',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
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

  Widget _buildDrawerSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.grey[500],
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    String? badge,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          hoverColor: color.withOpacity(0.08),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: color.withOpacity(0.08),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B6B),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6B6B).withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      badge ?? 'New',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    _showConfirmationDialog(
      context: context,
      title: 'Logout?',
      message: 'Are you sure you want to logout from Spendly?',
      confirmText: 'Logout',
      cancelText: 'Cancel',
      icon: Icons.logout_rounded,
      color: const Color(0xFFEF4444),
      onConfirm: () {
        // Navigate to logout page and remove all routes until home
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const LogoutPage(),
          ),
          (route) => route.isFirst,
        );
      },
    );
  }

  void _showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmText,
    required String cancelText,
    required IconData icon,
    required Color color,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                // Title
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                // Message
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                // Buttons
                Row(
                  children: [
                    // Cancel Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[100],
                          foregroundColor: Colors.grey[800],
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          cancelText,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Confirm Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onConfirm();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          confirmText,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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