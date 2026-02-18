//Rand
import 'package:flutter/material.dart';
import '../widgets/login_signup_background.dart'; // تأكد من صحة المسار
import 'package:flutter/gestures.dart';
import '../screens/login_page.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LoginSignupBackground(
      child: Center(
        // استخدام SingleChildScrollView لضمان ظهور المحتوى كاملاً في الشاشات الصغيرة
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: MediaQuery.of(context).size.width > 600 ? 400 : MediaQuery.of(context).size.width * 0.85,
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
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
                    // الشعار (اللوجو العلوي)
                    Image.asset(
                      'assets/images/logo.jpeg',
                      height: 70,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 10),

                    // العنوان: تسجيل الحساب
                    const Text(
                      "تسجيل الحساب",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                        fontFamily: 'Cairo', // يفضل استخدام خط Cairo للمظهر العربي
                      ),
                    ),
                    const Text(
                      "سجل معلوماتك ونكمل مشوارنا",
                      style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 25),

                    // الحقول المطلوبة بناءً على الصورة
                    _buildField("الاسم الكامل"),
                    const SizedBox(height: 15),
                    _buildField("البريد الإلكتروني"),
                    const SizedBox(height: 15),
                    _buildField("كلمة السر", isPass: true),
                    const SizedBox(height: 15),
                    _buildField("تأكيد كلمة السر", isPass: true),

                    const SizedBox(height: 25),

                    // زر التسجيل المتدرج
                    _buildSignUpButton(),

                    const SizedBox(height: 20),

                    // رابط تسجيل الدخول
                    GestureDetector(
                      onTap: () {
                        // Navigator.pop(context); // للعودة لصفحة الدخول
                      },
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan( // شلنا كلمة const من هنا
                          style: const TextStyle(fontSize: 14, fontFamily: 'Cairo'),
                          children: [
                            const TextSpan(
                              text: "لديك حساب بالفعل؟ ",
                              style: TextStyle(color: Colors.grey),
                            ),
                            TextSpan(
                              text: " قم بتسجيل الدخول",
                              style: const TextStyle(
                                color: Color(0xFFD2B4EC),
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const LoginPage()),
                                  );
                                },
                            ),
                          ],
                        ),
                      )
                    ),
                  ],
                ),
              ),
              // النص السفلي خارج الصندوق الأبيض (اختياري)
              // const SizedBox(height: 20),
              // const Text(
              //   "dhallah.com",
              //   style: TextStyle(color: Color(0xFF666666), fontSize: 14, letterSpacing: 1.1),
              // ),
              // const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ودجت بناء الحقول النصية
  Widget _buildField(String label, {bool isPass = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 5, bottom: 6),
          child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF444444))
          ),
        ),
        TextField(
          obscureText: isPass,
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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

  // ودجت زر التسجيل
  Widget _buildSignUpButton() {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [
            Color(0xFFE9D7F7), // فاتح
            Color(0xFFD2B4EC), // أغمق قليلاً
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD2B4EC).withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          "قم بالتسجيل",
          style: TextStyle(color: Color(0xFF444444), fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}