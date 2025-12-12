import 'package:flutter/material.dart';

class SuccessDialog {
  /// Shows a success dialog that automatically closes after the specified duration
  static void show(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(milliseconds: 1500),
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _FadeOutDialog(
        message: message,
        duration: duration,
      ),
    );
  }
}

class _FadeOutDialog extends StatefulWidget {
  final String message;
  final Duration duration;

  const _FadeOutDialog({
    required this.message,
    required this.duration,
  });

  @override
  State<_FadeOutDialog> createState() => _FadeOutDialogState();
}

class _FadeOutDialogState extends State<_FadeOutDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(widget.duration - const Duration(milliseconds: 300), () {
      if (mounted) {
        _controller.forward().then((_) {
          if (mounted) Navigator.pop(context);
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF10B981).withOpacity(0.1),
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_circle,
                    size: 50,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.message,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
