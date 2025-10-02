import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:io';

void main() => runApp(IconGeneratorApp());

class IconGeneratorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spendly Icon Generator',
      home: IconGeneratorPage(),
    );
  }
}

class IconGeneratorPage extends StatefulWidget {
  @override
  _IconGeneratorPageState createState() => _IconGeneratorPageState();
}

class _IconGeneratorPageState extends State<IconGeneratorPage> {
  bool _generating = false;

  Future<void> generateIcons() async {
    setState(() {
      _generating = true;
    });

    try {
      // Generate different sizes
      final sizes = [48, 72, 96, 144, 192, 512];
      
      for (final size in sizes) {
        final iconData = await _generateIcon(size.toDouble());
        
        // Create directory if it doesn't exist
        final iconDir = Directory('icons');
        if (!iconDir.existsSync()) {
          iconDir.createSync();
        }
        
        // Save the file
        final file = File('icons/ic_launcher_${size}x$size.png');
        await file.writeAsBytes(iconData);
        
        print('Generated: ${file.path}');
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Icons generated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }

    setState(() {
      _generating = false;
    });
  }

  Future<Uint8List> _generateIcon(double size) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    // Background circle with gradient effect
    final paint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(size / 2, size / 2),
        size / 2,
        [
          const Color(0xFF1976D2),
          const Color(0xFF1565C0),
        ],
      );
    
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, paint);
    
    // Draw shadow for the "S"
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    
    // Draw the "S" letter
    final textStyle = TextStyle(
      fontSize: size * 0.5,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );
    
    final textSpan = TextSpan(text: 'S', style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    
    // Draw shadow
    textPainter.paint(
      canvas,
      Offset(
        (size - textPainter.width) / 2 + 2,
        (size - textPainter.height) / 2 + 2,
      ),
    );
    
    // Draw main text
    final mainTextPainter = TextPainter(
      text: TextSpan(text: 'S', style: textStyle),
      textDirection: TextDirection.ltr,
    );
    mainTextPainter.layout();
    mainTextPainter.paint(
      canvas,
      Offset(
        (size - mainTextPainter.width) / 2,
        (size - mainTextPainter.height) / 2,
      ),
    );
    
    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    
    return byteData!.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Spendly Icon Generator'),
        backgroundColor: const Color(0xFF1976D2),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Preview of the icon
            Container(
              width: 150,
              height: 150,
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
              child: const Center(
                child: Text(
                  'S',
                  style: TextStyle(
                    fontSize: 75,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        offset: Offset(2, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            const Text(
              'Spendly App Icon',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1976D2),
              ),
            ),
            
            const SizedBox(height: 20),
            
            const Text(
              'This will generate app icons in different sizes\nfor your Android app launcher.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            
            const SizedBox(height: 40),
            
            ElevatedButton(
              onPressed: _generating ? null : generateIcons,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: _generating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Generate Icons',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}