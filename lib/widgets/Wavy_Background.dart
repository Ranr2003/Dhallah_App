// Wavy_Background.dart
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class WavyBackground extends StatelessWidget {
  final Widget child;

  const WavyBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFBF8FF), // لون فاتح جداً متناغم مع الثيم
              AppColors.secondary, // استخدام لون الثيم الثانوي
            ],
            stops: [0.6, 1.0],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: BackgroundPainter(),
              ),
            ),
            SafeArea(child: child),
          ],
        ),
      ),
    );
  }
}

class BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // التموجات العلوية
    _updrawBottomWaves(canvas, size, paint);

    // التموجات السفلية
    _drawBottomWaves(canvas, size, paint);
  }

  void _updrawBottomWaves(Canvas canvas, Size size, Paint paint) {
    // التموجات العلوية في الجهة اليمنى
    final Rect rectRight1 = Rect.fromLTWH(size.width * 0.5, 0, size.width * 0.9, size.height * 0.25);
    paint.shader = const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        AppColors.primary, // تم الاستبدال
        AppColors.secondary, // تم الاستبدال
      ],
    ).createShader(rectRight1);

    var pathRight1 = Path();
    pathRight1.moveTo(size.width, 0);
    pathRight1.lineTo(size.width * 0.2, 0);
    pathRight1.quadraticBezierTo(size.width * 0.7, size.height * 0.01, size.width, size.height * 0.07);
    pathRight1.close();
    canvas.drawPath(pathRight1, paint);

    paint.shader = const LinearGradient(
      begin: Alignment.centerRight,
      end: Alignment.centerLeft,
      colors: [
        AppColors.primary,
        AppColors.secondary,
      ],
    ).createShader(rectRight1);

    var pathRight2 = Path();
    pathRight2.moveTo(size.width, 0);
    pathRight2.lineTo(size.width * 0.4, 0);
    pathRight2.quadraticBezierTo(size.width * 0.97, size.height * 0.04, size.width, size.height * 0.01);
    pathRight2.close();
    canvas.drawPath(pathRight2, paint);

    // التموجات العلوية في الجهة اليسرى
    final Rect rect1 = Rect.fromLTWH(0, 0, size.width, size.height * 0.35);
    paint.shader = const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        AppColors.white,
        AppColors.secondary,
        AppColors.primary,
      ],
      stops: [0.0, 0.03, 1.0],
    ).createShader(rect1);

    var pathLeft1 = Path();
    pathLeft1.moveTo(0, 0);
    pathLeft1.lineTo(size.width * 0.8, 0);
    pathLeft1.quadraticBezierTo(size.width * 0.10, size.height * 0.10, 0, size.height * 0.18);
    pathLeft1.close();
    canvas.drawPath(pathLeft1, paint);

    final Rect rect2 = Rect.fromLTWH(0, 0, size.width, size.height * 0.28);
    paint.shader = const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        AppColors.primary,
        AppColors.secondary,
        AppColors.white,
      ],
      stops: [0.0, 0.75, 1.0],
    ).createShader(rect2);

    var pathLeft2 = Path();
    pathLeft2.moveTo(0, 0);
    pathLeft2.lineTo(size.width * 0.55, 0);
    pathLeft2.quadraticBezierTo(size.width * 0.9, -size.height * 0.1, 0, size.height * 0.10);
    pathLeft2.close();
    canvas.drawPath(pathLeft2, paint);
  }

  void _drawBottomWaves(Canvas canvas, Size size, Paint paint) {
    // التموجات السفلية في جهة اليسار
    paint.shader = const LinearGradient(
      begin: Alignment.bottomLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.primary, Color(0xFFFBF8FF)],
    ).createShader(Rect.fromLTWH(0, size.height * 0.9, size.width, size.height * 0.1));

    var pathLeft1 = Path();
    pathLeft1.moveTo(0, size.height);
    pathLeft1.lineTo(size.width, size.height);
    pathLeft1.lineTo(size.width, size.height * 0.92);
    pathLeft1.quadraticBezierTo(size.width * 0.3, size.height * 0.9, 0, size.height * 0.8);
    pathLeft1.close();
    canvas.drawPath(pathLeft1, paint);

    paint.shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.secondary, AppColors.primary]
    ).createShader(Rect.fromLTWH(0, size.height * 0.8, size.width, size.height * 0.2));

    var pathLeftL2 = Path();
    pathLeftL2.moveTo(0, size.height);
    pathLeftL2.lineTo(size.width, size.height);
    pathLeftL2.lineTo(size.width, size.height * 0.85);
    pathLeftL2.quadraticBezierTo(size.width * 0.7, size.height * 0.97, 0, size.height * 0.85);
    pathLeftL2.close();
    canvas.drawPath(pathLeftL2, paint);

    // التموجات السفلية في جهة اليمين
    paint.shader = LinearGradient(
      begin: Alignment.centerRight,
      end: Alignment.centerLeft,
      colors: [AppColors.primary.withOpacity(0.5), AppColors.primary],
      stops: const [0.0, 0.2],
    ).createShader(Rect.fromLTWH(0, size.height * 0.8, size.width, size.height * 0.2));

    var pathRight1 = Path();
    pathRight1.moveTo(size.width, size.height);
    pathRight1.lineTo(0, size.height);
    pathRight1.lineTo(0, size.height * 0.99);
    pathRight1.quadraticBezierTo(size.width * 0.67, size.height * 0.91, size.width, size.height * 0.78);
    pathRight1.close();
    canvas.drawPath(pathRight1, paint);

    paint.shader = const LinearGradient(
      begin: Alignment.bottomRight,
      end: Alignment.bottomLeft,
      colors: [AppColors.primary, AppColors.secondary, AppColors.secondary],
    ).createShader(Rect.fromLTWH(0, size.height * 0.85, size.width, size.height * 0.15));

    var pathRight2 = Path();
    pathRight2.moveTo(size.width, size.height);
    pathRight2.lineTo(0, size.height);
    pathRight2.lineTo(0, size.height * 0.95);
    pathRight2.quadraticBezierTo(size.width * 0.1, size.height * 0.99, size.width, size.height * 0.87);
    pathRight2.close();
    canvas.drawPath(pathRight2, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false; // تغيير لـ false للأداء طالما الرسم ثابت
}