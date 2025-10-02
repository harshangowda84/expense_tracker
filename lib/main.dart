import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/accounts_tab.dart';
import 'screens/transactions_tab.dart';
import 'screens/summary_tab.dart';
import 'providers/data_provider.dart';
import 'screens/credit_cards_tab.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Enable high refresh rate for smooth animations on Android devices
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  
  runApp(const SpendlyApp());
}

class SpendlyApp extends StatelessWidget {
  const SpendlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DataProvider(),
      child: MaterialApp(
        title: 'Spendly',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6366F1), // Modern indigo
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          visualDensity: VisualDensity.adaptivePlatformDensity, // Optimize for device refresh rate
          textTheme: GoogleFonts.interTextTheme(),
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
            titleTextStyle: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
        home: const HomeScreen(),
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
    AccountsTab(),
    CreditCardsTab(),
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize main animation controllers
    _animationControllers = List.generate(
      4,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 400),
        vsync: this,
      ),
    );
    
    // Initialize pulse controllers for continuous pulse effect
    _pulseControllers = List.generate(
      4,
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
      // Stop previous tab animations
      _animationControllers[_selectedIndex].reverse();
      _pulseControllers[_selectedIndex].stop();
      
      setState(() => _selectedIndex = index);
      
      // Start new tab animations
      _animationControllers[index].forward();
      _pulseControllers[index].repeat(reverse: true);
    } else {
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
    return Scaffold(
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Colors.white,
              Color(0xFFF8FAFC),
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            'Spendly',
            style: GoogleFonts.montserrat(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black38,
                  offset: const Offset(0, 3),
                  blurRadius: 6,
                ),
                Shadow(
                  color: Colors.white24,
                  offset: const Offset(0, -1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF6366F1),
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
        child: _tabs[_selectedIndex],
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
              icon: _buildAnimatedIcon(Icons.account_balance_wallet, 2), 
              label: 'Accounts'
            ),
            BottomNavigationBarItem(
              icon: _buildAnimatedIcon(Icons.credit_card, 3), 
              label: 'Credit Card'
            ),
          ],
          selectedItemColor: const Color(0xFF6366F1), // Modern indigo
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}