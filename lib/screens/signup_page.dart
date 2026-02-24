//Rand
import 'package:dhallah_app/services/authentication_serv.dart';
import 'package:flutter/material.dart';
import '../widgets/login_signup_background.dart';
import 'package:flutter/gestures.dart';
import '../screens/login_page.dart';
// استيراد السيرفس الخاصة بك

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // 1. تعريف المتحكمات لسحب النص من الحقول الأربعة
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // 2. نسخة من كلاس التوثيق
  final AuthenticationService _authService = AuthenticationService();

  // متغير حالة التحميل
  bool _isLoading = false;

  @override
  void dispose() {
    // تنظيف المتحكمات من الذاكرة
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // 3. دالة معالجة التسجيل
  void _handleSignUp() async {
    // التأكد من عدم وجود حقول فارغة
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _usernameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("الرجاء تعبئة جميع الحقول")),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      // استدعاء دالة التسجيل من كلاس AuthenticationService الخاص بك
      final user = await _authService.register(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        confirmPassword: _confirmPasswordController.text.trim(),
      );

      if (user != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("تم إنشاء الحساب بنجاح!")),
          );
          // العودة لصفحة تسجيل الدخول
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("خطأ في التسجيل: ${e.toString()}")),
        );
      }
    } finally {
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
                    Image.asset('assets/images/logo.jpeg', height: 70, fit: BoxFit.contain),
                    const SizedBox(height: 10),
                    const Text(
                      "تسجيل الحساب",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                    ),
                    const Text(
                      "سجل معلوماتك ونكمل مشوارنا",
                      style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 25),

                    // ربط الحقول بالمتحكمات
                    _buildField("الاسم الكامل", _usernameController),
                    const SizedBox(height: 15),
                    _buildField("البريد الإلكتروني", _emailController),
                    const SizedBox(height: 15),
                    _buildField("كلمة السر", _passwordController, isPass: true),
                    const SizedBox(height: 15),
                    _buildField("تأكيد كلمة السر", _confirmPasswordController, isPass: true),

                    const SizedBox(height: 25),

                    _buildSignUpButton(),

                    const SizedBox(height: 20),

                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(fontSize: 14, fontFamily: 'Cairo'),
                        children: [
                          const TextSpan(text: "لديك حساب بالفعل؟ ", style: TextStyle(color: Colors.grey)),
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
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {bool isPass = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 5, bottom: 6),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF444444))),
        ),
        TextField(
          controller: controller, // الربط هنا
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

  Widget _buildSignUpButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _handleSignUp, // ربط الدالة بالزر
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
              color: const Color(0xFFD2B4EC).withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
            "قم بالتسجيل",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
    );
  }
}