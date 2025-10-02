import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';

class AppIconGenerator {
  static Future<Uint8List> generateIcon({
    double size = 512,
    Color backgroundColor = const Color(0xFF1976D2),
    Color textColor = Colors.white,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint();

    // Background circle with gradient
    paint.shader = ui.Gradient.radial(
      Offset(size / 2, size / 2),
      size / 2,
      [
        backgroundColor,
        backgroundColor.withOpacity(0.8),
      ],
    );
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, paint);

    // Draw shadow for depth
    paint.shader = null;
    paint.color = Colors.black.withOpacity(0.2);
    canvas.drawCircle(Offset(size / 2 + 8, size / 2 + 8), size / 2 - 16, paint);

    // Draw main circle
    paint.color = backgroundColor;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 16, paint);

    // Draw dollar sign background (subtle)
    paint.color = textColor.withOpacity(0.1);
    final dollarPath = Path();
    dollarPath.moveTo(size * 0.35, size * 0.25);
    dollarPath.lineTo(size * 0.65, size * 0.25);
    dollarPath.lineTo(size * 0.65, size * 0.75);
    dollarPath.lineTo(size * 0.35, size * 0.75);
    dollarPath.close();
    canvas.drawPath(dollarPath, paint);

    // Draw "S" letter
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'S',
        style: TextStyle(
          fontSize: size * 0.4,
          fontWeight: FontWeight.w700,
          color: textColor,
          fontFamily: 'Roboto', // Fallback to system font for icon generation
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.3),
              offset: Offset(size * 0.01, size * 0.01),
              blurRadius: size * 0.02,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size - textPainter.width) / 2,
        (size - textPainter.height) / 2,
      ),
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}

// Widget to preview the icon
class IconPreview extends StatelessWidget {
  final double size;
  
  const IconPreview({Key? key, this.size = 100}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [
            Color(0xFF1976D2),
            Color(0xFF1565C0),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
              size: size * 0.4,
              color: Colors.white.withOpacity(0.1),
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
                    color: Colors.black.withOpacity(0.3),
                    offset: const Offset(2, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
