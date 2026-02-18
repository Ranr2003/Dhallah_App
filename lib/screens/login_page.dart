//Rand
import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. الخلفية المتدرجة والمنحنيات الطبقية برمجياً
          Positioned.fill(
            child: CustomPaint(
              painter: BackgroundPainter(),
            ),
          ),

          // 2. محتوى الصفحة (المربع الأبيض)
          Center(
            child: SingleChildScrollView(
              child: Container(
                width: MediaQuery.of(context).size.width > 600 ? 400 : MediaQuery.of(context).size.width * 0.85,
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(35),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD2B4EC).withValues(alpha: 0.2),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // الشعار الخاص بك
                    Image.asset(
                      'assets/images/logo.jpeg',
                      height: 90,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "تسجيل الدخول",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF444444)),
                    ),
                    const Text(
                      "هلابك من جديد!",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 35),

                    _buildField("البريد الإلكتروني"),
                    const SizedBox(height: 20),
                    _buildField("كلمة السر", isPass: true),

                    const SizedBox(height: 35),
                    _buildLoginButton(),

                    const SizedBox(height: 25),
                    const Text(
                      "dhallah.com",
                      style: TextStyle(color: Color(0xFFD2B4EC), fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, {bool isPass = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 10),
        TextField(
          obscureText: isPass,
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            filled: true,
            fillColor: const Color(0xFFFBF9FF),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: const Color(0xFFD2B4EC).withValues(alpha: 0.1)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE9D7F7),
            Color(0xFFD2B4EC),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD2B4EC).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          "قم بالتسجيل",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}

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