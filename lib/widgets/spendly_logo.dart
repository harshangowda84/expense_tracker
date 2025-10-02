import 'package:flutter/material.dart';

class SpendlyLogo extends StatelessWidget {
  final double size;
  final Color? color;
  final bool showText;

  const SpendlyLogo({
    Key? key,
    this.size = 120,
    this.color,
    this.showText = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logoColor = color ?? Colors.white;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo Icon
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                logoColor.withOpacity(0.9),
                logoColor.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: logoColor.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Dollar sign background
                Icon(
                  Icons.attach_money,
                  size: size * 0.5,
                  color: Colors.white.withOpacity(0.2),
                ),
                // Main "S" letter
                Text(
                  'S',
                  style: TextStyle(fontFamily: 'Montserrat', 
                    fontSize: size * 0.4,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.2),
                        offset: const Offset(2, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // App name (optional)
        if (showText) ...[
          const SizedBox(height: 16),
          Text(
            'Spendly',
            style: TextStyle(fontFamily: 'Montserrat', 
              fontSize: size * 0.25,
              fontWeight: FontWeight.w700,
              color: logoColor,
              letterSpacing: 1.2,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.3),
                  offset: const Offset(1, 1),
                  blurRadius: 3,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// Animated version for splash screen
class AnimatedSpendlyLogo extends StatefulWidget {
  final double size;
  final Color? color;
  final bool showText;
  final VoidCallback? onAnimationComplete;

  const AnimatedSpendlyLogo({
    Key? key,
    this.size = 120,
    this.color,
    this.showText = true,
    this.onAnimationComplete,
  }) : super(key: key);

  @override
  State<AnimatedSpendlyLogo> createState() => _AnimatedSpendlyLogoState();
}

class _AnimatedSpendlyLogoState extends State<AnimatedSpendlyLogo>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rotateController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotateController,
      curve: Curves.easeInOut,
    ));

    _startAnimation();
  }

  void _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _scaleController.forward();
    _rotateController.forward();
    
    await Future.delayed(const Duration(milliseconds: 2000));
    widget.onAnimationComplete?.call();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleController, _rotateController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotateAnimation.value * 0.1, // Subtle rotation
            child: SpendlyLogo(
              size: widget.size,
              color: widget.color,
              showText: widget.showText,
            ),
          ),
        );
      },
    );
  }
}
