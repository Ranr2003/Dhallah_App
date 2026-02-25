//Rand
import 'package:dhallah_app/screens/account_info_page.dart';
import 'package:dhallah_app/services/authentication_serv.dart';
import 'package:flutter/material.dart';
import '../widgets/login_signup_background.dart';
import 'package:flutter/gestures.dart';
import '../screens/signup_page.dart';
import '../screens/ForgotPassword_page.dart';
// استيراد السيرفس الخاصة بك

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // 1. تعريف المتحكمات لسحب النص من الخانات
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // 2. إنشاء نسخة من كلاس التوثيق الخاص بك
  final AuthenticationService _authService = AuthenticationService();

  // متغير لإظهار مؤشر التحميل عند الضغط على الزر
  bool _isLoading = false;

  @override
  void dispose() {
    // تنظيف الذاكرة عند إغلاق الصفحة
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  void _handleLogin() async {
    // 1. التأكد من أن الحقول ليست فارغة
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("الرجاء تعبئة جميع الحقول")),
      );
      return;
    }

    // 2. تشغيل علامة التحميل
    setState(() { _isLoading = true; });

    try {
      // 3. استدعاء الدالة من الكلاس حقك (AuthenticationService)
      final user = await _authService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (user != null) {
        // 4. إذا نجح تسجيل الدخول، ننتقل لصفحة البروفايل
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const ProfilePage()),
                (route) => false, // يحذف صفحة الدخول من الذاكرة
          );
        }
      }
    } catch (e) {
      // 5. في حال حدوث خطأ (مثل إيميل مو مفعل أو كلمة سر غلط)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll("Exception:", "")),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      // 6. إيقاف علامة التحميل
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }
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
                Image.asset(
                  'assets/images/logo.jpeg',
                  height: 80,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 15),
                const Text(
                  "تسجيل الدخول",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF444444)),
                ),
                const Text(
                  "! هلابك من جديد ",
                  style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 30),

                // تمرير المتحكمات للحقول
                _buildField("البريد الإلكتروني", _emailController),
                const SizedBox(height: 18),
                _buildField("كلمة السر", _passwordController, isPass: true),

                const SizedBox(height: 30),

                // زر الدخول
                _buildLoginButton(),

                const SizedBox(height: 20),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(fontSize: 13, fontFamily: 'Cairo'),
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
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SignUpPage()),
                            );
                          },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    text: "نسيت كلمة السر؟",
                    style: const TextStyle(
                      color: Color(0xFFD2B4EC),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                        );
                      },
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // تعديل الدالة لتستقبل الـ Controller
  Widget _buildField(String label, TextEditingController controller, {bool isPass = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 5, bottom: 8),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF444444))),
        ),
        TextField(
          controller: controller, // الربط هنا
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
    return GestureDetector(
      // التعديل هنا: نستدعي الدالة مباشرة
      onTap: _isLoading ? null : _handleLogin,
      child: Container(
        width: double.infinity,
        height: 55,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
            colors: [Color(0xFFE9D7F7), Color(0xFFD2B4EC)],
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
        child: Center(
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
            "دخول",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
    );
  }
}