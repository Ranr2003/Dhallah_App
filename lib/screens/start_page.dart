import 'package:dhallah_app/widgets/Wavy_Background.dart';
import 'package:flutter/material.dart';
import '../widgets/custom_widgets.dart';

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  // متغير للتحكم في حالة ظهور الأزرار أو الدعاء
  bool _isActionVisible = false;

  // --- [Functions Section] ---

  /// وظيفتها: تحويل الحالة من عرض الدعاء إلى عرض أزرار الدخول
  /// تُستدعى عند الضغط على أي مكان في الشاشة
  void _toggleView() {
    if (!_isActionVisible) {
      setState(() {
        _isActionVisible = true;
      });
    }
  }

  /// وظيفتها: التنقل بين الصفحات المختلفة
  /// [routeName] هو اسم الصفحة المعرف في App Routes
  void _navigateTo(String routeName, {bool isReplacement = false}) {
    if (isReplacement) {
      Navigator.pushReplacementNamed(context, routeName);
    } else {
      Navigator.pushNamed(context, routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    // الحصول على أبعاد الشاشة لجعل التصميم متجاوباً (Responsive)
    double screenWidth = MediaQuery.of(context).size.width;

    return Theme(
      // إزالة تأثير الظل عند الضغط (Splash) للحفاظ على نظافة التصميم
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: Scaffold(
        body: WavyBackground(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggleView, // استدعاء دالة التبديل
            child: Stack(
              children: [
                Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // [Widget 1]: شعار التطبيق المتحرك
                        // يصغر حجمه تلقائياً عند ظهور الأزرار لإعطاء مساحة
                        _buildAnimatedLogo(screenWidth),

                        const SizedBox(height: 30),

                        // [Widget 2]: تأثير الانتقال (CrossFade)
                        // يقوم بالتبديل السلس بين "الدعاء" و "أزرار التحكم"
                        AnimatedCrossFade(
                          duration: const Duration(milliseconds: 600),
                          crossFadeState: _isActionVisible
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          firstChild: _buildPrayerSection(screenWidth),
                          secondChild: _buildActionButtons(screenWidth),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- [UI Helper Widgets] ---

  /// وظيفتها: بناء شعار التطبيق مع خاصية التحريك (Animation)
  Widget _buildAnimatedLogo(double screenWidth) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      width: _isActionVisible ? screenWidth * 0.35 : screenWidth * 0.48,
      child: Image.asset(
        'resourses/DallahAppLogo2.png',
        fit: BoxFit.contain,
      ),
    );
  }

  /// وظيفتها: عرض النص الديني (الدعاء) في بداية فتح الصفحة
  Widget _buildPrayerSection(double screenWidth) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Text(
            "اللهم رادَّ الضالة رُدَّ عليَّ ضالتي",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: screenWidth * 0.055,
              color: const Color(0xFF5A4A75), // اللون البنفسجي المعتمد في دله
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
        ),
        const SizedBox(height: 50),
        const Text(
          "إضغط في أي مكان للبدء",
          style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontFamily: 'Cairo'
          ),
        ),
      ],
    );
  }

  /// وظيفتها: بناء قائمة الأزرار (تسجيل، إنشاء حساب، دخول كضيف)
  Widget _buildActionButtons(double screenWidth) {
    return Column(
      children: [
        const SizedBox(height: 20),

        WaterRippleButton(
          text: "تسجيل الدخول",
          onTap: () => _navigateTo('/login'),
          width: screenWidth * 0.80,
          height: 55,
        ),

        const SizedBox(height: 18),

        WaterRippleButton(
          text: "إنشاء حساب جديد",
          onTap: () => _navigateTo('/signup'),
          width: screenWidth * 0.80,
          height: 55,
        ),

        const SizedBox(height: 20),

        TextButton(
          onPressed: () => _navigateTo('/home', isReplacement: true),
          child: const Text(
            "تخطي والدخول كضيف",
            style: TextStyle(
              color: Color(0xFFB293CD),
              fontSize: 14,
              fontFamily: 'Cairo',
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}