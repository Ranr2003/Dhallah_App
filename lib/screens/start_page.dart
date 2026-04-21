import 'package:dhallah_app/utils/app_theme.dart';
import 'package:flutter/material.dart';
// استيراد الخلفية الموحدة
import '../widgets/Wavy_Background.dart';
// استيراد ويدجت الزر
//import '../widgets/custom_button1.dart';
import '../widgets/custom_widgets.dart';

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  bool _isActionVisible = false;

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: Scaffold(
        // استخدام LoginSignupBackground لتكون الخلفية نفس الهوم
        body: WavyBackground(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (!_isActionVisible) {
                setState(() {
                  _isActionVisible = true;
                });
              }
            },
            child: Stack(
              children: [
                // المحتوى الأساسي
                Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // شعار التطبيق (يصغر عند ظهور الأزرار)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          width: _isActionVisible ? screenWidth * 0.35 : screenWidth * 0.48,
                          child: Image.asset(
                            'resourses/DallahAppLogo2.png',
                            fit: BoxFit.contain,
                          ),
                        ),

                        const SizedBox(height: 30),

                        // تبديل الدعاء بالأزرار
                        AnimatedCrossFade(
                          duration: const Duration(milliseconds: 600),
                          crossFadeState: _isActionVisible
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,

                          // الحالة الأولى: الدعاء
                          firstChild: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 30),
                                child: Text(
                                  "اللهم رادَّ الضالة رُدَّ عليَّ ضالتي",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.055,
                                    // لون متناسق مع ثيم الهوم (اللون البنفسجي الغامق)
                                    color: AppColors.darkpurble,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Tajawal', // توحيد الخط مع الهوم
                                  ),
                                ),
                              ),
                              const SizedBox(height: 50),
                              const Text(
                                "إضغط في أي مكان للبدء",
                                style: TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'Tajawal'),
                              ),
                            ],
                          ),

                          // الحالة الثانية: الأزرار
                          secondChild: Column(
                            children: [
                              const SizedBox(height: 20),

                              WaterRippleButton(
                                text: "تسجيل الدخول",
                                onTap: () => Navigator.pushNamed(context, '/login'),
                                width: screenWidth * 0.80,
                                height: 55,
                              ),

                              const SizedBox(height: 18),

                              WaterRippleButton(
                                text: "إنشاء حساب جديد",
                                onTap: () => Navigator.pushNamed(context, '/signup'),
                                width: screenWidth * 0.80,
                                height: 55,
                              ),

                              const SizedBox(height: 20),

                              TextButton(
                                onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                                child: const Text(
                                  "تخطي والدخول كضيف",
                                  style: TextStyle(
                                    color: AppColors.primary, // لون بنفسجي فاتح للتخطي
                                    fontSize: 14,
                                    fontFamily: 'Tajawal',
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
}