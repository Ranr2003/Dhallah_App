import 'package:flutter/material.dart';

class LoginSignupBackground extends StatelessWidget {
  final Widget child; // هذا المتغير سيسمح لنا بوضع محتويات الشاشة فوق الخلفية

  const LoginSignupBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // الرسم الخاص بالخلفية
          Positioned.fill(
            child: CustomPaint(
              painter: BackgroundPainter(),
            ),
          ),
          // المحتوى الذي سيتم تمريره (المربع الأبيض وغيره)
          SafeArea(child: child),
        ],
      ),
    );
  }
}

// كود الرسم (BackgroundPainter) يبقى كما هو لكن معزول هنا
class BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final Rect rect = Offset.zero & size;

    final Gradient bgGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.white,
        const Color(0xFFD2B4EC).withValues(alpha: 0.08),
      ],
    );
    paint.shader = bgGradient.createShader(rect);
    canvas.drawRect(rect, paint);
    paint.shader = null;

    _drawTopWave(canvas, size, const Color(0xFFD2B4EC).withValues(alpha: 0.3), 0.10);
    _drawTopWave(canvas, size, const Color(0xFFD2B4EC).withValues(alpha: 0.15), 0.07);

    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 0.4;
    for (var i = 0; i < 6; i++) {
      paint.color = const Color(0xFFD2B4EC).withValues(alpha: 0.05 + (i * 0.02));
      var path = Path();
      path.moveTo(0, size.height * (0.25 + i * 0.03));
      path.cubicTo(
          size.width * 0.3, size.height * (0.15 + i * 0.04),
          size.width * 0.7, size.height * (0.55 - i * 0.04),
          size.width, size.height * (0.35 + i * 0.03)
      );
      canvas.drawPath(path, paint);
    }

    paint.style = PaintingStyle.fill;
    _drawBottomWave(canvas, size, const Color(0xFFD2B4EC).withValues(alpha: 0.25), 0.10);
    _drawBottomWave(canvas, size, const Color(0xFFD2B4EC).withValues(alpha: 0.12), 0.06);
  }

  void _drawTopWave(Canvas canvas, Size size, Color color, double hFactor) {
    final paint = Paint()..color = color;
    var path = Path();
    path.lineTo(0, size.height * hFactor);
    path.quadraticBezierTo(size.width * 0.5, size.height * (hFactor + 0.04), size.width, size.height * (hFactor - 0.02));
    path.lineTo(size.width, 0);
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawBottomWave(Canvas canvas, Size size, Color color, double hFactor) {
    final paint = Paint()..color = color;
    var path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, size.height * (1 - hFactor));
    path.quadraticBezierTo(size.width * 0.5, size.height * (1 - hFactor - 0.04), size.width, size.height * (1 - hFactor + 0.02));
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}