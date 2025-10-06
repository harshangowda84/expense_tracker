import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onAnimationComplete;

  const SplashScreen({Key? key, required this.onAnimationComplete}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeInController;
  late AnimationController _rippleController;
  late AnimationController _moveController;
  late AnimationController _zoomController; // New controller for clean zoom effect
  
  late Animation<double> _fadeInAnimation;
  late Animation<double> _rippleAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rippleOpacity;
  late Animation<double> _zoomAnimation; // New animation for zoom effect
  
  bool _showMainContent = false;
  bool _startRipple = false;

  @override
  void initState() {
    super.initState();
    
    // Fade in animation controller for Spendly text
    _fadeInController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Zoom animation controller for clean zoom effect
    _zoomController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    // Ripple animation controller for water effect
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    // Move to AppBar position animation controller
    _moveController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    // Fade in animation for Spendly text
    _fadeInAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeInController,
      curve: Curves.easeInOut,
    ));
    
    // Clean zoom animation - just a subtle scale effect
    _zoomAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1, // Subtle 10% zoom
    ).animate(CurvedAnimation(
      parent: _zoomController,
      curve: Curves.easeInOut,
    ));
    
    // Ripple animation for water spreading effect
    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOutQuart,
    ));
    
    // Ripple opacity animation
    _rippleOpacity = Tween<double>(
      begin: 0.8,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOut,
    ));
    
    // Scale animation for smooth size transition
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.42, // Scale down more to match AppBar text size exactly
    ).animate(CurvedAnimation(
      parent: _moveController,
      curve: Curves.easeInOutCubic,
    ));
    
    _startAnimationSequence();
  }
  
  void _startAnimationSequence() async {
    // Start fade in animation for Spendly text
    await _fadeInController.forward();
    
    // Brief pause, then start zoom effect
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Zoom in effect
    await _zoomController.forward();
    
    // Hold zoom for a moment
    await Future.delayed(const Duration(milliseconds: 150));
    
    // Zoom back to normal
    await _zoomController.reverse();
    
    // Brief pause before movement
    await Future.delayed(const Duration(milliseconds: 50));
    
    // Start the ripple effect
    setState(() {
      _startRipple = true;
      _showMainContent = true;
    });
    
    // Start ripple animation
    _rippleController.forward();
    // Start move animation slightly after ripple starts
    await Future.delayed(const Duration(milliseconds: 100));
    _moveController.forward();
    // Wait for move animation to complete
    await Future.delayed(const Duration(milliseconds: 600));
    // Complete the splash screen
    widget.onAnimationComplete();
  }

  @override
  void dispose() {
    _fadeInController.dispose();
    _rippleController.dispose();
    _moveController.dispose();
    _zoomController.dispose(); // Dispose the zoom controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final centerX = screenSize.width / 2;
    final centerY = screenSize.height / 2;
    final maxRadius = screenSize.height * 1.2; // Ensure full screen coverage
    
    return Scaffold(
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF667EEA), // Light purple-blue
                  Color(0xFF764BA2), // Deep purple
                ],
              ),
            ),
          ),
          
          // Main app content (appears during transition)
          if (_showMainContent)
            Container(
              color: Colors.white,
              child: const SizedBox.expand(),
            ),
          
          // Spendly text with clean zoom and movement animation
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_fadeInController, _moveController, _zoomController]),
              builder: (context, child) {
                // Calculate position during animation
                final progress = _moveController.value;
                final screenHeight = MediaQuery.of(context).size.height;
                final statusBarHeight = MediaQuery.of(context).padding.top;
                final appBarHeight = kToolbarHeight;
                
                // Calculate the target Y position (AppBar center)
                final targetY = statusBarHeight + (appBarHeight / 2);
                final startY = screenHeight / 2;
                
                // Interpolate between start and target positions
                final currentY = startY + ((targetY - startY) * progress);
                
                // Convert to offset from center
                final offsetFromCenter = currentY - startY;
                
                // Combine zoom effect with scale animation
                final combinedScale = _scaleAnimation.value * _zoomAnimation.value;
                
                return Transform.translate(
                  offset: Offset(0, offsetFromCenter),
                  child: Transform.scale(
                    scale: combinedScale,
                    child: AnimatedBuilder(
                      animation: _fadeInController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _fadeInAnimation.value,
                          child: Text(
                            'Spendly',
                            style: const TextStyle(
                              fontFamily: 'BagelFatOne',
                              fontSize: 56,
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.2,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  offset: Offset(3, 3),
                                  blurRadius: 8,
                                ),
                                Shadow(
                                  color: Colors.white12,
                                  offset: Offset(-2, -2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Water ripple effect
          if (_startRipple)
            AnimatedBuilder(
              animation: _rippleController,
              builder: (context, child) {
                return CustomPaint(
                  painter: RipplePainter(
                    animationValue: _rippleAnimation.value,
                    center: Offset(centerX, centerY),
                    maxRadius: maxRadius,
                    opacity: _rippleOpacity.value,
                  ),
                  size: Size.infinite,
                );
              },
            ),
        ],
      ),
    );
  }
}

// Custom painter for water ripple effect
class RipplePainter extends CustomPainter {
  final double animationValue;
  final Offset center;
  final double maxRadius;
  final double opacity;

  RipplePainter({
    required this.animationValue,
    required this.center,
    required this.maxRadius,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (animationValue == 0) return;

    final paint = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    // Create multiple ripple circles for more realistic effect
    final rippleRadius = maxRadius * animationValue;
    
    // Main ripple circle
    canvas.drawCircle(center, rippleRadius, paint);
    
    // Additional ripples for more depth
    if (animationValue > 0.3) {
      final secondRipple = Paint()
        ..color = Colors.white.withOpacity(opacity * 0.7)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, rippleRadius * 0.8, secondRipple);
    }
    
    if (animationValue > 0.6) {
      final thirdRipple = Paint()
        ..color = Colors.white.withOpacity(opacity * 0.4)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, rippleRadius * 0.6, thirdRipple);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is RipplePainter &&
        (oldDelegate.animationValue != animationValue ||
         oldDelegate.opacity != opacity);
  }
}