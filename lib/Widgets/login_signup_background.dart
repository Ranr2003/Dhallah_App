import 'package:flutter/material.dart';

class LoginSignupBackground extends StatelessWidget {
  final Widget child;

  const LoginSignupBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // استخدمت Color(0xFFDDC5F4).withValues(alpha: 0.1) كخلفية باهتة جداً للملأ
      backgroundColor: const Color(0xFFFBF8FF),
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: BackgroundPainter(),
            ),
          ),
          SafeArea(child: child),
        ],
      ),
    );
  }
}

class BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // --- الموجات العلوية ---

    // الطبقة الأغمق خلفاً (#B293CD)
    paint.color = const Color(0xFFB293CD).withValues(alpha: 0.4);
    var path1 = Path();
    path1.moveTo(0, 0);
    path1.lineTo(size.width * 0.8, 0);
    path1.quadraticBezierTo(size.width * 0.4, size.height * 0.12, 0, size.height * 0.08);
    path1.close();
    canvas.drawPath(path1, paint);

    // الطبقة الأساسية (#C0A2DB)
    paint.color = const Color(0xFFC0A2DB).withValues(alpha: 0.7);
    var path2 = Path();
    path2.moveTo(0, 0);
    path2.lineTo(size.width, 0);
    path2.quadraticBezierTo(size.width * 0.7, size.height * 0.15, 0, size.height * 0.05);
    path2.close();
    canvas.drawPath(path2, paint);

    // --- الموجات السفلية (كما في الصورة المرفقة) ---

    // الطبقة الفاتحة (#DDC5F4)
    paint.color = const Color(0xFFDDC5F4).withValues(alpha: 0.6);
    var pathBottom1 = Path();
    pathBottom1.moveTo(0, size.height);
    pathBottom1.lineTo(size.width, size.height);
    pathBottom1.lineTo(size.width, size.height * 0.82);
    pathBottom1.quadraticBezierTo(size.width * 0.5, size.height * 0.88, 0, size.height * 0.98);
    pathBottom1.close();
    canvas.drawPath(pathBottom1, paint);

    // الطبقة الوسطى (#C0A2DB)
    paint.color = const Color(0xFFC0A2DB).withValues(alpha: 0.5);
    var pathBottom2 = Path();
    pathBottom2.moveTo(0, size.height);
    pathBottom2.lineTo(size.width, size.height);
    pathBottom2.lineTo(size.width, size.height * 0.92);
    pathBottom2.quadraticBezierTo(size.width * 0.4, size.height * 0.95, 0, size.height * 0.85);
    pathBottom2.close();
    canvas.drawPath(pathBottom2, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}