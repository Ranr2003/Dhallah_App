//login_signup_background.dart
//Rand
import 'package:flutter/material.dart';

class LoginSignupBackground extends StatelessWidget {
  final Widget child;

  const LoginSignupBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // أزلنا اللون الثابت هنا واستبدلنا الـ body بـ Container للتدرج
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFBF8FF), // أبيض مائل للبنفسجي في الأعلى
              Color(0xFFE8DDF4), // الموفي الفاتح في الأسفل ليختلط مع التموجات
            ],
            stops: [0.6, 1.0], // يبدأ التدرج بالظهور فعلياً بعد منتصف الشاشة
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
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // التموجات العلوية
    _updrawBottomWaves(canvas, size, paint);

    // التموجات السفليه
    _drawBottomWaves(canvas, size, paint);
  }

  void _updrawBottomWaves(Canvas canvas, Size size, Paint paint) {
    // التموجات العلوية في الجهه اليمنى
    // الايمن الخلفي السفلي
    final Rect rectRight1 = Rect.fromLTWH(size.width * 0.5, 0, size.width * 0.9, size.height * 0.25);
    paint.shader = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        const Color(0xFFB293CD),
        const Color(0xFFE8DDF4),
      ],
    ).createShader(rectRight1);

    var pathRight1 = Path();
    pathRight1.moveTo(size.width, 0);
    pathRight1.lineTo(size.width * 0.2, 0);
    pathRight1.quadraticBezierTo(size.width * 0.7, size.height * 0.01, size.width, size.height * 0.07);
    pathRight1.close();
    canvas.drawPath(pathRight1, paint);

    // الايمن الامامي العلوي
    paint.shader = LinearGradient(
      begin: Alignment.centerRight,
      end: Alignment.centerLeft,
      colors: [
        const Color(0xFFB293CD),
        const Color(0xFFE8DDF4),
      ],
    ).createShader(rectRight1);

    var pathRight2 = Path();
    pathRight2.moveTo(size.width, 0);
    pathRight2.lineTo(size.width * 0.4, 0);
    pathRight2.quadraticBezierTo(size.width * 0.97, size.height * 0.04, size.width, size.height * 0.01);
    pathRight2.close();
    canvas.drawPath(pathRight2, paint);

    // التموجات العلوية في الجهه اليسرى
    //  الايسر الامامي السفلي
    final Rect rect1 = Rect.fromLTWH(0, 0, size.width, size.height * 0.35);
    paint.shader = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Colors.white,
        const Color(0xFFE8DDF4),
        const Color(0xFFB293CD),
      ],
      stops: const [0.0, 0.03, 1.0],
    ).createShader(rect1);

    var pathLeft1 = Path();
    pathLeft1.moveTo(0, 0);
    pathLeft1.lineTo(size.width * 0.8, 0);
    pathLeft1.quadraticBezierTo(size.width * 0.10, size.height * 0.10, 0, size.height * 0.18);
    pathLeft1.close();
    canvas.drawPath(pathLeft1, paint);

    // الايسر الخلفي العلوي
    final Rect rect2 = Rect.fromLTWH(0, 0, size.width, size.height * 0.28);
    paint.shader = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        const Color(0xFFB293CD),
        const Color(0xFFE8DDF4),
        Colors.white,
      ],
      stops: const [0.0, 0.75, 1.0],
    ).createShader(rect2);

    var pathLeft2 = Path();
    pathLeft2.moveTo(0, 0);
    pathLeft2.lineTo(size.width * 0.55, 0);
    pathLeft2.quadraticBezierTo(size.width * 0.9, -size.height * 0.1, 0, size.height * 0.10);
    pathLeft2.close();
    canvas.drawPath(pathLeft2, paint);
  }
//---------------------------------------------------------------------------------------
  void _drawBottomWaves(Canvas canvas, Size size, Paint paint) {
    // التموجات السفليه في جهه اليسار
    //التموج الخلفي في الاعلى
    paint.shader = LinearGradient(
      begin: Alignment.bottomLeft,
      end: Alignment.bottomRight,
      colors: [const Color(0xFFB293CD), const Color(0xFFFBF8FF)],
    ).createShader(Rect.fromLTWH(0, size.height * 0.9, size.width, size.height * 0.1));

    var pathLeft1 = Path();
    pathLeft1.moveTo(0, size.height);
    pathLeft1.lineTo(size.width, size.height);
    pathLeft1.lineTo(size.width, size.height * 0.92);
    pathLeft1.quadraticBezierTo(size.width * 0.3, size.height * 0.9, 0, size.height * 0.8);
    pathLeft1.close();
    canvas.drawPath(pathLeft1, paint);

    //التموج الامامي في الاسفل
    paint.shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [const Color(0xFFE8DDF4), const Color(0xFFB293CD)]
    ).createShader(Rect.fromLTWH(0, size.height * 0.8, size.width, size.height * 0.2));

    var pathLeftL2 = Path();
    pathLeftL2.moveTo(0, size.height);
    pathLeftL2.lineTo(size.width, size.height);
    pathLeftL2.lineTo(size.width, size.height * 0.85);
    pathLeftL2.quadraticBezierTo(size.width * 0.7, size.height * 0.97, 0, size.height * 0.85);
    pathLeftL2.close();
    canvas.drawPath(pathLeftL2, paint);

    //التموجات السفلية في جهه اليمين
    // الخلفي في الاعلى
    paint.shader = LinearGradient(
      begin: Alignment.centerRight,
      end: Alignment.centerLeft,
      colors: [const Color(0xFFB293CD).withOpacity(0.5), const Color(0xFFB293CD)],
      stops: const [0.0, 0.2],
    ).createShader(Rect.fromLTWH(0, size.height * 0.8, size.width, size.height * 0.2));

    var pathRight1 = Path();
    pathRight1.moveTo(size.width, size.height);
    pathRight1.lineTo(0, size.height);
    pathRight1.lineTo(0, size.height * 0.99);
    pathRight1.quadraticBezierTo(size.width * 0.67, size.height * 0.91, size.width, size.height * 0.78);
    pathRight1.close();
    canvas.drawPath(pathRight1, paint);

    // الأمامي في الاسفل
    paint.shader = LinearGradient(
      begin: Alignment.bottomRight,
      end: Alignment.bottomLeft,
      colors: [const Color(0xFFB293CD), const Color(0xFFE8DDF4), const Color(0xFFE8DDF4)],
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
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}