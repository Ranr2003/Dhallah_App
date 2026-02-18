//Rand
import 'package:flutter/material.dart';
import '../widgets/login_signup_background.dart'; // تأكد من المسار الصحيح لديك

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LoginSignupBackground(
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            width: MediaQuery.of(context).size.width > 600 ? 400 : MediaQuery.of(context).size.width * 0.85,
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 35),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(35),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD2B4EC).withValues(alpha: 0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // الشعار
                Image.asset(
                  'assets/images/logo.jpeg', // تأكد من إضافة اللوجو في ملف assets
                  height: 80,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 15),

                // العنوان والترحيب
                const Text(
                  "تسجيل الدخول",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF444444)),
                ),
                const Text(
                  "! هلابك من جديد ",
                  style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 30),

                // الحقول
                _buildField("البريد الإلكتروني"),
                const SizedBox(height: 18),
                _buildField("كلمة السر", isPass: true),

                const SizedBox(height: 30),

                // زر الدخول المحدث بالتدرج الصحيح
                _buildLoginButton(),

                const SizedBox(height: 20),

                // الروابط الإضافية (ليس لديك حساب؟)
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(fontSize: 13, fontFamily: 'Cairo'), // أضف نوع الخط المستخدم في مشروعك
                    children: [
                      const TextSpan(
                        text: "ليس لديك حساب ؟ ",
                        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                      ),
                      TextSpan(
                        text: "قم بتسجيل حساب جديد",
                        style: const TextStyle(
                          color: Color(0xFFD2B4EC),
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline, // اختياري: إضافة خط تحت النص ليظهر كرابط
                        ),
                        // هنا يمكنك إضافة التعليق البرمجي للانتقال لصفحة التسجيل لاحقاً
                        // recognizer: TapGestureRecognizer()..onTap = () => print('الانتقال للتسجيل'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "نسيت كلمة السر؟",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFFD2B4EC), fontSize: 13, fontWeight: FontWeight.w600,decoration: TextDecoration.underline),
                ),

                // const SizedBox(height: 30),
                // const Text(
                //   "dhallah.com",
                //   style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1.1),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, {bool isPass = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 5, bottom: 8),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF444444))),
        ),
        TextField(
          obscureText: isPass,
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            filled: true,
            fillColor: const Color(0xFFFBF9FF),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xFFD2B4EC), width: 1.5),
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
          // التدرج من اليمين (أفتح) إلى اليسار (أغمق) حسب طلبك
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [
            Color(0xFFE9D7F7), // الدرجة الفاتحة يمين
            Color(0xFFD2B4EC), // الدرجة الأغمق يسار
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